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
  # source  = "Azure/terraform-azurerm-avm-res-network-applicationgateway"
  # version = "0.1.0"

  # pre-requisites resources input required for the module
  public_ip_name      = "${module.naming.public_ip.name_unique}-pip"
  resource_group_name = azurerm_resource_group.rg_group.name
  location            = azurerm_resource_group.rg_group.location
  enable_telemetry    = var.enable_telemetry

  # provide Application gateway name
  name = module.naming.application_gateway.name_unique

  frontend_ip_configuration_private = {
    private_ip_address            = "100.64.1.5"
    private_ip_address_allocation = "Static"
  }

  gateway_ip_configuration = {
    subnet_id = azurerm_subnet.backend.id
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
    min_capacity = 2
    max_capacity = 15
  }

  # WAF : This example NO HTTPS, We recommend to  Secure all incoming connections using HTTPS for production services with end-to-end SSL/TLS or SSL/TLS termination at the Application Gateway to protect against attacks and ensure data remains private and encrypted between the web server and browsers.
  # WAF : Please refer kv_selfssl_waf_https_app_gateway example for HTTPS configuration
  frontend_ports = {
    frontend-port-80 = {
      name = "frontend-port-80"
      port = 80
    }
    # Add more ports as needed
  }

  # Backend address pool configuration for the application gateway
  # Mandatory Input
  backend_address_pools = {
    pool-1 = {
      name = "Pool1"
      # ip_addresses = ["100.64.2.4", "100.64.2.5"]
      #fqdns        = ["example1.com", "example2.com"]
    }

  }

  # Http Listerners configuration for the application gateway
  # Mandatory Input
  http_listeners = {
    http_listeners-for-80 = {
      name = "http_listeners-for-80"
      # The frontend_port_name must be same as given frontend_port block
      frontend_port_name = "frontend-port-80"
      protocol           = "Http"
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
      enable_https          = false
      request_timeout       = 30
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
    }
    # Add more rules as needed
  }

  # Optional Input
  zones = ["1", "2", "3"] #["1", "2", "3"] # Zone redundancy for the application gateway

  tags = {
    environment = "dev"
    owner       = "application_gateway"
    project     = "AVM"
  }

  lock = {
    name = "lock-${module.naming.application_gateway.name_unique}" # optional
    kind = "CanNotDelete"
  }
}
