# #----------All Required Provider Section----------- 

# terraform {
#   required_version = ">= 1.5"

#   required_providers {
#     azurerm = {
#       source  = "hashicorp/azurerm"
#       version = ">= 3.0, < 4.0"
#     }
#     random = {
#       source  = "hashicorp/random"
#       version = ">= 3.5.0, < 4.0.0"
#     }
#   }
# }

# provider "azurerm" {
#   features {}
# }

# # This ensures we have unique CAF compliant names for our resources.
# module "naming" {
#   source  = "Azure/naming/azurerm"
#   version = "0.3.0"
#   suffix  = ["agw"]
# }

# # This allows us to randomize the region for the resource group.
# module "regions" {
#   source  = "Azure/regions/azurerm"
#   version = ">= 0.3.0"

# }

# # This allows us to randomize the region for the resource group.
# resource "random_integer" "region_index" {
#   min = 0
#   max = length(module.regions.regions) - 1
  
# }

# module "application-gateway" {
#   # source  = "mofaizal/application-gateway/azure"
#   # version = "1.0.2"
#   source = "../../"

#   # pre-requisites resources input required for the module

#   public_ip_name             = "${module.naming.public_ip.name_unique}-pip"
#   resource_group_name        = azurerm_resource_group.rg-group.name
#   location                   = azurerm_resource_group.rg-group.location
#   vnet_name                  = azurerm_virtual_network.vnet.name
#   subnet_name_frontend       = azurerm_subnet.frontend.name
#   subnet_name_backend        = azurerm_subnet.backend.name
#   log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace.id
#   # enable_telemetry            = 1
#   # provide Application gateway name 
#   app_gateway_name = module.naming.application_gateway.name_unique

# tags = {
#     environment = "dev"
#     owner       = "application_gateway"
#     project     = "AVM"
#   }

#  sku = {
#     # Accpected value for names Standard_v2 and WAF_v2
#     name     = "Standard_v2"
#     # Accpected value for tier Standard_v2 and WAF_v2
#     tier     = "Standard_v2" 
#     # Accpected value for capacity 1 to 10 for a V1 SKU, 1 to 100 for a V2 SKU
#     capacity = 1  # Set the initial capacity to 0 for autoscaling
#   }
  
# # frontend configuration block for the application gateway
#   # frontend_ip_configuration_name = "app-gateway-feip"
#   private_ip_address = "10.90.1.5" // IP address from backend subnet

#   zone_redundant              = [] #["1", "2", "3"] # Zone redundancy for the application gateway
  
#   request_routing_rules = []
#   backend_address_pools = []
#   backend_http_settings = []
#   http_listeners = []
#   # identity_ids = ["${azurerm_user_assigned_identity.user_assigned_identity.id}"]

#   # This is required only when you create pre-requisites resources using above scripts else disable it and use the existing resources
#   #depends_on = [azurerm_virtual_network.vnet, azurerm_subnet.frontend, azurerm_subnet.backend, azurerm_resource_group.rg-group]

# }

