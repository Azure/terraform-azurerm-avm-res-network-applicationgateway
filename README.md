<!-- BEGIN_TF_DOCS -->
<!-- BEGIN\_TF\_DOCS -->
> [!IMPORTANT]
> As the overall AVM framework is not GA (generally available) yet - the CI framework and test automation is not fully functional and implemented across all supported languages yet - breaking changes are expected, and additional customer feedback is yet to be gathered and incorporated. Hence, modules **MUST NOT** be published at version `1.0.0` or higher at this time.
>
> All module **MUST** be published as a pre-release version (e.g., `0.1.0`, `0.1.1`, `0.2.0`, etc.) until the AVM framework becomes GA.
>
> However, it is important to note that this **DOES NOT** mean that the modules cannot be consumed and utilized. They **CAN** be leveraged in all types of environments (dev, test, prod etc.). Consumers can treat them just like any other IaC module and raise issues or feature requests against them as they learn from the usage of the module. Consumers should also read the release notes for each version, if considering updating to a more recent version of a module to see if there are any considerations or breaking changes etc.

# Azure Application Gateway Terraform Module

Azure Application Gateway is a load balancer that enables you to manage and optimize the traffic to your web applications. When using Terraform to deploy Azure resources, you can make use of a Terraform module to define and configure the Azure Application Gateway. Here is a summary page about using an Azure Application Gateway Terraform module:

## What is Azure Application Gateway?
Azure Application Gateway is a Layer-7 load balancer service provided by Microsoft Azure. It enables you to manage traffic to your web applications by providing features like SSL termination, routing, and session affinity. Using Terraform, you can automate the provisioning and configuration of an Azure Application Gateway.

## Terraform Module for Azure Application Gateway
A Terraform module is a reusable and shareable configuration for defining and deploying Azure resources. To create an Azure Application Gateway using Terraform, you can use a pre-built module. This module simplifies the configuration process and allows you to create and manage an Application Gateway efficiently.

The terraform module supports following scenarios.

## Supported frontend IP configuration
For current general availability support, Application Gateway V2 supports the following combinations
- Private IP and Public IP
- Public IP only

## Supported Scenarios

The Terraform module for Azure Application Gateway is versatile and adaptable, accommodating various deployment scenarios. These scenarios dictate distinct input requirements. Here's an overview of the supported scenarios, each offering a unique configuration:

Each of these scenarios has its own set of input requirements, which can be tailored to meet your specific use case. The module provides the flexibility to deploy Azure Application Gateways for a wide range of applications and security needs.

**[Simple HTTP Application Gateway](examples/simple\_http\_host\_single\_site\_app\_gateway/README.md)**
This scenario sets up a straightforward HTTP Application Gateway, typically for basic web applications or services.

**[Multi-site HTTP Application Gateway](examples/simple\_http\_host\_multiple\_sites\_app\_gateway/README.md)** Multi-site hosting enables you to configure more than one web application on the same port of application gateways using public-facing listeners. It allows you to configure a more efficient topology for your deployments by adding up to 100+ websites to one application gateway. Each website can be directed to its own backend pool. For example, three domains, contoso.com, fabrikam.com, and adatum.com, point to the IP address of the application gateway. You'd create three multi-site listeners and configure each listener for the respective port and protocol setting.

**[Application Gateway Internal](examples/simple\_http\_app\_gateway\_internal/README.md)**
Azure Application Gateway Standard v2 can be configured with an Internet-facing VIP or with an internal endpoint that isn't exposed to the Internet. An internal endpoint uses a private IP address for the frontend, which is also known as an internal load balancer (ILB) endpoint.

**[Web Application Firewall (WAF)](examples/simple\_waf\_http\_app\_gateway/README.md)**
A Web Application Firewall is employed to enhance security by inspecting and filtering traffic. Configuration entails defining custom rules and policies to protect against common web application vulnerabilities.

**[Application Gateway with Self-Signed SSL (HTTPS)](examples/selfssl\_waf\_https\_app\_gateway/README.md)**
In this scenario, self-signed SSL certificates are utilized to secure traffic to HTTPS. You'll need to configure SSL certificates and redirection rules.

**[Application Gateway with SSL with Azure Key Vault](examples/kv\_selfssl\_waf\_https\_app\_gateway/README.md)**
For enhanced security, SSL certificates are managed using Azure Key Vault. This scenario involves setting up Key Vault and integrating it with the Application Gateway. Detailed configuration for Key Vault and SSL certificates is necessary.

**[Application Gateway monitors the health probes](examples/simple\_http\_probe\_app\_gateway/README.md)**
Azure Application Gateway monitors the health of all the servers in its backend pool and automatically stops sending traffic to any server it considers unhealthy. The probes continue to monitor such an unhealthy server, and the gateway starts routing the traffic to it once again as soon as the probes detect it as healthy.

Before running the script, make sure you have logged in to your Azure subscription using the Azure CLI or Azure PowerShell, so Terraform can authenticate and interact with your Azure account.

Please ensure that you have a clear plan and architecture for your Azure Application Gateway, as the Terraform script should align with your specific requirements and network design.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.0.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.71.0)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (~> 0.3)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0)

## Resources

The following resources are used by this module:

- [azurerm_application_gateway.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway) (resource)
- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_monitor_diagnostic_setting.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) (resource)
- [azurerm_public_ip.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [modtm_telemetry.telemetry](https://registry.terraform.io/providers/Azure/modtm/latest/docs/resources/telemetry) (resource)
- [random_uuid.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [azurerm_client_config.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [azurerm_subnet.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) (data source)
- [modtm_module_source.telemetry](https://registry.terraform.io/providers/Azure/modtm/latest/docs/data-sources/module_source) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_backend_address_pools"></a> [backend\_address\_pools](#input\_backend\_address\_pools)

Description: List of backend address pools

Type:

```hcl
map(object({
    name         = string
    fqdns        = optional(list(string))
    ip_addresses = optional(list(string))
  }))
```

### <a name="input_backend_http_settings"></a> [backend\_http\_settings](#input\_backend\_http\_settings)

Description: List of backend HTTP settings

Type:

```hcl
map(object({
    name                                = string
    cookie_based_affinity               = string
    path                                = optional(string)
    affinity_cookie_name                = optional(string)
    port                                = optional(number)
    enable_https                        = bool
    probe_name                          = optional(string)
    request_timeout                     = number
    host_name                           = optional(string)
    pick_host_name_from_backend_address = optional(bool)
    authentication_certificate = optional(object({
      name = string
    }))
    trusted_root_certificate_names = optional(list(string))
    connection_draining = optional(object({
      enable_connection_draining = bool
      drain_timeout_sec          = number
    }))
  }))
```

### <a name="input_frontend_ports"></a> [frontend\_ports](#input\_frontend\_ports)

Description: Map of frontend ports

Type:

```hcl
map(object({
    name = string
    port = number

  }))
```

### <a name="input_http_listeners"></a> [http\_listeners](#input\_http\_listeners)

Description: List of HTTP listeners

Type:

```hcl
map(object({
    name               = string
    frontend_port_name = string

    firewall_policy_id   = optional(string)
    require_sni          = optional(bool)
    host_name            = optional(string)
    host_names           = optional(list(string))
    ssl_certificate_name = optional(string)
    ssl_profile_name     = optional(string)
    custom_error_configuration = optional(list(object({
      status_code           = string
      custom_error_page_url = string
    })))
    # Define other attributes as needed
  }))
```

### <a name="input_location"></a> [location](#input\_location)

Description: The Azure regional location where the resources will be deployed.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: The name of the application gateway.

Type: `string`

### <a name="input_public_ip_name"></a> [public\_ip\_name](#input\_public\_ip\_name)

Description: The name of the application gateway.

Type: `string`

### <a name="input_request_routing_rules"></a> [request\_routing\_rules](#input\_request\_routing\_rules)

Description: List of request routing rules

Type:

```hcl
map(object({
    name                        = string
    rule_type                   = string
    http_listener_name          = string
    backend_address_pool_name   = optional(string)
    priority                    = optional(number)
    url_path_map_name           = optional(string)
    backend_http_settings_name  = optional(string)
    redirect_configuration_name = optional(string)
    rewrite_rule_set_name       = optional(string)
    # Define other attributes as needed
  }))
```

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The resource group where the resources will be deployed.

Type: `string`

### <a name="input_subnet_name_backend"></a> [subnet\_name\_backend](#input\_subnet\_name\_backend)

Description: The backend subnet where the application gateway resources configuration will be deployed.

Type: `string`

### <a name="input_vnet_name"></a> [vnet\_name](#input\_vnet\_name)

Description: The VNET where the application gateway resources will be deployed.

Type: `string`

### <a name="input_vnet_resource_group_name"></a> [vnet\_resource\_group\_name](#input\_vnet\_resource\_group\_name)

Description: The resource group where the VNET resources deployed.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_app_gateway_waf_policy_resource_id"></a> [app\_gateway\_waf\_policy\_resource\_id](#input\_app\_gateway\_waf\_policy\_resource\_id)

Description: The ID of the WAF policy to associate with the Application Gateway.

Type: `string`

Default: `null`

### <a name="input_autoscale_configuration"></a> [autoscale\_configuration](#input\_autoscale\_configuration)

Description: V1 SKU this value must be between 1 and 32, and 1 to 125 for a V2 SKU

Type:

```hcl
object({
    min_capacity = optional(number, 1) # Minimum in the range 0 to 100
    max_capacity = optional(number, 2) # Maximum in the range 2 to 125
  })
```

Default: `null`

### <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings)

Description: A map of diagnostic settings to create on the ddos protection plan. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
- `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
- `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
- `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
- `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
- `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
- `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
- `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
- `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.

Type:

```hcl
map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_enable_classic_rule"></a> [enable\_classic\_rule](#input\_enable\_classic\_rule)

Description: Enable or disable the classic WAF rule

Type: `bool`

Default: `false`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see https://aka.ms/avm/telemetry.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_frontend_ip_type"></a> [frontend\_ip\_type](#input\_frontend\_ip\_type)

Description: Type of frontend IP configuration. Possible values: 'public', 'private', 'both'

Type: `string`

Default: `"public"`

### <a name="input_http2_enable"></a> [http2\_enable](#input\_http2\_enable)

Description: The Azure application gateway HTTP/2 protocol support

Type: `bool`

Default: `true`

### <a name="input_identity_ids"></a> [identity\_ids](#input\_identity\_ids)

Description: Specifies a list with a single user managed identity id to be assigned to the Application Gateway

Type: `list(string)`

Default: `[]`

### <a name="input_lock"></a> [lock](#input\_lock)

Description:   Controls the Resource Lock configuration for this resource. The following properties can be specified:

  - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
  - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

Type:

```hcl
object({
    kind = string
    name = optional(string, null)
  })
```

Default: `null`

### <a name="input_private_ip_address"></a> [private\_ip\_address](#input\_private\_ip\_address)

Description: Private IP Address to assign to the Application Gateway Load Balancer.

Type: `string`

Default: `null`

### <a name="input_probe_configurations"></a> [probe\_configurations](#input\_probe\_configurations)

Description: List of probe configurations.

Type:

```hcl
map(object({
    name                                      = string
    host                                      = string
    interval                                  = number
    timeout                                   = number
    unhealthy_threshold                       = number
    protocol                                  = string
    port                                      = optional(number)
    path                                      = string
    pick_host_name_from_backend_http_settings = optional(bool)
    minimum_servers                           = optional(number)
    match = optional(object({
      body        = optional(string)
      status_code = optional(list(string))
    }))
  }))
```

Default: `null`

### <a name="input_redirect_configuration"></a> [redirect\_configuration](#input\_redirect\_configuration)

Description: List of redirection configurations.

Type:

```hcl
map(object({
    name                 = string
    redirect_type        = string
    target_listener_name = optional(string)
    target_url           = optional(string)
    include_path         = optional(bool)
    include_query_string = optional(bool)

  }))
```

Default: `null`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description:   A map of role assignments to create on the <RESOURCE>. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `principal_id` - The ID of the principal to assign the role to.
  - `description` - (Optional) The description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `condition` - (Optional) The condition which will be used to scope the role assignment.
  - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
  - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

  > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

Type:

```hcl
map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_sku"></a> [sku](#input\_sku)

Description: The application gateway sku and tier.

Type:

```hcl
object({
    name     = string              # Standard_Small, Standard_Medium, Standard_Large, Standard_v2, WAF_Medium, WAF_Large, and WAF_v2
    tier     = string              # Standard, Standard_v2, WAF and WAF_v2
    capacity = optional(number, 2) # V1 SKU this value must be between 1 and 32, and 1 to 125 for a V2 SKU
  })
```

Default:

```json
{
  "capacity": 2,
  "name": "Standard_v2",
  "tier": "Standard_v2"
}
```

### <a name="input_ssl_certificates"></a> [ssl\_certificates](#input\_ssl\_certificates)

Description: List of SSL certificates data for Application gateway

Type:

```hcl
list(object({
    name                = string
    data                = optional(string)
    password            = optional(string)
    key_vault_secret_id = optional(string)
  }))
```

Default: `[]`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: A map of tags to apply to the Application Gateway.

Type: `map(string)`

Default: `null`

### <a name="input_url_path_map_configurations"></a> [url\_path\_map\_configurations](#input\_url\_path\_map\_configurations)

Description: List of URL path map configurations.

Type:

```hcl
map(object({
    name                                = string
    default_redirect_configuration_name = optional(string)
    default_rewrite_rule_set_name       = optional(string)
    default_backend_http_settings_name  = optional(string)
    default_backend_address_pool_name   = optional(string)
    path_rules = map(object({
      name                        = string
      paths                       = list(string)
      backend_address_pool_name   = optional(string)
      backend_http_settings_name  = optional(string)
      redirect_configuration_name = optional(string)
      rewrite_rule_set_name       = optional(string)
      firewall_policy_id          = optional(string)
    }))
  }))
```

Default: `null`

### <a name="input_waf_configuration"></a> [waf\_configuration](#input\_waf\_configuration)

Description: Web Application Firewall (WAF) configuration.

Type:

```hcl
list(object({
    enabled          = bool
    firewall_mode    = string
    rule_set_type    = string
    rule_set_version = string
    # disabled_rule_groups = list(string)
  }))
```

Default: `null`

### <a name="input_zones"></a> [zones](#input\_zones)

Description: The Azure application gateway zone redundancy

Type: `list(string)`

Default:

```json
[
  "1",
  "2",
  "3"
]
```

## Outputs

The following outputs are exported:

### <a name="output_application_gateway_id"></a> [application\_gateway\_id](#output\_application\_gateway\_id)

Description: The ID of the Azure Application Gateway.

### <a name="output_application_gateway_name"></a> [application\_gateway\_name](#output\_application\_gateway\_name)

Description: The name of the Azure Application Gateway.

### <a name="output_backend_address_pools"></a> [backend\_address\_pools](#output\_backend\_address\_pools)

Description: Information about the backend address pools configured for the Application Gateway, including their names.

### <a name="output_backend_http_settings"></a> [backend\_http\_settings](#output\_backend\_http\_settings)

Description: Information about the backend HTTP settings for the Application Gateway, including settings like port and protocol.

### <a name="output_backend_http_settings_debug"></a> [backend\_http\_settings\_debug](#output\_backend\_http\_settings\_debug)

Description: Outputs the entire backend\_http\_settings for debugging purposes

### <a name="output_frontend_port"></a> [frontend\_port](#output\_frontend\_port)

Description: Information about the frontend ports used by the Application Gateway, including their names and port numbers.

### <a name="output_http_listeners"></a> [http\_listeners](#output\_http\_listeners)

Description: Information about the HTTP listeners configured for the Application Gateway, including their names and settings.

### <a name="output_probes"></a> [probes](#output\_probes)

Description: Information about health probes configured for the Application Gateway, including their settings.

### <a name="output_public_ip_address"></a> [public\_ip\_address](#output\_public\_ip\_address)

Description: The actual public IP address associated with the Public IP resource.

### <a name="output_public_ip_id"></a> [public\_ip\_id](#output\_public\_ip\_id)

Description: The ID of the Azure Public IP address associated with the Application Gateway.

### <a name="output_request_routing_rules"></a> [request\_routing\_rules](#output\_request\_routing\_rules)

Description: Information about request routing rules defined for the Application Gateway, including their names and configurations.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: Resource ID of Container Group Instance

### <a name="output_ssl_certificates"></a> [ssl\_certificates](#output\_ssl\_certificates)

Description: Information about SSL certificates used by the Application Gateway, including their names and other details.

### <a name="output_tags"></a> [tags](#output\_tags)

Description: The tags applied to the Application Gateway.

### <a name="output_waf_configuration"></a> [waf\_configuration](#output\_waf\_configuration)

Description: Information about the Web Application Firewall (WAF) configuration, if applicable.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->