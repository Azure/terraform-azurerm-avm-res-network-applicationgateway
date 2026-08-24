
#----------Testing Use Case  -------------
# Application Gateway routing traffic from your application.
# Add a custom health probe to application gateway


#----------All Required Provider Section-----------
terraform {
  required_version = ">= 1.12, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.9"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.2"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.3"

  suffix = ["agw"]
}

# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/regions/azurerm"
  version = "0.8.2"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

locals {
  agw_id = "${azurerm_resource_group.rg_group.id}/providers/Microsoft.Network/applicationGateways/${module.naming.application_gateway.name_unique}"
}

module "application_gateway" {
  source = "../../"

  location = azurerm_resource_group.rg_group.location
  # provide Application gateway name
  name = module.naming.application_gateway.name_unique
  # pre-requisites resources input required for the module
  parent_id = azurerm_resource_group.rg_group.id
  autoscale_configuration = {
    min_capacity = 2
    max_capacity = 3
  }
  # Backend address pool configuration for the application gateway
  # Mandatory Input
  backend_address_pools = [
    {
      name = "app-Gateway-Backend-Pool"
      properties = {
        backend_addresses = [
          { ip_address = "100.64.2.6" },
          { ip_address = "100.64.2.5" },
        ]
      }
    }
  ]
  # Backend http settings configuration for the application gateway
  # Mandatory Input
  backend_http_settings_collection = [
    {
      name = "app-Gateway-Backend-Http-Settings"
      properties = {
        port                  = 80
        protocol              = "Http"
        cookie_based_affinity = "Disabled"
        path                  = "/"
        request_timeout       = 30
        connection_draining = {
          enabled              = true
          drain_timeout_in_sec = 300
        }
        probe = {
          id = "${local.agw_id}/probes/Probe1"
        }
        probe_enabled = true
      }
    }
  ]
  enable_telemetry = var.enable_telemetry
  frontend_ip_configurations = [
    {
      name = "appGatewayFrontendPublicIP"
      properties = {
        public_ip_address = {
          id = azurerm_public_ip.public_ip.id
        }
      }
    }
  ]
  # frontend port configuration block for the application gateway
  # WAF : This example NO HTTPS, We recommend to  Secure all incoming connections using HTTPS for production services with end-to-end SSL/TLS or SSL/TLS termination at the Application Gateway to protect against attacks and ensure data remains private and encrypted between the web server and browsers.
  # WAF : Please refer kv_selfssl_waf_https_app_gateway example for HTTPS configuration
  frontend_ports = [
    {
      name = "frontend-port-80"
      properties = {
        port = 80
      }
    }
  ]
  gateway_ip_configurations = [
    {
      name = "appGatewayIpConfig"
      properties = {
        subnet = {
          id = azurerm_subnet.backend.id
        }
      }
    }
  ]
  # Http Listerners configuration for the application gateway
  # Mandatory Input
  http_listeners = [
    {
      name = "app-Gateway-Http-Listener"
      properties = {
        frontend_ip_configuration = {
          id = "${local.agw_id}/frontendIPConfigurations/appGatewayFrontendPublicIP"
        }
        frontend_port = {
          id = "${local.agw_id}/frontendPorts/frontend-port-80"
        }
        protocol = "Http"
      }
    }
  ]
  # probe configurations for the application gateway
  # WAF : Use Health Probes to detect backend availability
  # # Optional Input
  probes = [
    {
      name = "Probe1"
      properties = {
        interval                                  = 30
        timeout                                   = 10
        unhealthy_threshold                       = 3
        protocol                                  = "Http"
        port                                      = 80
        path                                      = "/health"
        host                                      = "127.0.0.1"
        pick_host_name_from_backend_http_settings = false
        # Note on host : The Hostname used for this Probe. If the Application Gateway is configured for a single site,
        # by default the Host name should be specified as 127.0.0.1,
        # unless otherwise configured in custom probe.
        # Cannot be set if pick_host_name_from_backend_http_settings is set to true.
        # You must provide host value if pick_host_name_from_backend_http_settings is set to false.
        match = {
          body         = null
          status_codes = ["200-399"]
        }
      }
    }
  ]
  # Routing rules configuration for the backend pool
  # Mandatory Input
  request_routing_rules = [
    {
      name = "rule-1"
      properties = {
        rule_type = "Basic"
        http_listener = {
          id = "${local.agw_id}/httpListeners/app-Gateway-Http-Listener"
        }
        backend_address_pool = {
          id = "${local.agw_id}/backendAddressPools/app-Gateway-Backend-Pool"
        }
        backend_http_settings = {
          id = "${local.agw_id}/backendHttpSettingsCollection/app-Gateway-Backend-Http-Settings"
        }
        priority = 100
      }
    }
  ]
  # WAF : Azure Application Gateways v2 are always deployed in a highly available fashion with multiple instances by default. Enabling autoscale ensures the service is not reliant on manual intervention for scaling.
  sku = {
    # Accpected value for names Standard_v2 and WAF_v2
    name = "Standard_v2"
    # Accpected value for tier Standard_v2 and WAF_v2
    tier = "Standard_v2"
  }
  tags = {
    environment = "dev"
    owner       = "application_gateway"
    project     = "AVM"
  }
  # Optional Input
  # WAF :  Deploy Application Gateway in a zone-redundant configuration
  # Zone redundancy for the application gateway ["1", "2", "3"]
  zones = ["1", "2", "3"]
}
