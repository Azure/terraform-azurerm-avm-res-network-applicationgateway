mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-schema/providers/Microsoft.Network/applicationGateways/agw-schema"
    }
  }

  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }

  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = []
      }
    }
  }
}
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

run "empty_private_endpoint_configuration_creates_no_resources" {
  command = apply

  assert {
    condition     = length(var.private_endpoints) == 0 && var.private_endpoints_manage_dns_zone_group
    error_message = "The endpoint map must default to empty and DNS-zone-group management must default to true."
  }

  assert {
    condition = (
      length(azapi_resource.private_endpoints) == 0 &&
      length(module.private_dns_zone_groups) == 0 &&
      length(azapi_resource.private_endpoint_locks) == 0 &&
      length(azapi_resource.private_endpoint_role_assignments) == 0
    )
    error_message = "An empty endpoint configuration must not create endpoint or associated resources."
  }
}

run "creates_private_endpoint_with_dns_lock_and_role_assignment" {
  command = apply

  variables {
    private_link_configurations = [{
      name = "gateway-link"
      ip_configurations = [{
        name                         = "gateway-link-ip"
        private_ip_address           = "10.0.1.10"
        private_ip_allocation_method = "Static"
        subnet = {
          id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-schema/providers/Microsoft.Network/virtualNetworks/vnet/subnets/gateway"
        }
      }]
    }]
    frontend_ip_configurations = [{
      name                  = "public"
      public_ip_address     = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-schema/providers/Microsoft.Network/publicIPAddresses/pip" }
      private_link_configuration = {
        private_link_configuration_key = "gateway-link"
      }
    }]
    private_endpoints = {
      endpoint = {
        name               = "pe-schema"
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-schema/providers/Microsoft.Network/virtualNetworks/vnet/subnets/private-endpoints"
        private_dns_zone_resource_ids = [
          "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-schema/providers/Microsoft.Network/privateDnsZones/privatelink.example.test"
        ]
        tags = {
          environment = "test"
        }
        role_assignments = {
          reader = {
            role_definition_id_or_name = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/00000000-0000-0000-0000-000000000010"
            principal_id               = "00000000-0000-0000-0000-000000000002"
          }
        }
        lock = {
          kind  = "CanNotDelete"
          notes = "Unit test"
        }
        ip_configurations = {
          public = {
            name               = "private-ip"
            private_ip_address = "10.0.2.10"
            member_name        = "public"
          }
        }
      }
    }
  }

  assert {
    condition = (
      azapi_resource.private_endpoints["endpoint"].type == "Microsoft.Network/privateEndpoints@2025-03-01" &&
      azapi_resource.private_endpoints["endpoint"].body.properties.privateLinkServiceConnections[0].properties.privateLinkServiceId == azapi_resource.this.id &&
      azapi_resource.private_endpoints["endpoint"].body.properties.privateLinkServiceConnections[0].properties.groupIds == ["appGateway"] &&
      azapi_resource.private_endpoints["endpoint"].body.properties.subnet.id == var.private_endpoints.endpoint.subnet_resource_id &&
      azapi_resource.private_endpoints["endpoint"].body.properties.ipConfigurations[0].properties.memberName == "public" &&
      azapi_resource.private_endpoints["endpoint"].tags.environment == "test" &&
      output.private_endpoint_ids["endpoint"] == azapi_resource.private_endpoints["endpoint"].id
    )
    error_message = "The endpoint must target the gateway appGateway subresource through the configured frontend and return its ID."
  }

  assert {
    condition = (
      length(module.private_dns_zone_groups) == 1 &&
      module.private_dns_zone_groups["endpoint"].resource_id != null &&
      length(azapi_resource.private_endpoint_locks) == 1 &&
      length(azapi_resource.private_endpoint_role_assignments) == 1
    )
    error_message = "Configured DNS zones, lock, and role assignment must be created with the endpoint."
  }
}

run "dns_zone_group_can_be_managed_externally" {
  command = apply

  variables {
    private_link_configurations = [{
      name = "gateway-link"
      ip_configurations = [{
        name                         = "gateway-link-ip"
        private_ip_address           = "10.0.1.10"
        private_ip_allocation_method = "Static"
        subnet = {
          id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-schema/providers/Microsoft.Network/virtualNetworks/vnet/subnets/gateway"
        }
      }]
    }]
    frontend_ip_configurations = [{
      name                  = "public"
      public_ip_address     = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-schema/providers/Microsoft.Network/publicIPAddresses/pip" }
      private_link_configuration = {
        private_link_configuration_key = "gateway-link"
      }
    }]
    private_endpoints_manage_dns_zone_group = false
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-schema/providers/Microsoft.Network/virtualNetworks/vnet/subnets/private-endpoints"
        private_dns_zone_resource_ids = [
          "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-schema/providers/Microsoft.Network/privateDnsZones/privatelink.example.test"
        ]
      }
    }
  }

  assert {
    condition = (
      length(azapi_resource.private_endpoints) == 1 &&
      length(module.private_dns_zone_groups) == 0 &&
      length(output.private_endpoint_ids) == 1 &&
      length(output.private_endpoint_dns_zone_group_ids) == 0
    )
    error_message = "Disabling DNS-zone-group management must retain endpoint creation while leaving DNS association external."
  }
}

run "endpoint_without_dns_zone_ids_does_not_create_empty_zone_group" {
  command = apply

  variables {
    private_link_configurations = [{
      name = "gateway-link"
      ip_configurations = [{
        name                         = "gateway-link-ip"
        private_ip_address           = "10.0.1.10"
        private_ip_allocation_method = "Static"
        subnet = {
          id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-schema/providers/Microsoft.Network/virtualNetworks/vnet/subnets/gateway"
        }
      }]
    }]
    frontend_ip_configurations = [{
      name                  = "public"
      public_ip_address     = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-schema/providers/Microsoft.Network/publicIPAddresses/pip" }
      private_link_configuration = {
        private_link_configuration_key = "gateway-link"
      }
    }]
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-schema/providers/Microsoft.Network/virtualNetworks/vnet/subnets/private-endpoints"
      }
    }
  }

  assert {
    condition = (
      length(azapi_resource.private_endpoints) == 1 &&
      length(module.private_dns_zone_groups) == 0 &&
      length(output.private_endpoint_dns_zone_group_ids) == 0
    )
    error_message = "A private endpoint without DNS zone IDs must not create an empty DNS zone group."
  }
}

run "rejects_non_application_gateway_subresource" {
  command = apply

  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-schema/providers/Microsoft.Network/virtualNetworks/vnet/subnets/private-endpoints"
        subresource_name   = "unsupported"
      }
    }
  }

  expect_failures = [
    var.private_endpoints,
  ]
}
