<!-- BEGIN_TF_DOCS -->
# Application Gateway with Self-Signed SSL (HTTPS)
In this scenario, self-signed SSL certificates are utilized to secure traffic to HTTPS. You'll need to configure SSL certificates and redirection rules.

# Default example

This deploys the module in its simplest form.

```hcl
#----------Testing Use Case  -------------
# Application Gateway + WAF Enable routing traffic from your application. 
# Assume that your Application runing the scale set contains two virtual machine instances. 
# The scale set is added to the default backend pool need to updated with IP or FQDN of the application gateway.
# The example input from https://learn.microsoft.com/en-us/azure/application-gateway/tutorial-manage-web-traffic-cli

#----------All Required Provider Section----------- 
terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0, < 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
  suffix  = ["agw"]
}

# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/regions/azurerm"
  version = ">= 0.3.0"

}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
module "application_gateway" {
  source = "../../"
  # source             = "Azure/terraform-azurerm-avm-res-network-applicationgateway"
  depends_on = [azurerm_virtual_network.vnet, azurerm_resource_group.rg_group]

  # pre-requisites resources input required for the module

  public_ip_name      = "${module.naming.public_ip.name_unique}-pip"
  resource_group_name = azurerm_resource_group.rg_group.name
  location            = azurerm_resource_group.rg_group.location
  vnet_name           = azurerm_virtual_network.vnet.name

  subnet_name_backend = azurerm_subnet.backend.name
  # log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace.id
  enable_telemetry = var.enable_telemetry

  # provide Application gateway name 
  name = module.naming.application_gateway.name_unique

  tags = {
    environment = "dev"
    owner       = "application_gateway"
    project     = "AVM"
  }

  lock = {
    name = "lock-${module.naming.application_gateway.name_unique}" # optional
    kind = "CanNotDelete"
  }
  # WAF : Azure Application Gateways v2 are always deployed in a highly available fashion with multiple instances by default. Enabling autoscale ensures the service is not reliant on manual intervention for scaling.
  sku = {
    # Accpected value for names Standard_v2 and WAF_v2
    name = "WAF_v2"
    # Accpected value for tier Standard_v2 and WAF_v2
    tier = "WAF_v2"
    # Accpected value for capacity 1 to 10 for a V1 SKU, 1 to 100 for a V2 SKU
    capacity = 0 # Set the initial capacity to 0 for autoscaling
  }

  autoscale_configuration = {
    min_capacity = 1
    max_capacity = 2
  }

  # frontend port configuration block for the application gateway
  # WAF : Secure all incoming connections using HTTPS for production services with end-to-end SSL/TLS or SSL/TLS termination at the Application Gateway to protect against attacks and ensure data remains private and encrypted between the web server and browsers.

  frontend_ports = {
    frontend-port-443 = {
      name = "frontend-port-443"
      port = 443
    }
  }

  # Backend address pool configuration for the application gateway
  # Mandatory Input
  backend_address_pools = {
    appGatewayBackendPool = {
      name = "appGatewayBackendPool"
      # ip_addresses = ["100.64.2.6", "100.64.2.5"]
      #fqdns        = ["example1.com", "example2.com"]
    }
  }

  # Backend http settings configuration for the application gateway
  # Mandatory Input
  backend_http_settings = {

    appGatewayBackendHttpSettings = {
      name                  = "appGatewayBackendHttpSettings"
      cookie_based_affinity = "Disabled"
      path                  = "/"
      enable_https          = false
      request_timeout       = 30
      connection_draining = {
        enable_connection_draining = true
        drain_timeout_sec          = 300

      }
    }
    # Add more http settings as needed
  }

  # Http Listerners configuration for the application gateway
  # Mandatory Input
  http_listeners = {
    appGatewayHttpListener = {
      name                 = "appGatewayHttpListener"
      host_name            = null
      frontend_port_name   = "frontend-port-443"
      ssl_certificate_name = "app-gateway-cert"
    }
    # # Add more http listeners as needed
  }

  # WAF : Use Application Gateway with Web Application Firewall (WAF) in an application virtual network to safeguard inbound HTTP/S internet traffic. WAF offers centralized defense against potential exploits through OWASP core rule sets-based rules.
  # To Enable Web Application Firewall policies set enable_classic_rule = false and provide the WAF configuration block.
  # Ensure that you have a WAF policy created before enabling WAF on the Application Gateway

  app_gateway_waf_policy_resource_id = azurerm_web_application_firewall_policy.azure_waf.id
  enable_classic_rule                = false
  waf_configuration = [
    {
      enabled          = true
      firewall_mode    = "Prevention"
      rule_set_type    = "OWASP"
      rule_set_version = "3.1"
    }
  ]

  # Routing rules configuration for the backend pool
  # Mandatory Input
  request_routing_rules = {
    routing-rule-1 = {
      name                       = "rule-1"
      rule_type                  = "Basic"
      http_listener_name         = "appGatewayHttpListener"
      backend_address_pool_name  = "appGatewayBackendPool"
      backend_http_settings_name = "appGatewayBackendHttpSettings"
      priority                   = 100
    }
    # Add more rules as needed
  }

  # SSL Certificate Block
  ssl_certificates = [{
    name     = "app-gateway-cert"
    data     = filebase64("./ssl_cert_generate/certificate.pfx")
    password = "terraform-avm"
  }]

  # HTTP to HTTPS Redirection Configuration for

  redirect_configuration = {
    redirect_config_1 = {
      name                 = "Redirect1"
      redirect_type        = "Permanent"
      include_path         = true
      include_query_string = true
      target_listener_name = "appGatewayHttpListener"
    }
  }

  # Optional Input  
  # Zone redundancy for the application gateway ["1", "2", "3"] 
  zones = ["1", "2", "3"]

  identity_ids = [
    azurerm_user_assigned_identity.appag_umid.id # This should be a list of strings, not a list of objects.
  ]
  diagnostic_settings = {
    example_setting = {
      name                           = "${module.naming.application_gateway.name_unique}-diagnostic-setting"
      workspace_resource_id          = azurerm_log_analytics_workspace.log_analytics_workspace.id
      log_analytics_destination_type = "Dedicated" # Or "AzureDiagnostics"
      # log_categories                 = ["Application Gateway Access Log", "Application Gateway Performance Log", "Application Gateway Firewall Log"]
      log_groups        = ["allLogs"]
      metric_categories = ["AllMetrics"]
    }
  }

}



```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.5)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.0, < 4.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0, < 4.0.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>= 3.0, < 4.0)

- <a name="provider_random"></a> [random](#provider\_random) (>= 3.5.0, < 4.0.0)

## Resources

The following resources are used by this module:

- [azurerm_bastion_host.bastion_host](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/bastion_host) (resource)
- [azurerm_linux_virtual_machine_scale_set.app_gateway_web_vmss](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine_scale_set) (resource)
- [azurerm_log_analytics_workspace.log_analytics_workspace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) (resource)
- [azurerm_network_interface.bastion_win_vm_nic](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) (resource)
- [azurerm_network_security_group.ag_subnet_nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) (resource)
- [azurerm_network_security_rule.ag_nsg_rule_inbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) (resource)
- [azurerm_public_ip.bastion_public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) (resource)
- [azurerm_resource_group.rg_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_subnet.backend](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet.bastion](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet.frontend](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet.private_ip_test](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet.workload](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet_network_security_group_association.ag_subnet_nsg_associate](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) (resource)
- [azurerm_user_assigned_identity.appag_umid](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) (resource)
- [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [azurerm_web_application_firewall_policy.azure_waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/web_application_firewall_policy) (resource)
- [azurerm_windows_virtual_machine.bastion](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)

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

### <a name="output_backend_subnet_id"></a> [backend\_subnet\_id](#output\_backend\_subnet\_id)

Description: ID of the Backend Subnet

### <a name="output_backend_subnet_name"></a> [backend\_subnet\_name](#output\_backend\_subnet\_name)

Description: Name of the Backend Subnet

### <a name="output_frontend_subnet_id"></a> [frontend\_subnet\_id](#output\_frontend\_subnet\_id)

Description: ID of the Frontend Subnet

### <a name="output_frontend_subnet_name"></a> [frontend\_subnet\_name](#output\_frontend\_subnet\_name)

Description: Name of the Frontend Subnet

### <a name="output_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#output\_log\_analytics\_workspace\_id)

Description: ID of the Azure Log Analytics Workspace

### <a name="output_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#output\_log\_analytics\_workspace\_name)

Description: Name of the Azure Log Analytics Workspace

### <a name="output_private_ip_test_subnet_id"></a> [private\_ip\_test\_subnet\_id](#output\_private\_ip\_test\_subnet\_id)

Description: ID of the Private IP Test Subnet

### <a name="output_private_ip_test_subnet_name"></a> [private\_ip\_test\_subnet\_name](#output\_private\_ip\_test\_subnet\_name)

Description: Name of the Private IP Test Subnet

### <a name="output_resource_group_id"></a> [resource\_group\_id](#output\_resource\_group\_id)

Description: ID of the Azure Resource Group

### <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name)

Description: Name of the Azure Resource Group

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