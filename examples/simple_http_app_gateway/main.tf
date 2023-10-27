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
  min = 0
  max = length(module.regions.regions) - 1
  
}


module "application-gateway" {
  # source  = "mofaizal/application-gateway/azure"
  # version = "1.0.2"
  source = "../../"
  depends_on           = [azurerm_virtual_network.vnet, azurerm_resource_group.rg-group,azurerm_bastion_host.bastion-host,azurerm_linux_virtual_machine_scale_set.app_gateway_web_vmss,azurerm_log_analytics_workspace.log_analytics_workspace,azurerm_network_interface.bastion_win_vm_nic]

  # pre-requisites resources input required for the module

  public_ip_name             = "${module.naming.public_ip.name_unique}-pip"
  resource_group_name        = azurerm_resource_group.rg-group.name
  location                   = azurerm_resource_group.rg-group.location
  vnet_name                  = azurerm_virtual_network.vnet.name
  subnet_name_frontend       = azurerm_subnet.frontend.name
  subnet_name_backend        = azurerm_subnet.backend.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace.id
  # enable_telemetry            = 1
  # provide Application gateway name 
  app_gateway_name = module.naming.application_gateway.name_unique

tags = {
    environment = "dev"
    owner       = "application_gateway"
    project     = "AVM"
  }

 sku = {
    # Accpected value for names Standard_v2 and WAF_v2
    name     = "Standard_v2"
    # Accpected value for tier Standard_v2 and WAF_v2
    tier     = "Standard_v2" 
    # Accpected value for capacity 1 to 10 for a V1 SKU, 1 to 100 for a V2 SKU
    capacity = 0  # Set the initial capacity to 0 for autoscaling
  }
  
  autoscale_configuration = {
    min_capacity = 2
    max_capacity = 15
  }

# frontend configuration block for the application gateway
  # frontend_ip_configuration_name = "app-gateway-feip"
  private_ip_address = "10.90.1.5" // IP address from backend subnet
  
# Backend configuration for the application gateway
  backend_address_pools = [
    {
      name         = "Pool1"
      #fqdns        = ["example1.com", "example2.com"]
      ip_addresses = ["10.90.2.4", "10.90.2.6"]
     },
    {
      name         = "Pool2"
      # fqdns        = ["contoso.com", "app1.contoso.com"]
      ip_addresses = ["10.90.2.4", "10.90.2.6"]
    }
    # Add more pools as needed
  ]

  # backend_address_pools = [
  #   for instance in azurerm_linux_virtual_machine_scale_set.app_gateway_web_vmss : {
  #     name         = "Pool${instance.instance_id}"
  #     ip_addresses = [instance.network_interface_ids[0].private_ip_address]
  #   }
  # ]

# Http Listerners configuration for the application gateway
  http_listeners = [
    {
      name               = "http-listener-80"
      frontend_port_name = null
      protocol           = "Http"
      frontend_ip_assocation = "public"
     },
      {
      name               = "http-listener2-81"
      frontend_port_name = null
      protocol           = "Http"
      frontend_ip_assocation = "both"
     }
    # {
    #   name               = "http-listener-443"
    #   frontend_port_name = "frontend-port-443"
    #   protocol           = "Https"
    #   # Define other attributes as needed
    # }

    # Add more http listeners as needed
  ]

# Backend http settings configuration for the application gateway

backend_http_settings = [
    {
      name     = "port1-80"
      port     = 80
      protocol = "Http"
      cookie_based_affinity = "Disabled"
     },
       {
      name     = "port2-81" 
      port     = 81
      protocol = "Http"
      cookie_based_affinity = "Disabled"
     }
    #{
    #   name     = "http-settings-443"
    #   port     = 443
    #   protocol = "Https"
    #   cookie_based_affinity = "Disabled"
    #   # Define other attributes as needed
    # }
    # Add more http settings as needed
  ]

# Routing rules configuration for the backend pool
request_routing_rules = [
    {
      name               = "Rule1"
      rule_type          = "Basic"
      http_listener_name = null 
      backend_address_pool_name = null 
      priority           = 9
     } ,
     {
      name               = "Rule2"
      rule_type          = "Basic" //"PathBasedRouting"
      http_listener_name      = "http-listener-80" //null 
      backend_address_pool_name = "Pool1" //null
      priority           = 10
    },
    # Add more rules as needed
  ]

  # redirect_configuration_name    = "app-gateway-rdrcfg"

# Optional Input
  # enable_http2                = true
  # app_gateway_sku_capacity    = 1 # Capacity of the application gateway
  zone_redundant              = ["1", "2", "3"] #["1", "2", "3"] # Zone redundancy for the application gateway
 

  # identity_ids = ["${azurerm_user_assigned_identity.user_assigned_identity.id}"]

  # This is required only when you create pre-requisites resources using above scripts else disable it and use the existing resources
  #depends_on = [azurerm_virtual_network.vnet, azurerm_subnet.frontend, azurerm_subnet.backend, azurerm_resource_group.rg-group]

}

