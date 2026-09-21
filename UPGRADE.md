# Upgrading from the azurerm-based module to the AzAPI-based module

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
- **Variable shape**: variables changed from `map(object)` with flat
  fields to `list(object)` with nested `properties` blocks matching
  the ARM schema.
- **Cross-references**: legacy fields such as `probe_name` become reference
  objects. Use `probe = { name = "my-probe" }` for a probe declared in this
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
| `backend_address_pool` (map) | `backend_address_pools` (list) | Flat fields → `properties` block |
| `backend_http_settings` (map) | `backend_http_settings_collection` (list) | Renamed; flat fields → `properties` block |
| `http_listener` (map) | `http_listeners` (list) | Flat fields → `properties` block |
| `request_routing_rule` (map) | `request_routing_rules` (list) | Flat fields → `properties` block |
| `health_probes` / `probe_configurations` (map) | `probes` (list) | Renamed; flat fields → `properties` block |
| `url_path_map` (map) | `url_path_maps` (list) | Flat fields → `properties` block |
| `redirect_configuration` (map) | `redirect_configurations` (list) | Flat fields → `properties` block |
| `rewrite_rule_set` (map) | `rewrite_rule_sets` (list) | Flat fields → `properties` block |
| `ssl_certificates` (map) | `ssl_certificates` (list) | Flat fields → `properties` block |
| `frontend_ports` (map) | `frontend_ports` (list) | Flat fields → `properties` block |
| `gateway_ip_configuration` | `gateway_ip_configurations` (list) | Flat fields → `properties` block |
| `app_gateway_waf_policy_resource_id` / `firewall_policy_id` | `firewall_policy` | Object: `{ id = "..." }` |
| `public_ip_address_configuration` | `public_ip_addresses` | Optional managed-IP map; empty by default. Each entry requires `name`. |
| `public_ip_address_configuration.create_public_ip_enabled` | Map membership | Include an entry to manage an IP; omit it for an external IP. Transfer state before changing ownership. |
| `public_ip_address_configuration.public_ip_name` | `public_ip_addresses[key].name` | Preserve the existing Azure name during adoption. |
| `public_ip_address_configuration.public_ip_resource_id` | `frontend_ip_configurations[*].properties.public_ip_address.id` | External IP ID; not adopted by the module. |
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

## Adopting named references (optional)

Existing AzAPI-based configurations do not need to change. To remove manual ID
construction, replace an internal reference's `id` with the corresponding
component's configured `name`:

```hcl
# Existing reference inside backend HTTP settings properties
probe = {
  id = "${local.appgw_id}/probes/myapp-probe"
}

# Equivalent name reference when probes contains name = "myapp-probe"
probe = {
  name = "myapp-probe"
}
```

Supply either `id` or `name`, not both. A name must identify exactly one component
in the corresponding collection supplied to this module. Matching is
case-insensitive. Explicit IDs remain the option for references to components
outside the supplied configuration; external public IPs, subnets and WAF policies
are not resolved by name.

For a named path-rule reference in a redirect configuration's `path_rules`,
also supply `url_path_map_name` to identify the parent map:

```hcl
path_rules = [
  {
    name              = "api"
    url_path_map_name = "routes"
  }
]
```

This resolves the `api` rule in the `routes` entry of `url_path_maps`. Repeated
rule names in different maps are not ambiguous when the parent is specified.
An ID-only reference must not also supply a name or parent map name.

Only the reference input changes: the module constructs the same ARM ID, and no
Terraform resources or state addresses are added or moved. Do not run
`terraform state rm`, `terraform state mv` or import solely to adopt names.
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

# New (list with properties block)
backend_address_pools = [
  {
    name = "myapp-pool"
    properties = {
      backend_addresses = [
        { fqdn = "myapp.azurewebsites.net" }
      ]
    }
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

# New (name reference to an entry declared in probes)
backend_http_settings_collection = [
  {
    name = "myapp-https"
    properties = {
      port                = 443
      protocol            = "Https"
      cookie_based_affinity = "Disabled"
      request_timeout     = 30
      probe = {
        name = "myapp-probe"
      }
    }
  }
]
```

When using explicit IDs instead of names, **ARM sub-resource type names are
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
    properties = {
      frontend_ip_configuration = {
        name = "public"
      }
      frontend_port = {
        name = "https"
      }
      protocol = "Https"
      ssl_certificate = {
        name = "wildcard-cert"
      }
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

An external IP keeps the existing interface:

```hcl
frontend_ip_configurations = [
  {
    name = "public"
    properties = {
      public_ip_address = {
        id = var.existing_public_ip_resource_id
      }
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

Migrating an existing gateway requires removing the old resource from
state and importing it into the new resource type. **Back up your state
first.**

```bash
# 1. Back up state
terraform state pull > terraform.tfstate.backup

# 2. Remove the old azurerm resource from state
terraform state rm 'module.appgw.azurerm_application_gateway.this'

# 3. If the module managed a public IP, complete the ownership
# migration below before applying. Do not just remove it from state.

# 4. Import into the new azapi resource
terraform import 'module.appgw.azapi_resource.this' \
  '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-example/providers/Microsoft.Network/applicationGateways/my-appgw'

# 5. Run plan to verify — expect no destructive changes
terraform plan
```

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
for every old counted IP. Stop if the resulting plan proposes IP or gateway
replacement or destruction. Reconcile the configuration with the existing
resource before applying.

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
