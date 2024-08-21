<!-- BEGIN_TF_DOCS -->
# Application Gateway with SSL with Azure Key Vault
For enhanced security, SSL certificates are managed using Azure Key Vault. This scenario involves setting up Key Vault and integrating it with the Application Gateway. Detailed configuration for Key Vault and SSL certificates is necessary.

# Default example

This deploys the module in its simplest form.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.5)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.0, < 4.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0, < 4.0.0)

## Resources

The following resources are used by this module:

- [azurerm_key_vault.keyvault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) (resource)
- [azurerm_key_vault_access_policy.appag_key_vault_access_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) (resource)
- [azurerm_key_vault_access_policy.key_vault_default_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) (resource)
- [azurerm_key_vault_certificate.ssl_cert_id](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_certificate) (resource)
- [azurerm_log_analytics_workspace.log_analytics_workspace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) (resource)
- [azurerm_resource_group.rg_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_subnet.backend](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet.frontend](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet.private_ip_test](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet.workload](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_user_assigned_identity.appag_umid](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) (resource)
- [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [azurerm_web_application_firewall_policy.azure_waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/web_application_firewall_policy) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see https://aka.ms/avm/telemetryinfo.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

## Outputs

The following outputs are exported:

### <a name="output_azurerm_key_vault_certificate_secret_id"></a> [azurerm\_key\_vault\_certificate\_secret\_id](#output\_azurerm\_key\_vault\_certificate\_secret\_id)

Description: n/a

### <a name="output_backend_subnet_id"></a> [backend\_subnet\_id](#output\_backend\_subnet\_id)

Description: ID of the Backend Subnet

### <a name="output_backend_subnet_name"></a> [backend\_subnet\_name](#output\_backend\_subnet\_name)

Description: Name of the Backend Subnet

### <a name="output_frontend_subnet_id"></a> [frontend\_subnet\_id](#output\_frontend\_subnet\_id)

Description: ID of the Frontend Subnet

### <a name="output_frontend_subnet_name"></a> [frontend\_subnet\_name](#output\_frontend\_subnet\_name)

Description: Name of the Frontend Subnet

### <a name="output_key_vault_id"></a> [key\_vault\_id](#output\_key\_vault\_id)

Description: ID of the Azure Key Vault

### <a name="output_private_ip_test_subnet_id"></a> [private\_ip\_test\_subnet\_id](#output\_private\_ip\_test\_subnet\_id)

Description: ID of the Private IP Test Subnet

### <a name="output_private_ip_test_subnet_name"></a> [private\_ip\_test\_subnet\_name](#output\_private\_ip\_test\_subnet\_name)

Description: Name of the Private IP Test Subnet

### <a name="output_resource_group_id"></a> [resource\_group\_id](#output\_resource\_group\_id)

Description: ID of the Azure Resource Group

### <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name)

Description: Name of the Azure Resource Group

### <a name="output_self_signed_certificate_id"></a> [self\_signed\_certificate\_id](#output\_self\_signed\_certificate\_id)

Description: ID of the self-signed SSL certificate in Azure Key Vault

### <a name="output_virtual_network_id"></a> [virtual\_network\_id](#output\_virtual\_network\_id)

Description: ID of the Azure Virtual Network

### <a name="output_virtual_network_name"></a> [virtual\_network\_name](#output\_virtual\_network\_name)

Description: Name of the Azure Virtual Network

### <a name="output_workload_subnet_id"></a> [workload\_subnet\_id](#output\_workload\_subnet\_id)

Description: ID of the Workload Subnet

### <a name="output_workload_subnet_name"></a> [workload\_subnet\_name](#output\_workload\_subnet\_name)

Description: Name of the Workload Subnet

## Modules

The following Modules are called:

### <a name="module_application_gateway"></a> [application\_gateway](#module\_application\_gateway)

Source: ../../

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: 0.3.0

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/regions/azurerm

Version: >= 0.3.0

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->