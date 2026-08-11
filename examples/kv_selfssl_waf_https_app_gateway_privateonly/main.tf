#----------Testing Use Case  -------------
# Application Gateway + WAF Enable routing traffic from your application. Private IP Only.
# Assume that your Application runing the scale set contains two virtual machine instances.
# The scale set is added to the default backend pool need to updated with IP or FQDN of the application gateway.
# The example input from https://learn.microsoft.com/en-us/azure/application-gateway/configure-keyvault-ps

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
  resource_provider_registrations = "core"
  features {}
}

provider "azapi" {}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.0"

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
      name       = "appGatewayBackendPool"
      properties = {}
    }
  ]
  # Backend http settings configuration for the application gateway
  # Mandatory Input
  backend_http_settings_collection = [
    {
      name = "appGatewayBackendHttpSettings"
      properties = {
        cookie_based_affinity = "Disabled"
        path                  = "/"
        port                  = 80
        protocol              = "Http"
        request_timeout       = 30
        connection_draining = {
          enabled              = true
          drain_timeout_in_sec = 300
        }
      }
    }
  ]
  enable_telemetry = var.enable_telemetry
  # WAF : Use Application Gateway with Web Application Firewall (WAF) in an application virtual network to safeguard inbound HTTP/S internet traffic. WAF offers centralized defense against potential exploits through OWASP core rule sets-based rules.
  # Ensure that you have a WAF policy created before enabling WAF on the Application Gateway
  # The use of an external WAF policy is recommended rather than using the classic WAF via the waf_configuration block.
  firewall_policy = {
    id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg_group.name}/providers/Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies/${azurerm_web_application_firewall_policy.azure_waf.name}"
  }
  frontend_ip_configurations = [
    {
      name = "private-ip-custom-name"
      properties = {
        private_ip_address           = "10.90.3.10"
        private_ip_allocation_method = "Static"
        subnet = {
          id = azurerm_subnet.private_ip_test.id
        }
      }
    }
  ]
  # frontend port configuration block for the application gateway
  # WAF : Secure all incoming connections using HTTPS for production services with end-to-end SSL/TLS or SSL/TLS termination at the Application Gateway to protect against attacks and ensure data remains private and encrypted between the web server and browsers.
  frontend_ports = [
    {
      name = "frontend-port-443"
      properties = {
        port = 443
      }
    }
  ]
  gateway_ip_configurations = [
    {
      name = "appGatewayIpConfig"
      properties = {
        subnet = {
          id = azurerm_subnet.private_ip_test.id
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
          id = "${local.agw_id}/frontendIPConfigurations/private-ip-custom-name"
        }
        frontend_port = {
          id = "${local.agw_id}/frontendPorts/frontend-port-443"
        }
        protocol = "Https"
        ssl_certificate = {
          id = "${local.agw_id}/sslCertificates/app-gateway-cert"
        }
        ssl_profile = {
          id = "${local.agw_id}/sslProfiles/example-ssl-profile"
        }
      }
    }
  ]
  managed_identities = {
    user_assigned_resource_ids = [
      azurerm_user_assigned_identity.appag_umid.id
    ]
  }
  # HTTP to HTTPS Redirection Configuration
  redirect_configurations = [
    {
      name = "Redirect1"
      properties = {
        redirect_type        = "Permanent"
        include_path         = true
        include_query_string = true
        target_listener = {
          id = "${local.agw_id}/httpListeners/appGatewayHttpListener"
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
          id = "${local.agw_id}/httpListeners/appGatewayHttpListener"
        }
        backend_address_pool = {
          id = "${local.agw_id}/backendAddressPools/appGatewayBackendPool"
        }
        backend_http_settings = {
          id = "${local.agw_id}/backendHttpSettingsCollection/appGatewayBackendHttpSettings"
        }
        priority = 100
      }
    }
  ]
  # WAF : Azure Application Gateways v2 are always deployed in a highly available fashion with multiple instances by default. Enabling autoscale ensures the service is not reliant on manual intervention for scaling.
  sku = {
    # Accpected value for names Standard_v2 and WAF_v2
    name = "WAF_v2"
    # Accpected value for tier Standard_v2 and WAF_v2
    tier = "WAF_v2"
  }
  # SSL Certificate Block
  ssl_certificates = [
    {
      name = "app-gateway-cert"
      properties = {
        key_vault_secret_id = azurerm_key_vault_certificate.ssl_cert_id.secret_id
      }
    }
  ]
  ssl_policy = {
    policy_type          = "Custom"
    min_protocol_version = "TLSv1_2"
    cipher_suites = [
      "TLS_RSA_WITH_AES_128_GCM_SHA256",
      "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
    ]
  }
  ssl_profiles = [
    {
      name = "example-ssl-profile"
      properties = {
        ssl_policy = {
          policy_type          = "Custom"
          min_protocol_version = "TLSv1_2"
          cipher_suites = [
            "TLS_RSA_WITH_AES_128_GCM_SHA256",
            "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
          ]
        }
      }
    }
  ]
  tags = {
    environment = "dev"
    owner       = "application_gateway"
    project     = "AVM"
  }
  # Optional Input
  # Zone redundancy for the application gateway ["1", "2", "3"]
  zones = ["1", "2", "3"]
}

