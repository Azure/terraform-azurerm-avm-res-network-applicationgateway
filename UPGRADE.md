# Upgrading the Application Gateway module

## Flat component inputs (breaking change)

The consumer-facing `properties` envelopes have been removed from gateway
component definitions. Move each envelope's contents directly beside the
component's `name` and any other existing definition fields. There is no
transition mode accepting the old wrapped shape.

```hcl
# Before: wrapped AzAPI-based input
backend_http_settings_collection = [
  {
    name = "backend-http"
    properties = {
      port                  = 80
      protocol              = "Http"
      cookie_based_affinity = "Disabled"
      probe                 = { probe_key = "health" }
    }
  }
]

# After: flat component input
backend_http_settings_collection = [
  {
    name                  = "backend-http"
    port                  = 80
    protocol              = "Http"
    cookie_based_affinity = "Disabled"
    probe                 = { probe_key = "health" }
  }
]
```

The `health` probe must still be declared in `probes`. Its fields also move
beside its `name`; the nested `probe = { probe_key = ... }` reference does not
change.

### Locations to migrate

Apply the same change to every component collection that previously exposed
a `properties` object, including pools, HTTP/TCP settings, listeners, ports,
gateway/frontend IP configurations, probes, certificates, SSL profiles,
JWT configurations, routing/redirect rules, rewrite sets, load-distribution
policies, Private Link configurations and URL path maps.

Three nested definition collections need their own envelopes removed as well:

| Previous consumer path | New consumer path |
| --- | --- |
| `load_distribution_policies[*].properties.load_distribution_targets[*].properties.backend_address_pool` | `load_distribution_policies[*].load_distribution_targets[*].backend_address_pool` |
| `private_link_configurations[*].properties.ip_configurations[*].properties.subnet` | `private_link_configurations[*].ip_configurations[*].subnet` |
| `url_path_maps[*].properties.path_rules[*].properties.backend_http_settings` | `url_path_maps[*].path_rules[*].backend_http_settings` |

For example, a current path-map definition can look like:

```hcl
url_path_maps = [
  {
    name                          = "routes"
    default_backend_address_pool  = { backend_address_pool_key = "application" }
    default_backend_http_settings = { backend_http_settings_key = "http" }
    path_rules = [
      {
        name                  = "api"
        paths                 = ["/api/*"]
        backend_address_pool  = { backend_address_pool_key = "application" }
        backend_http_settings = { backend_http_settings_key = "http" }
      }
    ]
  }
]
```

The referenced pool and settings must be defined in their corresponding
collections. Keep meaningful nested objects such as `connection_draining`,
`ssl_policy`, `client_auth_configuration`, `backend_addresses`, reference objects
and rewrite-rule action sets. Only the literal resource `properties` envelopes
are removed.

### Legacy-wrapper errors

Do not leave `properties = {}` behind after moving its fields. Non-null legacy
wrappers, including empty objects or a mixture of wrapped and flat fields,
are rejected with an error identifying the affected input path.

Generated type declarations retain an empty `properties` attribute solely as a
migration guard. Terraform normally discards unknown object attributes; without
this guard, an old configuration could silently lose its settings. This
attribute is not a compatibility wrapper, and its contents are never used.
An explicit `properties = null` has no contents and is treated as omitted;
remove it when updating the configuration.

### Values, state and release impact

Keep names, IDs, typed reference keys and all field values unchanged while moving
them. Explicit `false`, `0`, empty lists and empty maps remain values, not
omissions. Name-only definitions with no non-null settings omit their optional
ARM properties; use an explicit collection value when you intend to configure
or clear that collection.

The module builds the required ARM envelopes internally. Flattening alone
does not change provider/resource types or Terraform addresses, so it does not
require `terraform state rm`, `terraform state mv`, or import. Review the plan
and stop if it proposes unexpected changes or replacements. The state commands
later in this guide are for an older provider/ownership migration, not this
input-shape change.

This is a breaking consumer-interface change. While the module is pre-1.0,
it must be released with a minor-version increment, not a patch release, under
[AVM SNFR17](https://azure.github.io/Azure-Verified-Modules/spec/SNFR17/).
Keep an explicit module version pin until your configuration is migrated.

## Earlier AzureRM-to-AzAPI migration

This module has been rewritten to use the AzAPI provider instead of the
azurerm provider for the core `azurerm_application_gateway` resource.
The AzAPI provider talks directly to the Azure ARM API, giving day-zero
support for new features, a 1:1 mapping with the ARM schema, and
`list_unique_id_property` support for clean plans on shared gateways.
The azurerm provider is still used for locks, role assignments, and
diagnostic settings.

## Breaking changes summary

- **`resource_group_name` removed**: replaced by `parent_id`, which
  takes the full ARM resource ID of the parent resource group.
- **Variable shape**: component maps changed to lists. Early AzAPI-based
  versions added `properties` wrappers; the current interface uses flat
  component fields as described above.
- **Cross-references**: legacy fields such as `probe_name` become reference
  objects. Use `probe = { probe_key = "my-probe" }` for a probe declared in this
  module, or retain `probe = { id = "..." }`. Earlier AzAPI-based releases
  required the ID form; it remains supported.
- **Public IP**: `v0.5.3` removed management. Optional management is now
  available through the default-empty `public_ip_addresses` map. Existing
  external IP inputs remain supported. Migrating the old managed IP still
  requires an explicit ownership transfer; see
  [Public IP ownership migration](#public-ip-ownership-migration).
- **Terraform**: `>= 1.12` required.
- **AzAPI provider**: `~> 2.12` required.
- **azurerm provider**: `>= 3.117, < 5.0` required.
- **Zones**: changed from `set(number)` to `list(string)`.
- **Autoscale + SKU capacity**: when `autoscale_configuration` is set,
  omit `sku.capacity`. The ARM API now rejects `capacity = 0` for v2
  SKUs.

## Variable mapping

| Old variable (azurerm module) | New variable (AzAPI module) | Notes |
|---|---|---|
| `resource_group_name` | `parent_id` | Full ARM resource ID of the resource group |
| `location` | `location` | Unchanged |
| `name` | `name` | Unchanged |
| `tags` | `tags` | Unchanged |
| `enable_telemetry` | `enable_telemetry` | Unchanged |
| `lock` | `lock` | Unchanged |
| `role_assignments` | `role_assignments` | Unchanged |
| `diagnostic_settings` | `diagnostic_settings` | Unchanged |
| `managed_identities` | `managed_identities` | Unchanged |
| `backend_address_pool` (map) | `backend_address_pools` (list) | Component fields are flat; backend addresses remain a nested list |
| `backend_http_settings` (map) | `backend_http_settings_collection` (list) | Renamed; component fields are flat |
| `http_listener` (map) | `http_listeners` (list) | Component fields are flat |
| `request_routing_rule` (map) | `request_routing_rules` (list) | Component fields are flat |
| `health_probes` / `probe_configurations` (map) | `probes` (list) | Renamed; component fields are flat |
| `url_path_map` (map) | `url_path_maps` (list) | Map and nested path-rule fields are flat |
| `redirect_configuration` (map) | `redirect_configurations` (list) | Component fields are flat |
| `rewrite_rule_set` (map) | `rewrite_rule_sets` (list) | Set fields are flat; rewrite-rule objects stay nested |
| `ssl_certificates` (map) | `ssl_certificates` (list) | Component fields are flat |
| `frontend_ports` (map) | `frontend_ports` (list) | Component fields are flat |
| `gateway_ip_configuration` | `gateway_ip_configurations` (list) | Component fields are flat |
| `app_gateway_waf_policy_resource_id` / `firewall_policy_id` | `firewall_policy` | Object: `{ id = "..." }` |
| `public_ip_address_configuration` | `public_ip_addresses` | Optional managed-IP map; empty by default. Each entry requires `name`. |
| `public_ip_address_configuration.create_public_ip_enabled` | Map membership | Include an entry to manage an IP; omit it for an external IP. Transfer state before changing ownership. |
| `public_ip_address_configuration.public_ip_name` | `public_ip_addresses[key].name` | Preserve the existing Azure name during adoption. |
| `public_ip_address_configuration.public_ip_resource_id` | `frontend_ip_configurations[*].public_ip_address.id` | External IP ID; not adopted by the module. |
| `public_ip_address_configuration.public_ip_prefix_resource_id` | `public_ip_addresses[key].public_ip_prefix_resource_id` | Existing prefix, not created by the module. |
| `public_ip_address_configuration.resource_group_name` | `public_ip_addresses[key].parent_id` | Full ID of the existing resource group; defaults to the gateway's group. |
| `waf_configuration` | `web_application_firewall_configuration` | Renamed |
| `zones` (`set(number)`) | `zones` (`list(string)`) | Type changed |
| `sku_name` / `sku_tier` / `sku_capacity` | `sku` (object) | Combined into a single object; omit `capacity` when `autoscale_configuration` is set |
| `autoscale_configuration` | `autoscale_configuration` | Unchanged shape |
| `ssl_policy` | `ssl_policy` | Unchanged shape |
| N/A | `listeners` | New — TCP/TLS listener support |
| N/A | `backend_settings_collection` | New — TCP/TLS backend settings |
| N/A | `routing_rules` | New — TCP/TLS routing rules |
| N/A | `entra_jwt_validation_configs` | New |
| N/A | `load_distribution_policies` | New |
| N/A | `private_link_configurations` | New |
| N/A | `id` | Optional — set to import an existing resource |

## Adopting keyed references (optional)

After migrating any `properties` wrappers to flat inputs, adopting keyed
references is still optional. To remove manual ID construction, replace an internal reference's `id` with the corresponding
target type's `*_key` selector. The key matches the target component's configured
`name` case-insensitively; it does not create a separate alias or map-key system:

```hcl
# Existing reference inside a flat backend HTTP settings item
probe = {
  id = "${local.appgw_id}/probes/myapp-probe"
}

# Equivalent keyed reference when probes contains name = "myapp-probe"
probe = {
  probe_key = "myapp-probe"
}
```

Supply either `id` or the corresponding type-specific key, not both. A key must
identify exactly one component by its configured `name` in the target collection
supplied to this module. The selector follows the target type rather than the
property role: for example, `target_listener` uses `http_listener_key`, and
`default_backend_http_settings` uses `backend_http_settings_key`. Explicit IDs
remain the option for references to components outside the supplied
configuration; external public IPs, subnets and WAF policies are not resolved by
key.

For a keyed path-rule reference in a redirect configuration's `path_rules`,
also supply `url_path_map_key` to identify the parent map:

```hcl
path_rules = [
  {
    path_rule_key    = "api"
    url_path_map_key = "routes"
  }
]
```

This resolves the `api` rule in the `routes` entry of `url_path_maps`. Repeated
rule names in different maps are not ambiguous when the parent is specified.
An ID-only path-rule reference must not supply either key.

Only the reference input changes: the module constructs the same ARM ID, and no
Terraform resources or state addresses are added or moved. Do not run
`terraform state rm`, `terraform state mv` or import solely to adopt keys.
Inspect the resulting plan before applying. The provider-migration instructions
later in this guide apply to the older AzureRM implementation, not this optional
reference syntax.

## Migration examples

### Resource group reference

```hcl
# Old
module "appgw" {
  source = "Azure/avm-res-network-applicationgateway/azurerm"

  resource_group_name = "rg-example"
  # ...
}

# New
module "appgw" {
  source = "Azure/avm-res-network-applicationgateway/azurerm"

  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-example"
  # ...
}
```

### Backend address pool

```hcl
# Old (map with flat fields)
backend_address_pool = {
  pool1 = {
    name         = "myapp-pool"
    fqdns        = ["myapp.azurewebsites.net"]
    ip_addresses = []
  }
}

# Current (list with flat component fields)
backend_address_pools = [
  {
    name = "myapp-pool"
    backend_addresses = [
      { fqdn = "myapp.azurewebsites.net" }
    ]
  }
]
```

### Backend HTTP settings with probe reference

```hcl
# Old (name-based cross-reference)
backend_http_settings = {
  settings1 = {
    name                  = "myapp-https"
    port                  = 443
    protocol              = "Https"
    cookie_based_affinity = "Disabled"
    request_timeout       = 30
    probe_name            = "myapp-probe"
  }
}

# New (key reference to an entry declared in probes)
backend_http_settings_collection = [
  {
    name                  = "myapp-https"
    port                  = 443
    protocol              = "Https"
    cookie_based_affinity = "Disabled"
    request_timeout       = 30
    probe = {
      probe_key = "myapp-probe"
    }
  }
]
```

When using explicit IDs instead of keys, **ARM sub-resource type names are
camelCase.** The most common ones:

| Sub-resource | ARM path segment |
|---|---|
| Backend pool | `backendAddressPools` |
| Backend HTTP settings | `backendHttpSettingsCollection` |
| Frontend IP config | `frontendIPConfigurations` |
| Frontend port | `frontendPorts` |
| HTTP listener | `httpListeners` |
| SSL certificate | `sslCertificates` |
| Probe | `probes` |
| Redirect config | `redirectConfigurations` |
| URL path map | `urlPathMaps` |
| Rewrite rule set | `rewriteRuleSets` |

> **Gotcha**: the ARM path for backend HTTP settings is
> `backendHttpSettingsCollection`, not `backendHttpSettings`.

### HTTP listener with SSL certificate

```hcl
# Old
http_listener = {
  listener1 = {
    name                      = "myapp-https-listener"
    frontend_ip_configuration = "public"
    frontend_port_name        = "https"
    protocol                  = "Https"
    ssl_certificate_name      = "wildcard-cert"
  }
}

# New
http_listeners = [
  {
    name = "myapp-https-listener"
    frontend_ip_configuration = {
      frontend_ip_configuration_key = "public"
    }
    frontend_port = {
      frontend_port_key = "https"
    }
    protocol = "Https"
    ssl_certificate = {
      ssl_certificate_key = "wildcard-cert"
    }
  }
]
```

### Frontend IP configuration

The old module could create and manage a public IP internally. Optional
management is available again, but is no longer enabled by default.
The following are module arguments, not a state migration:

```hcl
# Old v0.5.2
public_ip_address_configuration = {
  create_public_ip_enabled = true
  public_ip_name           = "pip-appgw"
}

# New
public_ip_addresses = {
  internet_v4 = {
    name = "pip-appgw"
  }
}

frontend_ip_configurations = [
  {
    name                  = "public"
    public_ip_address_key = "internet_v4"
  }
]
```

Preserve the old IP's actual name, resource group, zones, tags, DDoS and DNS
settings. The new module uses the gateway's location and Standard/Regional/Static
IPs. Copy compatible settings into the selected entry; `public_ip_name` becomes
`name`, and `resource_group_name` becomes a full resource-group `parent_id`.
Other supported per-IP setting names are listed in the generated input
documentation. Do not treat adoption as an opportunity to change immutable IP
settings.

An external IP keeps its `id` reference, now directly on the flat frontend:

```hcl
frontend_ip_configurations = [
  {
    name = "public"
    public_ip_address = {
      id = var.existing_public_ip_resource_id
    }
  }
]
```

### Firewall policy

```hcl
# Old
firewall_policy_id = azurerm_web_application_firewall_policy.this.id

# New
firewall_policy = {
  id = azurerm_web_application_firewall_policy.this.id
}
```

### Zones

```hcl
# Old
zones = [1, 2, 3]

# New
zones = ["1", "2", "3"]
```

### Autoscale with v2 SKUs

```hcl
# Old / invalid with the AzAPI module
autoscale_configuration = {
  min_capacity = 2
  max_capacity = 10
}

sku = {
  name     = "Standard_v2"
  tier     = "Standard_v2"
  capacity = 0
}

# New
autoscale_configuration = {
  min_capacity = 2
  max_capacity = 10
}

sku = {
  name = "Standard_v2"
  tier = "Standard_v2"
}
```

## New features

The AzAPI-based module enables capabilities that the azurerm provider
did not yet support:

- **`list_unique_id_property`** — produces clean `terraform plan`
  output when sub-resources are reordered, which is common on shared
  gateways with multiple apps contributing to the same lists.
- **Day-zero ARM API support** — targets API version `2025-03-01`
  directly, no waiting for provider releases.
- **TCP/TLS listeners and routing** — use `listeners`,
  `backend_settings_collection`, and `routing_rules` for Layer 4
  workloads.
- **`entra_jwt_validation_configs`** — Entra ID JWT validation at the
  gateway level.
- **`load_distribution_policies`** — weighted traffic distribution
  across backend pools.
- **`private_link_configurations`** — Private Link support for the
  gateway frontend.

## State migration

This section applies only to the older AzureRM-to-AzAPI provider migration.
Do not perform these state operations solely to flatten component inputs.

### Application Gateway

The module includes a `moved` block that transfers an existing gateway from
`azurerm_application_gateway.this` to `azapi_resource.this` during the first
plan after you upgrade. You do not need to remove or import the gateway.

Moving state between these resource types requires Terraform 1.8 or later and
AzAPI 2.1 or later. The module's own version constraints (Terraform `>= 1.12`,
AzAPI `~> 2.12`) already guarantee both.

1. Back up state:

   ```powershell
   terraform state pull > terraform.tfstate.backup
   ```

2. Update the module version, convert your inputs, and run
   `terraform init -upgrade`.
3. If the module managed a public IP, complete the
   [public IP ownership migration](#public-ip-ownership-migration) now, before
   planning. The `moved` block covers only the gateway.
4. Run `terraform plan`. Confirm that it reports
   `module.appgw.azurerm_application_gateway.this` has moved to
   `module.appgw.azapi_resource.this`, and that nothing is replaced or
   destroyed. Expect an in-place update of the gateway: AzAPI reads the moved
   gateway with a newer API version, and the update re-applies your
   configuration with the module's API version. Review it as you would any
   gateway change.
5. Apply, then run `terraform plan` again and confirm it reports no changes.

> [!WARNING]
> Do not use `-refresh=false` for the migration plan. AzAPI's move does not
> carry over the gateway's `location`; the refresh restores it. Without the
> refresh, Terraform plans to replace the gateway.

### Fallback: remove and import

Use this path only when the `moved` block cannot be used:

- **The plan fails to read the gateway**, for example with
  `NoRegisteredProviderFound`. AzAPI's move reads the gateway with the newest
  API version AzAPI knows, not the module's configured version, and some
  regions or clouds do not serve it yet
  ([Azure/terraform-provider-azapi#1227](https://github.com/Azure/terraform-provider-azapi/issues/1227)).
  A failed plan does not change state.
- **The `moved` block is gone.** It will be removed in a future release. If you
  upgrade from an AzureRM-based release directly to such a release, migrate
  manually.

```powershell
terraform state pull > terraform.tfstate.backup
terraform state rm 'module.appgw.azurerm_application_gateway.this'
terraform import 'module.appgw.azapi_resource.this' '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-example/providers/Microsoft.Network/applicationGateways/my-appgw?api-version=2025-03-01'
terraform plan
```

The `?api-version=` suffix makes the import use the module's configured API
version. If you override `resource_types.network_application_gateways`, use
that version instead. Do not apply between these commands, and review the plan
as in step 4.

If you already migrated the gateway manually on an earlier release, the
`moved` block finds nothing to move, and no further action is needed.

Adjust the resource addresses above to match your module call. If you
use `for_each` or `count`, include the key or index in the address
(e.g. `module.appgw["prod"].azapi_resource.this`).

### Public IP ownership migration

Coordinate state operations with your deployment pipeline and back up the state
first. Do not run an apply between forgetting an old address and importing the
existing IP at its new address. None of the following commands should create,
delete or reallocate the Azure public IP.

**From v0.5.2 module management to the new managed map**

Configure the desired map key and matching frontend binding as shown above.
Use `terraform state list` and `terraform state show` to record the actual old
address, public IP resource ID and settings. The old module used `count`, so its
IP instance normally ends in `.this[0]`.

This migration changes both the Terraform resource type, from
`azurerm_public_ip` to `azapi_resource`, and the instance address, from a `count`
index to a named `for_each` key. A direct `terraform state mv` cannot perform
that resource-type conversion. The procedure below removes the old state
binding and imports the same existing Azure public IP under the new resource
type and address. Do not run an apply between these commands.

After installing the updated module, transfer ownership explicitly:

```powershell
terraform state pull > terraform.tfstate.backup
terraform state rm 'module.appgw.azurerm_public_ip.this[0]'
terraform import 'module.appgw.azapi_resource.public_ip_addresses["internet_v4"]' '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-example/providers/Microsoft.Network/publicIPAddresses/pip-appgw'
terraform plan
```

Substitute the real module addresses, map key and Azure resource ID. The selected
key is consumer-defined, so the module cannot supply one generic `moved` block
for every old counted IP. In-place updates to the IP and the moved gateway are
expected. Stop if the resulting plan proposes IP or gateway replacement or
destruction. Reconcile the configuration with the existing resource before
applying.

The `terraform state mv` command is distinct from provider-supported declarative
`moved` blocks. That alternative has not been validated for this public-IP upgrade
path; this guide uses the explicit remove/import procedure above.

**From external ownership to module ownership**

If the IP is already owned by an `azapi_resource` in the same state, configure
the new map entry and transfer its address using `terraform state mv`. If the
provider resource type changes, use the explicit forget/import sequence above
with the old external address instead. If the IP belongs to another state,
coordinate relinquishing ownership there before importing it here. Do not
leave two Terraform addresses or states managing the same Azure IP.

**From module ownership to an external IP**

Create a matching external resource declaration and change the frontend to use
its ID. For an external `azapi_resource` in the same state, transfer ownership
before any apply:

```powershell
terraform state pull > terraform.tfstate.backup
terraform state mv 'module.appgw.azapi_resource.public_ip_addresses["internet_v4"]' 'azapi_resource.appgw_public_ip'
terraform plan
```

Remove the managed map entry as part of that configuration change. Merely
emptying `public_ip_addresses` does not preserve the IP: Terraform would normally
schedule deletion. If the external owner uses another resource type or state,
coordinate an explicit forget/import transfer instead.

**Renaming a map key**

Keep the Azure name and configuration unchanged, update the frontend key, and
use an explicit address move:

```powershell
terraform state mv 'module.appgw.azapi_resource.public_ip_addresses["internet_v4"]' 'module.appgw.azapi_resource.public_ip_addresses["public_v4"]'
```

Inspect the plan before applying. A key rename must not allocate a new IP.

## Output changes

| Old output | New output | Notes |
|---|---|---|
| `resource_id` | `resource_id` | Unchanged |
| `name` | `name` | Unchanged |
| `public_ip_id` | `public_ip_addresses[key].resource_id` | For managed IPs; external IPs remain outputs of their owner. |
| `new_public_ip_address` | `public_ip_addresses[key].ip_address` | Managed IPs only. |
| N/A | `identity_principal_id` | New — system-assigned identity principal |
| N/A | `identity_tenant_id` | New — system-assigned identity tenant |
| N/A | `default_predefined_ssl_policy` | New |
| N/A | `operational_state` | New |
| N/A | `private_endpoint_connections` | New |
| N/A | `provisioning_state` | New |
| N/A | `resource_guid` | New |
| N/A | `type` | New |
