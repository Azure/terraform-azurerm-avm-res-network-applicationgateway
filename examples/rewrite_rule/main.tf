
#----------Testing Use Case  -------------
# Application Gateway routing traffic from your application.
# Assume that your Application runing the scale set contains two virtual machine instances.
# The scale set is added to the default backend pool need to updated with IP or FQDN of the application gateway.
# The example input from https://learn.microsoft.com/en-us/azure/application-gateway/tutorial-manage-web-traffic-cli

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
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.11.0"
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
    appGatewayBackendPool = {
      name         = "appGatewayBackendPool"
      ip_addresses = ["100.64.2.6", "100.64.2.5"]
      #fqdns        = ["example1.com", "example2.com"]
    }
  }
  # Backend http settings configuration for the application gateway
  # Mandatory Input
  backend_http_settings = {
    appGatewayBackendHttpSettings = {
      name = "appGatewayBackendHttpSettings"
      #Github issue #55 allow custom port for the backend
      port                  = 80
      protocol              = "Http"
      cookie_based_affinity = "Disabled"
      request_timeout       = 30


      connection_draining = {
        enable_connection_draining = true
        drain_timeout_sec          = 300

      }
    }
    # Add more http settings as needed
  }
  # frontend port configuration block for the application gateway
  # WAF : This example NO HTTPS, We recommend to  Secure all incoming connections using HTTPS for production services with end-to-end SSL/TLS or SSL/TLS termination at the Application Gateway to protect against attacks and ensure data remains private and encrypted between the web server and browsers.
  # WAF : Please refer kv_selfssl_waf_https_app_gateway example for HTTPS configuration
  frontend_ports = {
    frontend-port-80 = {
      name = "frontend-port-80"
      port = 8080
    }
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
    }
    # # Add more http listeners as needed
  }
  location = azurerm_resource_group.rg_group.location
  # provide Application gateway name
  name = module.naming.application_gateway.name_unique
  # Routing rules configuration for the backend pool
  # Mandatory Input
  request_routing_rules = {
    routing-rule-1 = {
      name                       = "rule-1"
      rule_type                  = "Basic"
      http_listener_name         = "appGatewayHttpListener"
      backend_address_pool_name  = "appGatewayBackendPool"
      backend_http_settings_name = "appGatewayBackendHttpSettings"
      priority                   = 100
      rewrite_rule_set_name      = "my-rewrite-rule-set"
    }
    # Add more rules as needed
  }
  resource_group_name = azurerm_resource_group.rg_group.name
  autoscale_configuration = {
    min_capacity = 2
    max_capacity = 3
  }
  # pre-requisites resources input required for the module
  public_ip_address_configuration = {
    public_ip_name = "${module.naming.public_ip.name_unique}-pip"
  }
  rewrite_rule_set = {
    ruleset1 = {
      name = "my-rewrite-rule-set"
      rewrite_rules = {
        rule_1 = {
          name          = "rr-x-forwarded-for"
          rule_sequence = 102
          request_header_configurations = {
            x-forwarded-for = {
              header_name  = "X-Forwarded-For"
              header_value = "{var_client_ip}"
            }
          }
        }
        rule_2 = {
          name          = "rr-blog-post-rewrite"
          rule_sequence = 103

          # this example will rewrite the URL path from blogpost.aspx?id=X&title=Y to /blog/{id}/{title}
          conditions = {
            blog_path = {
              variable    = "var_uri_path"
              pattern     = ".*blogpost.aspx\\?id=(.*)&title=(.*)"
              ignore_case = false
              negate      = false
            }
          }
          response_header_configurations = {
            # example frame embedding protection
            x-frame-options = {
              header_name  = "X-Frame-Options"
              header_value = "DENY"
            }
          }

          url = {
            path    = "/blog/{var_uri_path_1}/{var_uri_path_2}"
            reroute = false
          }
        }
      }
    }
  }
  tags = {
    environment = "dev"
    owner       = "application_gateway"
    project     = "AVM"
  }
  # Zone redundancy for the application gateway
  zones = ["1", "2", "3"]
}
