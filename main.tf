# TODO: insert resources here.

#----------About Terraform Module  -------------
# Azure Application Gateway Terraform Module
# Azure Application Gateway is a load balancer that enables you to manage and optimize the traffic to your web applications. 
# When using Terraform to deploy Azure resources, you can make use of a Terraform module to define and configure the Azure Application Gateway. 
#----------All Required Provider Section----------- 


#----------Local declarations-----------
locals {
  frontend_ip_configuration_name = "appgw-${var.name}-fepip"
  frontend_ip_private_name       = "appgw-${var.name}-fepvt-ip"
  gateway_ip_configuration_name  = "appgw-${var.name}-gwipc"
}

#----------Frontend Subnet Selection Data block-----------
data "azurerm_subnet" "this" {
  name = var.subnet_name_backend
  #GitHub issue #54 create AGW and Subnet in different resource group
  resource_group_name  = var.vnet_resource_group_name
  virtual_network_name = var.vnet_name
}



#----------Public IP for application gateway-----------
resource "azurerm_public_ip" "this" {
  allocation_method   = var.sku.tier == "Standard" ? "Dynamic" : "Static" # Allocation method for the public ip //var.public_ip_allocation_method
  location            = var.location
  name                = var.public_ip_name
  resource_group_name = var.resource_group_name
  sku                 = var.sku.tier == "Standard" ? "Basic" : "Standard" # SKU for the public ip //var.public_ip_sku_tier
  tags                = var.tags
  # WAF : Deploy Application Gateway in a zone-redundant configuration
  zones = var.zones
}

#----------Application Gateway resource creation provider block-----------
resource "azurerm_application_gateway" "this" {
  location = var.location
  #----------Basic configuration for the application gateway-----------
  name                              = var.name
  resource_group_name               = var.resource_group_name
  enable_http2                      = var.http2_enable
  firewall_policy_id                = var.app_gateway_waf_policy_resource_id
  force_firewall_policy_association = true
  #----------Tag configuration for the application gateway-----------
  tags  = var.tags
  zones = var.zones

  #----------Backend Address Pool Configuration for the application gateway -----------
  dynamic "backend_address_pool" {
    for_each = var.backend_address_pools

    content {
      name         = backend_address_pool.value.name
      fqdns        = backend_address_pool.value.fqdns != null ? backend_address_pool.value.fqdns : null
      ip_addresses = backend_address_pool.value.ip_addresses != null ? backend_address_pool.value.ip_addresses : null
    }
  }
  #----------Backend Http Settings Configuration for the application gateway -----------
  dynamic "backend_http_settings" {
    for_each = var.backend_http_settings

    content {
      cookie_based_affinity = lookup(backend_http_settings.value, "cookie_based_affinity", "Disabled")
      name                  = backend_http_settings.value.name
      #Github issue #55 allow custom port for the backend
      port                                = backend_http_settings.value.enable_https ? 443 : coalesce(lookup(backend_http_settings.value, "port", null), 80)
      protocol                            = backend_http_settings.value.enable_https ? "Https" : "Http"
      affinity_cookie_name                = lookup(backend_http_settings.value, "affinity_cookie_name", null)
      host_name                           = backend_http_settings.value.pick_host_name_from_backend_address == false ? lookup(backend_http_settings.value, "host_name", null) : null
      path                                = lookup(backend_http_settings.value, "path", "/")
      pick_host_name_from_backend_address = lookup(backend_http_settings.value, "pick_host_name_from_backend_address", false)
      probe_name                          = lookup(backend_http_settings.value, "probe_name", null)
      request_timeout                     = lookup(backend_http_settings.value, "request_timeout", 30)
      trusted_root_certificate_names      = lookup(backend_http_settings.value, "trusted_root_certificate_names", null)

      dynamic "authentication_certificate" {
        for_each = backend_http_settings.value.authentication_certificate[*]

        content {
          name = authentication_certificate.value.name
        }
      }
      dynamic "connection_draining" {
        for_each = backend_http_settings.value.connection_draining[*]

        content {
          drain_timeout_sec = connection_draining.value.drain_timeout_sec
          enabled           = connection_draining.value.enable_connection_draining
        }
      }
    }
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
  # Private frontend IP Port configuration
  dynamic "frontend_port" {
    for_each = var.frontend_ports

    content {
      name = lookup(frontend_port.value, "name", null)
      port = lookup(frontend_port.value, "port", null)
    }
  }
  #----------Frontend configuration for the application gateway-----------
  gateway_ip_configuration {
    name      = local.gateway_ip_configuration_name
    subnet_id = data.azurerm_subnet.this.id
  }
  #----------Http Listener Configuration for the application gateway -----------
  dynamic "http_listener" {
    for_each = var.http_listeners

    content {
      frontend_ip_configuration_name = var.frontend_ip_type != null && var.private_ip_address != null ? local.frontend_ip_private_name : local.frontend_ip_configuration_name
      frontend_port_name             = lookup(http_listener.value, "frontend_port_name", null)
      name                           = http_listener.value.name
      protocol                       = http_listener.value.ssl_certificate_name == null ? "Http" : "Https"
      firewall_policy_id             = http_listener.value.firewall_policy_id != null ? http_listener.value.firewall_policy_id : null
      host_name                      = http_listener.value.host_name != null ? http_listener.value.host_name : null
      host_names                     = http_listener.value.host_names != null ? http_listener.value.host_names : null
      require_sni                    = http_listener.value.ssl_certificate_name != null ? http_listener.value.require_sni : null
      ssl_certificate_name           = http_listener.value.ssl_certificate_name != null ? http_listener.value.ssl_certificate_name : null
      ssl_profile_name               = http_listener.value.ssl_profile_name != null ? http_listener.value.ssl_profile_name : null

      dynamic "custom_error_configuration" {
        for_each = http_listener.value.custom_error_configuration != null ? lookup(http_listener.value, "custom_error_configuration", {}) : []

        content {
          custom_error_page_url = lookup(custom_error_configuration.value, "custom_error_page_url", null)
          status_code           = lookup(custom_error_configuration.value, "status_code", null)
        }
      }
    }
  }
  #----------Rules Configuration for the application gateway -----------
  dynamic "request_routing_rule" {
    for_each = var.request_routing_rules

    content {
      http_listener_name          = request_routing_rule.value.http_listener_name
      name                        = request_routing_rule.value.name
      rule_type                   = lookup(request_routing_rule.value, "rule_type", "Basic")
      backend_address_pool_name   = request_routing_rule.value.redirect_configuration_name == null ? lookup(request_routing_rule.value, "backend_address_pool_name", null) : null
      backend_http_settings_name  = request_routing_rule.value.redirect_configuration_name == null ? lookup(request_routing_rule.value, "backend_http_settings_name", null) : null
      priority                    = lookup(request_routing_rule.value, "priority", 100)
      redirect_configuration_name = lookup(request_routing_rule.value, "redirect_configuration_name", null)
      rewrite_rule_set_name       = lookup(request_routing_rule.value, "rewrite_rule_set_name", null)
      url_path_map_name           = lookup(request_routing_rule.value, "url_path_map_name", null)
    }
  }
  #----------SKU and configuration for the application gateway-----------
  # WAF : Azure Application Gateways v2 are always deployed in a highly available fashion with multiple instances by default. Enabling autoscale ensures the service is not reliant on manual intervention for scaling.
  sku {
    name     = var.sku.name
    tier     = var.sku.tier
    capacity = var.autoscale_configuration == null ? var.sku.capacity : null
  }
  dynamic "autoscale_configuration" {
    for_each = var.autoscale_configuration != null ? [var.autoscale_configuration] : []

    content {
      min_capacity = lookup(autoscale_configuration.value, "min_capacity", 1)
      max_capacity = lookup(autoscale_configuration.value, "max_capacity", 2)
    }
  }
  dynamic "identity" {
    for_each = length(var.ssl_certificates) > 0 ? [1] : []

    content {
      type         = "UserAssigned"
      identity_ids = var.identity_ids # Directly use the list of identity IDs
    }
  }
  #----------Prod Rules Configuration for the application gateway -----------
  # WAF : Use Health Probes to detect backend availability
  #----------Optionl Configuration  -----------
  dynamic "probe" {
    for_each = var.probe_configurations != null ? var.probe_configurations : {}

    content {
      interval                                  = lookup(probe.value, "interval", 5)
      name                                      = probe.value.name
      path                                      = lookup(probe.value, "path", "/")
      protocol                                  = lookup(probe.value, "protocol", null)
      timeout                                   = lookup(probe.value, "timeout", 30)
      unhealthy_threshold                       = lookup(probe.value, "unhealthy_threshold", 2)
      host                                      = lookup(probe.value, "host", "127.0.0.1")
      minimum_servers                           = lookup(probe.value, "minimum_servers", 0)
      pick_host_name_from_backend_http_settings = lookup(probe.value, "pick_host_name_from_backend_http_settings", false)
      port                                      = lookup(probe.value, "port", 80)

      #GitHub issue #59 request updated probe match configuration
      dynamic "match" {
        for_each = lookup(probe.value, "match", {}) != {} ? [probe.value.match] : []

        content {
          status_code = lookup(match.value, "status_code", ["200-399"])
          body        = lookup(match.value, "body", null)
        }
      }
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
  #----------SSL Certificate Configuration for the application gateway -----------
  #----------Optionl Configuration  -----------
  dynamic "ssl_certificate" {
    for_each = var.ssl_certificates

    content {
      name                = ssl_certificate.value.name
      data                = ssl_certificate.value.key_vault_secret_id == null ? ssl_certificate.value.data : null
      key_vault_secret_id = lookup(ssl_certificate.value, "key_vault_secret_id", null)
      password            = ssl_certificate.value.key_vault_secret_id == null ? ssl_certificate.value.password : null
    }
  }
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
          name                       = path_rule.value.name
          paths                      = path_rule.value.paths
          backend_address_pool_name  = path_rule.value.backend_address_pool_name
          backend_http_settings_name = path_rule.value.backend_http_settings_name
          # WAF Enable Web Application Firewall policies
          firewall_policy_id          = path_rule.value.firewall_policy_id
          redirect_configuration_name = path_rule.value.redirect_configuration_name
          rewrite_rule_set_name       = path_rule.value.rewrite_rule_set_name
        }
      }
    }
  }
  #----------Classic WAF Configuration for the application gateway -----------
  # WAF : Use Application Gateway with Web Application Firewall (WAF) in an application virtual network to safeguard inbound HTTP/S internet traffic. WAF offers centralized defense against potential exploits through OWASP core rule sets-based rules.
  # To Enable Web Application Firewall policies set enable_classic_rule = false and provide the WAF configuration block.
  #----------Optionl Configuration  -----------
  dynamic "waf_configuration" {
    for_each = var.sku.name == "WAF_v2" && var.enable_classic_rule == true != null ? [1] : []

    content {
      enabled          = var.waf_configuration[0].enabled
      firewall_mode    = var.waf_configuration[0].firewall_mode
      rule_set_version = var.waf_configuration[0].rule_set_version
      rule_set_type    = var.waf_configuration[0].rule_set_type
    }
  }

  depends_on = [azurerm_public_ip.this]
}

# Example resource implementation
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azurerm_application_gateway.this.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}


#----------role assignment settings for the application gateway -----------
resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azurerm_application_gateway.this.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}
#----------Diagnostic logs settings for the application gateway -----------
# WAF : Monitor and Log the configurations and traffic
resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.diagnostic_settings

  name                           = each.value.name != null ? each.value.name : "diag-${var.name}"
  target_resource_id             = azurerm_application_gateway.this.id
  eventhub_authorization_rule_id = each.value.event_hub_authorization_rule_resource_id
  eventhub_name                  = each.value.event_hub_name
  log_analytics_destination_type = each.value.log_analytics_destination_type
  log_analytics_workspace_id     = each.value.workspace_resource_id
  partner_solution_id            = each.value.marketplace_partner_resource_id
  storage_account_id             = each.value.storage_account_resource_id

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
