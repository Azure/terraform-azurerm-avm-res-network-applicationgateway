<!-- BEGIN_TF_DOCS -->
# Azure Application Gateway Terraform Module

This module deploys an Azure Application Gateway using the [AzAPI provider](https://registry.terraform.io/providers/Azure/azapi/latest), providing day-zero support for new ARM API features, a 1:1 mapping with the ARM schema, and `list_unique_id_property` support for clean plans on shared gateways.

> [!IMPORTANT]
> As the overall AVM framework is not GA (generally available) yet - the CI framework and test automation is not fully functional and implemented across all supported languages yet - breaking changes are expected, and additional customer feedback is yet to be gathered and incorporated. Hence, modules **MUST NOT** be published at version `1.0.0` or higher at this time.
>
> All module **MUST** be published as a pre-release version (e.g., `0.1.0`, `0.1.1`, `0.2.0`, etc.) until the AVM framework becomes GA.
>
> However, it is important to note that this **DOES NOT** mean that the modules cannot be consumed and utilized. They **CAN** be leveraged in all types of environments (dev, test, prod etc.). Consumers can treat them just like any other IaC module and raise issues or feature requests against them as they learn from the usage of the module. Consumers should also read the release notes for each version, if considering updating to a more recent version of a module to see if there are any considerations or breaking changes etc.

## Breaking changes — AzAPI migration

This module has been rewritten from `azurerm_application_gateway` to `azapi_resource`. A `moved` block is included to preserve Terraform state for existing deployments; this block will be removed in a future release. Key breaking changes:

- **AzAPI provider** — the core resource now uses `azapi_resource` instead of `azurerm_application_gateway`
- **Public IP** — `v0.5.3` removed public IP management. Optional management is now available through `public_ip_addresses`, but old counted public IP instances still require an explicit state migration.

### Requirements

| Dependency | Version |
|---|---|
| Terraform | `>= 1.12, < 2.0` |
| AzAPI provider | `~> 2.12` |
| azurerm provider | `>= 3.117, < 5.0` |

For the full migration guide including variable mapping and code examples, see [UPGRADE.md](UPGRADE.md).

## Optional public IP management

Public IP creation is opt-in: `public_ip_addresses` defaults to `{}`. Upgrading
does not create public IPs or change existing external-IP and private-only
frontends.

To create and attach a public IP, supply a named map entry and reference its key
on the frontend. These are arguments to this module:

```hcl
public_ip_addresses = {
  internet_v4 = {
    name       = "pip-appgw-prod-v4"
    ip_version = "IPv4"
  }
}

frontend_ip_configurations = [
  {
    name                  = "public-v4"
    public_ip_address_key = "internet_v4"
  }
]
```

The module resolves the public IP resource ID internally; the frontend
`properties` block may be omitted. Existing properties, such as
`private_link_configuration`, may still be supplied. The helper
`public_ip_address_key` is not sent to the ARM API.

For an externally managed IP, keep the existing input shape and omit
`public_ip_address_key`:

```hcl
frontend_ip_configurations = [
  {
    name = "public-v4"
    properties = {
      public_ip_address = {
        id = var.existing_public_ip_resource_id
      }
    }
  }
]
```

A frontend cannot select both a managed key and an external IP ID, or combine a
managed public IP with private IP/subnet settings. A managed key must exist and
can be attached to only one frontend. The module does not look up, adopt, modify
or delete an external IP.

Managed IPs use Standard/Regional/Static settings in the gateway's location.
They inherit the gateway's resource group and zones unless overridden, and
merge per-IP tags over module tags. Explicit non-empty IP zones must cover the
gateway's zones; an empty list preserves Azure's default zone selection.
An existing public IP prefix, DDoS settings, DNS settings, IP tags and idle
timeout can also be configured. Prefixes, DDoS plans and resource groups remain
external dependencies.

The map supports one IPv4 and one IPv6 public IP for a dual-stack gateway.
The surrounding subnet, frontend and listener configuration must also support
the selected protocol. This feature does not create listeners, routing rules,
networks or public IP prefixes.

The `public_ip_addresses` output contains only module-managed IPs, indexed by
the same keys. Each entry exposes `resource_id`, `ip_address` and `fqdn`
(`null` without a DNS label).

> [!WARNING]
> Map keys are Terraform resource identities. Removing an entry normally
> schedules its public IP for deletion; changing a key requires a state move
> to preserve ownership. Azure names, address family, prefix and zone changes
> can require replacement and loss of the allocated address. Gateway-scoped
> locks do not protect these separate public IP resources. Follow
> [the ownership migration instructions](UPGRADE.md#public-ip-ownership-migration)
> before switching between managed and external ownership.

### Public IP regression coverage

Run `avm test unit` from the module root for provider-mocked coverage of legacy
frontends, optional creation, IPv4/IPv6 bindings, outputs, advanced IP settings,
unknown values and invalid inputs. Positive cases use mocked apply; invalid
inputs intentionally fail during plan.

`avm test integration` creates billable Azure resources using the isolated
fixture in `tests/integration`. Run it only in an approved test subscription
with the required permissions. It verifies a real managed IPv4 gateway and
independently reads back its IP attachment and outputs. A second plan verifies
retained identity, not a complete zero-change plan. Real upgrade/state-transfer
and dual-stack deployment coverage are still required before claiming those
paths are production-proven.

## Supported frontend IP configuration

Application Gateway V2 supports the following combinations:

- Private IP and Public IP
- Public IP only
- Private only

> [!IMPORTANT]
> Private link configuration support for tunneling traffic through private endpoints to Application Gateway is unsupported with private-only gateways.

## Supported Scenarios

**[Default — Simple HTTP Application Gateway](examples/default/README.md)**
A straightforward HTTP Application Gateway for basic web applications or services.

**[Single-site HTTP Application Gateway](examples/simple_http_host_single_site_app_gateway/README.md)**
Routes traffic for a single site behind the gateway.

**[Multi-site HTTP Application Gateway](examples/simple_http_host_multiple_sites_app_gateway/README.md)**
Multi-site hosting enables you to configure more than one web application on the same port using public-facing listeners, directing each website to its own backend pool.

**[Application Gateway Internal](examples/simple_http_app_gateway_internal/README.md)**
Configured with an internal endpoint using a private IP address for the frontend (ILB endpoint).

**[Application Gateway Internal — Private only](examples/front_end_ip_private_custom_name_privateonly/README.md)**
A private-only frontend configuration with a custom frontend IP name.

**[Application Gateway — Private + Public with custom name](examples/front_end_ip_private_custom_name/README.md)**
Dual frontend (private and public) with custom frontend IP configuration names.

**[Web Application Firewall (WAF)](examples/simple_waf_http_app_gateway/README.md)**
Enhances security by inspecting and filtering traffic with custom rules and policies.

**[Application Gateway with Self-Signed SSL (HTTPS)](examples/selfssl_waf_https_app_gateway/README.md)**
Uses self-signed SSL certificates to secure traffic over HTTPS with redirection rules.

**[Application Gateway with SSL via Azure Key Vault](examples/kv_selfssl_waf_https_app_gateway/README.md)**
SSL certificates managed using Azure Key Vault for enhanced security. TLS version defaults to 1.2.

**[Application Gateway with SSL via Azure Key Vault — Private only](examples/kv_selfssl_waf_https_app_gateway_privateonly/README.md)**
Private-only frontend with WAF and SSL certificates managed via Azure Key Vault. TLS version defaults to 1.2.

**[Health Probe monitoring](examples/simple_http_probe_app_gateway/README.md)**
Monitors the health of backend servers and automatically stops sending traffic to unhealthy instances.

**[Rewrite Rules](examples/rewrite_rule/README.md)**
Demonstrates URL and header rewrite rules on the Application Gateway.
