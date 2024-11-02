#----------Testing Use Case  -------------
# Application Gateway + WAF Enable routing traffic from your application. 
# Assume that your Application runing the scale set contains two virtual machine instances. 
# The scale set is added to the default backend pool need to updated with IP or FQDN of the application gateway.
# The example input from https://learn.microsoft.com/en-us/azure/application-gateway/configure-keyvault-ps

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
  # source  = "Azure/terraform-azurerm-avm-res-network-applicationgateway"
  # version = "0.1.0"

  # pre-requisites resources input required for the module
  public_ip_name      = "${module.naming.public_ip.name_unique}-pip"
  resource_group_name = azurerm_resource_group.rg_group.name
  location            = azurerm_resource_group.rg_group.location
  # log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace.id
  enable_telemetry = var.enable_telemetry

  # provide Application gateway name 
  name = module.naming.application_gateway.name_unique

  gateway_ip_configuration = {
    subnet_id = azurerm_subnet.backend.id
  }

  # WAF : Azure Application Gateways v2 are always deployed in a highly available fashion with multiple instances by default. Enabling autoscale ensures the service is not reliant on manual intervention for scaling.
  sku = {
    # Accpected value for names Standard_v2 and WAF_v2
    name = "WAF_v2"
    # Accpected value for tier Standard_v2 and WAF_v2
    tier = "WAF_v2"
    # Accpected value for capacity 1 to 10 for a V1 SKU, 1 to 100 for a V2 SKU
    capacity = 0 # Set the initial capacity to 0 for autoscaling
  }

  autoscale_configuration = {
    min_capacity = 1
    max_capacity = 2
  }

  # frontend port configuration block for the application gateway
  # WAF : Secure all incoming connections using HTTPS for production services with end-to-end SSL/TLS or SSL/TLS termination at the Application Gateway to protect against attacks and ensure data remains private and encrypted between the web server and browsers.
  frontend_ports = {
    frontend-port-443 = {
      name = "frontend-port-443"
      port = 443
    }
  }

  # Backend address pool configuration for the application gateway
  # Mandatory Input
  backend_address_pools = {
    appGatewayBackendPool = {
      name = "appGatewayBackendPool"
      # ip_addresses = ["100.64.2.6", "100.64.2.5"]
      #fqdns        = ["example1.com", "example2.com"]
    }
  }

  # Backend http settings configuration for the application gateway
  # Mandatory Input
  backend_http_settings = {
    appGatewayBackendHttpSettings = {
      name                  = "appGatewayBackendHttpSettings"
      cookie_based_affinity = "Disabled"
      path                  = "/"
      port                  = 80
      protocol              = "Http"
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
      name                 = "appGatewayHttpListener"
      host_name            = null
      frontend_port_name   = "frontend-port-443"
      ssl_certificate_name = "app-gateway-cert"
      ssl_profile_name     = "example-ssl-profile"
    }
    # # Add more http listeners as needed
  }


  # WAF : Use Application Gateway with Web Application Firewall (WAF) in an application virtual network to safeguard inbound HTTP/S internet traffic. WAF offers centralized defense against potential exploits through OWASP core rule sets-based rules.
  # Ensure that you have a WAF policy created before enabling WAF on the Application Gateway
  # The use of an external WAF policy is recommended rather than using the classic WAF via the waf_configuration block.
  app_gateway_waf_policy_resource_id = azurerm_web_application_firewall_policy.azure_waf.id

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

  # SSL Certificate Block
  ssl_certificates = {
    "app-gateway-cert" = {
      name                = "app-gateway-cert"
      key_vault_secret_id = azurerm_key_vault_certificate.ssl_cert_id.secret_id
    }
  }

  ssl_profile = {
    profile1 = {
      name = "example-ssl-profile"
      ssl_policy = {
        policy_name = "AppGwSslPolicy20220101"
        policy_type = "Predefined"
      }
    }
  }
  ssl_policy = {

    policy_name = "AppGwSslPolicy20220101"
    policy_type = "Predefined"
  }

  # HTTP to HTTPS Redirection Configuration for
  redirect_configuration = {
    redirect_config_1 = {
      name                 = "Redirect1"
      redirect_type        = "Permanent"
      include_path         = true
      include_query_string = true
      target_listener_name = "appGatewayHttpListener"
    }
  }

  # Optional Input  
  # Zone redundancy for the application gateway ["1", "2", "3"] 
  zones = ["1", "2", "3"]

  managed_identities = {
    user_assigned_resource_ids = [
      azurerm_user_assigned_identity.appag_umid.id # This should be a list of strings, not a list of objects.
    ]
  }

  diagnostic_settings = {
    example_setting = {
      name                           = "${module.naming.application_gateway.name_unique}-diagnostic-setting"
      workspace_resource_id          = azurerm_log_analytics_workspace.log_analytics_workspace.id
      log_analytics_destination_type = "Dedicated" # Or "AzureDiagnostics"
      # log_categories                 = ["Application Gateway Access Log", "Application Gateway Performance Log", "Application Gateway Firewall Log"]
      log_groups        = ["allLogs"]
      metric_categories = ["AllMetrics"]
    }
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

}


