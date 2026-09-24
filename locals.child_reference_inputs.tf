locals {
  # Empty collections simplify bookkeeping only; ARM rendering retains the original null/empty distinction.
  normalized_child_collections = {
    authentication_certificates      = coalesce(var.authentication_certificates, [])
    backend_address_pools            = coalesce(var.backend_address_pools, [])
    backend_http_settings_collection = coalesce(var.backend_http_settings_collection, [])
    backend_settings_collection      = coalesce(var.backend_settings_collection, [])
    entra_jwt_validation_configs     = coalesce(var.entra_jwt_validation_configs, [])
    frontend_ip_configurations       = coalesce(var.frontend_ip_configurations, [])
    frontend_ports                   = coalesce(var.frontend_ports, [])
    http_listeners                   = coalesce(var.http_listeners, [])
    listeners                        = coalesce(var.listeners, [])
    load_distribution_policies       = coalesce(var.load_distribution_policies, [])
    private_link_configurations      = coalesce(var.private_link_configurations, [])
    probes                           = coalesce(var.probes, [])
    redirect_configurations          = coalesce(var.redirect_configurations, [])
    request_routing_rules            = coalesce(var.request_routing_rules, [])
    rewrite_rule_sets                = coalesce(var.rewrite_rule_sets, [])
    routing_rules                    = coalesce(var.routing_rules, [])
    ssl_certificates                 = coalesce(var.ssl_certificates, [])
    ssl_profiles                     = coalesce(var.ssl_profiles, [])
    trusted_client_certificates      = coalesce(var.trusted_client_certificates, [])
    trusted_root_certificates        = coalesce(var.trusted_root_certificates, [])
    url_path_maps                    = coalesce(var.url_path_maps, [])
  }
  child_reference_key_attributes = {
    authentication_certificates      = "authentication_certificate_key"
    backend_address_pools            = "backend_address_pool_key"
    backend_http_settings_collection = "backend_http_settings_key"
    backend_settings_collection      = "backend_settings_key"
    entra_jwt_validation_configs     = "entra_jwt_validation_config_key"
    frontend_ip_configurations       = "frontend_ip_configuration_key"
    frontend_ports                   = "frontend_port_key"
    http_listeners                   = "http_listener_key"
    listeners                        = "listener_key"
    load_distribution_policies       = "load_distribution_policy_key"
    path_rules                       = "path_rule_key"
    private_link_configurations      = "private_link_configuration_key"
    probes                           = "probe_key"
    redirect_configurations          = "redirect_configuration_key"
    request_routing_rules            = "request_routing_rule_key"
    rewrite_rule_sets                = "rewrite_rule_set_key"
    ssl_certificates                 = "ssl_certificate_key"
    ssl_profiles                     = "ssl_profile_key"
    trusted_client_certificates      = "trusted_client_certificate_key"
    trusted_root_certificates        = "trusted_root_certificate_key"
    url_path_maps                    = "url_path_map_key"
  }
  child_scalar_reference_targets = {
    backend_http_settings_collection = { probe = "probes" }
    backend_settings_collection      = { probe = "probes" }
    frontend_ip_configurations       = { private_link_configuration = "private_link_configurations" }
    http_listeners = {
      frontend_ip_configuration = "frontend_ip_configurations"
      frontend_port             = "frontend_ports"
      ssl_certificate           = "ssl_certificates"
      ssl_profile               = "ssl_profiles"
    }
    listeners = {
      frontend_ip_configuration = "frontend_ip_configurations"
      frontend_port             = "frontend_ports"
      ssl_certificate           = "ssl_certificates"
      ssl_profile               = "ssl_profiles"
    }
    load_distribution_targets = { backend_address_pool = "backend_address_pools" }
    path_rules = {
      backend_address_pool     = "backend_address_pools"
      backend_http_settings    = "backend_http_settings_collection"
      load_distribution_policy = "load_distribution_policies"
      redirect_configuration   = "redirect_configurations"
      rewrite_rule_set         = "rewrite_rule_sets"
    }
    redirect_configurations = { target_listener = "http_listeners" }
    request_routing_rules = {
      backend_address_pool        = "backend_address_pools"
      backend_http_settings       = "backend_http_settings_collection"
      entra_jwt_validation_config = "entra_jwt_validation_configs"
      http_listener               = "http_listeners"
      load_distribution_policy    = "load_distribution_policies"
      redirect_configuration      = "redirect_configurations"
      rewrite_rule_set            = "rewrite_rule_sets"
      url_path_map                = "url_path_maps"
    }
    routing_rules = {
      backend_address_pool = "backend_address_pools"
      backend_settings     = "backend_settings_collection"
      listener             = "listeners"
    }
    url_path_maps = {
      default_backend_address_pool     = "backend_address_pools"
      default_backend_http_settings    = "backend_http_settings_collection"
      default_load_distribution_policy = "load_distribution_policies"
      default_redirect_configuration   = "redirect_configurations"
      default_rewrite_rule_set         = "rewrite_rule_sets"
    }
  }
  child_list_reference_targets = {
    backend_http_settings_collection = {
      authentication_certificates = "authentication_certificates"
      trusted_root_certificates   = "trusted_root_certificates"
    }
    backend_settings_collection = {
      trusted_root_certificates = "trusted_root_certificates"
    }
    redirect_configurations = {
      path_rules            = "path_rules"
      request_routing_rules = "request_routing_rules"
      url_path_maps         = "url_path_maps"
    }
    ssl_profiles = {
      trusted_client_certificates = "trusted_client_certificates"
    }
  }

  child_reference_sources = merge(
    {
      for collection in setsubtract(
        setunion(keys(local.child_scalar_reference_targets), keys(local.child_list_reference_targets)),
        ["load_distribution_targets", "path_rules"],
        ) : collection => [
        for index, item in local.normalized_child_collections[collection] : {
          path       = "${collection}[${index}].properties"
          properties = try(item.properties, null)
        }
      ]
    },
    {
      load_distribution_targets = flatten([
        for policy_index, policy in local.normalized_child_collections.load_distribution_policies : [
          for target_index, target in coalesce(try(policy.properties.load_distribution_targets, null), []) : {
            path       = "load_distribution_policies[${policy_index}].properties.load_distribution_targets[${target_index}].properties"
            properties = try(target.properties, null)
          }
        ]
      ])
      path_rules = flatten([
        for map_index, path_map in local.normalized_child_collections.url_path_maps : [
          for rule_index, rule in coalesce(try(path_map.properties.path_rules, null), []) : {
            path       = "url_path_maps[${map_index}].properties.path_rules[${rule_index}].properties"
            properties = try(rule.properties, null)
          }
        ]
      ])
    },
  )
  raw_child_references = concat(
    flatten([
      for collection, targets in local.child_scalar_reference_targets : [
        for source in local.child_reference_sources[collection] : [
          for attribute, target_type in targets : {
            path        = "${source.path}.${attribute}"
            target_type = target_type
            value       = try(source.properties[attribute], null)
          }
        ]
      ]
    ]),
    flatten([
      for collection, targets in local.child_list_reference_targets : [
        for source in local.child_reference_sources[collection] : [
          for attribute, target_type in targets : [
            for index, reference in coalesce(try(source.properties[attribute], null), []) : {
              path        = "${source.path}.${attribute}[${index}]"
              target_type = target_type
              value       = reference
            }
          ]
        ]
      ]
    ]),
  )
  # Keep null references distinct from legacy {} references, even though both select mode "none".
  child_reference_values = {
    for reference in local.raw_child_references : reference.path => {
      path        = reference.path
      target_type = reference.target_type
      present     = reference.value != null
      id          = try(reference.value.id, null)
      key         = reference.value == null ? null : reference.value[local.child_reference_key_attributes[reference.target_type]]
      scope_key   = reference.target_type == "path_rules" ? (reference.value == null ? null : reference.value.url_path_map_key) : null
    }
  }
  normalized_child_references = {
    for path, reference in local.child_reference_values : path => merge(reference, {
      mode = (
        reference.id != null && (reference.key != null || reference.scope_key != null) ||
        (reference.target_type == "path_rules" && ((reference.key == null) != (reference.scope_key == null)))
        ) ? "invalid" : (
        reference.key != null ? "key" : reference.id != null ? "id" : "none"
      )
    })
  }
}
