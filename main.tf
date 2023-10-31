# TODO: insert resources here.
#----------Local declarations-----------

locals {
  frontend_ports = [
    {
      name = null
      port = null
    }
  ]
}

#----------Frontend Subnet Selection Data block-----------

data "azurerm_subnet" "subnet" {
  name                 = var.subnet_name_backend
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
}


#----------Public IP for application gateway-----------


resource "azurerm_public_ip" "public_ip" {
  name                = var.public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = var.sku.tier == "Standard" ? "Dynamic" : "Static" # Allocation method for the public ip //var.public_ip_allocation_method
  sku                 = var.sku.tier == "Standard" ? "Basic" : "Standard" # SKU for the public ip //var.public_ip_sku_tier
  zones               = var.zone_redundant
}

#----------Application Gateway resource creation provider block-----------

resource "azurerm_application_gateway" "application_gateway" {

  depends_on = [azurerm_public_ip.public_ip]

  #----------Basic configuration for the application gateway-----------
  name                = var.app_gateway_name
  resource_group_name = var.resource_group_name
  location            = var.location
  enable_http2        = var.http2_enable
  zones               = var.zone_redundant
  firewall_policy_id  = var.app_gateway_waf_policy_name //var.http_listeners[0].firewall_policy_id != null ? var.http_listeners[0].firewall_policy_id : null 


  #----------Tag configuration for the application gateway-----------
  tags = var.tags

  #----------SKU and configuration for the application gateway-----------
  sku {
    name     = var.sku.name
    tier     = var.sku.tier
    capacity = var.autoscale_configuration == null ? var.sku.capacity : null
  }

   autoscale_configuration {
    min_capacity = 1
    max_capacity = 5 # Set your desired maximum capacity
  }

  #----------Frontend configuration for the application gateway-----------

  gateway_ip_configuration {
    name      = "${var.app_gateway_name}-ip-configuration"
    subnet_id = data.azurerm_subnet.subnet.id
  }

  dynamic "frontend_port" {
    for_each = var.backend_http_settings
    content {
      name = length(var.backend_http_settings) > 1 ? var.backend_http_settings[frontend_port.key].name : var.backend_http_settings[0].name
      port = length(var.backend_http_settings) > 1 ? var.backend_http_settings[frontend_port.key].port : var.backend_http_settings[0].port
      # Define other attributes as needed
    }
  }

  # Public frontend IP configuration
  frontend_ip_configuration {
    name                 = "${var.app_gateway_name}-feip"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }

  # Private frontend IP configuration
  frontend_ip_configuration {
    name = "${var.app_gateway_name}-private-feip"
    #name                          = "${var.app_gateway_name}-feip"
    # subnet_id = azurerm_subnet.private.id  # Replace with your private subnet ID
    private_ip_address            = var.private_ip_address
    private_ip_address_allocation = "Static"
    subnet_id                     = data.azurerm_subnet.subnet.id //var.private_ip_address != null ? data.azurerm_subnet.subnet.id : null
  }

  #----------Backend Address Pool Configuration for the application gateway -----------

  dynamic "backend_address_pool" {
    for_each = var.backend_address_pools
    content {
      name         = backend_address_pool.value.name
      fqdns        = backend_address_pool.value.fqdns
      ip_addresses = backend_address_pool.value.ip_addresses
      # Define other attributes as needed
    }
  }

  #----------Backend Http Settings Configuration for the application gateway -----------

  dynamic "backend_http_settings" {
    for_each = var.backend_http_settings
    content {
      name                  = backend_http_settings.value.name
      port                  = backend_http_settings.value.port
      protocol              = backend_http_settings.value.protocol
      cookie_based_affinity = backend_http_settings.value.cookie_based_affinity
      # Define other attributes as needed
    }
  }

  #----------Http Listener Configuration for the application gateway -----------

  dynamic "http_listener" {
    for_each = var.http_listeners
    content {
      name               = http_listener.value.name
      frontend_port_name = length(var.backend_http_settings) > 1 ? var.backend_http_settings[http_listener.key].name : var.backend_http_settings[0].name
      protocol           = http_listener.value.protocol
      frontend_ip_configuration_name = http_listener.value.frontend_ip_assocation == "public" ? "${var.app_gateway_name}-feip" : "${var.app_gateway_name}-private-feip"
      firewall_policy_id             = http_listener.value.firewall_policy_id
      ssl_certificate_name = http_listener.value.ssl_certificate_name
      ssl_profile_name     = http_listener.value.ssl_profile_name
      host_name            = http_listener.value.host_name
      host_names           = http_listener.value.host_names

      # Define other attributes as needed
      dynamic "custom_error_configuration" {
        for_each = http_listener.value.custom_error_configuration != null ? lookup(http_listener.value, "custom_error_configuration", {}) : []
        content {
          custom_error_page_url = lookup(custom_error_configuration.value, "custom_error_page_url", null)
          status_code           = lookup(custom_error_configuration.value, "status_code", null)
        }
      }

    }
  }

  dynamic "ssl_certificate" {
    for_each = var.ssl_certificates
    content {
      name                = ssl_certificate.value.name
      data                = ssl_certificate.value.key_vault_secret_id == null ? ssl_certificate.value.data : null
      password            = ssl_certificate.value.key_vault_secret_id == null ? ssl_certificate.value.password : null
      key_vault_secret_id = lookup(ssl_certificate.value, "key_vault_secret_id", null)
    }
  }

  # Check if key_vault_secret_id is not null, and include the identity block accordingly
  dynamic "identity" {
    for_each = length(var.ssl_certificates) > 0 ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = var.identity_ids[0].identity_ids
    }
  }

  #----------Rules Configuration for the application gateway -----------

  dynamic "request_routing_rule" {

    for_each = var.request_routing_rules
    content {
      name               = request_routing_rule.value.name
      rule_type          = request_routing_rule.value.rule_type
      priority           = request_routing_rule.value.priority
      http_listener_name = length(var.http_listeners) > 1 ? var.http_listeners[request_routing_rule.key].name : var.http_listeners[0].name
      //   backend_address_pool_name  = length(var.backend_address_pools) > 1 ? var.backend_address_pools[request_routing_rule.key].name : var.backend_address_pools[0].name 
      //   backend_http_settings_name = length(var.backend_http_settings) > 1 ? var.backend_http_settings[request_routing_rule.key].name : var.backend_http_settings[0].name
      backend_address_pool_name   = request_routing_rule.value.redirect_configuration_name == null ? length(var.backend_address_pools) > 1 ? var.backend_address_pools[request_routing_rule.key].name : var.backend_address_pools[0].name : null
      backend_http_settings_name  = request_routing_rule.value.redirect_configuration_name == null ? length(var.backend_http_settings) > 1 ? var.backend_http_settings[request_routing_rule.key].name : var.backend_http_settings[0].name : null
      url_path_map_name           = lookup(request_routing_rule.value, "url_path_map_name", null)
      redirect_configuration_name = lookup(request_routing_rule.value, "redirect_configuration_name", null)
      rewrite_rule_set_name       = lookup(request_routing_rule.value, "rewrite_rule_set_name", null)
    }

  }


  #----------Prod Rules Configuration for the application gateway -----------

  dynamic "probe" {
    for_each = var.probe_configurations
    content {
      name                                      = probe.value.name
      host                                      = probe.value.host
      interval                                  = probe.value.interval
      timeout                                   = probe.value.timeout
      unhealthy_threshold                       = probe.value.unhealthy_threshold
      protocol                                  = probe.value.protocol
      port                                      = probe.value.port
      path                                      = probe.value.path
      pick_host_name_from_backend_http_settings = probe.value.pick_host_name_from_backend_http_settings
    }
  }

  # dynamic "url_path_map" {
  #   for_each = var.url_path_map_configurations
  #   content {
  #     name                       = url_path_map.value.name
  #     default_redirect_configuration_name = url_path_map.value.default_redirect_configuration_name

  #     dynamic "path_rule" {
  #       for_each = url_path_map.value.path_rules
  #       content {
  #         name                  = path_rule.value.name
  #         paths                 = path_rule.value.paths
  #         backend_address_pool_name = path_rule.value.backend_address_pool_name
  #         backend_http_settings_name = path_rule.value.backend_http_settings_name
  #       }
  #     }
  #   }
  # }

  dynamic "redirect_configuration" {
    for_each = var.redirection_configurations
    content {
      name          = redirect_configuration.value.name
      redirect_type = redirect_configuration.value.redirect_type
      target_url    = redirect_configuration.value.target_url
    }
  }

  # dynamic "rewrite_rule_set" {
  #   for_each = var.rewrite_rule_set_configurations
  #   content {
  #     name = var.rewrite_rule_set.name

  #     dynamic "rewrite_rule" {
  #       for_each = lookup(var.rewrite_rule_set_configurations, "rewrite_rules", [])
  #       content {
  #         name          = rewrite_rule.value.name
  #         rule_sequence = rewrite_rule.value.rule_sequence

  #         dynamic "condition" {
  #           for_each = lookup(rewrite_rule_set.value, "condition", [])
  #           content {
  #             variable    = condition.value.variable
  #             pattern     = condition.value.pattern
  #             ignore_case = condition.value.ignore_case
  #             negate      = condition.value.negate
  #           }
  #         }

  #         dynamic "request_header_configuration" {
  #           for_each = lookup(rewrite_rule.value, "request_header_configuration", [])
  #           content {
  #             header_name  = request_header_configuration.value.header_name
  #             header_value = request_header_configuration.value.header_value
  #           }
  #         }

  #         dynamic "response_header_configuration" {
  #           for_each = lookup(rewrite_rule.value, "response_header_configuration", [])
  #           content {
  #             header_name  = response_header_configuration.value.header_name
  #             header_value = response_header_configuration.value.header_value
  #           }
  #         }

  #         dynamic "url" {
  #           for_each = lookup(rewrite_rule.value, "url", [])
  #           content {
  #             path         = url.value.path
  #             query_string = url.value.query_string
  #             reroute      = url.value.reroute
  #           }
  #         }
  #       }
  #     }
  #   }
  # }


  # dynamic "custom_error_configuration" {
  #     for_each = var.custom_error_configurations
  #     content {
  #       name     = custom_error_configuration.value.name
  #       status   = custom_error_configuration.value.status
  #       error_response {
  #         custom_response {
  #           response_html = custom_error_configuration.value.error_response.custom_response.response_html
  #         }
  #       }
  #     }
  #   }

  #----------Classic WAF Configuration for the application gateway -----------

  dynamic "waf_configuration" {

    for_each = var.sku.name == "WAF_v2" && var.enable_classic_rule == true != null ? [1] : []

    content {
      enabled          = var.waf_configuration[0].enabled
      firewall_mode    = var.waf_configuration[0].firewall_mode
      rule_set_type    = var.waf_configuration[0].rule_set_type
      rule_set_version = var.waf_configuration[0].rule_set_version
    }

  }
  force_firewall_policy_association = true

}

#----------Diagnostic logs settings for the application gateway -----------

resource "azurerm_monitor_diagnostic_setting" "diagnostic_setting_for_app_gateway" {
  name                       = "${var.app_gateway_name}-app-gateway"
  target_resource_id         = azurerm_application_gateway.application_gateway.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    # category = "allLogs"
    category_group = "allLogs"

  }

  metric {
    category = "AllMetrics"

  }
}

#----------Diagnostic logs settings for the public ip -----------

resource "azurerm_monitor_diagnostic_setting" "diagnostic_setting_for_public_ip" {
  name                       = "${var.app_gateway_name}-public_ip"
  target_resource_id         = azurerm_public_ip.public_ip.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    # category = "allLogs"
    category_group = "allLogs"

  }

  metric {
    category = "AllMetrics"

  }
}
# Other configurations for your environment

