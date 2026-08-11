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
- **Public IP** — no longer managed by the module. Create and manage your public IP externally and pass its ID into `frontend_ip_configurations`.

### Requirements

| Dependency | Version |
|---|---|
| Terraform | `>= 1.9` |
| AzAPI provider | `~> 2.12` |
| azurerm provider | `>= 3.117, < 5.0` |

For the full migration guide including variable mapping and code examples, see [UPGRADE.md](UPGRADE.md).

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

**[Application Gateway with SSL via Key Vault — Private only](examples/kv_selfssl_waf_https_app_gateway_privateonly/README.md)**
Key Vault–integrated SSL on a private-only frontend.

**[Health Probe monitoring](examples/simple_http_probe_app_gateway/README.md)**
Monitors the health of backend servers and automatically stops sending traffic to unhealthy instances.

**[Rewrite Rules](examples/rewrite_rule/README.md)**
Demonstrates URL and header rewrite rules on the Application Gateway.
