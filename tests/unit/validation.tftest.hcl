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

run "rejects_id_and_key_together" {
  command = plan

  variables {
    frontend_ports = [{ name = "port" }]
    http_listeners = [{
      name = "listener"
      properties = {
        frontend_port = {
          frontend_port_key = "port"
          id                = "/opaque/legacy-id"
        }
      }
    }]
  }

  expect_failures = [azapi_resource.this]
}

run "rejects_missing_keyed_target" {
  command = plan

  variables {
    http_listeners = [{
      name = "listener"
      properties = {
        frontend_port = { frontend_port_key = "missing" }
      }
    }]
  }

  expect_failures = [azapi_resource.this]
}

run "rejects_case_insensitive_ambiguity_only_when_referenced" {
  command = plan

  variables {
    frontend_ports = [
      { name = "Port" },
      { name = "PORT" },
    ]
    http_listeners = [{
      name = "listener"
      properties = {
        frontend_port = { frontend_port_key = "port" }
      }
    }]
  }

  expect_failures = [azapi_resource.this]
}

run "allows_unreferenced_duplicate_declarations" {
  command = apply

  variables {
    frontend_ports = [
      { name = "Port" },
      { name = "PORT" },
    ]
  }

  assert {
    condition     = length(azapi_resource.this.body.properties.frontendPorts) == 2
    error_message = "Duplicate declaration names should be validated only when a keyed reference targets them."
  }
}

run "rejects_malformed_new_keys" {
  command = plan

  variables {
    frontend_ports = [{ name = "port" }]
    http_listeners = [{
      name = "listener"
      properties = {
        frontend_port = { frontend_port_key = "child/name" }
      }
    }]
  }

  expect_failures = [azapi_resource.this]

  assert {
    condition = (
      local.child_reference_resolution["http_listeners[0].properties.frontend_port"].status == "invalid_key" &&
      contains(local.invalid_child_reference_key_paths, "http_listeners[0].properties.frontend_port")
    )
    error_message = "Malformed selectors must be classified as invalid_key and reported through invalid_child_reference_key_paths."
  }
}

run "rejects_blank_new_keys" {
  command = plan

  variables {
    frontend_ports = [{ name = "port" }]
    http_listeners = [{
      name = "listener"
      properties = {
        frontend_port = { frontend_port_key = "   " }
      }
    }]
  }

  expect_failures = [azapi_resource.this]
}

run "rejects_path_rule_key_without_scope_key" {
  command = plan

  variables {
    redirect_configurations = [{
      name = "redirect"
      properties = {
        path_rules = [{ path_rule_key = "rule" }]
      }
    }]
  }

  expect_failures = [azapi_resource.this]
}

run "rejects_orphan_path_rule_scope_key" {
  command = plan

  variables {
    redirect_configurations = [{
      name = "redirect"
      properties = {
        path_rules = [{ url_path_map_key = "map" }]
      }
    }]
  }

  expect_failures = [azapi_resource.this]
}

run "rejects_path_rule_id_with_keys" {
  command = plan

  variables {
    redirect_configurations = [{
      name = "redirect"
      properties = {
        path_rules = [{
          id               = "/opaque/legacy-id"
          path_rule_key    = "rule"
          url_path_map_key = "map"
        }]
      }
    }]
  }

  expect_failures = [azapi_resource.this]
}

run "rejects_ambiguous_path_map_scope_key" {
  command = plan

  variables {
    redirect_configurations = [{
      name = "redirect"
      properties = {
        path_rules = [{
          path_rule_key    = "rule"
          url_path_map_key = "map"
        }]
      }
    }]
    url_path_maps = [
      {
        name       = "Map"
        properties = { path_rules = [{ name = "Rule" }] }
      },
      {
        name       = "MAP"
        properties = { path_rules = [{ name = "OtherRule" }] }
      },
    ]
  }

  expect_failures = [azapi_resource.this]
}
