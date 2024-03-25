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
  min = 0
  max = length(module.regions.regions) - 1

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
    min_capacity = 2
    max_capacity = 15
  }

  # frontend configuration block for the application gateway
  # Provide Static IP address from backend subnet
  # Mandatory Input

  private_ip_address = "100.64.1.5"
  # Frontend port configuration for the application gateway
  # Mandatory Input
  frontend_ports = {

    frontend-port-80 = {
      name = "frontend-port-80"
      port = 80
    },
    frontend-port-81 = {
      name = "frontend-port-81"
      port = 81
    }
    # Add more ports as needed
  }


  # Backend address pool configuration for the application gateway
  # Mandatory Input
  backend_address_pools = {
    pool-1 = {
      name         = "Pool1"
      ip_addresses = ["100.64.2.4", "100.64.2.5"]
      #fqdns        = ["example1.com", "example2.com"]
    }
    pool-2 = {
      name = "Pool2"
      #ip_addresses = ["10.90.2.4", "10.90.2.6"]
      fqdns = ["example1.com", "example2.com"]
    }
  }


  # Http Listerners configuration for the application gateway
  # Mandatory Input
  http_listeners = {
    http_listeners-for-80 = {
      name = "http_listeners-for-80"
      # The frontend_port_name must be same as given frontend_port block 
      frontend_port_name      = "frontend-port-80"
      protocol                = "Http"
      frontend_ip_association = "public"
    },
    http_listeners-for-81 = {
      name = "http_listeners-for-81"
      # The frontend_port_name must be same as given frontend_port block
      frontend_port_name      = "frontend-port-81"
      protocol                = "Http"
      frontend_ip_association = "both"
    }
    # Add more http listeners as needed
  }

  # Backend http settings configuration for the application gateway
  # Mandatory Input
  backend_http_settings = {
    port80 = {
      name                  = "backend_http_settings-port-80"
      port                  = 80
      protocol              = "Http"
      cookie_based_affinity = "Disabled"
    },
    port81 = {
      name                  = "backend_http_settings-port-81"
      port                  = 81
      protocol              = "Http"
      cookie_based_affinity = "Disabled"
    }
    # Add more http settings as needed
  }

  # Routing rules configuration for the backend pool
  # Mandatory Input
  request_routing_rules = {
    routing-rule-1 = {
      name      = "Rule1"
      rule_type = "Basic"
      # The http_listener_name must be same as given http_listeners block
      http_listener_name = "http_listeners-for-80"
      # The backend_address_pool_name  must be same as given backend_address_pool block
      backend_address_pool_name = "Pool1"
      # The backend_http_settings_name must be same as given backend_http_settings block
      backend_http_settings_name = "backend_http_settings-port-80"
      priority                   = 9
    },
    routing-rule-2 = {
      name      = "Rule2"
      rule_type = "Basic"
      # The http_listener_name must be same as given http_listeners block
      http_listener_name = "http_listeners-for-81"
      # The backend_address_pool_name must be same as given backend_address_pool block
      backend_address_pool_name = "Pool2"
      # The backend_http_settings_name must be same as given backend_http_settings block
      backend_http_settings_name = "backend_http_settings-port-81"
      priority                   = 10
    },
    # Add more rules as needed
  }

  # Optional Input  
  zones = ["1", "2", "3"] #["1", "2", "3"] # Zone redundancy for the application gateway


  # probe configurations for the application gateway
  # # Optional Input
  # probe_configurations = {
  #   probe1 = {
  #     name                                      = "Probe1"
  #     host                                      = "example.com"
  #     interval                                  = 30
  #     timeout                                   = 10
  #     unhealthy_threshold                       = 3
  #     protocol                                  = "Http"
  #     port                                      = 80
  #     path                                      = "/health"

  #   }
  #   probe2 = {
  #     name                                      = "Probe2"
  #     host                                      = "example.org"
  #     interval                                  = 60
  #     timeout                                   = 15
  #     unhealthy_threshold                       = 2
  #     protocol                                  = "Http"
  #     port                                      = 81
  #     path                                      = "/status"

  #   }
  # }


  # ---> Redirect configuration for the application gateway
  # ---> Optional input

  # redirect_configuration = {
  #   redirect1 = {
  #     name                 = "Redirect1"
  #     redirect_type        = "Permanent"
  #     # redirection is either to URL or target listener, one should be null
  #     target_listener_name = "http_listeners-for-81"
  #     target_url           = null
  #     include_path         = true
  #     include_query_string = false
  #   }
  #   redirect2 = {
  #     name                 = "Redirect2"
  #     redirect_type        = "Temporary"
  #     # redirection is either to URL or target listener, one should be null
  #     target_listener_name = null
  #     target_url           = "https://example.com/other-path"
  #     include_path         = true
  #     include_query_string = true
  #   }
  # }


  #   url_path_map_configurations = {
  #     url_path_map_default = {
  #       name                                = "URL Path Map 1"
  #       default_backend_address_pool_name   = "default-pool"
  #       default_backend_http_settings_name  = "default-settings"
  #       default_redirect_configuration_name = "redirect-config"
  #       default_rewrite_rule_set_name       = null
  #       path_rules = [
  #         {
  #           name                        = "Path Rule 1"
  #           backend_address_pool_name   = "Pool1"
  #           backend_http_settings_name  = "backend_http_settings-port-80"
  #           paths                       = ["/path1", "/path2"]
  #           redirect_configuration_name = "redirect-rule"
  #           rewrite_rule_set_name       = null
  #           firewall_policy_id          = null
  #         }
  #         # {
  #         #   name                        = "Path Rule 2"
  #         #   backend_address_pool_name   = "Pool2"
  #         #   backend_http_settings_name  = "backend_http_settings-port-81"
  #         #   paths                       = ["/path3", "/path4"]
  #         #   redirect_configuration_name = null
  #         #   rewrite_rule_set_name       = null
  #         #   firewall_policy_id          = null
  #         # }
  #       ]
  #     }
  #   }
  # }

  #   url_path_map_configurations = {
  #     url_path_map_default = {
  #       name                                = "URL Path Map 1"
  #       default_backend_address_pool_name   = "default-pool"
  #       default_backend_http_settings_name  = "default-settings"
  #       default_redirect_configuration_name = "redirect-config"
  #       default_rewrite_rule_set_name       = null
  #       path_rules = [
  #         {
  #           name                        = "Path Rule 1"
  #           backend_address_pool_name   = null
  #           backend_http_settings_name  = null
  #           paths                       = ["/path1", "/path2"]
  #           redirect_configuration_name = "redirect-rule"
  #           rewrite_rule_set_name       = null
  #           firewall_policy_id          = null
  #         }
  #       ]
  #     }
  #   }
}

