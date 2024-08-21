output "application_gateway_id" {
  description = "The ID of the Azure Application Gateway."
  value       = azurerm_application_gateway.this.id
}

output "application_gateway_name" {
  description = "The name of the Azure Application Gateway."
  value       = azurerm_application_gateway.this.name
}

output "backend_address_pools" {
  description = "Information about the backend address pools configured for the Application Gateway, including their names."
  value       = azurerm_application_gateway.this.backend_address_pool[*]
}

output "backend_http_settings" {
  description = "Information about the backend HTTP settings for the Application Gateway, including settings like port and protocol."
  value       = azurerm_application_gateway.this.backend_http_settings[*]
}

output "frontend_port" {
  description = "Information about the frontend ports used by the Application Gateway, including their names and port numbers."
  value       = azurerm_application_gateway.this.frontend_port[*]
}

output "http_listeners" {
  description = "Information about the HTTP listeners configured for the Application Gateway, including their names and settings."
  value       = azurerm_application_gateway.this.http_listener[*]
}

output "probes" {
  description = "Information about health probes configured for the Application Gateway, including their settings."
  value       = azurerm_application_gateway.this.probe[*]
}

output "public_ip_address" {
  description = "The actual public IP address associated with the Public IP resource."
  value       = azurerm_public_ip.this.ip_address
}

output "public_ip_id" {
  description = "The ID of the Azure Public IP address associated with the Application Gateway."
  value       = azurerm_public_ip.this.id
}

output "request_routing_rules" {
  description = "Information about request routing rules defined for the Application Gateway, including their names and configurations."
  value       = azurerm_application_gateway.this.request_routing_rule[*]
}

output "resource_id" {
  description = "Resource ID of Container Group Instance"
  value       = azurerm_application_gateway.this.id
}

output "ssl_certificates" {
  description = "Information about SSL certificates used by the Application Gateway, including their names and other details."
  value       = azurerm_application_gateway.this.ssl_certificate[*]
}

output "tags" {
  description = "The tags applied to the Application Gateway."
  value       = azurerm_application_gateway.this.tags
}

output "waf_configuration" {
  description = "Information about the Web Application Firewall (WAF) configuration, if applicable."
  value       = azurerm_application_gateway.this.waf_configuration[*]
}
