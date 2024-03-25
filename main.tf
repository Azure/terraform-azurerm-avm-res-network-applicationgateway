# TODO: insert resources here.
#----------Local declarations-----------
locals {
  # frontend_ports = [
  #   {
  #     name = null
  #     port = null
  #   }
  # ]

  frontend_port_name             = "appgw-${var.name}-feport"
  frontend_ip_configuration_name = "appgw-${var.name}-fepip"
  gateway_ip_configuration_name  = "appgw-${var.name}-gwipc"
  frontend_ip_private_name       = "appgw-${var.name}-fepvt-ip"

}

#----------Frontend Subnet Selection Data block-----------
data "azurerm_subnet" "this" {
  name                 = var.subnet_name_backend
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
}

#----------Public IP for application gateway-----------
resource "azurerm_public_ip" "this" {
  name                = var.public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = var.sku.tier == "Standard" ? "Dynamic" : "Static" # Allocation method for the public ip //var.public_ip_allocation_method
  sku                 = var.sku.tier == "Standard" ? "Basic" : "Standard" # SKU for the public ip //var.public_ip_sku_tier
  zones               = var.zones
}


#----------Application Gateway resource creation provider block-----------
resource "azurerm_application_gateway" "this" {

  depends_on = [azurerm_public_ip.this]

  #----------Basic configuration for the application gateway-----------
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  enable_http2        = var.http2_enable
  zones               = var.zones
  firewall_policy_id  = var.app_gateway_waf_policy_resource_id //var.http_listeners[0].firewall_policy_id != null ? var.http_listeners[0].firewall_policy_id : null 


  #----------Tag configuration for the application gateway-----------
  tags = var.tags

  #----------SKU and configuration for the application gateway-----------
  sku {
    name     = var.sku.name
    tier     = var.sku.tier
    capacity = var.autoscale_configuration == null ? var.sku.capacity : null
  }

  dynamic "autoscale_configuration" {
    for_each = var.autoscale_configuration != null ? [var.autoscale_configuration] : []
    content {
      min_capacity = lookup(autoscale_configuration.value, "min_capacity")
      max_capacity = lookup(autoscale_configuration.value, "max_capacity")
    }
  }


  #----------Frontend configuration for the application gateway-----------
  gateway_ip_configuration {
    name      = local.gateway_ip_configuration_name
    subnet_id = data.azurerm_subnet.this.id
  }

  # Public frontend IP configuration
  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.this.id
  }

  # Private frontend IP configuration
  dynamic "frontend_ip_configuration" {
    for_each = var.frontend_ip_type != null && var.private_ip_address != null ? [1] : []
    content {
      name                          = local.frontend_ip_private_name
      private_ip_address            = var.private_ip_address != null ? var.private_ip_address : null
      private_ip_address_allocation = var.private_ip_address != null ? "Static" : null
      subnet_id                     = var.private_ip_address != null ? data.azurerm_subnet.this.id : null
    }
  }



  dynamic "frontend_port" {
    for_each = var.frontend_ports
    content {
      name = lookup(frontend_port.value, "name", null)
      port = lookup(frontend_port.value, "port", null)
    }
  }


  # frontend_port {
  #   name = "${local.frontend_port_name}-80"
  #   port = 80
  # }

  #  frontend_port {
  #   name = "${local.frontend_port_name}-8080"
  #   port = 8080
  # }
  # frontend_port {
  #   name = "${local.frontend_port_name}-443"
  #   port = 443
  # }


  #----------Backend Address Pool Configuration for the application gateway -----------
  dynamic "backend_address_pool" {
    for_each = var.backend_address_pools
    content {
      name = backend_address_pool.value.name
      # Check if the value is not null before assigning it
      fqdns        = backend_address_pool.value.fqdns != null ? backend_address_pool.value.fqdns : null
      ip_addresses = backend_address_pool.value.ip_addresses != null ? backend_address_pool.value.ip_addresses : null

    }
  }


  #----------Backend Http Settings Configuration for the application gateway -----------
  dynamic "backend_http_settings" {
    for_each = var.backend_http_settings
    content {
      name                                = backend_http_settings.value.name
      cookie_based_affinity               = lookup(backend_http_settings.value, "cookie_based_affinity", "Disabled")
      affinity_cookie_name                = lookup(backend_http_settings.value, "affinity_cookie_name", null)
      path                                = lookup(backend_http_settings.value, "path", "/")
      port                                = backend_http_settings.value.enable_https ? 443 : 80
      probe_name                          = lookup(backend_http_settings.value, "probe_name", null)
      protocol                            = backend_http_settings.value.enable_https ? "Https" : "Http"
      request_timeout                     = lookup(backend_http_settings.value, "request_timeout", 30)
      host_name                           = backend_http_settings.value.pick_host_name_from_backend_address == false ? lookup(backend_http_settings.value, "host_name") : null
      pick_host_name_from_backend_address = lookup(backend_http_settings.value, "pick_host_name_from_backend_address", false)
      # Check if the value is not null before assigning it
      # protocol              = backend_http_settings.value.protocol != null ? backend_http_settings.value.protocol : null
      # cookie_based_affinity = backend_http_settings.value.cookie_based_affinity != null ? backend_http_settings.value.cookie_based_affinity : null
      #   # Define other attributes as needed
      dynamic "authentication_certificate" {
        for_each = backend_http_settings.value.authentication_certificate[*]
        content {
          name = authentication_certificate.value.name
        }
      }

      trusted_root_certificate_names = lookup(backend_http_settings.value, "trusted_root_certificate_names", null)

      dynamic "connection_draining" {
        for_each = backend_http_settings.value.connection_draining[*]
        content {
          enabled           = connection_draining.value.enable_connection_draining
          drain_timeout_sec = connection_draining.value.drain_timeout_sec
        }
      }
    }
  }

  #----------Http Listener Configuration for the application gateway -----------
  dynamic "http_listener" {
    for_each = var.http_listeners
    content {
      name = http_listener.value.name
      //frontend_port_name             = http_listener.value.ssl_certificate_name == null ? "${local.frontend_port_name}-80" : "${local.frontend_port_name}-443"
      frontend_port_name = lookup(http_listener.value, "frontend_port_name", null)
      protocol           = http_listener.value.ssl_certificate_name == null ? "Http" : "Https"
      //frontend_ip_configuration_name = local.frontend_ip_configuration_name
      frontend_ip_configuration_name = var.frontend_ip_type != null && var.private_ip_address != null ? local.frontend_ip_private_name : local.frontend_ip_configuration_name
      # Check if the value is not null before assigning it
      require_sni          = http_listener.value.ssl_certificate_name != null ? http_listener.value.require_sni : null
      firewall_policy_id   = http_listener.value.firewall_policy_id != null ? http_listener.value.firewall_policy_id : null
      ssl_certificate_name = http_listener.value.ssl_certificate_name != null ? http_listener.value.ssl_certificate_name : null
      ssl_profile_name     = http_listener.value.ssl_profile_name != null ? http_listener.value.ssl_profile_name : null
      host_name            = http_listener.value.host_name != null ? http_listener.value.host_name : null
      host_names           = http_listener.value.host_names != null ? http_listener.value.host_names : null

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

  #----------SSL Certificate Configuration for the application gateway -----------
  #----------Optionl Configuration  -----------
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
  #----------Optionl Configuration  -----------
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
      name                        = request_routing_rule.value.name
      rule_type                   = lookup(request_routing_rule.value, "rule_type", "Basic")
      priority                    = lookup(request_routing_rule.value, "priority", 100)
      http_listener_name          = request_routing_rule.value.http_listener_name
      url_path_map_name           = lookup(request_routing_rule.value, "url_path_map_name", null)
      redirect_configuration_name = lookup(request_routing_rule.value, "redirect_configuration_name", null)
      rewrite_rule_set_name       = lookup(request_routing_rule.value, "rewrite_rule_set_name", null)
      // Using lookup function for conditional assignment
      backend_address_pool_name  = request_routing_rule.value.redirect_configuration_name == null ? lookup(request_routing_rule.value, "backend_address_pool_name", null) : null
      backend_http_settings_name = request_routing_rule.value.redirect_configuration_name == null ? lookup(request_routing_rule.value, "backend_http_settings_name", null) : null
    }
  }
  #----------Prod Rules Configuration for the application gateway -----------
  #----------Optionl Configuration  -----------
  dynamic "probe" {
    for_each = var.probe_configurations != null ? var.probe_configurations : {}
    content {
      name                                      = probe.value.name
      interval                                  = lookup(probe.value, "interval", 5)
      timeout                                   = lookup(probe.value, "timeout", 30)
      unhealthy_threshold                       = lookup(probe.value, "unhealthy_threshold", 2)
      protocol                                  = lookup(probe.value, "protocol", null)
      port                                      = lookup(probe.value, "port", 80)
      path                                      = lookup(probe.value, "path", "/")
      host                                      = lookup(probe.value, "host", "127.0.0.1")
      minimum_servers                           = lookup(probe.value, "minimum_servers", 0)
      pick_host_name_from_backend_http_settings = lookup(probe.value, "pick_host_name_from_backend_http_settings", false)

    }
  }

  #----------Redirect Configuration for the application gateway -----------
  #----------Optionl Configuration  -----------
  dynamic "redirect_configuration" {
    for_each = var.redirect_configuration != null ? var.redirect_configuration : {}
    content {
      name                 = lookup(redirect_configuration.value, "name", null)
      redirect_type        = lookup(redirect_configuration.value, "redirect_type", "Permanent")
      include_path         = lookup(redirect_configuration.value, "include_path", true)
      include_query_string = lookup(redirect_configuration.value, "include_query_string", true)
      target_listener_name = contains(keys(redirect_configuration.value), "target_listener_name") ? redirect_configuration.value.target_listener_name : null
      target_url           = contains(keys(redirect_configuration.value), "target_url") ? redirect_configuration.value.target_url : null
    }
  }

  #----------URL Path Map Configuration for the application gateway -----------
  # #----------Optionl Configuration  -----------
  # dynamic "url_path_map" {
  #   for_each = var.url_path_map_configurations != null ? var.url_path_map_configurations : {}
  #   content {
  #     name                                = url_path_map.value.name
  #     default_backend_address_pool_name   = url_path_map.value.default_backend_address_pool_name == null ? url_path_map.value.default_backend_address_pool_name : null
  #     default_backend_http_settings_name  = url_path_map.value.default_backend_http_settings_name == null ? url_path_map.value.default_backend_http_settings_name : null
  #     default_redirect_configuration_name = lookup(url_path_map.value, "default_redirect_configuration_name", null)
  #     default_rewrite_rule_set_name       = lookup(url_path_map.value, "default_rewrite_rule_set_name", null)
  #     dynamic "path_rule" {
  #       # for_each = lookup(url_path_map.value, "path_rules")
  #       //for_each = url_path_map.value.path_rules != null ? url_path_map.value.path_rules : []
  #       for_each = var.url_path_map_configurations != null ? flatten([for k, v in var.url_path_map_configurations : v.path_rules]) : []
  #       content {
  #         name                        = path_rule.value.name
  #         paths                       = flatten(path_rule.value.paths)
  #         backend_address_pool_name   = path_rule.value.backend_address_pool_name
  #         backend_http_settings_name  = path_rule.value.backend_http_settings_name
  #         redirect_configuration_name = lookup(path_rule.value, "redirect_configuration_name", null)
  #         rewrite_rule_set_name       = lookup(path_rule.value, "rewrite_rule_set_name", null)
  #         firewall_policy_id          = lookup(path_rule.value, "firewall_policy_id", null)
  #       }
  #     }
  #   }
  # }


  dynamic "url_path_map" {
    for_each = var.url_path_map_configurations != null ? var.url_path_map_configurations : {}

    content {
      name                                = url_path_map.value.name
      default_backend_address_pool_name   = url_path_map.value.default_backend_address_pool_name
      default_backend_http_settings_name  = url_path_map.value.default_backend_http_settings_name
      default_redirect_configuration_name = url_path_map.value.default_redirect_configuration_name
      default_rewrite_rule_set_name       = url_path_map.value.default_rewrite_rule_set_name

      dynamic "path_rule" {
        for_each = url_path_map.value.path_rules != null ? url_path_map.value.path_rules : {}

        content {
          name                        = path_rule.value.name
          paths                       = path_rule.value.paths
          backend_address_pool_name   = path_rule.value.backend_address_pool_name
          backend_http_settings_name  = path_rule.value.backend_http_settings_name
          redirect_configuration_name = path_rule.value.redirect_configuration_name
          rewrite_rule_set_name       = path_rule.value.rewrite_rule_set_name
          firewall_policy_id          = path_rule.value.firewall_policy_id
        }
      }
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
  #----------Optionl Configuration  -----------
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

#----------lock settings for the application gateway -----------
#----------Optionl Configuration  -----------
resource "azurerm_management_lock" "this" {
  count      = var.lock.kind != "None" ? 1 : 0
  name       = coalesce(var.lock.name, "lock-${var.name}")
  scope      = azurerm_application_gateway.this.id
  lock_level = var.lock.kind
}

#----------role assignment settings for the application gateway -----------
resource "azurerm_role_assignment" "this" {
  for_each                               = var.role_assignments
  scope                                  = azurerm_application_gateway.this.id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  principal_id                           = each.value.principal_id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
}

#----------Diagnostic logs settings for the application gateway -----------
resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each                       = var.diagnostic_settings
  name                           = each.value.name != null ? each.value.name : "diag-${var.name}"
  target_resource_id             = azurerm_application_gateway.this.id
  storage_account_id             = each.value.storage_account_resource_id
  eventhub_authorization_rule_id = each.value.event_hub_authorization_rule_resource_id
  eventhub_name                  = each.value.event_hub_name
  partner_solution_id            = each.value.marketplace_partner_resource_id
  log_analytics_workspace_id     = each.value.workspace_resource_id
  log_analytics_destination_type = each.value.log_analytics_destination_type

  dynamic "enabled_log" {
    for_each = each.value.log_categories
    content {
      category = enabled_log.value
    }
  }

  dynamic "enabled_log" {
    for_each = each.value.log_groups
    content {
      category_group = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = each.value.metric_categories
    content {
      category = metric.value
    }
  }
}

# Other configurations for your environment

