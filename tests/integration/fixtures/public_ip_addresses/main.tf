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

resource "azapi_resource" "network_security_group" {
  location  = var.location
  name      = "nsg-${random_id.suffix.hex}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/networkSecurityGroups@2025-03-01"
  body = {
    properties = {
      securityRules = [
        {
          name = "AllowHttpInbound"
          properties = {
            access                   = "Allow"
            destinationAddressPrefix = "10.87.0.0/24"
            destinationPortRange     = "80"
            direction                = "Inbound"
            priority                 = 100
            protocol                 = "Tcp"
            sourceAddressPrefix      = "Internet"
            sourcePortRange          = "*"
          }
        },
        {
          name = "AllowGatewayManagerInbound"
          properties = {
            access                   = "Allow"
            destinationAddressPrefix = "*"
            destinationPortRange     = "65200-65535"
            direction                = "Inbound"
            priority                 = 110
            protocol                 = "Tcp"
            sourceAddressPrefix      = "GatewayManager"
            sourcePortRange          = "*"
          }
        }
      ]
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
      networkSecurityGroup = {
        id = azapi_resource.network_security_group.id
      }
    }
  }
  response_export_values = []
}

resource "azapi_resource" "private_link_subnet" {
  name      = "application-gateway-private-link"
  parent_id = azapi_resource.virtual_network.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2025-03-01"
  body = {
    properties = {
      addressPrefix = "10.87.1.0/24"
    }
  }
  response_export_values = []
}

resource "azapi_resource" "private_endpoint_subnet" {
  name      = "private-endpoints"
  parent_id = azapi_resource.virtual_network.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2025-03-01"
  body = {
    properties = {
      addressPrefix                  = "10.87.2.0/24"
      privateEndpointNetworkPolicies = "Disabled"
    }
  }
  response_export_values = []
}

resource "azapi_resource" "private_dns_zone" {
  location  = "global"
  name      = "privatelink.appgw.example.test"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/privateDnsZones@2024-06-01"
  body      = {}
  response_export_values = []
}

# A single fixture state preserves dependencies during Terraform test teardown:
# endpoint and gateway -> subnets, VNet/NSG, and DNS zone -> resource group.
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
    private_link_configuration = {
      private_link_configuration_key = "gateway-link"
    }
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
  private_endpoints = {
    endpoint = {
      name               = "pe-${random_id.suffix.hex}"
      subnet_resource_id = azapi_resource.private_endpoint_subnet.id
      private_dns_zone_resource_ids = [
        azapi_resource.private_dns_zone.id
      ]
    }
  }
  private_link_configurations = [{
    name = "gateway-link"
    ip_configurations = [{
      name                         = "gateway-link-ip"
      primary                      = true
      private_ip_address           = "10.87.1.10"
      private_ip_allocation_method = "Static"
      subnet = {
        id = azapi_resource.private_link_subnet.id
      }
    }]
  }]
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
    frontend_ip_configurations   = "properties.frontendIPConfigurations"
    private_endpoint_connections = "properties.privateEndpointConnections"
    provisioning_state           = "properties.provisioningState"
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

data "azapi_resource" "private_dns_zone_group" {
  resource_id = module.gateway.private_endpoint_dns_zone_group_ids["endpoint"]
  type        = "Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2025-03-01"
  response_export_values = {
    private_dns_zone_configs = "properties.privateDnsZoneConfigs"
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

output "private_endpoint_connection_target_ids" {
  value = [
    for connection in data.azapi_resource.gateway.output.private_endpoint_connections :
    connection.properties.privateEndpoint.id
  ]
}

output "private_dns_zone_ids" {
  value = [
    for zone_config in data.azapi_resource.private_dns_zone_group.output.private_dns_zone_configs :
    zone_config.properties.privateDnsZoneId
  ]
}

output "expected_private_dns_zone_id" {
  value = azapi_resource.private_dns_zone.id
}

output "public_ip_addresses" {
  value = module.gateway.public_ip_addresses
}

output "private_endpoint_resource_id" {
  value = module.gateway.private_endpoint_ids["endpoint"]
}

output "private_dns_zone_group_resource_id" {
  value = module.gateway.private_endpoint_dns_zone_group_ids["endpoint"]
}
