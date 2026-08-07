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
- **Cross-references**: name-based references (e.g.
  `probe_name = "my-probe"`) are replaced by ARM resource ID
  references (e.g. `probe = { id = "..." }`).
- **Public IP**: no longer managed by the module. Create and manage
  your public IP externally and pass its ID into
  `frontend_ip_configurations`.
- **Terraform**: `>= 1.12` required.
- **AzAPI provider**: `~> 2.7` required.
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
| `create_public_ip` | Removed | Manage the public IP externally |
| `public_ip_name` | Removed | Manage the public IP externally |
| `public_ip_resource_id` | Removed | Pass the ID into `frontend_ip_configurations` |
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

# New (ARM resource ID cross-reference)
# Build the gateway ID first:
#   appgw_id = "/subscriptions/.../resourceGroups/rg-example/providers/Microsoft.Network/applicationGateways/my-appgw"
backend_http_settings_collection = [
  {
    name = "myapp-https"
    properties = {
      port                = 443
      protocol            = "Https"
      cookie_based_affinity = "Disabled"
      request_timeout     = 30
      probe = {
        id = "${local.appgw_id}/probes/myapp-probe"
      }
    }
  }
]
```

**ARM sub-resource type names are camelCase.** The most common ones:

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
        id = "${local.appgw_id}/frontendIPConfigurations/public"
      }
      frontend_port = {
        id = "${local.appgw_id}/frontendPorts/https"
      }
      protocol = "Https"
      ssl_certificate = {
        id = "${local.appgw_id}/sslCertificates/wildcard-cert"
      }
    }
  }
]
```

### Frontend IP configuration

The old module could create and manage a public IP internally. The new
module does not — create the public IP as a separate resource and pass
its ID:

```hcl
# Old
create_public_ip      = true
public_ip_name        = "pip-appgw"

# New — create the public IP yourself
resource "azurerm_public_ip" "appgw" {
  name                = "pip-appgw"
  location            = "australiaeast"
  resource_group_name = "rg-example"
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

# Then pass it into the module
frontend_ip_configurations = [
  {
    name = "public"
    properties = {
      public_ip_address = {
        id = azurerm_public_ip.appgw.id
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

# 3. If the module managed a public IP, remove that too
terraform state rm 'module.appgw.azurerm_public_ip.this'

# 4. Import into the new azapi resource
terraform import 'module.appgw.azapi_resource.this' \
  '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-example/providers/Microsoft.Network/applicationGateways/my-appgw'

# 5. Run plan to verify — expect no destructive changes
terraform plan
```

Adjust the resource addresses above to match your module call. If you
use `for_each` or `count`, include the key or index in the address
(e.g. `module.appgw["prod"].azapi_resource.this`).

## Output changes

| Old output | New output | Notes |
|---|---|---|
| `resource_id` | `resource_id` | Unchanged |
| `name` | `name` | Unchanged |
| `public_ip_id` | Removed | Manage the public IP externally |
| `new_public_ip_address` | Removed | Use `azurerm_public_ip.*.ip_address` |
| N/A | `identity_principal_id` | New — system-assigned identity principal |
| N/A | `identity_tenant_id` | New — system-assigned identity tenant |
| N/A | `default_predefined_ssl_policy` | New |
| N/A | `operational_state` | New |
| N/A | `private_endpoint_connections` | New |
| N/A | `provisioning_state` | New |
| N/A | `resource_guid` | New |
| N/A | `type` | New |
