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
  address_space       = ["100.64.0.0/16"] # address space for VNET 
  depends_on          = [azurerm_resource_group.rg-group]
}

resource "azurerm_subnet" "frontend" {
  name                 = "frontend"
  resource_group_name  = azurerm_resource_group.rg-group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["100.64.0.0/24"] #[local.subnet_range[0]]
  depends_on           = [azurerm_virtual_network.vnet, azurerm_resource_group.rg-group]
}

resource "azurerm_subnet" "backend" {
  name                 = "backend"
  resource_group_name  = azurerm_resource_group.rg-group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["100.64.1.0/24"]
  depends_on           = [azurerm_virtual_network.vnet, azurerm_resource_group.rg-group]
}

# Required for to deploy VMSS and Web Server to host application
resource "azurerm_subnet" "workload" {
  name                 = "workload"
  resource_group_name  = azurerm_resource_group.rg-group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["100.64.2.0/24"]
  depends_on           = [azurerm_virtual_network.vnet, azurerm_resource_group.rg-group]
}

# Required for Frontend Private IP endpoint testing 
resource "azurerm_subnet" "private-ip-test" {
  name                 = "private-ip-test"
  resource_group_name  = azurerm_resource_group.rg-group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["100.64.3.0/24"]
  depends_on           = [azurerm_virtual_network.vnet, azurerm_resource_group.rg-group]
}

#-----------------------------------------------------------------
#  Enable these to deeploy sample application to VMSS 
#  Enable these code to test private IP endpoint via bastion host  
#-----------------------------------------------------------------

# Required bastion host subnet to test private IP endpoint
# resource "azurerm_subnet" "bastion" {
#   name                 = "AzureBastionSubnet"
#   resource_group_name  = azurerm_resource_group.rg-group.name
#   virtual_network_name = azurerm_virtual_network.vnet.name
#   address_prefixes     = ["100.64.4.0/24"] # Adjust the IP address prefix as needed
#   depends_on           = [azurerm_virtual_network.vnet, azurerm_resource_group.rg-group]
# }

# THIS NEED TO BE REMOVED AFTER TESTING

# resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
#   name                = module.naming.log_analytics_workspace.name_unique
#   resource_group_name = azurerm_resource_group.rg-group.name
#   location            = azurerm_resource_group.rg-group.location
#   sku                 = "PerGB2018"
#   depends_on          = [azurerm_resource_group.rg-group]
# }

# -----------------------------------------------------------------
#  Enable these to deeploy sample application to VMSS 
#  Enable these code to test private IP endpoint via bastion host  
# -----------------------------------------------------------------

# resource "azurerm_windows_virtual_machine" "bastion" {
#   name                  = module.naming.windows_virtual_machine.name_unique
#   resource_group_name   = azurerm_resource_group.rg-group.name
#   location              = azurerm_resource_group.rg-group.location
#   network_interface_ids = [azurerm_network_interface.bastion_win_vm_nic.id]
#   size                  = "Standard_DS1_v2"
#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }
#   source_image_reference {
#     publisher = "MicrosoftWindowsDesktop"
#     offer     = "Windows-11"
#     sku       = "win11-22h2-pro"
#     version   = "latest"
#   }
#   admin_username = "adminuser"
#   admin_password = "YourPasswordHere123!" # Replace with your actual password
# }

# resource "azurerm_network_interface" "bastion_win_vm_nic" {
#   name                = module.naming.network_interface.name_unique
#   resource_group_name = azurerm_resource_group.rg-group.name
#   location            = azurerm_resource_group.rg-group.location

#   ip_configuration {
#     name                          = module.naming.network_interface.name_unique
#     subnet_id                     = azurerm_subnet.private-ip-test.id
#     private_ip_address_allocation = "Dynamic"
#   }
# }

# resource "azurerm_public_ip" "bastion_public_ip" {
#   name                = module.naming.public_ip.name_unique
#   location            = azurerm_resource_group.rg-group.location
#   resource_group_name = azurerm_resource_group.rg-group.name
#   allocation_method   = "Static" # You can choose Dynamic if preferred
#   sku                 = "Standard"
# }

# # Create Azure Bastion Host
# resource "azurerm_bastion_host" "bastion-host" {
#   name                = module.naming.bastion_host.name_unique
#   location            = azurerm_resource_group.rg-group.location
#   resource_group_name = azurerm_resource_group.rg-group.name
#   scale_units         = 2

#   ip_configuration {
#     name                 = "bastion-Ip-configuration"
#     subnet_id            = azurerm_subnet.bastion.id
#     public_ip_address_id = azurerm_public_ip.bastion_public_ip.id
#   }
# }


# resource "azurerm_linux_virtual_machine_scale_set" "app_gateway_web_vmss" {
#   name                            = module.naming.linux_virtual_machine_scale_set.name_unique
#   resource_group_name             = azurerm_resource_group.rg-group.name
#   location                        = azurerm_resource_group.rg-group.location
#   sku                             = "Standard_DS1_v2"
#   instances                       = 2
#   admin_username                  = "azureuser"
#   admin_password                  = "YourComplexPassword123!" # Set your desired password here
#   disable_password_authentication = false

#   source_image_reference {
#     publisher = "RedHat"
#     offer     = "RHEL"
#     sku       = "83-gen2"
#     version   = "latest"

#   }

#   os_disk {
#     storage_account_type = "Standard_LRS"
#     caching              = "ReadWrite"
#   }

#   # upgrade_mode = "Automatic"

#   network_interface {
#     name    = "app-vmss-nic"
#     primary = true

#     ip_configuration {
#       name                                         = "internal"
#       primary                                      = true
#       subnet_id                                    = azurerm_subnet.workload.id
#       application_gateway_backend_address_pool_ids = module.application-gateway.backend_address_pools[*].id
#     }
#   }
#   custom_data = base64encode(local.webvm_custom_data)
#   depends_on  = [azurerm_virtual_network.vnet, azurerm_resource_group.rg-group, module.application-gateway]
# }


# # Create Network Security Group (NSG)
# resource "azurerm_network_security_group" "ag_subnet_nsg" {
#   name                = module.naming.network_security_group.name_unique
#   resource_group_name = azurerm_resource_group.rg-group.name
#   location            = azurerm_resource_group.rg-group.location
#   depends_on          = [azurerm_virtual_network.vnet, azurerm_resource_group.rg-group]
# }

# # Associate NSG and Subnet
# resource "azurerm_subnet_network_security_group_association" "ag_subnet_nsg_associate" {
#   depends_on = [azurerm_network_security_rule.ag_nsg_rule_inbound]
#   # Every NSG Rule Association will disassociate NSG from Subnet and Associate it, so we associate it only after NSG is completely created 
#   #- Azure Provider Bug https://github.com/terraform-providers/terraform-provider-azurerm/issues/354  
#   subnet_id                 = azurerm_subnet.workload.id
#   network_security_group_id = azurerm_network_security_group.ag_subnet_nsg.id

# }

# # Create NSG Rules
# ## Locals Block for Security Rules
# locals {
#   ag_inbound_ports_map = {
#     "100" : {
#       destination_port = "80",
#       source_address   = "*" # Add the source address prefix here
#       access           = "Allow"
#     },
#     "140" : {
#       destination_port = "81",
#       source_address   = "*" # Add the source address prefix here
#       access           = "Allow"
#     },
#     "110" : {
#       destination_port = "443",
#       source_address   = "*" # Add the source address prefix here
#       access           = "Allow"
#     },
#     "130" : {
#       destination_port = "65200-65535",
#       source_address   = "GatewayManager" # Add the source address prefix here
#       access           = "Allow"
#     }
#     "150" : {
#       destination_port = "8080",
#       source_address   = "AzureLoadBalancer" # Add the source address prefix here
#       access           = "Allow"
#     }
#     "4096" : {
#       destination_port = "8080",
#       source_address   = "Internet" # Add the source address prefix here
#       access           = "Deny"
#     }
#   }
# }

# ## NSG Inbound Rule for Azure Application Gateway Subnets
# resource "azurerm_network_security_rule" "ag_nsg_rule_inbound" {
#   for_each                    = local.ag_inbound_ports_map
#   name                        = "Rule-Port-${each.value.destination_port}-${each.value.access}"
#   priority                    = each.key
#   direction                   = "Inbound"
#   access                      = each.value.access
#   protocol                    = "Tcp"
#   source_port_range           = "*"
#   destination_port_range      = each.value.destination_port
#   source_address_prefix       = each.value.source_address
#   destination_address_prefix  = "*"
#   resource_group_name         = azurerm_resource_group.rg-group.name
#   network_security_group_name = azurerm_network_security_group.ag_subnet_nsg.name
#   depends_on                  = [azurerm_virtual_network.vnet, azurerm_resource_group.rg-group]
# }
