#----------Testing Use Case  -------------
# Application Gateway routing for different types of traffic from your application. 
# The routing then directs the traffic to different server pools based on the URL.
# The input from https://learn.microsoft.com/en-us/azure/application-gateway/tutorial-url-route-cli

#----------All Required Provider Section----------- 
terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0, < 4.0"
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
  suffix  = ["agw"]
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

module "application-gateway" {
  source = "../../"
  # source             = "Azure/terraform-azurerm-avm-res-network-applicationgateway"
  depends_on = [azurerm_virtual_network.vnet, azurerm_resource_group.rg-group]

  # pre-requisites resources input required for the module

  public_ip_name       = "${module.naming.public_ip.name_unique}-pip"
  resource_group_name  = azurerm_resource_group.rg-group.name
  location             = azurerm_resource_group.rg-group.location
  vnet_name            = azurerm_virtual_network.vnet.name
  subnet_name_frontend = azurerm_subnet.frontend.name
  subnet_name_backend  = azurerm_subnet.backend.name
  # log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace.id
  enable_telemetry = var.enable_telemetry

  # provide Application gateway name 
  name = module.naming.application_gateway.name_unique

  tags = {
    environment = "dev"
    owner       = "application_gateway"
    project     = "AVM"
  }

  sku = {
    # Accpected value for names Standard_v2 and WAF_v2
    name = "Standard_v2"
    # Accpected value for tier Standard_v2 and WAF_v2
    tier = "Standard_v2"
    # Accpected value for capacity 1 to 10 for a V1 SKU, 1 to 100 for a V2 SKU
    capacity = 0 # Set the initial capacity to 0 for autoscaling
  }

  autoscale_configuration = {
    min_capacity = 1
    max_capacity = 2
  }

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

  # Backend address pool configuration for the application gateway
  # Mandatory Input
  backend_address_pools = {
    appGatewayBackendPool = {
      name = "appGatewayBackendPool"

    },
    imagesBackendPool = {
      name = "imagesBackendPool"

    },
    videoBackendPool = {
      name = "videoBackendPool"

    }

  }

  # Backend http settings configuration for the application gateway
  # Mandatory Input
  backend_http_settings = {

    appGatewayBackendHttpSettings = {
      name                  = "appGatewayBackendHttpSettings"
      cookie_based_affinity = "Disabled"
      path                  = "/"
      enable_https          = false
      request_timeout       = 30
      connection_draining = {
        enable_connection_draining = true
        drain_timeout_sec          = 300

      }
    }
    # Add more http settings as needed
  }

  # Http Listerners configuration for the application gateway
  # Mandatory Input
  http_listeners = {
    appGatewayHttpListener = {
      name               = "appGatewayHttpListener"
      host_name          = null
      frontend_port_name = "frontend-port-80"
      //frontend_ip_association = "public"
    },
    backendListener = {
      name               = "backendListener"
      host_name          = null
      frontend_port_name = "port8080"
      // frontend_ip_association = "Private"

    }
    # # Add more http listeners as needed
  }

  # Routing rules configuration for the backend pool
  # Mandatory Input
  request_routing_rules = {
    routing-rule-1 = {
      name                       = "rule1"
      rule_type                  = "Basic"
      http_listener_name         = "appGatewayHttpListener"
      backend_address_pool_name  = "appGatewayBackendPool"
      backend_http_settings_name = "appGatewayBackendHttpSettings"
      priority                   = 100
    }
    routing-rule-2 = {
      name                       = "rule2"
      rule_type                  = "PathBasedRouting"
      url_path_map_name          = "myPathMap"
      http_listener_name         = "backendListener"
      backend_address_pool_name  = "appGatewayBackendPool"
      backend_http_settings_name = "appGatewayBackendHttpSettings"
      priority                   = 200
    }
    # Add more rules as needed
  }

  url_path_map_configurations = {
    url_path_map_default = {
      name                                = "myPathMap"
      default_backend_address_pool_name   = "appGatewayBackendPool"
      default_backend_http_settings_name  = "appGatewayBackendHttpSettings"
      default_redirect_configuration_name = null
      default_rewrite_rule_set_name       = null
      path_rules = {
        imagePathRule = {
          name                        = "imagePathRule"
          paths                       = ["/images/*"]
          backend_address_pool_name   = "imagesBackendPool"
          backend_http_settings_name  = "appGatewayBackendHttpSettings"
          redirect_configuration_name = null
          rewrite_rule_set_name       = null
          firewall_policy_id          = null
        },
        videoPathRule = {
          name                        = "videoPathRule"
          paths                       = ["/video/*"]
          backend_address_pool_name   = "videoBackendPool"
          backend_http_settings_name  = "appGatewayBackendHttpSettings"
          redirect_configuration_name = null
          rewrite_rule_set_name       = null
          firewall_policy_id          = null
        }
      }
    }
  }


  # Optional Input  
  zones = ["1", "2", "3"] #["1", "2", "3"] # Zone redundancy for the application gateway

  diagnostic_settings = {
    example_setting = {
      name                           = "${module.naming.application_gateway.name_unique}-diagnostic-setting"
      workspace_resource_id          = azurerm_log_analytics_workspace.log_analytics_workspace.id
      log_analytics_destination_type = "Dedicated" # Or "AzureDiagnostics"
      log_groups                     = ["allLogs"]
      metric_categories              = ["AllMetrics"]
    }
  }

}
