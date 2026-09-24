locals {
  child_reference_segments = {
    authentication_certificates      = "authenticationCertificates"
    backend_address_pools            = "backendAddressPools"
    backend_http_settings_collection = "backendHttpSettingsCollection"
    backend_settings_collection      = "backendSettingsCollection"
    entra_jwt_validation_configs     = "entraJWTValidationConfigs"
    frontend_ip_configurations       = "frontendIPConfigurations"
    frontend_ports                   = "frontendPorts"
    http_listeners                   = "httpListeners"
    listeners                        = "listeners"
    load_distribution_policies       = "loadDistributionPolicies"
    private_link_configurations      = "privateLinkConfigurations"
    probes                           = "probes"
    redirect_configurations          = "redirectConfigurations"
    request_routing_rules            = "requestRoutingRules"
    rewrite_rule_sets                = "rewriteRuleSets"
    ssl_certificates                 = "sslCertificates"
    ssl_profiles                     = "sslProfiles"
    trusted_client_certificates      = "trustedClientCertificates"
    trusted_root_certificates        = "trustedRootCertificates"
    url_path_maps                    = "urlPathMaps"
  }
  child_path_rule_targets = flatten([
    for path_map in local.normalized_child_collections.url_path_maps : [
      for rule in coalesce(try(path_map.properties.path_rules, null), []) : {
        key           = jsonencode([lower(path_map.name), lower(rule.name)])
        relative_path = "urlPathMaps/${path_map.name}/pathRules/${rule.name}"
      } if rule == null ? false : rule.name != null
    ] if path_map == null ? false : path_map.name != null
  ])
  # Group duplicates rather than choosing a target silently; resolution requires a unique match.
  child_target_paths = merge(
    {
      for target_type, segment in local.child_reference_segments : target_type => {
        for item in local.normalized_child_collections[target_type] :
        lower(item.name) => "${segment}/${item.name}"...
        if item == null ? false : item.name != null
      }
    },
    {
      path_rules = {
        for target in local.child_path_rule_targets : target.key => target.relative_path...
      }
    },
  )
  child_reference_lookups = {
    for path, reference in local.normalized_child_references : path => {
      target_type = reference.target_type
      lookup_key = reference.name == null ? null : (
        reference.target_type == "path_rules" ? (
          reference.scope_name == null ? null : jsonencode([lower(reference.scope_name), lower(reference.name)])
        ) : lower(reference.name)
      )
      scope_key = reference.scope_name == null ? null : lower(reference.scope_name)
      name_valid = reference.name == null ? true : (
        trimspace(reference.name) != "" && !strcontains(reference.name, "/")
      )
      scope_valid = reference.scope_name == null ? true : (
        trimspace(reference.scope_name) != "" && !strcontains(reference.scope_name, "/")
      )
    }
  }
  child_reference_matches = {
    for path, reference in local.child_reference_lookups : path => {
      target_paths = reference.lookup_key == null ? [] : lookup(local.child_target_paths[reference.target_type], reference.lookup_key, [])
      scope_paths  = reference.scope_key == null ? [] : lookup(local.child_target_paths.url_path_maps, reference.scope_key, [])
    }
  }
  matched_child_reference_paths = {
    for path, matches in local.child_reference_matches : path => (
      length(matches.target_paths) == 1 &&
      (local.normalized_child_references[path].target_type != "path_rules" || length(matches.scope_paths) == 1)
    ) ? one(matches.target_paths) : null
  }
  child_reference_resolution = {
    for path, reference in local.normalized_child_references : path => {
      present       = reference.present
      id            = reference.id
      relative_path = local.matched_child_reference_paths[path]
      status = reference.mode != "name" ? reference.mode : (
        !local.child_reference_lookups[path].name_valid || !local.child_reference_lookups[path].scope_valid ? "invalid_name" :
        local.matched_child_reference_paths[path] == null ? "unresolved" : "resolved"
      )
    }
  }
  invalid_child_reference_shape_paths = [
    for path, reference in local.child_reference_resolution : path if reference.status == "invalid"
  ]
  invalid_child_reference_name_paths = [
    for path, reference in local.child_reference_resolution : path if reference.status == "invalid_name"
  ]
  unresolved_child_reference_paths = [
    for path, reference in local.child_reference_resolution : path if reference.status == "unresolved"
  ]

  # ID-only and absent references do not need to construct or validate the gateway prefix.
  application_gateway_resource_id = anytrue([
    for reference in values(local.child_reference_resolution) : reference.status == "resolved"
  ]) ? provider::azapi::build_resource_id(var.parent_id, "Microsoft.Network/applicationGateways", var.name) : null
  resolved_child_references = {
    for path, reference in local.child_reference_resolution : path => reference.present ? {
      id = reference.status == "id" ? reference.id : (
        reference.status == "resolved" ? "${local.application_gateway_resource_id}/${reference.relative_path}" : null
      )
    } : null
  }
}
