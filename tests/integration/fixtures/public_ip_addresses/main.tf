terraform {
  required_version = ">= 1.12, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.117, < 5.0"
    }
    modtm = {
      source  = "azure/modtm"
      version = "~> 0.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

variable "location" {
  type        = string
  default     = "eastus2"
  description = "Azure region for the explicitly approved integration deployment."
  nullable    = false
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
  type                   = "Microsoft.Resources/resourceGroups@2024-03-01"
  name                   = "rg-avm-pip-${random_id.suffix.hex}"
  parent_id              = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  location               = var.location
  body                   = {}
  response_export_values = []
}

resource "azapi_resource" "virtual_network" {
  type      = "Microsoft.Network/virtualNetworks@2025-03-01"
  name      = "vnet-${random_id.suffix.hex}"
  parent_id = azapi_resource.resource_group.id
  location  = var.location
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
  type      = "Microsoft.Network/virtualNetworks/subnets@2025-03-01"
  name      = "application-gateway"
  parent_id = azapi_resource.virtual_network.id
  body = {
    properties = {
      addressPrefix = "10.87.0.0/24"
    }
  }
  response_export_values = []
}

# A single fixture state preserves dependencies during Terraform test teardown:
# gateway and managed IP -> subnet/VNet -> resource group.
module "gateway" {
  source = "../../../.."

  enable_telemetry = false
  location         = var.location
  name             = local.gateway_name
  parent_id        = azapi_resource.resource_group.id
  zones            = ["1"]
  tags = {
    purpose = "managed-public-ip-integration"
  }
  public_ip_addresses = {
    edge = {
      name              = local.public_ip_name
      domain_name_label = "avm-pip-${random_id.suffix.hex}"
    }
  }
  frontend_ip_configurations = [{
    name                  = "public"
    public_ip_address_key = "edge"
  }]
  gateway_ip_configurations = [{
    name = "gateway"
    properties = {
      subnet = {
        id = azapi_resource.subnet.id
      }
    }
  }]
  frontend_ports = [{
    name       = "http"
    properties = { port = 80 }
  }]
  backend_address_pools = [{
    name       = "backend"
    properties = { backend_addresses = [] }
  }]
  backend_http_settings_collection = [{
    name = "http"
    properties = {
      cookie_based_affinity = "Disabled"
      port                  = 80
      protocol              = "Http"
      request_timeout       = 20
    }
  }]
  http_listeners = [{
    name = "http"
    properties = {
      frontend_ip_configuration = {
        id = "${local.gateway_resource_id}/frontendIPConfigurations/public"
      }
      frontend_port = {
        id = "${local.gateway_resource_id}/frontendPorts/http"
      }
      protocol = "Http"
    }
  }]
  request_routing_rules = [{
    name = "http"
    properties = {
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
    }
  }]
  sku = {
    capacity = 1
    name     = "Standard_v2"
    tier     = "Standard_v2"
  }
}

data "azapi_resource" "gateway" {
  type        = "Microsoft.Network/applicationGateways@2025-03-01"
  resource_id = module.gateway.resource_id
  response_export_values = {
    frontend_ip_configurations = "properties.frontendIPConfigurations"
    provisioning_state         = "properties.provisioningState"
  }
}

data "azapi_resource" "public_ip" {
  type        = "Microsoft.Network/publicIPAddresses@2025-03-01"
  resource_id = module.gateway.public_ip_addresses["edge"].resource_id
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
