provider "azapi" {}

# The module still requires AzureRM for its existing support-resource declarations.
provider "azurerm" {
  resource_provider_registrations = "none"
  features {}
}

provider "random" {}

data "azapi_client_config" "current" {}

resource "random_id" "suffix" {
  byte_length = 6
}

resource "azapi_resource" "resource_group" {
  location               = var.location
  name                   = "rg-avm-ref-${random_id.suffix.hex}"
  parent_id              = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type                   = "Microsoft.Resources/resourceGroups@2024-03-01"
  body                   = {}
  response_export_values = []
  tags                   = var.tags
}

resource "azapi_resource" "virtual_network" {
  location  = var.location
  name      = "vnet-ref-${random_id.suffix.hex}"
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
  tags                   = var.tags
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

resource "azapi_resource" "public_ip" {
  location  = var.location
  name      = "pip-ref-${random_id.suffix.hex}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/publicIPAddresses@2025-03-01"
  body = {
    properties = {
      ipTags = [for type, tag in var.public_ip_tags : {
        ipTagType = type
        tag       = tag
      }]
      publicIPAddressVersion   = "IPv4"
      publicIPAllocationMethod = "Static"
    }
    sku = {
      name = "Standard"
      tier = "Regional"
    }
    zones = ["1", "2", "3"]
  }
  response_export_values = ["properties.ipAddress"]
  tags                   = var.tags
}

module "gateway" {
  source = "../../"

  location  = var.location
  name      = local.gateway_name
  parent_id = azapi_resource.resource_group.id
  autoscale_configuration = {
    min_capacity = 2
    max_capacity = 3
  }
  backend_address_pools = [{
    name       = local.component_names.backendAddressPools
    properties = { backend_addresses = [] }
  }]
  backend_http_settings_collection = [{
    name = local.component_names.backendHttpSettingsCollection
    properties = {
      cookie_based_affinity = "Disabled"
      port                  = 80
      probe                 = local.references.probes
      protocol              = "Http"
      request_timeout       = 20
    }
  }]
  enable_telemetry = var.enable_telemetry
  frontend_ip_configurations = [{
    name = local.component_names.frontendIPConfigurations
    properties = {
      public_ip_address = { id = azapi_resource.public_ip.id }
    }
  }]
  frontend_ports = [{
    name       = local.component_names.frontendPorts
    properties = { port = 80 }
  }]
  gateway_ip_configurations = [{
    name = "GatewaySubnet"
    properties = {
      subnet = { id = azapi_resource.subnet.id }
    }
  }]
  http_listeners = [{
    name = local.component_names.httpListeners
    properties = {
      frontend_ip_configuration = local.references.frontendIPConfigurations
      frontend_port             = local.references.frontendPorts
      protocol                  = "Http"
    }
  }]
  probes = [{
    name = local.component_names.probes
    properties = {
      host                = "127.0.0.1"
      interval            = 30
      path                = "/health"
      protocol            = "Http"
      timeout             = 10
      unhealthy_threshold = 3
    }
  }]
  request_routing_rules = [{
    name = "BasicRule"
    properties = {
      backend_address_pool  = local.references.backendAddressPools
      backend_http_settings = local.references.backendHttpSettingsCollection
      http_listener         = local.references.httpListeners
      priority              = 100
      rule_type             = "Basic"
    }
  }]
  sku = {
    name = "Standard_v2"
    tier = "Standard_v2"
  }
  tags  = var.tags
  zones = ["1", "2", "3"]
}

data "azapi_resource" "gateway" {
  resource_id = module.gateway.resource_id
  type        = "Microsoft.Network/applicationGateways@2025-03-01"
  response_export_values = {
    autoscale_min_capacity = "properties.autoscaleConfiguration.minCapacity"
    frontends              = "properties.frontendIPConfigurations"
    listeners              = "properties.httpListeners"
    provisioning_state     = "properties.provisioningState"
    rules                  = "properties.requestRoutingRules"
    settings               = "properties.backendHttpSettingsCollection"
  }

  lifecycle {
    postcondition {
      condition     = self.output.provisioning_state == "Succeeded"
      error_message = "The deployed gateway must reach Succeeded."
    }
    postcondition {
      condition     = self.output.autoscale_min_capacity >= 2
      error_message = "Azure readback must confirm autoscaling with a minimum capacity of at least two."
    }
    postcondition {
      condition = alltrue([
        lower(one(self.output.frontends).properties.publicIPAddress.id) == lower(azapi_resource.public_ip.id),
        lower(one(self.output.settings).properties.probe.id) == lower(local.expected_ids.probes),
        lower(one(self.output.listeners).properties.frontendIPConfiguration.id) == lower(local.expected_ids.frontendIPConfigurations),
        lower(one(self.output.listeners).properties.frontendPort.id) == lower(local.expected_ids.frontendPorts),
        lower(one(self.output.rules).properties.backendAddressPool.id) == lower(local.expected_ids.backendAddressPools),
        lower(one(self.output.rules).properties.backendHttpSettings.id) == lower(local.expected_ids.backendHttpSettingsCollection),
        lower(one(self.output.rules).properties.httpListener.id) == lower(local.expected_ids.httpListeners),
      ])
      error_message = "Azure readback must resolve every exercised named reference to its expected child ID and preserve the external public IP reference."
    }
  }
}
