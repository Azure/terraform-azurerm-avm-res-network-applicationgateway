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

run "rejects_id_and_name_together" {
  command = plan

  variables {
    frontend_ports = [{ name = "port" }]
    http_listeners = [{
      name = "listener"
      properties = {
        frontend_port = {
          id   = "/opaque/legacy-id"
          name = "port"
        }
      }
    }]
  }

  expect_failures = [azapi_resource.this]
}

run "rejects_missing_named_target" {
  command = plan

  variables {
    http_listeners = [{
      name = "listener"
      properties = {
        frontend_port = { name = "missing" }
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
        frontend_port = { name = "port" }
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
    error_message = "Duplicate declaration names should be validated only when a named reference targets them."
  }
}

run "rejects_malformed_new_names" {
  command = plan

  variables {
    frontend_ports = [{ name = "port" }]
    http_listeners = [{
      name = "listener"
      properties = {
        frontend_port = { name = "child/name" }
      }
    }]
  }

  expect_failures = [azapi_resource.this]
}

run "rejects_blank_new_names" {
  command = plan

  variables {
    frontend_ports = [{ name = "port" }]
    http_listeners = [{
      name = "listener"
      properties = {
        frontend_port = { name = "   " }
      }
    }]
  }

  expect_failures = [azapi_resource.this]
}

run "rejects_path_rule_name_without_scope" {
  command = plan

  variables {
    redirect_configurations = [{
      name = "redirect"
      properties = {
        path_rules = [{ name = "rule" }]
      }
    }]
  }

  expect_failures = [azapi_resource.this]
}

run "rejects_orphan_path_rule_scope" {
  command = plan

  variables {
    redirect_configurations = [{
      name = "redirect"
      properties = {
        path_rules = [{ url_path_map_name = "map" }]
      }
    }]
  }

  expect_failures = [azapi_resource.this]
}

run "rejects_path_rule_id_with_new_scope" {
  command = plan

  variables {
    redirect_configurations = [{
      name = "redirect"
      properties = {
        path_rules = [{
          id                = "/opaque/legacy-id"
          name              = "rule"
          url_path_map_name = "map"
        }]
      }
    }]
  }

  expect_failures = [azapi_resource.this]
}

run "rejects_ambiguous_path_map_scope" {
  command = plan

  variables {
    redirect_configurations = [{
      name = "redirect"
      properties = {
        path_rules = [{
          name              = "rule"
          url_path_map_name = "map"
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
