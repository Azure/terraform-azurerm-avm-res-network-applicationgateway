#---------- All Required Pre-requisites Section-----------

# Below code allow you to create Azure resource group for application gateway,
# Virtual network, subnets, log analytics workspace, virtual machine scale set,
# network security group, storage account, key vault and user assigned identity.

resource "azurerm_resource_group" "rg_group" {
  location = "southeastasia"
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_virtual_network" "vnet" {
  location            = azurerm_resource_group.rg_group.location
  name                = module.naming.virtual_network.name_unique
  resource_group_name = azurerm_resource_group.rg_group.name
  address_space       = ["100.64.0.0/16"] # address space for VNET
}

resource "azurerm_subnet" "frontend" {
  address_prefixes     = ["100.64.0.0/24"] #[local.subnet_range[0]]
  name                 = "frontend"
  resource_group_name  = azurerm_resource_group.rg_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_subnet" "backend" {
  address_prefixes     = ["100.64.1.0/24"]
  name                 = "backend"
  resource_group_name  = azurerm_resource_group.rg_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_subnet" "nat_subnet" {
  address_prefixes     = ["100.64.6.0/24"]
  name                 = "nat_subnet"
  resource_group_name  = azurerm_resource_group.rg_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

# Required for to deploy VMSS and Web Server to host application
resource "azurerm_subnet" "workload" {
  address_prefixes     = ["100.64.2.0/24"]
  name                 = "workload"
  resource_group_name  = azurerm_resource_group.rg_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

# Required for Frontend Private IP endpoint testing
resource "azurerm_subnet" "private_ip_test" {
  address_prefixes     = ["100.64.3.0/24"]
  name                 = "private_ip_test"
  resource_group_name  = azurerm_resource_group.rg_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azapi_update_resource" "allow_appgw_v2_network_isolation" {
  resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Features/featureProviders/Microsoft.Network/subscriptionFeatureRegistrations/EnableApplicationGatewayNetworkIsolation"
  type        = "Microsoft.Features/featureProviders/subscriptionFeatureRegistrations@2021-07-01"
  body = {
    properties = {}
  }
}
