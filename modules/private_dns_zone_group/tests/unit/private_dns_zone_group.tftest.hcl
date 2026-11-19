mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/privateEndpoints/pe-test/privateDnsZoneGroups/default"
    }
  }
}

run "creates_private_dns_zone_group" {
  command = apply

  variables {
    name      = "default"
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/privateEndpoints/pe-test"
    body = {
      properties = {
        privateDnsZoneConfigs = [{
          name = "zone"
          properties = {
            privateDnsZoneId = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/privateDnsZones/privatelink.example.test"
          }
        }]
      }
    }
  }

  assert {
    condition = (
      azapi_resource.this.parent_id == var.parent_id &&
      azapi_resource.this.body.properties.privateDnsZoneConfigs[0].properties.privateDnsZoneId == var.body.properties.privateDnsZoneConfigs[0].properties.privateDnsZoneId &&
      output.resource_id != null
    )
    error_message = "The submodule must create the DNS zone group under the supplied private endpoint and return its resource ID."
  }
}
