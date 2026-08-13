output "default_predefined_ssl_policy" {
  description = "Ssl predefined policy name enums."
  value       = try(azapi_resource.this.output.properties.defaultPredefinedSslPolicy, null)
}

output "identity_principal_id" {
  description = "The principal id of the system assigned identity. This property will only be provided for a system assigned identity."
  value       = try(azapi_resource.this.output.identity.principalId, null)
}

output "identity_tenant_id" {
  description = "The tenant id of the system assigned identity. This property will only be provided for a system assigned identity."
  value       = try(azapi_resource.this.output.identity.tenantId, null)
}

output "name" {
  description = "The name of the created resource."
  value       = azapi_resource.this.name
}

output "operational_state" {
  description = "Operational state of the application gateway resource."
  value       = try(azapi_resource.this.output.properties.operationalState, null)
}

output "private_endpoint_connections" {
  description = "Private Endpoint connections on application gateway."
  value       = try(azapi_resource.this.output.properties.privateEndpointConnections, [])
}

output "provisioning_state" {
  description = "The current provisioning state."
  value       = try(azapi_resource.this.output.properties.provisioningState, null)
}

output "resource_guid" {
  description = "The resource GUID property of the application gateway resource."
  value       = try(azapi_resource.this.output.properties.resourceGuid, null)
}

output "resource_id" {
  description = "The ID of the created resource."
  value       = azapi_resource.this.id
}

output "type" {
  description = "Resource type."
  value       = try(azapi_resource.this.output.type, null)
}
