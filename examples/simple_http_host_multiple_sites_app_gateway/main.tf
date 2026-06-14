#----------Testing Use Case  -------------
# Create an application gateway that hosts multiple web sites.
#
# The input from https://learn.microsoft.com/en-us/azure/application-gateway/tutorial-multiple-sites-cli
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
      version = "~> 4.0"
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
  version = "0.3.0"

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
  name      = module.naming.application_gateway.name_unique
  parent_id = azurerm_resource_group.rg_group.id
  autoscale_configuration = {
    min_capacity = 2
    max_capacity = 3
  }
  # Backend address pool configuration for the application gateway
  # Mandatory Input
  backend_address_pools = [
    {
      name       = "contosoPool"
      properties = {}
    },
    {
      name       = "fabrikamPool"
      properties = {}
    }
  ]
  # Backend http settings configuration for the application gateway
  # Mandatory Input
  backend_http_settings_collection = [
    {
      name = "appGatewayBackendHttpSettings"
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
      }
    }
  ]
  diagnostic_settings = {
    example_setting = {
      name                           = "${module.naming.application_gateway.name_unique}-diagnostic-setting"
      workspace_resource_id          = azurerm_log_analytics_workspace.log_analytics_workspace.id
      log_analytics_destination_type = "Dedicated" # Or "AzureDiagnostics"
      log_groups                     = ["allLogs"]
      metric_categories              = ["AllMetrics"]
    }
  }
  enable_telemetry = var.enable_telemetry
  frontend_ip_configurations = [
    {
      name = "appGatewayFrontendPublicIP"
      properties = {
        public_ip_address = {
          id = azurerm_public_ip.pip.id
        }
      }
    }
  ]
  # Frontend port configuration for the application gateway
  # Mandatory Input
  # WAF : This example NO HTTPS, We recommend to  Secure all incoming connections using HTTPS for production services with end-to-end SSL/TLS or SSL/TLS termination at the Application Gateway to protect against attacks and ensure data remains private and encrypted between the web server and browsers.
  # WAF : Please refer kv_selfssl_waf_https_app_gateway example for HTTPS configuration
  frontend_ports = [
    {
      name = "frontend-port-80"
      properties = {
        port = 80
      }
    },
    {
      name = "port8080"
      properties = {
        port = 8080
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
      name = "appGatewayHttpListener"
      properties = {
        frontend_ip_configuration = {
          id = "${local.agw_id}/frontendIPConfigurations/appGatewayFrontendPublicIP"
        }
        frontend_port = {
          id = "${local.agw_id}/frontendPorts/frontend-port-80"
        }
        protocol = "Http"
      }
    },
    {
      name = "contosoListener"
      properties = {
        frontend_ip_configuration = {
          id = "${local.agw_id}/frontendIPConfigurations/appGatewayFrontendPublicIP"
        }
        frontend_port = {
          id = "${local.agw_id}/frontendPorts/frontend-port-80"
        }
        protocol  = "Http"
        host_name = "www.contoso.com"
      }
    },
    {
      name = "fabrikamListener"
      properties = {
        frontend_ip_configuration = {
          id = "${local.agw_id}/frontendIPConfigurations/appGatewayFrontendPublicIP"
        }
        frontend_port = {
          id = "${local.agw_id}/frontendPorts/frontend-port-80"
        }
        protocol   = "Http"
        host_names = ["www.fabrikam.com", "www.fabrikam.org"]
      }
    }
  ]
  # Routing rules configuration for the backend pool
  # Mandatory Input
  request_routing_rules = [
    {
      name = "contosoRule"
      properties = {
        rule_type = "Basic"
        http_listener = {
          id = "${local.agw_id}/httpListeners/contosoListener"
        }
        backend_address_pool = {
          id = "${local.agw_id}/backendAddressPools/contosoPool"
        }
        backend_http_settings = {
          id = "${local.agw_id}/backendHttpSettingsCollection/appGatewayBackendHttpSettings"
        }
        priority = 100
      }
    },
    {
      name = "fabrikamRule"
      properties = {
        rule_type = "Basic"
        http_listener = {
          id = "${local.agw_id}/httpListeners/fabrikamListener"
        }
        backend_address_pool = {
          id = "${local.agw_id}/backendAddressPools/fabrikamPool"
        }
        backend_http_settings = {
          id = "${local.agw_id}/backendHttpSettingsCollection/appGatewayBackendHttpSettings"
        }
        priority = 200
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
  # Zone redundancy for the application gateway ["1", "2", "3"]
  zones = ["1", "2", "3"]
}
