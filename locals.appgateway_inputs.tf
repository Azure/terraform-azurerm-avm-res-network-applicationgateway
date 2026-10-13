locals {
  appgateway_component_metadata = toset([
    "id",
    "name",
    "properties",
    "public_ip_address_key",
  ])
  appgateway_raw_component_inputs = {
    authentication_certificates      = var.authentication_certificates
    backend_address_pools            = var.backend_address_pools
    backend_http_settings_collection = var.backend_http_settings_collection
    backend_settings_collection      = var.backend_settings_collection
    entra_jwt_validation_configs     = var.entra_jwt_validation_configs
    frontend_ip_configurations       = var.frontend_ip_configurations
    frontend_ports                   = var.frontend_ports
    gateway_ip_configurations        = var.gateway_ip_configurations
    http_listeners                   = var.http_listeners
    listeners                        = var.listeners
    load_distribution_policies       = var.load_distribution_policies
    private_link_configurations      = var.private_link_configurations
    probes                           = var.probes
    redirect_configurations          = var.redirect_configurations
    request_routing_rules            = var.request_routing_rules
    rewrite_rule_sets                = var.rewrite_rule_sets
    routing_rules                    = var.routing_rules
    ssl_certificates                 = var.ssl_certificates
    ssl_profiles                     = var.ssl_profiles
    trusted_client_certificates      = var.trusted_client_certificates
    trusted_root_certificates        = var.trusted_root_certificates
    url_path_maps                    = var.url_path_maps
  }
  appgateway_component_inputs = merge(local.appgateway_raw_component_inputs, {
    frontend_ip_configurations = local.frontend_ip_configurations
    load_distribution_policies = var.load_distribution_policies == null ? null : [
      for policy in var.load_distribution_policies : policy == null ? null : merge(policy, {
        load_distribution_targets = policy.load_distribution_targets == null ? null : [
          for target in policy.load_distribution_targets : target == null ? null : {
            id   = target.id
            name = target.name
            properties = anytrue([
              for attribute, value in target : value != null
              if !contains(local.appgateway_component_metadata, attribute)
              ]) ? {
              for attribute, value in target : attribute => value
              if !contains(local.appgateway_component_metadata, attribute)
            } : null
          }
        ]
      })
    ]
    private_link_configurations = var.private_link_configurations == null ? null : [
      for configuration in var.private_link_configurations : configuration == null ? null : merge(configuration, {
        ip_configurations = configuration.ip_configurations == null ? null : [
          for ip_configuration in configuration.ip_configurations : ip_configuration == null ? null : {
            id   = ip_configuration.id
            name = ip_configuration.name
            properties = anytrue([
              for attribute, value in ip_configuration : value != null
              if !contains(local.appgateway_component_metadata, attribute)
              ]) ? {
              for attribute, value in ip_configuration : attribute => value
              if !contains(local.appgateway_component_metadata, attribute)
            } : null
          }
        ]
      })
    ]
    url_path_maps = var.url_path_maps == null ? null : [
      for path_map in var.url_path_maps : path_map == null ? null : merge(path_map, {
        path_rules = path_map.path_rules == null ? null : [
          for path_rule in path_map.path_rules : path_rule == null ? null : {
            id   = path_rule.id
            name = path_rule.name
            properties = anytrue([
              for attribute, value in path_rule : value != null
              if !contains(local.appgateway_component_metadata, attribute)
              ]) ? {
              for attribute, value in path_rule : attribute => value
              if !contains(local.appgateway_component_metadata, attribute)
            } : null
          }
        ]
      })
    ]
  })
  normalized_appgateway_components = {
    for collection, items in local.appgateway_component_inputs : collection => items == null ? null : [
      for item in items : item == null ? null : {
        id   = try(item.id, null)
        name = item.name
        properties = anytrue([
          for attribute, value in item : value != null
          if !contains(local.appgateway_component_metadata, attribute)
          ]) ? {
          for attribute, value in item : attribute => value
          if !contains(local.appgateway_component_metadata, attribute)
        } : null
      }
    ]
  }
  legacy_properties_wrapper_paths = concat(
    flatten([
      for collection, items in local.appgateway_raw_component_inputs : [
        for index, item in coalesce(items, []) :
        "${collection}[${index}].properties"
        if item != null && item.properties != null
      ]
    ]),
    flatten([
      for policy_index, policy in coalesce(var.load_distribution_policies, []) : [
        for target_index, target in coalesce(policy == null ? null : policy.load_distribution_targets, []) :
        "load_distribution_policies[${policy_index}].load_distribution_targets[${target_index}].properties"
        if target != null && target.properties != null
      ]
    ]),
    flatten([
      for configuration_index, configuration in coalesce(var.private_link_configurations, []) : [
        for ip_configuration_index, ip_configuration in coalesce(configuration == null ? null : configuration.ip_configurations, []) :
        "private_link_configurations[${configuration_index}].ip_configurations[${ip_configuration_index}].properties"
        if ip_configuration != null && ip_configuration.properties != null
      ]
    ]),
    flatten([
      for map_index, path_map in coalesce(var.url_path_maps, []) : [
        for rule_index, path_rule in coalesce(path_map == null ? null : path_map.path_rules, []) :
        "url_path_maps[${map_index}].path_rules[${rule_index}].properties"
        if path_rule != null && path_rule.properties != null
      ]
    ]),
  )
}
