#----------Testing Use Case  -------------
# Create an application gateway that hosts multiple web sites.
#
# The input from https://learn.microsoft.com/en-us/azure/application-gateway/tutorial-multiple-sites-cli
#----------All Required Provider Section-----------
terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
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

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"

  suffix = ["agw"]
}

# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/regions/azurerm"
  version = ">= 0.3.0"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

module "application_gateway" {
  source = "../../"

  # Backend address pool configuration for the application gateway
  # Mandatory Input
  backend_address_pools = {
    contosoPool = {
      name = "contosoPool"
    },
    fabrikamPool = {
      name = "fabrikamPool"
    }
  }
  # Backend http settings configuration for the application gateway
  # Mandatory Input
  backend_http_settings = {
    appGatewayBackendHttpSettings = {
      name                  = "appGatewayBackendHttpSettings"
      port                  = 80
      protocol              = "Http"
      cookie_based_affinity = "Disabled"
      path                  = "/"
      request_timeout       = 30
      connection_draining = {
        enable_connection_draining = true
        drain_timeout_sec          = 300
      }
    }
  }
  # Frontend port configuration for the application gateway
  # Mandatory Input
  # WAF : This example NO HTTPS, We recommend to  Secure all incoming connections using HTTPS for production services with end-to-end SSL/TLS or SSL/TLS termination at the Application Gateway to protect against attacks and ensure data remains private and encrypted between the web server and browsers.
  # WAF : Please refer kv_selfssl_waf_https_app_gateway example for HTTPS configuration
  frontend_ports = {

    frontend-port-80 = {
      name = "frontend-port-80"
      port = 80
    },
    port8080 = {
      name = "port8080"
      port = 8080
    }
    # Add more ports as needed
  }
  gateway_ip_configuration = {
    subnet_id = azurerm_subnet.backend.id
  }
  # Http Listerners configuration for the application gateway
  # Mandatory Input
  http_listeners = {
    appGatewayHttpListener = {
      name               = "appGatewayHttpListener"
      host_name          = null
      frontend_port_name = "frontend-port-80"
    },
    contosoListener = {
      name               = "contosoListener"
      frontend_port_name = "frontend-port-80"
      host_name          = "www.contoso.com"
    },
    fabrikamListener = {
      name               = "fabrikamListener"
      frontend_port_name = "frontend-port-80"
      host_names         = ["www.fabrikam.com", "www.fabrikam.org"]
    }
    # # Add more http listeners as needed
  }
  location = azurerm_resource_group.rg_group.location
  # provide Application gateway name
  name = module.naming.application_gateway.name_unique
  # Routing rules configuration for the backend pool
  # Mandatory Input
  request_routing_rules = {
    contosoRule = {
      name                       = "contosoRule"
      rule_type                  = "Basic"
      http_listener_name         = "contosoListener"
      backend_address_pool_name  = "contosoPool"
      backend_http_settings_name = "appGatewayBackendHttpSettings"
      priority                   = 100
    },
    fabrikamRule = {
      name      = "fabrikamRule"
      rule_type = "Basic"

      http_listener_name         = "fabrikamListener"
      backend_address_pool_name  = "fabrikamPool"
      backend_http_settings_name = "appGatewayBackendHttpSettings"
      priority                   = 200
    }
    # Add more rules as needed
  }
  resource_group_name = azurerm_resource_group.rg_group.name
  autoscale_configuration = {
    min_capacity = 2
    max_capacity = 2
  }
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
  # pre-requisites resources input required for the module
  public_ip_name = "${module.naming.public_ip.name_unique}-pip"
  # WAF : Azure Application Gateways v2 are always deployed in a highly available fashion with multiple instances by default. Enabling autoscale ensures the service is not reliant on manual intervention for scaling.
  sku = {
    # Accpected value for names Standard_v2 and WAF_v2
    name = "Standard_v2"
    # Accpected value for tier Standard_v2 and WAF_v2
    tier = "Standard_v2"
    # Accpected value for capacity 1 to 10 for a V1 SKU, 1 to 100 for a V2 SKU
    capacity = 0 # Set the initial capacity to 0 for autoscaling
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
