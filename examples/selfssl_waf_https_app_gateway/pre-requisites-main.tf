#---------- All Required Pre-requisites Section-----------

# Below code allow you to create Azure resource group for application gateway, 
# Virtual network, subnets, log analytics workspace, virtual machine scale set, 
# network security group, storage account, key vault and user assigned identity.

resource "azurerm_resource_group" "rg_group" {
  location = "southeastasia"
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_virtual_network" "vnet" {
  address_space       = ["10.90.0.0/16"] # address space for VNET 
  location            = azurerm_resource_group.rg_group.location
  name                = module.naming.virtual_network.name_unique
  resource_group_name = azurerm_resource_group.rg_group.name
}

resource "azurerm_subnet" "frontend" {
  address_prefixes     = ["10.90.0.0/24"] #[local.subnet_range[0]]
  name                 = "frontend"
  resource_group_name  = azurerm_resource_group.rg_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_subnet" "backend" {
  address_prefixes     = ["10.90.1.0/24"]
  name                 = "backend"
  resource_group_name  = azurerm_resource_group.rg_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

# Required for to deploy VMSS and Web Server to host application
resource "azurerm_subnet" "workload" {
  address_prefixes     = ["10.90.2.0/24"]
  name                 = "workload"
  resource_group_name  = azurerm_resource_group.rg_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

# Required for Frontend Private IP endpoint testing 
resource "azurerm_subnet" "private_ip_test" {
  address_prefixes     = ["10.90.3.0/24"]
  name                 = "private_ip_test"
  resource_group_name  = azurerm_resource_group.rg_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_public_ip" "this" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.rg_group.location
  name                = module.naming.public_ip.name_unique
  resource_group_name = azurerm_resource_group.rg_group.name
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

#-----------------------------------------------------------------
#  Enable these to deploy sample application to VMSS 
#  Enable these code to test private IP endpoint via bastion host  
#-----------------------------------------------------------------

# Required bastion host subnet to test private IP endpoint
resource "azurerm_subnet" "bastion" {
  address_prefixes     = ["10.90.4.0/24"] # Adjust the IP address prefix as needed
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  location            = azurerm_resource_group.rg_group.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.rg_group.name
  sku                 = "PerGB2018"
}

#-----------------------------------------------------------------
#  Enable these to deploy sample application to VMSS 
#  Enable these code to test private IP endpoint via bastion host  
#-----------------------------------------------------------------

resource "azurerm_windows_virtual_machine" "bastion" {
  admin_password        = "YourPasswordHere123!" # Replace with your actual password
  admin_username        = "adminuser"
  location              = azurerm_resource_group.rg_group.location
  name                  = module.naming.windows_virtual_machine.name_unique
  network_interface_ids = [azurerm_network_interface.bastion_win_vm_nic.id]
  resource_group_name   = azurerm_resource_group.rg_group.name
  size                  = "Standard_DS1_v2"

  os_disk {
    # name              = "bastion-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    offer     = "Windows-11"
    publisher = "MicrosoftWindowsDesktop"
    sku       = "win11-22h2-pro"
    version   = "latest"
  }
}

resource "azurerm_network_interface" "bastion_win_vm_nic" {
  location            = azurerm_resource_group.rg_group.location
  name                = module.naming.network_interface.name_unique
  resource_group_name = azurerm_resource_group.rg_group.name

  ip_configuration {
    name                          = module.naming.network_interface.name_unique
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.private_ip_test.id
  }
}

resource "azurerm_public_ip" "bastion_public_ip" {
  allocation_method   = "Static" # You can choose Dynamic if preferred
  location            = azurerm_resource_group.rg_group.location
  name                = "${module.naming.public_ip.name_unique}-bastion"
  resource_group_name = azurerm_resource_group.rg_group.name
  sku                 = "Standard"
}

# Create Azure Bastion Host
resource "azurerm_bastion_host" "bastion_host" {
  location            = azurerm_resource_group.rg_group.location
  name                = module.naming.bastion_host.name_unique
  resource_group_name = azurerm_resource_group.rg_group.name
  scale_units         = 2

  ip_configuration {
    name                 = "bastion-Ip-configuration"
    public_ip_address_id = azurerm_public_ip.bastion_public_ip.id
    subnet_id            = azurerm_subnet.bastion.id
  }
}


resource "azurerm_linux_virtual_machine_scale_set" "app_gateway_web_vmss" {
  admin_username                  = "azureuser"
  location                        = azurerm_resource_group.rg_group.location
  name                            = module.naming.linux_virtual_machine_scale_set.name_unique
  resource_group_name             = azurerm_resource_group.rg_group.name
  sku                             = "Standard_DS1_v2"
  admin_password                  = "YourComplexPassword123!" # Set your desired password here
  custom_data                     = base64encode(local.webvm_custom_data)
  disable_password_authentication = false
  instances                       = 2

  network_interface {
    name    = "app-vmss-nic"
    primary = true

    ip_configuration {
      name                                         = "internal"
      application_gateway_backend_address_pool_ids = module.application_gateway.backend_address_pools[*].id
      primary                                      = true
      subnet_id                                    = azurerm_subnet.workload.id
    }
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    offer     = "RHEL"
    publisher = "RedHat"
    sku       = "83-gen2"
    version   = "latest"
  }
}

# Create Network Security Group (NSG)
resource "azurerm_network_security_group" "ag_subnet_nsg" {
  location            = azurerm_resource_group.rg_group.location
  name                = module.naming.network_security_group.name_unique
  resource_group_name = azurerm_resource_group.rg_group.name
}

# Associate NSG and Subnet
resource "azurerm_subnet_network_security_group_association" "ag_subnet_nsg_associate" {
  network_security_group_id = azurerm_network_security_group.ag_subnet_nsg.id
  # Every NSG Rule Association will disassociate NSG from Subnet and Associate it, so we associate it only after NSG is completely created 
  #- Azure Provider Bug https://github.com/terraform-providers/terraform-provider-azurerm/issues/354  
  subnet_id = azurerm_subnet.workload.id
}

# Create NSG Rules
## Locals Block for Security Rules
locals {
  ag_inbound_ports_map = {
    "100" : {
      destination_port = "80",
      source_address   = "*" # Add the source address prefix here
      access           = "Allow"
    },
    "140" : {
      destination_port = "81",
      source_address   = "*" # Add the source address prefix here
      access           = "Allow"
    },
    "110" : {
      destination_port = "443",
      source_address   = "*" # Add the source address prefix here
      access           = "Allow"
    },
    "130" : {
      destination_port = "65200-65535",
      source_address   = "GatewayManager" # Add the source address prefix here
      access           = "Allow"
    }
    "150" : {
      destination_port = "8080",
      source_address   = "AzureLoadBalancer" # Add the source address prefix here
      access           = "Allow"
    }
    "4096" : {
      destination_port = "8080",
      source_address   = "Internet" # Add the source address prefix here
      access           = "Deny"
    }
  }
}

## NSG Inbound Rule for Azure Application Gateway Subnets
resource "azurerm_network_security_rule" "ag_nsg_rule_inbound" {
  for_each = local.ag_inbound_ports_map

  access                      = each.value.access
  direction                   = "Inbound"
  name                        = "Rule-Port-${each.value.destination_port}-${each.value.access}"
  network_security_group_name = azurerm_network_security_group.ag_subnet_nsg.name
  priority                    = each.key
  protocol                    = "Tcp"
  resource_group_name         = azurerm_resource_group.rg_group.name
  destination_address_prefix  = "*"
  destination_port_range      = each.value.destination_port
  source_address_prefix       = each.value.source_address
  source_port_range           = "*"
}

# # Datasource-1: To get Azure Tenant Id
# data "azurerm_client_config" "current" {}

resource "azurerm_user_assigned_identity" "appag_umid" {
  location            = azurerm_resource_group.rg_group.location
  name                = module.naming.user_assigned_identity.name_unique
  resource_group_name = azurerm_resource_group.rg_group.name
}

resource "azurerm_web_application_firewall_policy" "azure_waf" {
  location            = azurerm_resource_group.rg_group.location
  name                = "example-wafpolicy"
  resource_group_name = azurerm_resource_group.rg_group.name

  managed_rules {
    managed_rule_set {
      version = "3.2"
      type    = "OWASP"

      rule_group_override {
        rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"

        rule {
          id      = "920300"
          action  = "Log"
          enabled = true
        }
        rule {
          id      = "920440"
          action  = "Block"
          enabled = true
        }
      }
    }
    exclusion {
      match_variable          = "RequestHeaderNames"
      selector                = "x-company-secret-header"
      selector_match_operator = "Equals"
    }
    exclusion {
      match_variable          = "RequestCookieNames"
      selector                = "too-tasty"
      selector_match_operator = "EndsWith"
    }
  }
  custom_rules {
    action    = "Block"
    priority  = 1
    rule_type = "MatchRule"
    name      = "Rule1"

    match_conditions {
      operator           = "IPMatch"
      match_values       = ["192.168.1.0/24", "10.0.0.0/24"]
      negation_condition = false

      match_variables {
        variable_name = "RemoteAddr"
      }
    }
  }
  custom_rules {
    action    = "Block"
    priority  = 2
    rule_type = "MatchRule"
    name      = "Rule2"

    match_conditions {
      operator           = "IPMatch"
      match_values       = ["192.168.1.0/24"]
      negation_condition = false

      match_variables {
        variable_name = "RemoteAddr"
      }
    }
    match_conditions {
      operator           = "Contains"
      match_values       = ["Windows"]
      negation_condition = false

      match_variables {
        variable_name = "RequestHeaders"
        selector      = "UserAgent"
      }
    }
  }
  policy_settings {
    enabled                     = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
    mode                        = "Prevention"
    request_body_check          = true
  }
}
