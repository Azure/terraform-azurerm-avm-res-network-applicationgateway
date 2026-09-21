locals {
  child_reference_segments = {
    authentication_certificates  = "authenticationCertificates"
    backend_address_pools        = "backendAddressPools"
    backend_http_settings        = "backendHttpSettingsCollection"
    backend_settings             = "backendSettingsCollection"
    entra_jwt_validation_configs = "entraJWTValidationConfigs"
    frontend_ip_configurations   = "frontendIPConfigurations"
    frontend_ports               = "frontendPorts"
    http_listeners               = "httpListeners"
    listeners                    = "listeners"
    load_distribution_policies   = "loadDistributionPolicies"
    private_link_configurations  = "privateLinkConfigurations"
    probes                       = "probes"
    redirect_configurations      = "redirectConfigurations"
    request_routing_rules        = "requestRoutingRules"
    rewrite_rule_sets            = "rewriteRuleSets"
    ssl_certificates             = "sslCertificates"
    ssl_profiles                 = "sslProfiles"
    trusted_client_certificates  = "trustedClientCertificates"
    trusted_root_certificates    = "trustedRootCertificates"
    url_path_maps                = "urlPathMaps"
  }
  child_declarations = concat(
    [for item in var.authentication_certificates == null ? [] : var.authentication_certificates : { target_type = "authentication_certificates", name = item.name } if item == null ? false : item.name != null],
    [for item in var.backend_address_pools == null ? [] : var.backend_address_pools : { target_type = "backend_address_pools", name = item.name } if item == null ? false : item.name != null],
    [for item in var.backend_http_settings_collection == null ? [] : var.backend_http_settings_collection : { target_type = "backend_http_settings", name = item.name } if item == null ? false : item.name != null],
    [for item in var.backend_settings_collection == null ? [] : var.backend_settings_collection : { target_type = "backend_settings", name = item.name } if item == null ? false : item.name != null],
    [for item in var.entra_jwt_validation_configs == null ? [] : var.entra_jwt_validation_configs : { target_type = "entra_jwt_validation_configs", name = item.name } if item == null ? false : item.name != null],
    [for item in var.frontend_ip_configurations == null ? [] : var.frontend_ip_configurations : { target_type = "frontend_ip_configurations", name = item.name } if item == null ? false : item.name != null],
    [for item in var.frontend_ports == null ? [] : var.frontend_ports : { target_type = "frontend_ports", name = item.name } if item == null ? false : item.name != null],
    [for item in var.http_listeners == null ? [] : var.http_listeners : { target_type = "http_listeners", name = item.name } if item == null ? false : item.name != null],
    [for item in var.listeners == null ? [] : var.listeners : { target_type = "listeners", name = item.name } if item == null ? false : item.name != null],
    [for item in var.load_distribution_policies == null ? [] : var.load_distribution_policies : { target_type = "load_distribution_policies", name = item.name } if item == null ? false : item.name != null],
    [for item in var.private_link_configurations == null ? [] : var.private_link_configurations : { target_type = "private_link_configurations", name = item.name } if item == null ? false : item.name != null],
    [for item in var.probes == null ? [] : var.probes : { target_type = "probes", name = item.name } if item == null ? false : item.name != null],
    [for item in var.redirect_configurations == null ? [] : var.redirect_configurations : { target_type = "redirect_configurations", name = item.name } if item == null ? false : item.name != null],
    [for item in var.request_routing_rules == null ? [] : var.request_routing_rules : { target_type = "request_routing_rules", name = item.name } if item == null ? false : item.name != null],
    [for item in var.rewrite_rule_sets == null ? [] : var.rewrite_rule_sets : { target_type = "rewrite_rule_sets", name = item.name } if item == null ? false : item.name != null],
    [for item in var.ssl_certificates == null ? [] : var.ssl_certificates : { target_type = "ssl_certificates", name = item.name } if item == null ? false : item.name != null],
    [for item in var.ssl_profiles == null ? [] : var.ssl_profiles : { target_type = "ssl_profiles", name = item.name } if item == null ? false : item.name != null],
    [for item in var.trusted_client_certificates == null ? [] : var.trusted_client_certificates : { target_type = "trusted_client_certificates", name = item.name } if item == null ? false : item.name != null],
    [for item in var.trusted_root_certificates == null ? [] : var.trusted_root_certificates : { target_type = "trusted_root_certificates", name = item.name } if item == null ? false : item.name != null],
    [for item in var.url_path_maps == null ? [] : var.url_path_maps : { target_type = "url_path_maps", name = item.name } if item == null ? false : item.name != null],
  )
  child_names_by_type = {
    for target_type, _ in local.child_reference_segments : target_type => {
      for declaration in local.child_declarations : lower(declaration.name) => declaration.name...
      if declaration.target_type == target_type
    }
  }
  path_rule_declarations = flatten([
    for url_path_map in var.url_path_maps == null ? [] : var.url_path_maps : [
      for path_rule in try(url_path_map.properties.path_rules, null) == null ? [] : url_path_map.properties.path_rules : {
        name              = path_rule.name
        url_path_map_name = url_path_map.name
      } if path_rule == null ? false : path_rule.name != null && url_path_map.name != null
    ] if try(url_path_map.properties, null) != null
  ])
  path_rule_names = {
    for declaration in local.path_rule_declarations :
    jsonencode([lower(declaration.url_path_map_name), lower(declaration.name)]) => declaration...
  }
}

locals {
  child_references = concat(
    flatten([for source_index, source in var.backend_http_settings_collection == null ? [] : var.backend_http_settings_collection : [
      for reference_index, reference in try(source.properties.authentication_certificates, null) == null ? [] : source.properties.authentication_certificates : {
        path              = "backend_http_settings_collection[${source_index}].properties.authentication_certificates[${reference_index}]"
        target_type       = "authentication_certificates"
        id                = reference.id
        name              = reference.name
        url_path_map_name = null
      } if reference != null
    ]]),
    [for source_index, source in var.backend_http_settings_collection == null ? [] : var.backend_http_settings_collection : {
      path              = "backend_http_settings_collection[${source_index}].properties.probe"
      target_type       = "probes"
      id                = try(source.properties.probe.id, null)
      name              = try(source.properties.probe.name, null)
      url_path_map_name = null
    } if try(source.properties.probe, null) != null],
    flatten([for source_index, source in var.backend_http_settings_collection == null ? [] : var.backend_http_settings_collection : [
      for reference_index, reference in try(source.properties.trusted_root_certificates, null) == null ? [] : source.properties.trusted_root_certificates : {
        path              = "backend_http_settings_collection[${source_index}].properties.trusted_root_certificates[${reference_index}]"
        target_type       = "trusted_root_certificates"
        id                = reference.id
        name              = reference.name
        url_path_map_name = null
      } if reference != null
    ]]),
    [for source_index, source in var.backend_settings_collection == null ? [] : var.backend_settings_collection : {
      path              = "backend_settings_collection[${source_index}].properties.probe"
      target_type       = "probes"
      id                = try(source.properties.probe.id, null)
      name              = try(source.properties.probe.name, null)
      url_path_map_name = null
    } if try(source.properties.probe, null) != null],
    flatten([for source_index, source in var.backend_settings_collection == null ? [] : var.backend_settings_collection : [
      for reference_index, reference in try(source.properties.trusted_root_certificates, null) == null ? [] : source.properties.trusted_root_certificates : {
        path              = "backend_settings_collection[${source_index}].properties.trusted_root_certificates[${reference_index}]"
        target_type       = "trusted_root_certificates"
        id                = reference.id
        name              = reference.name
        url_path_map_name = null
      } if reference != null
    ]]),
    [for source_index, source in var.frontend_ip_configurations == null ? [] : var.frontend_ip_configurations : {
      path              = "frontend_ip_configurations[${source_index}].properties.private_link_configuration"
      target_type       = "private_link_configurations"
      id                = try(source.properties.private_link_configuration.id, null)
      name              = try(source.properties.private_link_configuration.name, null)
      url_path_map_name = null
    } if try(source.properties.private_link_configuration, null) != null],
    flatten([
      for source_type, sources in {
        http_listeners = var.http_listeners
        listeners      = var.listeners
        } : flatten([
          for source_index, source in sources == null ? [] : sources : [
            for reference_name, target_type in {
              frontend_ip_configuration = "frontend_ip_configurations"
              frontend_port             = "frontend_ports"
              ssl_certificate           = "ssl_certificates"
              ssl_profile               = "ssl_profiles"
              } : {
              path              = "${source_type}[${source_index}].properties.${reference_name}"
              target_type       = target_type
              id                = try(source.properties[reference_name].id, null)
              name              = try(source.properties[reference_name].name, null)
              url_path_map_name = null
            } if try(source.properties[reference_name], null) != null
          ]
      ])
    ]),
    flatten([for policy_index, policy in var.load_distribution_policies == null ? [] : var.load_distribution_policies : [
      for target_index, target in try(policy.properties.load_distribution_targets, null) == null ? [] : policy.properties.load_distribution_targets : {
        path              = "load_distribution_policies[${policy_index}].properties.load_distribution_targets[${target_index}].properties.backend_address_pool"
        target_type       = "backend_address_pools"
        id                = try(target.properties.backend_address_pool.id, null)
        name              = try(target.properties.backend_address_pool.name, null)
        url_path_map_name = null
      } if try(target.properties.backend_address_pool, null) != null
    ]]),
    flatten([for source_index, source in var.redirect_configurations == null ? [] : var.redirect_configurations : [
      for reference_index, reference in try(source.properties.path_rules, null) == null ? [] : source.properties.path_rules : {
        path              = "redirect_configurations[${source_index}].properties.path_rules[${reference_index}]"
        target_type       = "path_rules"
        id                = reference.id
        name              = reference.name
        url_path_map_name = reference.url_path_map_name
      } if reference != null
    ]]),
    flatten([for source_index, source in var.redirect_configurations == null ? [] : var.redirect_configurations : [
      for reference_index, reference in try(source.properties.request_routing_rules, null) == null ? [] : source.properties.request_routing_rules : {
        path              = "redirect_configurations[${source_index}].properties.request_routing_rules[${reference_index}]"
        target_type       = "request_routing_rules"
        id                = reference.id
        name              = reference.name
        url_path_map_name = null
      } if reference != null
    ]]),
    [for source_index, source in var.redirect_configurations == null ? [] : var.redirect_configurations : {
      path              = "redirect_configurations[${source_index}].properties.target_listener"
      target_type       = "http_listeners"
      id                = try(source.properties.target_listener.id, null)
      name              = try(source.properties.target_listener.name, null)
      url_path_map_name = null
    } if try(source.properties.target_listener, null) != null],
    flatten([for source_index, source in var.redirect_configurations == null ? [] : var.redirect_configurations : [
      for reference_index, reference in try(source.properties.url_path_maps, null) == null ? [] : source.properties.url_path_maps : {
        path              = "redirect_configurations[${source_index}].properties.url_path_maps[${reference_index}]"
        target_type       = "url_path_maps"
        id                = reference.id
        name              = reference.name
        url_path_map_name = null
      } if reference != null
    ]]),
    flatten([for source_index, source in var.request_routing_rules == null ? [] : var.request_routing_rules : [
      for reference_name, target_type in {
        backend_address_pool        = "backend_address_pools"
        backend_http_settings       = "backend_http_settings"
        entra_jwt_validation_config = "entra_jwt_validation_configs"
        http_listener               = "http_listeners"
        load_distribution_policy    = "load_distribution_policies"
        redirect_configuration      = "redirect_configurations"
        rewrite_rule_set            = "rewrite_rule_sets"
        url_path_map                = "url_path_maps"
        } : {
        path              = "request_routing_rules[${source_index}].properties.${reference_name}"
        target_type       = target_type
        id                = try(source.properties[reference_name].id, null)
        name              = try(source.properties[reference_name].name, null)
        url_path_map_name = null
      } if try(source.properties[reference_name], null) != null
    ]]),
    flatten([for source_index, source in var.routing_rules == null ? [] : var.routing_rules : [
      for reference_name, target_type in {
        backend_address_pool = "backend_address_pools"
        backend_settings     = "backend_settings"
        listener             = "listeners"
        } : {
        path              = "routing_rules[${source_index}].properties.${reference_name}"
        target_type       = target_type
        id                = try(source.properties[reference_name].id, null)
        name              = try(source.properties[reference_name].name, null)
        url_path_map_name = null
      } if try(source.properties[reference_name], null) != null
    ]]),
    flatten([for source_index, source in var.ssl_profiles == null ? [] : var.ssl_profiles : [
      for reference_index, reference in try(source.properties.trusted_client_certificates, null) == null ? [] : source.properties.trusted_client_certificates : {
        path              = "ssl_profiles[${source_index}].properties.trusted_client_certificates[${reference_index}]"
        target_type       = "trusted_client_certificates"
        id                = reference.id
        name              = reference.name
        url_path_map_name = null
      } if reference != null
    ]]),
    flatten([for source_index, source in var.url_path_maps == null ? [] : var.url_path_maps : [
      for reference_name, target_type in {
        default_backend_address_pool     = "backend_address_pools"
        default_backend_http_settings    = "backend_http_settings"
        default_load_distribution_policy = "load_distribution_policies"
        default_redirect_configuration   = "redirect_configurations"
        default_rewrite_rule_set         = "rewrite_rule_sets"
        } : {
        path              = "url_path_maps[${source_index}].properties.${reference_name}"
        target_type       = target_type
        id                = try(source.properties[reference_name].id, null)
        name              = try(source.properties[reference_name].name, null)
        url_path_map_name = null
      } if try(source.properties[reference_name], null) != null
    ]]),
    flatten([for map_index, url_path_map in var.url_path_maps == null ? [] : var.url_path_maps : [
      for rule_index, path_rule in try(url_path_map.properties.path_rules, null) == null ? [] : url_path_map.properties.path_rules : [
        for reference_name, target_type in {
          backend_address_pool     = "backend_address_pools"
          backend_http_settings    = "backend_http_settings"
          load_distribution_policy = "load_distribution_policies"
          redirect_configuration   = "redirect_configurations"
          rewrite_rule_set         = "rewrite_rule_sets"
          } : {
          path              = "url_path_maps[${map_index}].properties.path_rules[${rule_index}].properties.${reference_name}"
          target_type       = target_type
          id                = try(path_rule.properties[reference_name].id, null)
          name              = try(path_rule.properties[reference_name].name, null)
          url_path_map_name = null
        } if try(path_rule.properties[reference_name], null) != null
      ] if path_rule != null
    ]]),
  )
}

locals {
  child_reference_validation = [
    for reference in local.child_references : {
      path        = reference.path
      target_type = reference.target_type
      id          = reference.id
      name        = reference.name
      scope_name  = reference.url_path_map_name
      shape_valid = reference.target_type == "path_rules" ? (
        !(reference.id != null && (reference.name != null || reference.url_path_map_name != null)) &&
        ((reference.name == null) == (reference.url_path_map_name == null))
        ) : !(
        reference.id != null && reference.name != null
      )
      name_valid = reference.name == null ? true : (
        trimspace(reference.name) != "" && !strcontains(reference.name, "/")
      )
      scope_valid = reference.url_path_map_name == null ? true : (
        trimspace(reference.url_path_map_name) != "" && !strcontains(reference.url_path_map_name, "/")
      )
      target_match_count = reference.name == null ? 0 : reference.target_type == "path_rules" ? (
        reference.url_path_map_name == null ? 0 : try(length(local.path_rule_names[jsonencode([lower(reference.url_path_map_name), lower(reference.name)])]), 0)
        ) : try(
        length(local.child_names_by_type[reference.target_type][lower(reference.name)]),
        0,
      )
      scope_match_count = reference.target_type != "path_rules" || reference.url_path_map_name == null ? 0 : try(
        length(local.child_names_by_type.url_path_maps[lower(reference.url_path_map_name)]),
        0,
      )
    }
  ]
  invalid_child_reference_shape_paths = [
    for reference in local.child_reference_validation : reference.path
    if !reference.shape_valid
  ]
  invalid_child_reference_name_paths = [
    for reference in local.child_reference_validation : reference.path
    if reference.shape_valid && (!reference.name_valid || !reference.scope_valid)
  ]
  unresolved_child_reference_paths = [
    for reference in local.child_reference_validation : reference.path
    if reference.shape_valid && reference.name_valid && reference.scope_valid && reference.name != null && (
      reference.target_match_count != 1 ||
      (reference.target_type == "path_rules" && reference.scope_match_count != 1)
    )
  ]
  has_resolvable_named_child_reference = anytrue([
    for reference in local.child_reference_validation :
    reference.shape_valid &&
    reference.name_valid &&
    reference.scope_valid &&
    reference.name != null &&
    reference.target_match_count == 1 &&
    (reference.target_type != "path_rules" || reference.scope_match_count == 1)
  ])
  application_gateway_resource_id = local.has_resolvable_named_child_reference ? provider::azapi::build_resource_id(
    var.parent_id,
    "Microsoft.Network/applicationGateways",
    var.name,
  ) : null
  child_reference_ids = {
    for reference in local.child_references : reference.path => reference.name == null ? reference.id : (
      reference.target_type == "path_rules" ? (
        reference.id == null && reference.url_path_map_name != null ? (
          trimspace(reference.name) != "" &&
          !strcontains(reference.name, "/") &&
          trimspace(reference.url_path_map_name) != "" &&
          !strcontains(reference.url_path_map_name, "/") &&
          try(length(local.child_names_by_type.url_path_maps[lower(reference.url_path_map_name)]), 0) == 1 &&
          try(length(local.path_rule_names[jsonencode([lower(reference.url_path_map_name), lower(reference.name)])]), 0) == 1 ? format(
            "%s/urlPathMaps/%s/pathRules/%s",
            local.application_gateway_resource_id,
            one(local.child_names_by_type.url_path_maps[lower(reference.url_path_map_name)]),
            one(local.path_rule_names[jsonencode([lower(reference.url_path_map_name), lower(reference.name)])]).name,
          ) : null
        ) : null
      ) : reference.id == null &&
      trimspace(reference.name) != "" &&
      !strcontains(reference.name, "/") &&
      try(length(local.child_names_by_type[reference.target_type][lower(reference.name)]), 0) == 1 ? format(
        "%s/%s/%s",
        local.application_gateway_resource_id,
        local.child_reference_segments[reference.target_type],
        one(local.child_names_by_type[reference.target_type][lower(reference.name)]),
      ) : null
    )
  }
  child_reference_ids_by_target = {
    for target_type in concat(keys(local.child_reference_segments), ["path_rules"]) : target_type => {
      for reference in local.child_references :
      jsonencode([reference.id, reference.name, reference.url_path_map_name]) => local.child_reference_ids[reference.path]...
      if reference.target_type == target_type
    }
  }
}
