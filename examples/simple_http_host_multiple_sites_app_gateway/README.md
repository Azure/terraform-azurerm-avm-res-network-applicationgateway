<!-- BEGIN_TF_DOCS -->
# Multi-site HTTP Application Gateway

Multi-site hosting enables you to configure more than one web application on the same port of application gateways using public-facing listeners. It allows you to configure a more efficient topology for your deployments by adding up to 100+ websites to one application gateway. Each website can be directed to its own backend pool. For example, three domains, contoso.com, fabrikam.com, and adatum.com, point to the IP address of the application gateway. You'd create three multi-site listeners and configure each listener for the respective port and protocol setting.

# Default example

This deploys the module in its simplest form.

```hcl
#----------Testing Use Case  -------------
# Create an application gateway that hosts multiple web sites. 
# 
# The input from https://learn.microsoft.com/en-us/azure/application-gateway/tutorial-multiple-sites-cli
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
  source     = "../../"
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
    name = "Standard_v2"
    # Accpected value for tier Standard_v2 and WAF_v2
    tier = "Standard_v2"
    # Accpected value for capacity 1 to 10 for a V1 SKU, 1 to 100 for a V2 SKU
    capacity = 0 # Set the initial capacity to 0 for autoscaling
  }

  autoscale_configuration = {
    min_capacity = 1
    max_capacity = 2
  }

  # Frontend port configuration for the application gateway
  # Mandatory Input
  # WAF : This example NO HTTPS, We recommend to  Secure all incoming connections using HTTPS for production services with end-to-end SSL/TLS or SSL/TLS termination at the Application Gateway to protect against attacks and ensure data remains private and encrypted between the web server and browsers.
  # WAF : Please refer kv_selfssl_waf_https_app_gateway example for HTTPS configuration
  frontend_ports = {

    frontend-port-80 = {
      name = "frontend-port-80"
      port = 80
    },
    port8080 = {
      name = "port8080"
      port = 8080
    }
    # Add more ports as needed
  }

  # Backend address pool configuration for the application gateway
  # Mandatory Input
  backend_address_pools = {
    contosoPool = {
      name = "contosoPool"
    },
    fabrikamPool = {
      name = "fabrikamPool"
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
  }

  # Http Listerners configuration for the application gateway
  # Mandatory Input
  http_listeners = {

    appGatewayHttpListener = {
      name               = "appGatewayHttpListener"
      host_name          = null
      frontend_port_name = "frontend-port-80"
    },
    contosoListener = {
      name               = "contosoListener"
      frontend_port_name = "frontend-port-80"
      host_name          = "www.contoso.com"
    },
    fabrikamListener = {
      name               = "fabrikamListener"
      frontend_port_name = "frontend-port-80"
      host_names         = ["www.fabrikam.com", "www.fabrikam.org"]
    }
    # # Add more http listeners as needed
  }

  # Routing rules configuration for the backend pool
  # Mandatory Input
  request_routing_rules = {
    contosoRule = {
      name                       = "contosoRule"
      rule_type                  = "Basic"
      http_listener_name         = "contosoListener"
      backend_address_pool_name  = "contosoPool"
      backend_http_settings_name = "appGatewayBackendHttpSettings"
      priority                   = 100
    },
    fabrikamRule = {
      name      = "fabrikamRule"
      rule_type = "Basic"

      http_listener_name         = "fabrikamListener"
      backend_address_pool_name  = "fabrikamPool"
      backend_http_settings_name = "appGatewayBackendHttpSettings"
      priority                   = 200
    }
    # Add more rules as needed
  }

  # Optional Input 
  # Zone redundancy for the application gateway ["1", "2", "3"] 
  zones = ["1", "2", "3"]

  diagnostic_settings = {
    example_setting = {
      name                           = "${module.naming.application_gateway.name_unique}-diagnostic-setting"
      workspace_resource_id          = azurerm_log_analytics_workspace.log_analytics_workspace.id
      log_analytics_destination_type = "Dedicated" # Or "AzureDiagnostics"
      log_groups                     = ["allLogs"]
      metric_categories              = ["AllMetrics"]
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

## Resources

The following resources are used by this module:

- [azurerm_log_analytics_workspace.log_analytics_workspace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) (resource)
- [azurerm_resource_group.rg_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_subnet.backend](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet.frontend](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet.private_ip_test](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet.workload](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
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