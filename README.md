<!-- BEGIN_TF_DOCS -->
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

**[Application Gateway Route web traffic based on the URL ](examples/simple\_http\_route\_by\_url\_app\_gateway/README.md)**
Route web traffic based on the URL set up and configure Application Gateway routing for different types of traffic from your application. The routing then directs the traffic to different server pools based on the URL.

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

```hcl
# TODO: insert resources here.

#----------About Terraform Module  -------------
# Azure Application Gateway Terraform Module
# Azure Application Gateway is a load balancer that enables you to manage and optimize the traffic to your web applications. 
# When using Terraform to deploy Azure resources, you can make use of a Terraform module to define and configure the Azure Application Gateway. 
#----------All Required Provider Section----------- 


#----------Local declarations-----------
locals {
  frontend_ip_configuration_name = "appgw-${var.name}-fepip"
  frontend_ip_private_name       = "appgw-${var.name}-fepvt-ip"
  frontend_port_name             = "appgw-${var.name}-feport"
  gateway_ip_configuration_name  = "appgw-${var.name}-gwipc"
}

#----------Frontend Subnet Selection Data block-----------
data "azurerm_subnet" "this" {
  name                 = var.subnet_name_backend
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
}

#----------Public IP for application gateway-----------
resource "azurerm_public_ip" "this" {
  allocation_method   = var.sku.tier == "Standard" ? "Dynamic" : "Static" # Allocation method for the public ip //var.public_ip_allocation_method
  location            = var.location
  name                = var.public_ip_name
  resource_group_name = var.resource_group_name
  sku                 = var.sku.tier == "Standard" ? "Basic" : "Standard" # SKU for the public ip //var.public_ip_sku_tier
  zones               = var.zones
}

#----------Application Gateway resource creation provider block-----------
resource "azurerm_application_gateway" "this" {
  location = var.location
  #----------Basic configuration for the application gateway-----------
  name                              = var.name
  resource_group_name               = var.resource_group_name
  enable_http2                      = var.http2_enable
  firewall_policy_id                = var.app_gateway_waf_policy_resource_id
  force_firewall_policy_association = true
  #----------Tag configuration for the application gateway-----------
  tags  = var.tags
  zones = var.zones

  #----------Backend Address Pool Configuration for the application gateway -----------
  dynamic "backend_address_pool" {
    for_each = var.backend_address_pools
    content {
      name         = backend_address_pool.value.name
      fqdns        = backend_address_pool.value.fqdns != null ? backend_address_pool.value.fqdns : null
      ip_addresses = backend_address_pool.value.ip_addresses != null ? backend_address_pool.value.ip_addresses : null
    }
  }
  #----------Backend Http Settings Configuration for the application gateway -----------
  dynamic "backend_http_settings" {
    for_each = var.backend_http_settings
    content {
      cookie_based_affinity               = lookup(backend_http_settings.value, "cookie_based_affinity", "Disabled")
      name                                = backend_http_settings.value.name
      port                                = backend_http_settings.value.enable_https ? 443 : 80
      protocol                            = backend_http_settings.value.enable_https ? "Https" : "Http"
      affinity_cookie_name                = lookup(backend_http_settings.value, "affinity_cookie_name", null)
      host_name                           = backend_http_settings.value.pick_host_name_from_backend_address == false ? lookup(backend_http_settings.value, "host_name") : null
      path                                = lookup(backend_http_settings.value, "path", "/")
      pick_host_name_from_backend_address = lookup(backend_http_settings.value, "pick_host_name_from_backend_address", false)
      probe_name                          = lookup(backend_http_settings.value, "probe_name", null)
      request_timeout                     = lookup(backend_http_settings.value, "request_timeout", 30)
      trusted_root_certificate_names      = lookup(backend_http_settings.value, "trusted_root_certificate_names", null)

      dynamic "authentication_certificate" {
        for_each = backend_http_settings.value.authentication_certificate[*]
        content {
          name = authentication_certificate.value.name
        }
      }
      dynamic "connection_draining" {
        for_each = backend_http_settings.value.connection_draining[*]
        content {
          drain_timeout_sec = connection_draining.value.drain_timeout_sec
          enabled           = connection_draining.value.enable_connection_draining
        }
      }
    }
  }
  # Public frontend IP configuration
  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.this.id
  }
  # Private frontend IP configuration
  dynamic "frontend_ip_configuration" {
    for_each = var.frontend_ip_type != null && var.private_ip_address != null ? [1] : []
    content {
      name                          = local.frontend_ip_private_name
      private_ip_address            = var.private_ip_address != null ? var.private_ip_address : null
      private_ip_address_allocation = var.private_ip_address != null ? "Static" : null
      subnet_id                     = var.private_ip_address != null ? data.azurerm_subnet.this.id : null
    }
  }
  # Private frontend IP Port configuration
  dynamic "frontend_port" {
    for_each = var.frontend_ports
    content {
      name = lookup(frontend_port.value, "name", null)
      port = lookup(frontend_port.value, "port", null)
    }
  }
  #----------Frontend configuration for the application gateway-----------
  gateway_ip_configuration {
    name      = local.gateway_ip_configuration_name
    subnet_id = data.azurerm_subnet.this.id
  }
  #----------Http Listener Configuration for the application gateway -----------
  dynamic "http_listener" {
    for_each = var.http_listeners
    content {
      frontend_ip_configuration_name = var.frontend_ip_type != null && var.private_ip_address != null ? local.frontend_ip_private_name : local.frontend_ip_configuration_name
      frontend_port_name             = lookup(http_listener.value, "frontend_port_name", null)
      name                           = http_listener.value.name
      protocol                       = http_listener.value.ssl_certificate_name == null ? "Http" : "Https"
      firewall_policy_id             = http_listener.value.firewall_policy_id != null ? http_listener.value.firewall_policy_id : null
      host_name                      = http_listener.value.host_name != null ? http_listener.value.host_name : null
      host_names                     = http_listener.value.host_names != null ? http_listener.value.host_names : null
      require_sni                    = http_listener.value.ssl_certificate_name != null ? http_listener.value.require_sni : null
      ssl_certificate_name           = http_listener.value.ssl_certificate_name != null ? http_listener.value.ssl_certificate_name : null
      ssl_profile_name               = http_listener.value.ssl_profile_name != null ? http_listener.value.ssl_profile_name : null

      dynamic "custom_error_configuration" {
        for_each = http_listener.value.custom_error_configuration != null ? lookup(http_listener.value, "custom_error_configuration", {}) : []
        content {
          custom_error_page_url = lookup(custom_error_configuration.value, "custom_error_page_url", null)
          status_code           = lookup(custom_error_configuration.value, "status_code", null)
        }
      }
    }
  }
  #----------Rules Configuration for the application gateway -----------
  dynamic "request_routing_rule" {
    for_each = var.request_routing_rules
    content {
      http_listener_name          = request_routing_rule.value.http_listener_name
      name                        = request_routing_rule.value.name
      rule_type                   = lookup(request_routing_rule.value, "rule_type", "Basic")
      backend_address_pool_name   = request_routing_rule.value.redirect_configuration_name == null ? lookup(request_routing_rule.value, "backend_address_pool_name", null) : null
      backend_http_settings_name  = request_routing_rule.value.redirect_configuration_name == null ? lookup(request_routing_rule.value, "backend_http_settings_name", null) : null
      priority                    = lookup(request_routing_rule.value, "priority", 100)
      redirect_configuration_name = lookup(request_routing_rule.value, "redirect_configuration_name", null)
      rewrite_rule_set_name       = lookup(request_routing_rule.value, "rewrite_rule_set_name", null)
      url_path_map_name           = lookup(request_routing_rule.value, "url_path_map_name", null)
    }
  }
  #----------SKU and configuration for the application gateway-----------
  sku {
    name     = var.sku.name
    tier     = var.sku.tier
    capacity = var.autoscale_configuration == null ? var.sku.capacity : null
  }
  dynamic "autoscale_configuration" {
    for_each = var.autoscale_configuration != null ? [var.autoscale_configuration] : []
    content {
      min_capacity = lookup(autoscale_configuration.value, "min_capacity")
      max_capacity = lookup(autoscale_configuration.value, "max_capacity")
    }
  }
  # Check if key_vault_secret_id is not null, and include the identity block accordingly
  #----------Optionl Configuration  -----------
  dynamic "identity" {
    for_each = length(var.ssl_certificates) > 0 ? [1] : []
    content {
      identity_ids = var.identity_ids[0].identity_ids
      type         = "UserAssigned"
    }
  }
  #----------Prod Rules Configuration for the application gateway -----------
  #----------Optionl Configuration  -----------
  dynamic "probe" {
    for_each = var.probe_configurations != null ? var.probe_configurations : {}
    content {
      interval                                  = lookup(probe.value, "interval", 5)
      name                                      = probe.value.name
      path                                      = lookup(probe.value, "path", "/")
      protocol                                  = lookup(probe.value, "protocol", null)
      timeout                                   = lookup(probe.value, "timeout", 30)
      unhealthy_threshold                       = lookup(probe.value, "unhealthy_threshold", 2)
      host                                      = lookup(probe.value, "host", "127.0.0.1")
      minimum_servers                           = lookup(probe.value, "minimum_servers", 0)
      pick_host_name_from_backend_http_settings = lookup(probe.value, "pick_host_name_from_backend_http_settings", false)
      port                                      = lookup(probe.value, "port", 80)
    }
  }
  #----------Redirect Configuration for the application gateway -----------
  #----------Optionl Configuration  -----------
  dynamic "redirect_configuration" {
    for_each = var.redirect_configuration != null ? var.redirect_configuration : {}
    content {
      name                 = lookup(redirect_configuration.value, "name", null)
      redirect_type        = lookup(redirect_configuration.value, "redirect_type", "Permanent")
      include_path         = lookup(redirect_configuration.value, "include_path", true)
      include_query_string = lookup(redirect_configuration.value, "include_query_string", true)
      target_listener_name = contains(keys(redirect_configuration.value), "target_listener_name") ? redirect_configuration.value.target_listener_name : null
      target_url           = contains(keys(redirect_configuration.value), "target_url") ? redirect_configuration.value.target_url : null
    }
  }
  #----------SSL Certificate Configuration for the application gateway -----------
  #----------Optionl Configuration  -----------
  dynamic "ssl_certificate" {
    for_each = var.ssl_certificates
    content {
      name                = ssl_certificate.value.name
      data                = ssl_certificate.value.key_vault_secret_id == null ? ssl_certificate.value.data : null
      key_vault_secret_id = lookup(ssl_certificate.value, "key_vault_secret_id", null)
      password            = ssl_certificate.value.key_vault_secret_id == null ? ssl_certificate.value.password : null
    }
  }
  dynamic "url_path_map" {
    for_each = var.url_path_map_configurations != null ? var.url_path_map_configurations : {}

    content {
      name                                = url_path_map.value.name
      default_backend_address_pool_name   = url_path_map.value.default_backend_address_pool_name
      default_backend_http_settings_name  = url_path_map.value.default_backend_http_settings_name
      default_redirect_configuration_name = url_path_map.value.default_redirect_configuration_name
      default_rewrite_rule_set_name       = url_path_map.value.default_rewrite_rule_set_name

      dynamic "path_rule" {
        for_each = url_path_map.value.path_rules != null ? url_path_map.value.path_rules : {}

        content {
          name                        = path_rule.value.name
          paths                       = path_rule.value.paths
          backend_address_pool_name   = path_rule.value.backend_address_pool_name
          backend_http_settings_name  = path_rule.value.backend_http_settings_name
          firewall_policy_id          = path_rule.value.firewall_policy_id
          redirect_configuration_name = path_rule.value.redirect_configuration_name
          rewrite_rule_set_name       = path_rule.value.rewrite_rule_set_name
        }
      }
    }
  }
  #----------Classic WAF Configuration for the application gateway -----------
  #----------Optionl Configuration  -----------
  dynamic "waf_configuration" {

    for_each = var.sku.name == "WAF_v2" && var.enable_classic_rule == true != null ? [1] : []

    content {
      enabled          = var.waf_configuration[0].enabled
      firewall_mode    = var.waf_configuration[0].firewall_mode
      rule_set_version = var.waf_configuration[0].rule_set_version
      rule_set_type    = var.waf_configuration[0].rule_set_type
    }
  }

  depends_on = [azurerm_public_ip.this]
}

#----------lock settings for the application gateway -----------
#----------Optionl Configuration  -----------
resource "azurerm_management_lock" "this" {
  count = var.lock.kind != "None" ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.name}")
  scope      = azurerm_application_gateway.this.id
}

#----------role assignment settings for the application gateway -----------
resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azurerm_application_gateway.this.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

#----------Diagnostic logs settings for the application gateway -----------
resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.diagnostic_settings

  name                           = each.value.name != null ? each.value.name : "diag-${var.name}"
  target_resource_id             = azurerm_application_gateway.this.id
  eventhub_authorization_rule_id = each.value.event_hub_authorization_rule_resource_id
  eventhub_name                  = each.value.event_hub_name
  log_analytics_destination_type = each.value.log_analytics_destination_type
  log_analytics_workspace_id     = each.value.workspace_resource_id
  partner_solution_id            = each.value.marketplace_partner_resource_id
  storage_account_id             = each.value.storage_account_resource_id

  dynamic "enabled_log" {
    for_each = each.value.log_categories
    content {
      category = enabled_log.value
    }
  }
  dynamic "enabled_log" {
    for_each = each.value.log_groups
    content {
      category_group = enabled_log.value
    }
  }
  dynamic "metric" {
    for_each = each.value.metric_categories
    content {
      category = metric.value
    }
  }
}

# Other configurations for your environment
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.0.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.71.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>= 3.71.0)

- <a name="provider_random"></a> [random](#provider\_random) (>= 3.5.0)

## Resources

The following resources are used by this module:

- [azurerm_application_gateway.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway) (resource)
- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_monitor_diagnostic_setting.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) (resource)
- [azurerm_public_ip.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) (resource)
- [azurerm_resource_group_template_deployment.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_template_deployment) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [random_id.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) (resource)
- [azurerm_subnet.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) (data source)

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

### <a name="input_app_gateway_waf_policy_resource_id"></a> [app\_gateway\_waf\_policy\_resource\_id](#input\_app\_gateway\_waf\_policy\_resource\_id)

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
    min_capacity = optional(number, 1) // Minimum in the range 0 to 100
    max_capacity = optional(number, 2) // Maximum in the range 2 to 125
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

Type: `any`

Default: `null`

### <a name="input_lock"></a> [lock](#input\_lock)

Description: The lock level to apply to the deployed resource. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.

Type:

```hcl
object({
    name = optional(string, null)
    kind = optional(string, "None")
  })
```

Default: `{}`

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

### <a name="input_public_ip_allocation_method"></a> [public\_ip\_allocation\_method](#input\_public\_ip\_allocation\_method)

Description: The Azure public allocation method dynamic / static

Type: `string`

Default: `"Static"`

### <a name="input_public_ip_sku_tier"></a> [public\_ip\_sku\_tier](#input\_public\_ip\_sku\_tier)

Description: The Azure public ip sku Basic / Standard

Type: `string`

Default: `"Standard"`

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

Description:  A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.

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
  }))
```

Default: `{}`

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
map(object({
    disabled_protocols   = optional(list(string))
    policy_type          = optional(string)
    policy_name          = optional(string)
    cipher_suites        = optional(list(string))
    min_protocol_version = optional(string)
  }))
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

### <a name="input_waf_enable"></a> [waf\_enable](#input\_waf\_enable)

Description: Enable or disable the Web Application Firewall

Type: `bool`

Default: `true`

### <a name="input_zones"></a> [zones](#input\_zones)

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