mock_provider "azapi" {}
mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  enable_telemetry = false
  location         = "eastus2"
  name             = "agw-schema"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-schema"
  sku = {
    capacity = 1
    name     = "Standard_v2"
    tier     = "Standard_v2"
  }
}

# Schema compatibility only; these runs do not claim endpoint creation support (#284).
run "default_private_endpoint_schema_is_compatible" {
  command = apply

  assert {
    condition     = length(var.private_endpoints) == 0 && var.private_endpoints_manage_dns_zone_group
    error_message = "The endpoint map must default to empty and the standard DNS toggle must default to true."
  }
}

run "retains_current_optional_schema_fields" {
  command = apply

  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-schema/providers/Microsoft.Network/virtualNetworks/vnet/subnets/private-endpoints"
        subresource_name   = "PublicFrontend"
        role_assignments = {
          reader = {
            name                       = "00000000-0000-0000-0000-000000000001"
            principal_id               = "00000000-0000-0000-0000-000000000002"
            role_definition_id_or_name = "Reader"
          }
        }
        lock = {
          kind  = "CanNotDelete"
          notes = "Schema compatibility"
        }
        ip_configurations = {
          primary = {
            name               = "private-ip"
            private_ip_address = "10.0.0.10"
            member_name        = "PublicFrontend"
          }
        }
      }
    }
  }

  assert {
    condition = (
      var.private_endpoints.endpoint.subresource_name == "PublicFrontend" &&
      var.private_endpoints.endpoint.role_assignments.reader.name == "00000000-0000-0000-0000-000000000001" &&
      var.private_endpoints.endpoint.lock.notes == "Schema compatibility" &&
      var.private_endpoints.endpoint.ip_configurations.primary.member_name == "PublicFrontend"
    )
    error_message = "Terraform must retain the optional standard-interface fields rather than discard them during type conversion."
  }

  assert {
    condition = (
      length(azurerm_management_lock.this) == 0 &&
      length(azurerm_role_assignment.this) == 0 &&
      length(azurerm_monitor_diagnostic_setting.this) == 0 &&
      azapi_resource.this.body.properties.privateLinkConfigurations == null
    )
    error_message = "This schema-only change must not alter existing deployment behavior or confuse endpoints with gateway-side Private Link configuration."
  }
}

run "accepts_dns_zone_group_toggle_false" {
  command = apply

  variables {
    private_endpoints_manage_dns_zone_group = false
  }

  assert {
    condition     = !var.private_endpoints_manage_dns_zone_group
    error_message = "Consumers must be able to set the standard DNS-zone-group control to false."
  }
}
