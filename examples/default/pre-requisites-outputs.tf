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



# Output for Log Analytics Workspace
output "log_analytics_workspace_name" {
  description = "Name of the Azure Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.log_analytics_workspace.name
}



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


# Output for Log Analytics Workspace
output "log_analytics_workspace_id" {
  description = "ID of the Azure Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.log_analytics_workspace.id
}




