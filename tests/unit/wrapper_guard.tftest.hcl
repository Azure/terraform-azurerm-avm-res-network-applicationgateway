mock_provider "azapi" {}
mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  enable_telemetry = false
  location         = "westus2"
  name             = "gateway"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg"
}

run "rejects_every_legacy_properties_wrapper" {
  command = plan

  variables {
    authentication_certificates      = [{ data = "mixed-flat-value", properties = { data = "discarded-legacy-value" } }]
    backend_address_pools            = [{ properties = {} }]
    backend_http_settings_collection = [{ properties = {} }]
    backend_settings_collection      = [{ properties = {} }]
    entra_jwt_validation_configs     = [{ properties = {} }]
    frontend_ip_configurations       = [{ properties = {} }]
    frontend_ports                   = [{ properties = {} }]
    gateway_ip_configurations        = [{ properties = {} }]
    http_listeners                   = [{ properties = {} }]
    listeners                        = [{ properties = {} }]
    load_distribution_policies = [{
      properties = {}
      load_distribution_targets = [{
        properties = {}
      }]
    }]
    private_link_configurations = [{
      properties = {}
      ip_configurations = [{
        properties = {}
      }]
    }]
    probes                      = [{ properties = {} }]
    redirect_configurations     = [{ properties = {} }]
    request_routing_rules       = [{ properties = {} }]
    rewrite_rule_sets           = [{ properties = {} }]
    routing_rules               = [{ properties = {} }]
    ssl_certificates            = [{ properties = {} }]
    ssl_profiles                = [{ properties = {} }]
    trusted_client_certificates = [{ properties = {} }]
    trusted_root_certificates   = [{ properties = {} }]
    url_path_maps = [{
      properties = {}
      path_rules = [{
        properties = {}
      }]
    }]
  }

  expect_failures = [azapi_resource.this]

  assert {
    condition = jsonencode(sort(local.legacy_properties_wrapper_paths)) == jsonencode(sort([
      "authentication_certificates[0].properties",
      "backend_address_pools[0].properties",
      "backend_http_settings_collection[0].properties",
      "backend_settings_collection[0].properties",
      "entra_jwt_validation_configs[0].properties",
      "frontend_ip_configurations[0].properties",
      "frontend_ports[0].properties",
      "gateway_ip_configurations[0].properties",
      "http_listeners[0].properties",
      "listeners[0].properties",
      "load_distribution_policies[0].load_distribution_targets[0].properties",
      "load_distribution_policies[0].properties",
      "private_link_configurations[0].ip_configurations[0].properties",
      "private_link_configurations[0].properties",
      "probes[0].properties",
      "redirect_configurations[0].properties",
      "request_routing_rules[0].properties",
      "rewrite_rule_sets[0].properties",
      "routing_rules[0].properties",
      "ssl_certificates[0].properties",
      "ssl_profiles[0].properties",
      "trusted_client_certificates[0].properties",
      "trusted_root_certificates[0].properties",
      "url_path_maps[0].path_rules[0].properties",
      "url_path_maps[0].properties",
    ]))
    error_message = "The migration guard must report all 22 top-level and three nested legacy wrapper locations, including empty, populated, and mixed wrappers."
  }
}

run "explicit_null_sentinels_are_harmless" {
  command = apply

  variables {
    authentication_certificates = [{
      data       = "flat-value"
      name       = "certificate"
      properties = null
    }]
    load_distribution_policies = [{
      load_distribution_algorithm = "RoundRobin"
      name                        = "policy"
      properties                  = null
      load_distribution_targets = [{
        name              = "target"
        properties        = null
        weight_per_server = 0
      }]
    }]
    private_link_configurations = [{
      name       = "private-link"
      properties = null
      ip_configurations = [{
        name       = "ip"
        primary    = false
        properties = null
      }]
    }]
    url_path_maps = [{
      name       = "map"
      properties = null
      path_rules = [{
        name       = "rule"
        paths      = []
        properties = null
      }]
    }]
  }

  assert {
    condition = (
      length(local.legacy_properties_wrapper_paths) == 0 &&
      azapi_resource.this.body.properties.authenticationCertificates[0].properties.data == "flat-value" &&
      azapi_resource.this.body.properties.loadDistributionPolicies[0].properties.loadDistributionTargets[0].properties.weightPerServer == 0 &&
      !azapi_resource.this.body.properties.privateLinkConfigurations[0].properties.ipConfigurations[0].properties.primary &&
      length(azapi_resource.this.body.properties.urlPathMaps[0].properties.pathRules[0].properties.paths) == 0
    )
    error_message = "Explicit null sentinels must behave like omission while flat false, zero, and empty-list values remain present in the ARM payload."
  }
}
