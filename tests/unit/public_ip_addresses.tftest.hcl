mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      output = {
        fqdn       = null
        ip_address = "203.0.113.10"
      }
    }
  }
}

# The module still declares AzureRM for its legacy support resources.
mock_provider "azurerm" {}
mock_provider "random" {}
mock_provider "modtm" {}

variables {
  enable_telemetry = false
  location         = "eastus2"
  name             = "agw-unit"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit"
  sku = {
    capacity = 1
    name     = "Standard_v2"
    tier     = "Standard_v2"
  }
}

run "default_creates_no_public_ips" {
  command = apply

  assert {
    condition     = length(azapi_resource.public_ip_addresses) == 0 && length(output.public_ip_addresses) == 0
    error_message = "Omitting public_ip_addresses must create no public IPs and return an empty map."
  }

  assert {
    condition     = azapi_resource.this.body.properties.frontendIPConfigurations == null
    error_message = "The legacy null frontend default must remain null."
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.Network/applicationGateways@2025-03-01"
    error_message = "The default gateway API version must remain unchanged."
  }
}

run "explicit_empty_map_and_frontends" {
  command = apply

  variables {
    public_ip_addresses        = {}
    frontend_ip_configurations = []
  }

  assert {
    condition     = length(output.public_ip_addresses) == 0 && length(azapi_resource.this.body.properties.frontendIPConfigurations) == 0
    error_message = "Explicit empty managed-IP and frontend collections must remain empty."
  }
}

run "external_id_is_unchanged" {
  command = apply

  variables {
    frontend_ip_configurations = [{
      name = "external"
      properties = {
        public_ip_address = {
          id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-external/providers/Microsoft.Network/publicIPAddresses/pip-existing"
        }
      }
    }]
  }

  assert {
    condition     = length(azapi_resource.public_ip_addresses) == 0 && length(output.public_ip_addresses) == 0
    error_message = "A bring-your-own public IP must not create or appear among managed public IPs."
  }

  assert {
    condition = jsonencode(azapi_resource.this.body.properties.frontendIPConfigurations) == jsonencode([{
      name = "external"
      properties = {
        privateIPAddress          = null
        privateIPAllocationMethod = null
        privateLinkConfiguration  = null
        publicIPAddress = {
          id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-external/providers/Microsoft.Network/publicIPAddresses/pip-existing"
        }
        subnet = null
      }
    }])
    error_message = "The entire legacy external frontend ARM object must remain unchanged."
  }
}

run "private_frontend_is_unchanged" {
  command = apply

  variables {
    frontend_ip_configurations = [{
      name = "private"
      properties = {
        private_ip_address           = "10.0.0.10"
        private_ip_allocation_method = "Static"
        subnet = {
          id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/virtualNetworks/vnet-unit/subnets/gateway"
        }
      }
    }]
  }

  assert {
    condition = jsonencode(azapi_resource.this.body.properties.frontendIPConfigurations) == jsonencode([{
      name = "private"
      properties = {
        privateIPAddress          = "10.0.0.10"
        privateIPAllocationMethod = "Static"
        privateLinkConfiguration  = null
        publicIPAddress           = null
        subnet = {
          id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/virtualNetworks/vnet-unit/subnets/gateway"
        }
      }
    }])
    error_message = "Private-only frontend properties must be preserved exactly."
  }

  assert {
    condition     = length(azapi_resource.public_ip_addresses) == 0
    error_message = "A private-only gateway must not allocate a public IP."
  }
}

run "legacy_optional_null_elements_are_preserved" {
  command = apply

  variables {
    frontend_ip_configurations = [
      null,
      {},
      { name = "no-properties" },
      { name = "null-properties", properties = null },
      { properties = { public_ip_address = { id = "legacy-id-not-validated" } } },
    ]
  }

  assert {
    condition = (
      azapi_resource.this.body.properties.frontendIPConfigurations[0] == null &&
      azapi_resource.this.body.properties.frontendIPConfigurations[1].name == null &&
      azapi_resource.this.body.properties.frontendIPConfigurations[1].properties == null &&
      azapi_resource.this.body.properties.frontendIPConfigurations[2].properties == null &&
      azapi_resource.this.body.properties.frontendIPConfigurations[3].properties == null &&
      azapi_resource.this.body.properties.frontendIPConfigurations[4].properties.publicIPAddress.id == "legacy-id-not-validated"
    )
    error_message = "Managed-frontend validation must not tighten legacy null, unnamed, or external-ID inputs."
  }
}

run "managed_ipv4_without_properties" {
  command = apply

  variables {
    public_ip_addresses = {
      edge = { name = "pip-edge" }
    }
    frontend_ip_configurations = [{
      name                  = "public"
      public_ip_address_key = "edge"
    }]
  }

  assert {
    condition = (
      toset(keys(azapi_resource.public_ip_addresses)) == toset(["edge"]) &&
      azapi_resource.public_ip_addresses["edge"].id != "" &&
      azapi_resource.this.body.properties.frontendIPConfigurations[0].properties.publicIPAddress.id == azapi_resource.public_ip_addresses["edge"].id &&
      output.public_ip_addresses["edge"].resource_id == azapi_resource.public_ip_addresses["edge"].id
    )
    error_message = "A properties-free frontend must attach the generated resource ID, not a key or guessed ARM ID."
  }

  assert {
    condition = (
      azapi_resource.public_ip_addresses["edge"].type == "Microsoft.Network/publicIPAddresses@2025-03-01" &&
      azapi_resource.public_ip_addresses["edge"].body.sku.name == "Standard" &&
      azapi_resource.public_ip_addresses["edge"].body.sku.tier == "Regional" &&
      azapi_resource.public_ip_addresses["edge"].body.properties.publicIPAllocationMethod == "Static" &&
      azapi_resource.public_ip_addresses["edge"].body.properties.publicIPAddressVersion == "IPv4" &&
      azapi_resource.public_ip_addresses["edge"].body.properties.idleTimeoutInMinutes == 4
    )
    error_message = "Managed IP defaults must use the approved API, Standard Regional SKU, Static IPv4, and four-minute timeout."
  }

  assert {
    condition = alltrue([
      for path in ["zones", "properties.publicIPAddressVersion", "properties.publicIPPrefix.id"] :
      contains(azapi_resource.public_ip_addresses["edge"].replace_triggers_refs, path)
    ])
    error_message = "Immutable zones, IP version, and prefix changes must be registered as body-relative replacement triggers."
  }

  assert {
    condition = (
      azapi_resource.public_ip_addresses["edge"].parent_id == var.parent_id &&
      azapi_resource.public_ip_addresses["edge"].location == var.location &&
      azapi_resource.public_ip_addresses["edge"].body.zones == null &&
      length(azapi_resource.public_ip_addresses["edge"].tags) == 0 &&
      azapi_resource.public_ip_addresses["edge"].body.properties.publicIPPrefix == null &&
      azapi_resource.public_ip_addresses["edge"].body.properties.dnsSettings == null &&
      length(azapi_resource.public_ip_addresses["edge"].body.properties.ipTags) == 0 &&
      azapi_resource.public_ip_addresses["edge"].body.properties.ddosSettings.protectionMode == "VirtualNetworkInherited" &&
      azapi_resource.public_ip_addresses["edge"].body.properties.ddosSettings.ddosProtectionPlan == null
    )
    error_message = "Optional settings must remain absent, with null gateway zones and tags handled safely."
  }

  assert {
    condition = (
      output.public_ip_addresses["edge"].ip_address == "203.0.113.10" &&
      output.public_ip_addresses["edge"].fqdn == null &&
      azapi_resource.public_ip_addresses["edge"].response_export_values.ip_address == "properties.ipAddress" &&
      azapi_resource.public_ip_addresses["edge"].response_export_values.fqdn == "properties.dnsSettings.fqdn"
    )
    error_message = "Outputs must consume explicitly exported Azure response paths; a mocked response alone is not evidence of correct exports."
  }

  assert {
    condition     = !strcontains(jsonencode(azapi_resource.this.body), "public_ip_address_key")
    error_message = "The Terraform-only public_ip_address_key helper must never leak into the ARM body."
  }

  assert {
    condition = (
      azapi_resource.this.retry == null &&
      azapi_resource.public_ip_addresses["edge"].retry == null &&
      length(var.ignore_body_changes.network_application_gateways) == 0 &&
      length(var.ignore_body_changes.network_public_ip_addresses) == 0 &&
      var.timeouts == null
    )
    error_message = "Optional AzAPI controls must preserve provider defaults unless configured."
  }
}

run "managed_frontend_with_empty_properties" {
  command = apply

  variables {
    location = "East US 2"
    public_ip_addresses = {
      edge = { name = "pip-edge" }
    }
    frontend_ip_configurations = [{
      name                  = "public"
      public_ip_address_key = "edge"
      properties            = {}
    }]
  }

  assert {
    condition = (
      azapi_resource.this.body.properties.frontendIPConfigurations[0].properties.publicIPAddress.id == azapi_resource.public_ip_addresses["edge"].id &&
      azapi_resource.this.body.properties.frontendIPConfigurations[0].properties.privateIPAddress == null &&
      azapi_resource.this.body.properties.frontendIPConfigurations[0].properties.subnet == null &&
      azapi_resource.public_ip_addresses["edge"].replace_triggers_external_values.location == "eastus2"
    )
    error_message = "An empty properties object must accept the managed ID, and the location replacement trigger must normalize case and spaces."
  }
}

run "managed_and_external_frontends" {
  command = apply

  variables {
    public_ip_addresses = {
      edge = { name = "pip-edge" }
    }
    frontend_ip_configurations = [
      {
        name                  = "managed"
        public_ip_address_key = "edge"
        properties = {
          private_link_configuration = {
            id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/applicationGateways/agw-unit/privateLinkConfigurations/link"
          }
        }
      },
      {
        name = "external"
        properties = {
          public_ip_address = {
            id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-external/providers/Microsoft.Network/publicIPAddresses/pip-existing-v6"
          }
        }
      },
      null,
    ]
  }

  assert {
    condition = (
      toset(keys(output.public_ip_addresses)) == toset(["edge"]) &&
      azapi_resource.this.body.properties.frontendIPConfigurations[0].properties.publicIPAddress.id == azapi_resource.public_ip_addresses["edge"].id &&
      azapi_resource.this.body.properties.frontendIPConfigurations[0].properties.privateLinkConfiguration.id == var.frontend_ip_configurations[0].properties.private_link_configuration.id &&
      azapi_resource.this.body.properties.frontendIPConfigurations[1].properties.publicIPAddress.id == var.frontend_ip_configurations[1].properties.public_ip_address.id &&
      azapi_resource.this.body.properties.frontendIPConfigurations[2] == null
    )
    error_message = "Managed attachment must preserve other frontend properties, external IDs, and null elements."
  }
}

run "dual_stack_uses_stable_keys" {
  command = apply

  variables {
    public_ip_addresses = {
      ipv4 = { name = "pip-v4" }
      ipv6 = { name = "pip-v6", ip_version = "IPv6" }
    }
    frontend_ip_configurations = [
      { name = "public-v4", public_ip_address_key = "ipv4" },
      { name = "public-v6", public_ip_address_key = "ipv6" },
    ]
  }

  assert {
    condition = (
      toset(keys(azapi_resource.public_ip_addresses)) == toset(["ipv4", "ipv6"]) &&
      toset(keys(output.public_ip_addresses)) == toset(["ipv4", "ipv6"]) &&
      azapi_resource.public_ip_addresses["ipv4"].body.properties.publicIPAddressVersion == "IPv4" &&
      azapi_resource.public_ip_addresses["ipv6"].body.properties.publicIPAddressVersion == "IPv6" &&
      azapi_resource.this.body.properties.frontendIPConfigurations[0].properties.publicIPAddress.id == azapi_resource.public_ip_addresses["ipv4"].id &&
      azapi_resource.this.body.properties.frontendIPConfigurations[1].properties.publicIPAddress.id == azapi_resource.public_ip_addresses["ipv6"].id
    )
    error_message = "Dual-stack resources and frontends must resolve independently by their caller-supplied map keys."
  }
}

run "reordering_frontends_retains_public_ip_identity" {
  command = apply

  variables {
    public_ip_addresses = {
      ipv6 = { name = "pip-v6", ip_version = "IPv6" }
      ipv4 = { name = "pip-v4" }
    }
    frontend_ip_configurations = [
      { name = "public-v6", public_ip_address_key = "ipv6" },
      { name = "public-v4", public_ip_address_key = "ipv4" },
    ]
  }

  assert {
    condition = (
      toset(keys(azapi_resource.public_ip_addresses)) == toset(["ipv4", "ipv6"]) &&
      output.public_ip_addresses == run.dual_stack_uses_stable_keys.public_ip_addresses &&
      azapi_resource.this.body.properties.frontendIPConfigurations[0].properties.publicIPAddress.id == azapi_resource.public_ip_addresses["ipv6"].id &&
      azapi_resource.this.body.properties.frontendIPConfigurations[1].properties.publicIPAddress.id == azapi_resource.public_ip_addresses["ipv4"].id
    )
    error_message = "Reordering frontend lists or input-map declarations must not change managed resource addresses or IDs."
  }
}

run "same_public_ip_name_in_different_resource_groups_is_valid" {
  command = apply

  variables {
    public_ip_addresses = {
      ipv4 = { name = "pip-shared-name" }
      ipv6 = {
        name       = "pip-shared-name"
        ip_version = "IPv6"
        parent_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-other"
      }
    }
  }

  assert {
    condition = (
      length(azapi_resource.public_ip_addresses) == 2 &&
      azapi_resource.public_ip_addresses["ipv4"].name == azapi_resource.public_ip_addresses["ipv6"].name &&
      azapi_resource.public_ip_addresses["ipv4"].parent_id != azapi_resource.public_ip_addresses["ipv6"].parent_id
    )
    error_message = "Azure name uniqueness must be scoped to the resource group, not enforced globally across managed IPs."
  }
}

run "inherits_tags_and_gateway_zones" {
  command = apply

  variables {
    tags  = { environment = "unit", owner = "gateway" }
    zones = ["3", "1", "2"]
    public_ip_addresses = {
      edge = { name = "pip-edge" }
    }
  }

  assert {
    condition = (
      azapi_resource.public_ip_addresses["edge"].tags == var.tags &&
      toset(azapi_resource.public_ip_addresses["edge"].body.zones) == toset(var.zones) &&
      azapi_resource.public_ip_addresses["edge"].parent_id == var.parent_id &&
      azapi_resource.public_ip_addresses["edge"].location == var.location
    )
    error_message = "Managed IPs must inherit location, resource-group parent, tags, and the gateway zone set."
  }
}

run "explicit_empty_zones_override_gateway_zones" {
  command = apply

  variables {
    zones = ["1", "2", "3"]
    public_ip_addresses = {
      edge = { name = "pip-edge", zones = [] }
    }
  }

  assert {
    condition     = length(azapi_resource.public_ip_addresses["edge"].body.zones) == 0
    error_message = "Explicit empty zones must not fall back to nonempty gateway zones."
  }
}

run "empty_gateway_zones_are_inherited" {
  command = apply

  variables {
    zones = []
    public_ip_addresses = {
      edge = { name = "pip-edge" }
    }
  }

  assert {
    condition     = length(azapi_resource.public_ip_addresses["edge"].body.zones) == 0
    error_message = "An empty gateway zone list must remain an empty list when inherited."
  }
}

run "advanced_public_ip_mapping" {
  command   = apply
  state_key = "advanced_public_ip_mapping"

  variables {
    location = "westus2"
    tags     = { environment = "unit", owner = "gateway" }
    zones    = ["2"]
    public_ip_addresses = {
      edge = {
        name                             = "pip-advanced"
        parent_id                        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-public"
        tags                             = { owner = "public-ip", purpose = "frontend" }
        zones                            = ["3", "2", "1"]
        public_ip_prefix_resource_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-public/providers/Microsoft.Network/publicIPPrefixes/prefix"
        ddos_protection_mode             = "Enabled"
        ddos_protection_plan_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-public/providers/Microsoft.Network/ddosProtectionPlans/plan"
        domain_name_label                = "avm-unit"
        reverse_fqdn                     = "avm-unit.westus2.cloudapp.azure.com."
        idle_timeout_in_minutes          = 30
        ip_tags                          = { RoutingPreference = "Internet" }
      }
    }
  }

  override_resource {
    target = azapi_resource.public_ip_addresses["edge"]
    values = {
      output = {
        ip_address = "203.0.113.30"
        fqdn       = "avm-unit.westus2.cloudapp.azure.com"
      }
    }
  }

  assert {
    condition = (
      azapi_resource.public_ip_addresses["edge"].parent_id == var.public_ip_addresses["edge"].parent_id &&
      azapi_resource.public_ip_addresses["edge"].location == "westus2" &&
      azapi_resource.public_ip_addresses["edge"].tags == tomap({ environment = "unit", owner = "public-ip", purpose = "frontend" }) &&
      toset(azapi_resource.public_ip_addresses["edge"].body.zones) == toset(["1", "2", "3"])
    )
    error_message = "Per-IP parent, tag precedence, and a gateway-zone superset must be honored without changing location inheritance."
  }

  assert {
    condition = (
      azapi_resource.public_ip_addresses["edge"].body.properties.publicIPPrefix.id == var.public_ip_addresses["edge"].public_ip_prefix_resource_id &&
      azapi_resource.public_ip_addresses["edge"].body.properties.ddosSettings.protectionMode == "Enabled" &&
      azapi_resource.public_ip_addresses["edge"].body.properties.ddosSettings.ddosProtectionPlan.id == var.public_ip_addresses["edge"].ddos_protection_plan_resource_id &&
      azapi_resource.public_ip_addresses["edge"].body.properties.dnsSettings.domainNameLabel == "avm-unit" &&
      azapi_resource.public_ip_addresses["edge"].body.properties.dnsSettings.reverseFqdn == "avm-unit.westus2.cloudapp.azure.com." &&
      azapi_resource.public_ip_addresses["edge"].body.properties.idleTimeoutInMinutes == 30 &&
      jsonencode(azapi_resource.public_ip_addresses["edge"].body.properties.ipTags) == jsonencode([{ ipTagType = "RoutingPreference", tag = "Internet" }])
    )
    error_message = "Prefix, DDoS, DNS, idle timeout, and IP tags must use the public-IP ARM schema."
  }

  assert {
    condition = (
      output.public_ip_addresses["edge"].ip_address == "203.0.113.30" &&
      output.public_ip_addresses["edge"].fqdn == "avm-unit.westus2.cloudapp.azure.com" &&
      output.public_ip_addresses["edge"].resource_id == azapi_resource.public_ip_addresses["edge"].id
    )
    error_message = "Managed outputs must expose the Azure-generated address, FQDN, and actual resource ID."
  }
}

run "individual_ddos_protection_without_plan_is_valid" {
  command = apply

  variables {
    public_ip_addresses = {
      edge = { name = "pip-edge", ddos_protection_mode = "Enabled" }
    }
  }

  assert {
    condition = (
      azapi_resource.public_ip_addresses["edge"].body.properties.ddosSettings.protectionMode == "Enabled" &&
      azapi_resource.public_ip_addresses["edge"].body.properties.ddosSettings.ddosProtectionPlan == null
    )
    error_message = "Enabled without a plan is valid individual IP protection and must not be rejected."
  }
}

run "disabled_ddos_and_reverse_only_dns_are_valid" {
  command = apply

  variables {
    public_ip_addresses = {
      edge = {
        name                 = "pip-edge"
        ddos_protection_mode = "Disabled"
        reverse_fqdn         = "existing.example.com."
      }
    }
  }

  assert {
    condition = (
      azapi_resource.public_ip_addresses["edge"].body.properties.ddosSettings.protectionMode == "Disabled" &&
      azapi_resource.public_ip_addresses["edge"].body.properties.dnsSettings.domainNameLabel == null &&
      azapi_resource.public_ip_addresses["edge"].body.properties.dnsSettings.reverseFqdn == "existing.example.com."
    )
    error_message = "Disabled DDoS and IPv4 reverse-only DNS must map independently without requiring a domain label."
  }
}

run "custom_azapi_controls_propagate" {
  command = apply

  variables {
    public_ip_addresses = {
      edge = { name = "pip-edge" }
    }
    resource_types = {
      network_application_gateways = "Microsoft.Network/applicationGateways@2025-05-01"
      network_public_ip_addresses  = "Microsoft.Network/publicIPAddresses@2024-05-01"
    }
    retry = {
      error_message_regex  = ["AnotherOperationInProgress"]
      interval_seconds     = 5
      max_interval_seconds = 30
    }
    timeouts = {
      create = "90m"
      read   = "5m"
      update = "80m"
      delete = "90m"
    }
    ignore_body_changes = {
      network_application_gateways = ["properties.enableHttp2"]
      network_public_ip_addresses  = ["properties.idleTimeoutInMinutes"]
    }
  }

  assert {
    condition = (
      azapi_resource.this.type == var.resource_types.network_application_gateways &&
      azapi_resource.public_ip_addresses["edge"].type == var.resource_types.network_public_ip_addresses &&
      azapi_resource.this.retry.error_message_regex == var.retry.error_message_regex &&
      azapi_resource.public_ip_addresses["edge"].retry.error_message_regex == var.retry.error_message_regex &&
      azapi_resource.this.retry.interval_seconds == 5 &&
      azapi_resource.public_ip_addresses["edge"].retry.interval_seconds == 5 &&
      azapi_resource.this.retry.max_interval_seconds == 30 &&
      azapi_resource.public_ip_addresses["edge"].retry.max_interval_seconds == 30
    )
    error_message = "Resource-type and retry overrides must reach both the gateway and managed public IP."
  }

  assert {
    condition = alltrue([
      for timeouts in [azapi_resource.this.timeouts, azapi_resource.public_ip_addresses["edge"].timeouts] :
      timeouts.create == "90m" && timeouts.read == "5m" && timeouts.update == "80m" && timeouts.delete == "90m"
    ])
    error_message = "Every configured operation timeout must reach both AzAPI resources."
  }

  # ignore_body_changes is write-only, so it cannot be read back from resource state.
  assert {
    condition = (
      var.ignore_body_changes.network_application_gateways == tolist(["properties.enableHttp2"]) &&
      var.ignore_body_changes.network_public_ip_addresses == tolist(["properties.idleTimeoutInMinutes"]) &&
      azapi_resource.public_ip_addresses["edge"].body.properties.idleTimeoutInMinutes == 4 &&
      output.public_ip_addresses["edge"].resource_id == azapi_resource.public_ip_addresses["edge"].id
    )
    error_message = "Custom ignore paths must be accepted without destroying the configured body or managed outputs."
  }
}

run "partial_azapi_controls_keep_other_defaults" {
  command = apply

  variables {
    public_ip_addresses = {
      edge = { name = "pip-edge" }
    }
    resource_types = {
      network_public_ip_addresses = "Microsoft.Network/publicIPAddresses@2024-05-01"
    }
    timeouts = { create = "75m" }
    ignore_body_changes = {
      network_public_ip_addresses = ["properties.idleTimeoutInMinutes"]
    }
  }

  assert {
    condition = (
      azapi_resource.this.type == "Microsoft.Network/applicationGateways@2025-03-01" &&
      azapi_resource.public_ip_addresses["edge"].type == "Microsoft.Network/publicIPAddresses@2024-05-01" &&
      length(var.ignore_body_changes.network_application_gateways) == 0 &&
      azapi_resource.this.timeouts.create == "75m" &&
      azapi_resource.public_ip_addresses["edge"].timeouts.create == "75m"
    )
    error_message = "Partial control objects must retain defaults for the gateway and omitted fields."
  }
}

run "unknown_values_do_not_determine_resource_keys" {
  # This intentional plan-only regression leaves upstream IDs and names unknown.
  command = plan

  module {
    source = "./tests/unit/fixtures/unknown_values"
  }

  assert {
    condition     = toset(output.public_ip_keys) == toset(["edge"])
    error_message = "A computed resource-group ID and generated IP name must not make managed for_each keys unknown."
  }
}

# Invalid inputs stop planning before a mocked apply can run.
run "rejects_null_entry" {
  command = plan
  variables {
    public_ip_addresses = { edge = null }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_empty_name" {
  command = plan
  variables {
    public_ip_addresses = { edge = { name = "" } }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_null_name" {
  command = plan
  variables {
    public_ip_addresses = { edge = { name = null } }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_name_with_invalid_characters" {
  command = plan
  variables {
    public_ip_addresses = { edge = { name = "invalid name!" } }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_name_with_trailing_hyphen" {
  command = plan
  variables {
    public_ip_addresses = { edge = { name = "pip-invalid-" } }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_name_longer_than_eighty_characters" {
  command = plan
  variables {
    public_ip_addresses = { edge = { name = join("", [for index in range(81) : "a"]) } }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_invalid_ip_version" {
  command = plan
  variables {
    public_ip_addresses = { edge = { name = "pip-edge", ip_version = "ipv4" } }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_duplicate_ipv4" {
  command = plan
  variables {
    public_ip_addresses = {
      first  = { name = "pip-first" }
      second = { name = "pip-second" }
    }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_duplicate_ipv6" {
  command = plan
  variables {
    public_ip_addresses = {
      first  = { name = "pip-first", ip_version = "IPv6" }
      second = { name = "pip-second", ip_version = "IPv6" }
    }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_duplicate_azure_identity" {
  command = plan
  variables {
    public_ip_addresses = {
      ipv4 = { name = "pip-same" }
      ipv6 = { name = "PIP-SAME", ip_version = "IPv6" }
    }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_malformed_parent" {
  command = plan
  variables {
    public_ip_addresses = { edge = { name = "pip-edge", parent_id = "rg-not-an-arm-id" } }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_parent_of_wrong_resource_type" {
  command = plan
  variables {
    public_ip_addresses = {
      edge = {
        name      = "pip-edge"
        parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/virtualNetworks/vnet-unit"
      }
    }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_malformed_prefix_id" {
  command = plan
  variables {
    public_ip_addresses = { edge = { name = "pip-edge", public_ip_prefix_resource_id = "prefix-not-an-arm-id" } }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_prefix_of_wrong_resource_type" {
  command = plan
  variables {
    public_ip_addresses = {
      edge = {
        name                         = "pip-edge"
        public_ip_prefix_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/publicIPAddresses/not-a-prefix"
      }
    }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_malformed_ddos_plan_id" {
  command = plan
  variables {
    public_ip_addresses = {
      edge = {
        name                             = "pip-edge"
        ddos_protection_mode             = "Enabled"
        ddos_protection_plan_resource_id = "plan-not-an-arm-id"
      }
    }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_ddos_plan_of_wrong_resource_type" {
  command = plan
  variables {
    public_ip_addresses = {
      edge = {
        name                             = "pip-edge"
        ddos_protection_mode             = "Enabled"
        ddos_protection_plan_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/publicIPPrefixes/not-a-plan"
      }
    }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_invalid_ddos_mode" {
  command = plan
  variables {
    public_ip_addresses = { edge = { name = "pip-edge", ddos_protection_mode = "Automatic" } }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_ddos_plan_with_inherited_mode" {
  command = plan
  variables {
    public_ip_addresses = {
      edge = {
        name                             = "pip-edge"
        ddos_protection_plan_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/ddosProtectionPlans/plan"
      }
    }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_ddos_plan_with_disabled_mode" {
  command = plan
  variables {
    public_ip_addresses = {
      edge = {
        name                             = "pip-edge"
        ddos_protection_mode             = "Disabled"
        ddos_protection_plan_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/ddosProtectionPlans/plan"
      }
    }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_idle_timeout_below_minimum" {
  command = plan
  variables {
    public_ip_addresses = { edge = { name = "pip-edge", idle_timeout_in_minutes = 3 } }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_idle_timeout_above_maximum" {
  command = plan
  variables {
    public_ip_addresses = { edge = { name = "pip-edge", idle_timeout_in_minutes = 31 } }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_fractional_idle_timeout" {
  command = plan
  variables {
    public_ip_addresses = { edge = { name = "pip-edge", idle_timeout_in_minutes = 4.5 } }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_invalid_zone" {
  command = plan
  variables {
    public_ip_addresses = { edge = { name = "pip-edge", zones = ["4"] } }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_duplicate_zones" {
  command = plan
  variables {
    public_ip_addresses = { edge = { name = "pip-edge", zones = ["1", "1"] } }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_null_zone" {
  command = plan
  variables {
    public_ip_addresses = { edge = { name = "pip-edge", zones = [null] } }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_zones_missing_gateway_zone" {
  command = plan
  variables {
    zones               = ["1", "2", "3"]
    public_ip_addresses = { edge = { name = "pip-edge", zones = ["1", "2"] } }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_reverse_fqdn_for_ipv6" {
  command = plan
  variables {
    public_ip_addresses = { edge = { name = "pip-edge", ip_version = "IPv6", reverse_fqdn = "example.com." } }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_empty_ip_tag" {
  command = plan
  variables {
    public_ip_addresses = { edge = { name = "pip-edge", ip_tags = { RoutingPreference = "" } } }
  }
  expect_failures = [var.public_ip_addresses]
}

run "rejects_missing_managed_key" {
  command = plan
  variables {
    frontend_ip_configurations = [{ name = "public", public_ip_address_key = "missing" }]
  }
  expect_failures = [var.frontend_ip_configurations]
}

run "rejects_managed_key_with_external_id" {
  command = plan
  variables {
    public_ip_addresses = { edge = { name = "pip-edge" } }
    frontend_ip_configurations = [{
      name                  = "public"
      public_ip_address_key = "edge"
      properties = {
        public_ip_address = {
          id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/publicIPAddresses/external"
        }
      }
    }]
  }
  expect_failures = [var.frontend_ip_configurations]
}

run "rejects_managed_key_with_private_address" {
  command = plan
  variables {
    public_ip_addresses = { edge = { name = "pip-edge" } }
    frontend_ip_configurations = [{
      name                  = "public"
      public_ip_address_key = "edge"
      properties            = { private_ip_address = "10.0.0.10" }
    }]
  }
  expect_failures = [var.frontend_ip_configurations]
}

run "rejects_managed_key_with_private_allocation" {
  command = plan
  variables {
    public_ip_addresses = { edge = { name = "pip-edge" } }
    frontend_ip_configurations = [{
      name                  = "public"
      public_ip_address_key = "edge"
      properties            = { private_ip_allocation_method = "Dynamic" }
    }]
  }
  expect_failures = [var.frontend_ip_configurations]
}

run "rejects_managed_key_with_subnet" {
  command = plan
  variables {
    public_ip_addresses = { edge = { name = "pip-edge" } }
    frontend_ip_configurations = [{
      name                  = "public"
      public_ip_address_key = "edge"
      properties = {
        subnet = {
          id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/virtualNetworks/vnet-unit/subnets/gateway"
        }
      }
    }]
  }
  expect_failures = [var.frontend_ip_configurations]
}

run "rejects_managed_frontend_without_name" {
  command = plan
  variables {
    public_ip_addresses        = { edge = { name = "pip-edge" } }
    frontend_ip_configurations = [{ public_ip_address_key = "edge" }]
  }
  expect_failures = [var.frontend_ip_configurations]
}

run "rejects_managed_frontend_with_blank_name" {
  command = plan
  variables {
    public_ip_addresses        = { edge = { name = "pip-edge" } }
    frontend_ip_configurations = [{ name = "  ", public_ip_address_key = "edge" }]
  }
  expect_failures = [var.frontend_ip_configurations]
}

run "rejects_duplicate_managed_binding" {
  command = plan
  variables {
    public_ip_addresses = { edge = { name = "pip-edge" } }
    frontend_ip_configurations = [
      { name = "first", public_ip_address_key = "edge" },
      { name = "second", public_ip_address_key = "edge" },
    ]
  }
  expect_failures = [var.frontend_ip_configurations]
}

run "rejects_ignore_path_with_list_index" {
  command = plan
  variables {
    ignore_body_changes = { network_application_gateways = ["properties.frontendIPConfigurations[0]"] }
  }
  expect_failures = [var.ignore_body_changes]
}

run "rejects_empty_ignore_path" {
  command = plan
  variables {
    ignore_body_changes = { network_public_ip_addresses = [""] }
  }
  expect_failures = [var.ignore_body_changes]
}
