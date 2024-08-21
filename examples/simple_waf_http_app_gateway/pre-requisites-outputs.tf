output "backend_subnet_id" {
  description = "ID of the Backend Subnet"
  value       = azurerm_subnet.backend.id
}

output "backend_subnet_name" {
  description = "Name of the Backend Subnet"
  value       = azurerm_subnet.backend.name
}

# Output for Subnets
output "frontend_subnet_id" {
  description = "ID of the Frontend Subnet"
  value       = azurerm_subnet.frontend.id
}

# Output for Subnets
output "frontend_subnet_name" {
  description = "Name of the Frontend Subnet"
  value       = azurerm_subnet.frontend.name
}

# Output for Log Analytics Workspace
output "log_analytics_workspace_id" {
  description = "ID of the Azure Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.log_analytics_workspace.id
}

# Output for Log Analytics Workspace
output "log_analytics_workspace_name" {
  description = "Name of the Azure Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.log_analytics_workspace.name
}

output "private_ip_test_subnet_id" {
  description = "ID of the Private IP Test Subnet"
<<<<<<< HEAD
  value       = azurerm_subnet.private_ip_test.id
=======
  value       = azurerm_subnet.private-ip-test.id
>>>>>>> edc4a8a5c63b47006a932f49cb5e7e860ba577b7
}

output "private_ip_test_subnet_name" {
  description = "Name of the Private IP Test Subnet"
<<<<<<< HEAD
  value       = azurerm_subnet.private_ip_test.name
=======
  value       = azurerm_subnet.private-ip-test.name
>>>>>>> edc4a8a5c63b47006a932f49cb5e7e860ba577b7
}

# Output for Resource Group
output "resource_group_id" {
  description = "ID of the Azure Resource Group"
  value       = azurerm_resource_group.rg_group.id
}

# Output for Resource Group
output "resource_group_name" {
  description = "Name of the Azure Resource Group"
  value       = azurerm_resource_group.rg_group.name
}

# Output for Resource Group
output "resource_group_name" {
  description = "Name of the Azure Resource Group"
  value       = azurerm_resource_group.rg-group.name
}

# Output for Virtual Network
output "virtual_network_id" {
  description = "ID of the Azure Virtual Network"
  value       = azurerm_virtual_network.vnet.id
}

# Output for Virtual Network
output "virtual_network_name" {
  description = "Name of the Azure Virtual Network"
  value       = azurerm_virtual_network.vnet.name
}

output "workload_subnet_id" {
  description = "ID of the Workload Subnet"
  value       = azurerm_subnet.workload.id
}

output "workload_subnet_name" {
  description = "Name of the Workload Subnet"
  value       = azurerm_subnet.workload.name
}
