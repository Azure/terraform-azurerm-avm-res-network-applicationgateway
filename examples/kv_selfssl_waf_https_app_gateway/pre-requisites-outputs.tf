output "azurerm_key_vault_certificate_secret_id" {
  value = azurerm_key_vault_certificate.ssl_cert_id.secret_id
}

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

output "key_vault_id" {
  description = "ID of the Azure Key Vault"
  value       = azurerm_key_vault.keyvault.id
}

output "private_ip_test_subnet_id" {
  description = "ID of the Private IP Test Subnet"
  value       = azurerm_subnet.private-ip-test.id
}

output "private_ip_test_subnet_name" {
  description = "Name of the Private IP Test Subnet"
  value       = azurerm_subnet.private-ip-test.name
}

# Output for Resource Group
output "resource_group_id" {
  description = "ID of the Azure Resource Group"
  value       = azurerm_resource_group.rg-group.id
}

# Output for Resource Group
output "resource_group_name" {
  description = "Name of the Azure Resource Group"
  value       = azurerm_resource_group.rg-group.name
}

output "self_signed_certificate_id" {
  description = "ID of the self-signed SSL certificate in Azure Key Vault"
  value       = azurerm_key_vault_certificate.ssl_cert_id.id
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
