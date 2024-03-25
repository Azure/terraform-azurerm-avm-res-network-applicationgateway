# Output for Resource Group
output "resource_group_name" {
  description = "Name of the Azure Resource Group"
  value       = azurerm_resource_group.rg-group.name
}

# Output for Virtual Network
output "virtual_network_name" {
  description = "Name of the Azure Virtual Network"
  value       = azurerm_virtual_network.vnet.name
}

# Output for Subnets
output "frontend_subnet_name" {
  description = "Name of the Frontend Subnet"
  value       = azurerm_subnet.frontend.name
}

output "backend_subnet_name" {
  description = "Name of the Backend Subnet"
  value       = azurerm_subnet.backend.name
}

output "workload_subnet_name" {
  description = "Name of the Workload Subnet"
  value       = azurerm_subnet.workload.name
}

output "private_ip_test_subnet_name" {
  description = "Name of the Private IP Test Subnet"
  value       = azurerm_subnet.private-ip-test.name
}

# output "bastion_subnet_name" {
#   description = "Name of the Bastion Host Subnet"
#   value       = azurerm_subnet.bastion.name
# }

# # Output for Log Analytics Workspace
# output "log_analytics_workspace_name" {
#   description = "Name of the Azure Log Analytics Workspace"
#   value       = azurerm_log_analytics_workspace.log_analytics_workspace.name
# }

# Output for Windows Virtual Machine (Bastion)
# output "bastion_virtual_machine_name" {
#   description = "Name of the Windows Virtual Machine (Bastion Host)"
#   value       = azurerm_windows_virtual_machine.bastion.name
# }

# # Output for Network Interface (Bastion NIC)
# output "bastion_nic_name" {
#   description = "Name of the Network Interface (NIC) for Bastion Host"
#   value       = azurerm_network_interface.bastion_win_vm_nic.name
# }

# # Output for Public IP (Bastion Public IP)
# output "bastion_public_ip_name" {
#   description = "Name of the Public IP Address for Bastion Host"
#   value       = azurerm_public_ip.bastion_public_ip.name
# }

# # Output for Bastion Host
# output "bastion_host_name" {
#   description = "Name of the Azure Bastion Host"
#   value       = azurerm_bastion_host.bastion-host.name
# }

# # Output for Linux Virtual Machine Scale Set
# output "linux_vmss_name" {
#   description = "Name of the Linux Virtual Machine Scale Set"
#   value       = azurerm_linux_virtual_machine_scale_set.app_gateway_web_vmss.name
# }

# # Output for Network Security Group
# output "network_security_group_name" {
#   description = "Name of the Network Security Group (NSG)"
#   value       = azurerm_network_security_group.ag_subnet_nsg.name
# }

# # Output for NSG Rule Inbound Ports
# output "inbound_ports_map" {
#   description = "Map of NSG inbound rule ports"
#   value       = local.ag_inbound_ports_map
# }

# Output for Resource Group
output "resource_group_id" {
  description = "ID of the Azure Resource Group"
  value       = azurerm_resource_group.rg-group.id
}

# Output for Virtual Network
output "virtual_network_id" {
  description = "ID of the Azure Virtual Network"
  value       = azurerm_virtual_network.vnet.id
}

# Output for Subnets
output "frontend_subnet_id" {
  description = "ID of the Frontend Subnet"
  value       = azurerm_subnet.frontend.id
}

output "backend_subnet_id" {
  description = "ID of the Backend Subnet"
  value       = azurerm_subnet.backend.id
}

output "workload_subnet_id" {
  description = "ID of the Workload Subnet"
  value       = azurerm_subnet.workload.id
}

output "private_ip_test_subnet_id" {
  description = "ID of the Private IP Test Subnet"
  value       = azurerm_subnet.private-ip-test.id
}

# output "bastion_subnet_id" {
#   description = "ID of the Bastion Host Subnet"
#   value       = azurerm_subnet.bastion.id
# }

# Output for Log Analytics Workspace
# output "log_analytics_workspace_id" {
#   description = "ID of the Azure Log Analytics Workspace"
#   value       = azurerm_log_analytics_workspace.log_analytics_workspace.id
# }

# # Output for Windows Virtual Machine (Bastion)
# output "bastion_virtual_machine_id" {
#   description = "ID of the Windows Virtual Machine (Bastion Host)"
#   value       = azurerm_windows_virtual_machine.bastion.id
# }

# # Output for Network Interface (Bastion NIC)
# output "bastion_nic_id" {
#   description = "ID of the Network Interface (NIC) for Bastion Host"
#   value       = azurerm_network_interface.bastion_win_vm_nic.id
# }

# # Output for Public IP (Bastion Public IP)
# output "bastion_public_ip_id" {
#   description = "ID of the Public IP Address for Bastion Host"
#   value       = azurerm_public_ip.bastion_public_ip.id
# }

# # Output for Bastion Host
# output "bastion_host_id" {
#   description = "ID of the Azure Bastion Host"
#   value       = azurerm_bastion_host.bastion-host.id
# }

# # Output for Linux Virtual Machine Scale Set
# output "linux_vmss_id" {
#   description = "ID of the Linux Virtual Machine Scale Set"
#   value       = azurerm_linux_virtual_machine_scale_set.app_gateway_web_vmss.id
# }

# # Output for Network Security Group
# output "network_security_group_id" {
#   description = "ID of the Network Security Group (NSG)"
#   value       = azurerm_network_security_group.ag_subnet_nsg.id
# }


