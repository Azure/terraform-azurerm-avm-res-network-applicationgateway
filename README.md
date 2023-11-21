<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-template

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

**[Simple HTTP Application Gateway](examples/simple\_http\_app\_gateway/README.md)**
This scenario sets up a straightforward HTTP Application Gateway, typically for basic web applications or services.

**[Web Application Firewall (WAF)](examples/simple\_waf\_http\_app\_gateway/README.md)**
A Web Application Firewall is employed to enhance security by inspecting and filtering traffic. Configuration entails defining custom rules and policies to protect against common web application vulnerabilities.

**[Self-Signed SSL (HTTPS)](examples/simple\_http\_app\_gateway/README.md)**
In this scenario, self-signed SSL certificates are utilized to secure traffic to HTTPS. You'll need to configure SSL certificates and redirection rules.

**[SSL with Azure Key Vault](examples/kv\_selfssl\_waf\_https\_app\_gateway/README.md)**
For enhanced security, SSL certificates are managed using Azure Key Vault. This scenario involves setting up Key Vault and integrating it with the Application Gateway. Detailed configuration for Key Vault and SSL certificates is necessary.

Before running the script, make sure you have logged in to your Azure subscription using the Azure CLI or Azure PowerShell, so Terraform can authenticate and interact with your Azure account.

Please ensure that you have a clear plan and architecture for your Azure Application Gateway, as the Terraform script should align with your specific requirements and network design.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.0.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.71.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (3.78.0)

- <a name="provider_random"></a> [random](#provider\_random) (3.5.1)

## Resources

The following resources are used by this module:

- [azurerm_application_gateway.application_gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway) (resource)
- [azurerm_monitor_diagnostic_setting.diagnostic_setting_for_app_gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) (resource)
- [azurerm_monitor_diagnostic_setting.diagnostic_setting_for_public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) (resource)
- [azurerm_public_ip.public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) (resource)
- [azurerm_resource_group_template_deployment.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_template_deployment) (resource)
- [random_id.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) (resource)
- [azurerm_subnet.subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_app_gateway_name"></a> [app\_gateway\_name](#input\_app\_gateway\_name)

Description: The name of the application gateway.

Type: `string`

### <a name="input_backend_address_pools"></a> [backend\_address\_pools](#input\_backend\_address\_pools)

Description: List of backend address pools

Type:

```hcl
list(object({
    name         = string
    fqdns        = optional(list(string))
    ip_addresses = optional(list(string))
  }))
```

### <a name="input_backend_http_settings"></a> [backend\_http\_settings](#input\_backend\_http\_settings)

Description: List of backend HTTP settings

Type:

```hcl
list(object({
    name                  = string
    port                  = number
    protocol              = string
    cookie_based_affinity = string
    # affinity_cookie_name  = optional(string)
    # enable_https = bool

    # Define other attributes as needed
  }))
```

### <a name="input_http_listeners"></a> [http\_listeners](#input\_http\_listeners)

Description: List of HTTP listeners

Type:

```hcl
list(object({
    name                   = string
    frontend_port_name     = string
    protocol               = string
    firewall_policy_id     = optional(string)
    frontend_ip_assocation = string
    host_name              = optional(string)
    host_names             = optional(list(string))
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

### <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id)

Description: The Log Analytics Workspace ID

Type: `string`

### <a name="input_public_ip_name"></a> [public\_ip\_name](#input\_public\_ip\_name)

Description: The name of the application gateway.

Type: `string`

### <a name="input_request_routing_rules"></a> [request\_routing\_rules](#input\_request\_routing\_rules)

Description: List of request routing rules

Type:

```hcl
list(object({
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

### <a name="input_sku"></a> [sku](#input\_sku)

Description: The application gateway sku and tier.

Type:

```hcl
object({
    name     = string           // Standard_Small, Standard_Medium, Standard_Large, Standard_v2, WAF_Medium, WAF_Large, and WAF_v2
    tier     = string           // Standard, Standard_v2, WAF and WAF_v2
    capacity = optional(number) // V1 SKU this value must be between 1 and 32, and 1 to 125 for a V2 SKU
  })
```

### <a name="input_subnet_name_backend"></a> [subnet\_name\_backend](#input\_subnet\_name\_backend)

Description: The backend subnet where the applicaiton gateway resources configuration will be deployed.

Type: `string`

### <a name="input_subnet_name_frontend"></a> [subnet\_name\_frontend](#input\_subnet\_name\_frontend)

Description: The frontend subnet where the applicaiton gateway IP address resources will be deployed.

Type: `string`

### <a name="input_vnet_name"></a> [vnet\_name](#input\_vnet\_name)

Description: The VNET where the applicaiton gateway resources will be deployed.

Type: `any`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_app_gateway_waf_policy_name"></a> [app\_gateway\_waf\_policy\_name](#input\_app\_gateway\_waf\_policy\_name)

Description: n/a

Type: `string`

Default: `null`

### <a name="input_authentication_certificates"></a> [authentication\_certificates](#input\_authentication\_certificates)

Description: Authentication certificates to allow the backend with Azure Application Gateway

Type:

```hcl
list(object({
    name = string
    data = string
  }))
```

Default: `[]`

### <a name="input_autoscale_configuration"></a> [autoscale\_configuration](#input\_autoscale\_configuration)

Description: V1 SKU this value must be between 1 and 32, and 1 to 125 for a V2 SKU

Type:

```hcl
object({
    min_capacity = number           // Minimum in the range 0 to 100
    max_capacity = optional(number) // Maximum in the range 2 to 125
  })
```

Default: `null`

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

### <a name="input_http2_enable"></a> [http2\_enable](#input\_http2\_enable)

Description: The Azure application gateway HTTP/2 protocol support

Type: `bool`

Default: `true`

### <a name="input_identity_ids"></a> [identity\_ids](#input\_identity\_ids)

Description: Specifies a list with a single user managed identity id to be assigned to the Application Gateway

Type: `any`

Default: `null`

### <a name="input_private_ip_address"></a> [private\_ip\_address](#input\_private\_ip\_address)

Description: Private IP Address to assign to the Application Gateway Load Balancer.

Type: `string`

Default: `null`

### <a name="input_probe_configurations"></a> [probe\_configurations](#input\_probe\_configurations)

Description: List of probe configurations.

Type:

```hcl
list(object({
    name                                      = string
    host                                      = optional(string)
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

Default: `[]`

### <a name="input_public_ip_allocation_method"></a> [public\_ip\_allocation\_method](#input\_public\_ip\_allocation\_method)

Description: The Azure public allocation method dynamic / static

Type: `string`

Default: `"Static"`

### <a name="input_public_ip_sku_tier"></a> [public\_ip\_sku\_tier](#input\_public\_ip\_sku\_tier)

Description: The Azure public ip sku Basic / Standard

Type: `string`

Default: `"Standard"`

### <a name="input_redirection_configurations"></a> [redirection\_configurations](#input\_redirection\_configurations)

Description: List of redirection configurations.

Type:

```hcl
list(object({
    name                 = string
    redirect_type        = string
    target_url           = string
    include_path         = optional(bool)
    include_query_string = optional(bool)

  }))
```

Default: `[]`

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

### <a name="input_ssl_policy"></a> [ssl\_policy](#input\_ssl\_policy)

Description: Application Gateway SSL configuration

Type:

```hcl
object({
    disabled_protocols   = optional(list(string))
    policy_type          = optional(string)
    policy_name          = optional(string)
    cipher_suites        = optional(list(string))
    min_protocol_version = optional(string)
  })
```

Default: `null`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: A map of tags to apply to the Application Gateway.

Type: `map(string)`

Default:

```json
{
  "environment": "development",
  "owner": "your-name",
  "project": "my-project"
}
```

### <a name="input_trusted_root_certificates"></a> [trusted\_root\_certificates](#input\_trusted\_root\_certificates)

Description: Trusted root certificates to allow the backend with Azure Application Gateway

Type:

```hcl
list(object({
    name = string
    data = string
  }))
```

Default: `[]`

### <a name="input_url_path_map_configurations"></a> [url\_path\_map\_configurations](#input\_url\_path\_map\_configurations)

Description: List of URL path map configurations.

Type:

```hcl
list(object({
    name                                = string
    default_redirect_configuration_name = optional(string)
    default_rewrite_rule_set_name       = optional(string)
    default_backend_http_settings_name  = optional(string)
    default_backend_address_pool_name   = optional(string)
    path_rules = list(object({
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

Default: `[]`

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

### <a name="input_waf_enable"></a> [waf\_enable](#input\_waf\_enable)

Description: Enable or disable the Web Application Firewall

Type: `bool`

Default: `true`

### <a name="input_zone_redundant"></a> [zone\_redundant](#input\_zone\_redundant)

Description: The Azure application gateway zone redundancy

Type: `list(string)`

Default: `[]`

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

### <a name="output_diagnostic_setting_for_app_gateway_id"></a> [diagnostic\_setting\_for\_app\_gateway\_id](#output\_diagnostic\_setting\_for\_app\_gateway\_id)

Description: The ID of the diagnostic settings for the Application Gateway.

### <a name="output_diagnostic_setting_for_public_ip_id"></a> [diagnostic\_setting\_for\_public\_ip\_id](#output\_diagnostic\_setting\_for\_public\_ip\_id)

Description: The ID of the diagnostic settings for the associated Public IP address.

### <a name="output_frontend_port"></a> [frontend\_port](#output\_frontend\_port)

Description: Information about the frontend ports used by the Application Gateway, including their names and port numbers.

### <a name="output_http_listeners"></a> [http\_listeners](#output\_http\_listeners)

Description: Information about the HTTP listeners configured for the Application Gateway, including their names and settings.

### <a name="output_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#output\_log\_analytics\_workspace\_id)

Description: The ID of the Azure Log Analytics workspace.

### <a name="output_probes"></a> [probes](#output\_probes)

Description: Information about health probes configured for the Application Gateway, including their settings.

### <a name="output_public_ip_address"></a> [public\_ip\_address](#output\_public\_ip\_address)

Description: The actual public IP address associated with the Public IP resource.

### <a name="output_public_ip_id"></a> [public\_ip\_id](#output\_public\_ip\_id)

Description: The ID of the Azure Public IP address associated with the Application Gateway.

### <a name="output_request_routing_rules"></a> [request\_routing\_rules](#output\_request\_routing\_rules)

Description: Information about request routing rules defined for the Application Gateway, including their names and configurations.

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