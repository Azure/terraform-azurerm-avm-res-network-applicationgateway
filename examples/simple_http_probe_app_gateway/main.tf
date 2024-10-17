
#----------Testing Use Case  -------------
# Application Gateway routing traffic from your application. 
# Add a custom health probe to application gateway


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


module "application_gateway" {
  source = "../../"
  # source             = "Azure/terraform-azurerm-avm-res-network-applicationgateway"

  # pre-requisites resources input required for the module
  public_ip_name      = "${module.naming.public_ip.name_unique}-pip"
  resource_group_name = azurerm_resource_group.rg_group.name
  location            = azurerm_resource_group.rg_group.location
  enable_telemetry    = var.enable_telemetry

  # provide Application gateway name 
  name = module.naming.application_gateway.name_unique

  gateway_ip_configuration = {
    subnet_id = azurerm_subnet.backend.id
  }

  tags = {
    environment = "dev"
    owner       = "application_gateway"
    project     = "AVM"
  }

  lock = {
    name = "lock-${module.naming.application_gateway.name_unique}" # optional
    kind = "CanNotDelete"
  }

  # WAF : Azure Application Gateways v2 are always deployed in a highly available fashion with multiple instances by default. Enabling autoscale ensures the service is not reliant on manual intervention for scaling.
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

  # frontend port configuration block for the application gateway
  # WAF : This example NO HTTPS, We recommend to  Secure all incoming connections using HTTPS for production services with end-to-end SSL/TLS or SSL/TLS termination at the Application Gateway to protect against attacks and ensure data remains private and encrypted between the web server and browsers.
  # WAF : Please refer kv_selfssl_waf_https_app_gateway example for HTTPS configuration
  frontend_ports = {
    frontend-port-80 = {
      name = "frontend-port-80"
      port = 80
    }
  }

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
    # Add more http settings as needed
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
    }
    # Add more rules as needed
  }

  # probe configurations for the application gateway
  # WAF : Use Health Probes to detect backend availability
  # # Optional Input
  probe_configurations = {
    probe1 = {
      name                = "Probe1"
      host                = "127.0.0.1"
      interval            = 30
      timeout             = 10
      unhealthy_threshold = 3
      protocol            = "Http"
      port                = 80
      path                = "/health"

    }
  }

  # Optional Input  
  # WAF :  Deploy Application Gateway in a zone-redundant configuration
  # Zone redundancy for the application gateway ["1", "2", "3"] 
  zones = ["1", "2", "3"] #["1", "2", "3"] # Zone redundancy for the application gateway

}
