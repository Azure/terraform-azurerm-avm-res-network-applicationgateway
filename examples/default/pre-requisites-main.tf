#---------- All Required Pre-requisites Section-----------

# Below code allow you to create Azure resource group for application gateway, 
# Virtual network, subnets, log analytics workspace, virtual machine scale set, 
# network security group, storage account, key vault and user assigned identity.

resource "azurerm_resource_group" "rg-group" {
  name     = module.naming.resource_group.name_unique
  location = "southeastasia" //module.regions.regions[random_integer.region_index.result].name
}

resource "azurerm_virtual_network" "vnet" {
  name                = module.naming.virtual_network.name_unique
  resource_group_name = azurerm_resource_group.rg-group.name
  location            = azurerm_resource_group.rg-group.location
  address_space       = ["10.90.0.0/16"] # address space for VNET 
  depends_on          = [azurerm_resource_group.rg-group]
}

resource "azurerm_subnet" "frontend" {
  name                 = "frontend"
   resource_group_name = azurerm_resource_group.rg-group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.90.0.0/24"] #[local.subnet_range[0]]
  depends_on           = [azurerm_virtual_network.vnet, azurerm_resource_group.rg-group]
}

resource "azurerm_subnet" "backend" {
  name                 = "backend"
 resource_group_name = azurerm_resource_group.rg-group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.90.1.0/24"]
  depends_on           = [azurerm_virtual_network.vnet, azurerm_resource_group.rg-group]
}

# Required for Frontend Private IP endpoint testing 
resource "azurerm_subnet" "private-ip-test" {
  name                 = "private-ip-test"
  resource_group_name = azurerm_resource_group.rg-group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.90.3.0/24"]
  depends_on           = [azurerm_virtual_network.vnet, azurerm_resource_group.rg-group]
}

resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.rg-group.name
  location            = azurerm_resource_group.rg-group.location
  sku                 = "PerGB2018"
  depends_on          = [azurerm_resource_group.rg-group]
}
