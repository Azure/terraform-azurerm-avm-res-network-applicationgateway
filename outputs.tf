output "application_gateway_id" {
  description = "The ID of the Azure Application Gateway."
  value       = azurerm_application_gateway.this.id
  # Usage: You can use this ID to reference the Application Gateway in other Terraform configurations or scripts.
}

output "application_gateway_name" {
  description = "The name of the Azure Application Gateway."
  value       = azurerm_application_gateway.this.name
  # Usage: You can use this name to display or reference the Application Gateway in other parts of your infrastructure or documentation.
}

output "public_ip_id" {
  description = "The ID of the Azure Public IP address associated with the Application Gateway."
  value       = azurerm_public_ip.this.id
  # Usage: You can use this ID to reference the Public IP address in other Terraform configurations or scripts.
}

output "public_ip_address" {
  description = "The actual public IP address associated with the Public IP resource."
  value       = azurerm_public_ip.this.ip_address
  # Usage: You can use this IP address to configure DNS records or external access to your Application Gateway.
}

output "frontend_port" {
  description = "Information about the frontend ports used by the Application Gateway, including their names and port numbers."
  value       = azurerm_application_gateway.this.frontend_port[*]
  # Usage: You can use this information to understand which ports are open on the Application Gateway.
}

output "backend_address_pools" {
  description = "Information about the backend address pools configured for the Application Gateway, including their names."
  value       = azurerm_application_gateway.this.backend_address_pool[*]
  # Usage: You can use this information to understand which backend resources are associated with the Application Gateway.
}

output "backend_http_settings" {
  description = "Information about the backend HTTP settings for the Application Gateway, including settings like port and protocol."
  value       = azurerm_application_gateway.this.backend_http_settings[*]
  # Usage: You can use this information to understand how the Application Gateway communicates with the backend resources.
}

output "http_listeners" {
  description = "Information about the HTTP listeners configured for the Application Gateway, including their names and settings."
  value       = azurerm_application_gateway.this.http_listener[*]
  # Usage: You can use this information to understand how the Application Gateway handles incoming traffic.
}

output "ssl_certificates" {
  description = "Information about SSL certificates used by the Application Gateway, including their names and other details."
  value       = azurerm_application_gateway.this.ssl_certificate[*]
  # Usage: You can use this information to manage and update SSL certificates for secure connections.
}

output "request_routing_rules" {
  description = "Information about request routing rules defined for the Application Gateway, including their names and configurations."
  value       = azurerm_application_gateway.this.request_routing_rule[*]
  # Usage: You can use this information to understand how traffic is routed within the Application Gateway.
}

output "probes" {
  description = "Information about health probes configured for the Application Gateway, including their settings."
  value       = azurerm_application_gateway.this.probe[*]
  # Usage: You can use this information to monitor the health of backend resources.
}

output "waf_configuration" {
  description = "Information about the Web Application Firewall (WAF) configuration, if applicable."
  value       = azurerm_application_gateway.this.waf_configuration[*]
  # Usage: You can use this information to manage and update the WAF settings for security.
}

# output "diagnostic_setting_for_app_gateway_id" {
#   description = "The ID of the diagnostic settings for the Application Gateway."
#   value       = azurerm_monitor_diagnostic_setting.diagnostic_setting_for_app_gateway.id
#   # Usage: You can use this ID to configure diagnostic logging for the Application Gateway.
# }

# output "diagnostic_setting_for_public_ip_id" {
#   description = "The ID of the diagnostic settings for the associated Public IP address."
#   value       = azurerm_monitor_diagnostic_setting.diagnostic_setting_for_public_ip.id
#   # Usage: You can use this ID to configure diagnostic logging for the Public IP address.
# }

# output "log_analytics_workspace_id" {
#   description = "The ID of the Azure Log Analytics workspace."
#   value       = var.log_analytics_workspace_id
#   # Usage: You can use this ID to link the Application Gateway and Public IP logs to the specified Log Analytics workspace for monitoring and analysis.
# }

output "tags" {
  description = "The tags applied to the Application Gateway."
  value       = azurerm_application_gateway.this.tags
  # Usage: You can use these tags for organizing and categorizing resources in your Azure environment.
}
