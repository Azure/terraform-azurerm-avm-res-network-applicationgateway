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

run "preserves_legacy_id_null_and_empty_references" {
  command = apply

  variables {
    backend_http_settings_collection = [
      null,
      {
        name = "settings"
        properties = {
          authentication_certificates = [
            null,
            {},
            { id = null },
            { id = "not/an/arm/resource/id" },
          ]
          probe = {}
          trusted_root_certificates = [
            null,
            { id = "/opaque/root" },
          ]
        }
      },
    ]
    redirect_configurations = [{
      name = "redirect"
      properties = {
        path_rules = [
          null,
          {},
          { id = "opaque/path/rule" },
        ]
      }
    }]
  }

  assert {
    condition = alltrue([
      azapi_resource.this.body.properties.backendHttpSettingsCollection[0] == null,
      azapi_resource.this.body.properties.backendHttpSettingsCollection[1].properties.authenticationCertificates[0] == null,
      azapi_resource.this.body.properties.backendHttpSettingsCollection[1].properties.authenticationCertificates[1].id == null,
      azapi_resource.this.body.properties.backendHttpSettingsCollection[1].properties.authenticationCertificates[2].id == null,
      azapi_resource.this.body.properties.backendHttpSettingsCollection[1].properties.authenticationCertificates[3].id == "not/an/arm/resource/id",
      azapi_resource.this.body.properties.backendHttpSettingsCollection[1].properties.probe.id == null,
      azapi_resource.this.body.properties.backendHttpSettingsCollection[1].properties.trustedRootCertificates[0] == null,
      azapi_resource.this.body.properties.backendHttpSettingsCollection[1].properties.trustedRootCertificates[1].id == "/opaque/root",
      azapi_resource.this.body.properties.redirectConfigurations[0].properties.pathRules[0] == null,
      azapi_resource.this.body.properties.redirectConfigurations[0].properties.pathRules[1].id == null,
      azapi_resource.this.body.properties.redirectConfigurations[0].properties.pathRules[2].id == "opaque/path/rule",
    ])
    error_message = "Legacy ID-only values, null elements, and empty reference objects must pass through unchanged."
  }
}

run "matching_name_and_id_modes_emit_equivalent_reference_ids" {
  command = apply

  variables {
    backend_address_pools = [{ name = "Pool" }]
    request_routing_rules = [
      {
        name = "name-mode"
        properties = {
          backend_address_pool = { name = "pool" }
        }
      },
      {
        name = "id-mode"
        properties = {
          backend_address_pool = {
            id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/gateway/backendAddressPools/Pool"
          }
        }
      },
    ]
  }

  assert {
    condition     = azapi_resource.this.body.properties.requestRoutingRules[0].properties.backendAddressPool == azapi_resource.this.body.properties.requestRoutingRules[1].properties.backendAddressPool
    error_message = "A matching name-mode reference and legacy ID-mode reference should emit identical ARM objects."
  }
}

run "qualifies_same_path_rule_name_by_parent_map" {
  command = apply

  variables {
    redirect_configurations = [{
      name = "redirect"
      properties = {
        path_rules = [
          { name = "rule", url_path_map_name = "mapone" },
          { name = "RULE", url_path_map_name = "MAPTWO" },
        ]
      }
    }]
    url_path_maps = [
      {
        name       = "MapOne"
        properties = { path_rules = [{ name = "Rule" }] }
      },
      {
        name       = "MapTwo"
        properties = { path_rules = [{ name = "Rule" }] }
      },
    ]
  }

  assert {
    condition = alltrue([
      azapi_resource.this.body.properties.redirectConfigurations[0].properties.pathRules[0].id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/gateway/urlPathMaps/MapOne/pathRules/Rule",
      azapi_resource.this.body.properties.redirectConfigurations[0].properties.pathRules[1].id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/gateway/urlPathMaps/MapTwo/pathRules/Rule",
    ])
    error_message = "Path rule names should be resolved only within their qualified URL path map."
  }
}
