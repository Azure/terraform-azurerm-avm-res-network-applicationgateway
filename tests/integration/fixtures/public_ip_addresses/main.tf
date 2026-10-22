terraform {
  required_version = ">= 1.12, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    # tflint-ignore: terraform_unused_required_providers
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.117, < 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

data "azapi_client_config" "current" {}

resource "random_id" "suffix" {
  byte_length = 6
}

locals {
  gateway_name        = "agw-pip-${random_id.suffix.hex}"
  gateway_resource_id = "${azapi_resource.resource_group.id}/providers/Microsoft.Network/applicationGateways/${local.gateway_name}"
  public_ip_name      = "pip-${random_id.suffix.hex}"
}

resource "azapi_resource" "resource_group" {
  location               = var.location
  name                   = "rg-avm-pip-${random_id.suffix.hex}"
  parent_id              = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type                   = "Microsoft.Resources/resourceGroups@2024-03-01"
  body                   = {}
  response_export_values = []
}

resource "azapi_resource" "virtual_network" {
  location  = var.location
  name      = "vnet-${random_id.suffix.hex}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/virtualNetworks@2025-03-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["10.87.0.0/16"]
      }
    }
  }
  response_export_values = []
}

resource "azapi_resource" "subnet" {
  name      = "application-gateway"
  parent_id = azapi_resource.virtual_network.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2025-03-01"
  body = {
    properties = {
      addressPrefix = "10.87.0.0/24"
      delegations = [{
        name = "application-gateway"
        properties = {
          serviceName = "Microsoft.Network/applicationGateways"
        }
      }]
    }
  }
  response_export_values = []
}

# A single fixture state preserves dependencies during Terraform test teardown:
# gateway and managed IP -> subnet/VNet -> resource group.
module "gateway" {
  source = "../../../.."

  location  = var.location
  name      = local.gateway_name
  parent_id = azapi_resource.resource_group.id
  backend_address_pools = [{
    backend_addresses = []
    name              = "backend"
  }]
  backend_http_settings_collection = [{
    cookie_based_affinity = "Disabled"
    name                  = "http"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }]
  enable_telemetry = false
  frontend_ip_configurations = [{
    name                  = "public"
    public_ip_address_key = "edge"
  }]
  frontend_ports = [{
    name = "http"
    port = 80
  }]
  gateway_ip_configurations = [{
    name = "gateway"
    subnet = {
      id = azapi_resource.subnet.id
    }
  }]
  http_listeners = [{
    name = "http"
    frontend_ip_configuration = {
      id = "${local.gateway_resource_id}/frontendIPConfigurations/public"
    }
    frontend_port = {
      id = "${local.gateway_resource_id}/frontendPorts/http"
    }
    protocol = "Http"
  }]
  public_ip_addresses = {
    edge = {
      name              = local.public_ip_name
      domain_name_label = "avm-pip-${random_id.suffix.hex}"
    }
  }
  request_routing_rules = [{
    name = "http"
    backend_address_pool = {
      id = "${local.gateway_resource_id}/backendAddressPools/backend"
    }
    backend_http_settings = {
      id = "${local.gateway_resource_id}/backendHttpSettingsCollection/http"
    }
    http_listener = {
      id = "${local.gateway_resource_id}/httpListeners/http"
    }
    priority  = 100
    rule_type = "Basic"
  }]
  sku = {
    capacity = 1
    name     = "Standard_v2"
    tier     = "Standard_v2"
  }
  tags = {
    purpose = "managed-public-ip-integration"
  }
  zones = ["1"]
}

data "azapi_resource" "gateway" {
  resource_id = module.gateway.resource_id
  type        = "Microsoft.Network/applicationGateways@2025-03-01"
  response_export_values = {
    frontend_ip_configurations = "properties.frontendIPConfigurations"
    provisioning_state         = "properties.provisioningState"
  }
}

data "azapi_resource" "public_ip" {
  resource_id = module.gateway.public_ip_addresses["edge"].resource_id
  type        = "Microsoft.Network/publicIPAddresses@2025-03-01"
  response_export_values = {
    fqdn       = "properties.dnsSettings.fqdn"
    ip_address = "properties.ipAddress"
  }
}

output "attached_public_ip_resource_id" {
  value = one([
    for frontend in data.azapi_resource.gateway.output.frontend_ip_configurations :
    frontend.properties.publicIPAddress.id if frontend.name == "public"
  ])
}

output "expected_public_ip_resource_id" {
  value = "${azapi_resource.resource_group.id}/providers/Microsoft.Network/publicIPAddresses/${local.public_ip_name}"
}

output "gateway_provisioning_state" {
  value = data.azapi_resource.gateway.output.provisioning_state
}

output "gateway_resource_id" {
  value = module.gateway.resource_id
}

output "observed_public_ip_address" {
  value = data.azapi_resource.public_ip.output.ip_address
}

output "observed_public_ip_fqdn" {
  value = data.azapi_resource.public_ip.output.fqdn
}

output "public_ip_addresses" {
  value = module.gateway.public_ip_addresses
}
