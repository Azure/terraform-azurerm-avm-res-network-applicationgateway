mock_provider "azapi" {}
mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}

run "classifies_scalar_references_and_preserves_rendering" {
  command = apply

  variables {
    enable_telemetry = false
    location         = "westus2"
    name             = "gateway"
    parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg"
    probes           = [{ name = "CanonicalProbe" }]
    backend_http_settings_collection = [
      {
        name  = "id-only"
        probe = { id = "not/an/arm/resource/id" }
      },
      {
        name  = "name-only"
        probe = { probe_key = "canonicalprobe" }
      },
      {
        name  = "null-reference"
        probe = null
      },
      {
        name  = "empty-reference"
        probe = {}
      },
      {
        name = "explicit-nulls"
        probe = {
          id        = null
          probe_key = null
        }
      },
      {
        name  = "empty-id"
        probe = { id = "" }
      },
    ]
  }

  assert {
    condition = alltrue([
      local.normalized_child_references["backend_http_settings_collection[0].probe"].mode == "id",
      local.normalized_child_references["backend_http_settings_collection[0].probe"].present,
      local.normalized_child_references["backend_http_settings_collection[0].probe"].id == "not/an/arm/resource/id",
      local.normalized_child_references["backend_http_settings_collection[1].probe"].mode == "key",
      local.normalized_child_references["backend_http_settings_collection[1].probe"].key == "canonicalprobe",
      local.normalized_child_references["backend_http_settings_collection[1].probe"].scope_key == null,
      local.normalized_child_references["backend_http_settings_collection[1].probe"].target_type == "probes",
      local.normalized_child_references["backend_http_settings_collection[2].probe"].mode == "none",
      !local.normalized_child_references["backend_http_settings_collection[2].probe"].present,
      local.normalized_child_references["backend_http_settings_collection[3].probe"].mode == "none",
      local.normalized_child_references["backend_http_settings_collection[3].probe"].present,
      local.normalized_child_references["backend_http_settings_collection[4].probe"].mode == "none",
      local.normalized_child_references["backend_http_settings_collection[4].probe"].present,
      local.normalized_child_references["backend_http_settings_collection[5].probe"].mode == "id",
      local.normalized_child_references["backend_http_settings_collection[5].probe"].id == "",
      local.resolved_child_references["backend_http_settings_collection[2].probe"] == null,
      jsonencode(local.resolved_child_references["backend_http_settings_collection[3].probe"]) == jsonencode({ id = null }),
      jsonencode(local.resolved_child_references["backend_http_settings_collection[4].probe"]) == jsonencode({ id = null }),
    ])
    error_message = "Scalar references must retain their source path, presence, target type, raw values, classification, and null-versus-present resolution."
  }

  assert {
    condition = jsonencode([
      for item in azapi_resource.this.body.properties.backendHttpSettingsCollection :
      try(item.properties.probe, null)
      ]) == jsonencode([
      { id = "not/an/arm/resource/id" },
      { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/gateway/probes/CanonicalProbe" },
      null,
      { id = null },
      { id = null },
      { id = "" },
    ])
    error_message = "ARM rendering must distinguish null from present null-valued objects and must preserve raw IDs, including an empty string."
  }
}

run "preserves_list_indexes_nulls_and_duplicates" {
  command = apply

  variables {
    enable_telemetry            = false
    location                    = "westus2"
    name                        = "gateway"
    parent_id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg"
    authentication_certificates = [{ name = "CanonicalCertificate" }]
    backend_http_settings_collection = [{
      name = "settings"
      authentication_certificates = [
        null,
        {},
        { authentication_certificate_key = "canonicalcertificate" },
        { authentication_certificate_key = "CANONICALCERTIFICATE" },
        { id = "/opaque/certificate" },
      ]
    }]
  }

  assert {
    condition = alltrue([
      for index in range(5) :
      local.normalized_child_references["backend_http_settings_collection[0].authentication_certificates[${index}]"].path == "backend_http_settings_collection[0].authentication_certificates[${index}]"
    ])
    error_message = "List reference normalization must retain each original source index."
  }

  assert {
    condition = jsonencode(
      azapi_resource.this.body.properties.backendHttpSettingsCollection[0].properties.authenticationCertificates
      ) == jsonencode([
        null,
        { id = null },
        { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/gateway/authenticationCertificates/CanonicalCertificate" },
        { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/gateway/authenticationCertificates/CanonicalCertificate" },
        { id = "/opaque/certificate" },
    ])
    error_message = "List rendering must preserve null and empty elements, duplicates, order, and raw IDs."
  }
}

run "resolves_reused_names_by_target_type" {
  command = apply

  variables {
    enable_telemetry      = false
    location              = "westus2"
    name                  = "gateway"
    parent_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg"
    backend_address_pools = [{ name = "Shared" }]
    probes                = [{ name = "Shared" }]
    backend_http_settings_collection = [{
      name  = "Settings"
      probe = { probe_key = "shared" }
    }]
    request_routing_rules = [{
      name                  = "rule"
      backend_address_pool  = { backend_address_pool_key = "SHARED" }
      backend_http_settings = { id = "/opaque/backend-settings" }
    }]
  }

  assert {
    condition = jsonencode({
      probe = azapi_resource.this.body.properties.backendHttpSettingsCollection[0].properties.probe
      pool  = azapi_resource.this.body.properties.requestRoutingRules[0].properties.backendAddressPool
      raw   = azapi_resource.this.body.properties.requestRoutingRules[0].properties.backendHttpSettings
      }) == jsonencode({
      probe = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/gateway/probes/Shared" }
      pool  = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/gateway/backendAddressPools/Shared" }
      raw   = { id = "/opaque/backend-settings" }
    })
    error_message = "The same case-insensitive name must resolve independently by target type while explicit IDs pass through unchanged."
  }
}

run "preserves_compound_invalid_list_paths" {
  command = plan

  variables {
    enable_telemetry = false
    location         = "westus2"
    name             = "gateway"
    parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg"
    backend_http_settings_collection = [{
      name = "settings"
      authentication_certificates = [{
        authentication_certificate_key = "certificate"
        id                             = "/opaque/certificate"
      }]
    }]
    redirect_configurations = [{
      name = "redirect"
      path_rules = [
        {
          id               = "/opaque/path-rule"
          path_rule_key    = "rule"
          url_path_map_key = "map"
        },
        { url_path_map_key = "map" },
        { path_rule_key = "rule" },
      ]
    }]
  }

  expect_failures = [azapi_resource.this]

  assert {
    condition = jsonencode(sort(local.invalid_child_reference_shape_paths)) == jsonencode(sort([
      "backend_http_settings_collection[0].authentication_certificates[0]",
      "redirect_configurations[0].path_rules[0]",
      "redirect_configurations[0].path_rules[1]",
      "redirect_configurations[0].path_rules[2]",
    ]))
    error_message = "Compound shape validation must report every original list source path."
  }
}

run "plans_mixed_known_and_unknown_references" {
  command = plan

  module {
    source = "./tests/unit/fixtures/reference_normalization"
  }
}

run "preserves_null_elements_and_properties" {
  command = apply

  variables {
    enable_telemetry = false
    location         = "westus2"
    name             = "gateway"
    parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg"
    probes           = [{ name = "Probe" }]
    backend_http_settings_collection = [
      null,
      {
        name       = "null-properties"
        properties = null
      },
      {
        name  = "resolved-properties"
        probe = { probe_key = "probe" }
      },
    ]
  }

  assert {
    condition = alltrue([
      jsonencode(slice(azapi_resource.this.body.properties.backendHttpSettingsCollection, 0, 2)) == jsonencode([
        null,
        {
          name       = "null-properties"
          properties = null
        },
      ]),
      !local.normalized_child_references["backend_http_settings_collection[0].probe"].present,
      local.normalized_child_references["backend_http_settings_collection[0].probe"].mode == "none",
      local.resolved_child_references["backend_http_settings_collection[0].probe"] == null,
      !local.normalized_child_references["backend_http_settings_collection[1].probe"].present,
      local.normalized_child_references["backend_http_settings_collection[1].probe"].mode == "none",
      local.resolved_child_references["backend_http_settings_collection[1].probe"] == null,
      azapi_resource.this.body.properties.backendHttpSettingsCollection[2].properties.probe.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/gateway/probes/Probe",
    ])
    error_message = "Null collection elements and null properties must render unchanged without preventing heterogeneous siblings from resolving."
  }
}
