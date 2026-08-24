
#----------Testing Use Case  -------------
# Application Gateway routing traffic from your application.
# Add a custom health probe to application gateway
# This example demonstrates how to create an Application Gateway configure with custom name for public and private ip address.


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
      name = "app-Gateway-Backend-Pool-80"
      properties = {
        backend_addresses = [
          { ip_address = "100.64.2.6" },
          { ip_address = "100.64.2.5" },
        ]
      }
    },
    {
      name = "app-Gateway-Backend-Pool-81"
      properties = {
        backend_addresses = [
          { fqdn = "example1.com" },
          { fqdn = "example2.com" },
        ]
      }
    }
  ]
  # Backend http settings configuration for the application gateway
  # Mandatory Input
  backend_http_settings_collection = [
    {
      name = "app-Gateway-Backend-Http-Settings-80"
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
    },
    {
      name = "app-Gateway-Backend-Http-Settings-81"
      properties = {
        port                  = 81
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
  enable_telemetry = var.enable_telemetry
  frontend_ip_configurations = [
    {
      name = "public-ip-custom-name"
      properties = {
        public_ip_address = {
          id = azurerm_public_ip.public_ip.id
        }
      }
    },
    {
      name = "private-ip-custom-name"
      properties = {
        private_ip_address           = "100.64.1.5"
        private_ip_allocation_method = "Static"
        subnet = {
          id = azurerm_subnet.backend.id
        }
      }
    }
  ]
  # frontend port configuration block for the application gateway
  # WAF : This example NO HTTPS, We recommend to  Secure all incoming connections using HTTPS for production services with end-to-end SSL/TLS or SSL/TLS termination at the Application Gateway to protect against attacks and ensure data remains private and encrypted between the web server and browsers.
  # WAF : Please refer kv_selfssl_waf_https_app_gateway example for HTTPS configuration
  frontend_ports = [
    {
      name = "port_81"
      properties = {
        port = 81
      }
    },
    {
      name = "port_80"
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
      name = "app-Gateway-Http-Listener-80"
      properties = {
        frontend_ip_configuration = {
          id = "${local.agw_id}/frontendIPConfigurations/public-ip-custom-name"
        }
        frontend_port = {
          id = "${local.agw_id}/frontendPorts/port_80"
        }
        protocol = "Http"
      }
    },
    {
      name = "app-Gateway-Http-Listener-81"
      properties = {
        frontend_ip_configuration = {
          id = "${local.agw_id}/frontendIPConfigurations/private-ip-custom-name"
        }
        frontend_port = {
          id = "${local.agw_id}/frontendPorts/port_81"
        }
        protocol = "Http"
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
          id = "${local.agw_id}/httpListeners/app-Gateway-Http-Listener-80"
        }
        backend_address_pool = {
          id = "${local.agw_id}/backendAddressPools/app-Gateway-Backend-Pool-80"
        }
        backend_http_settings = {
          id = "${local.agw_id}/backendHttpSettingsCollection/app-Gateway-Backend-Http-Settings-80"
        }
        priority = 100
      }
    },
    {
      name = "rule-2"
      properties = {
        rule_type = "Basic"
        http_listener = {
          id = "${local.agw_id}/httpListeners/app-Gateway-Http-Listener-81"
        }
        backend_address_pool = {
          id = "${local.agw_id}/backendAddressPools/app-Gateway-Backend-Pool-81"
        }
        backend_http_settings = {
          id = "${local.agw_id}/backendHttpSettingsCollection/app-Gateway-Backend-Http-Settings-81"
        }
        priority = 101
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
