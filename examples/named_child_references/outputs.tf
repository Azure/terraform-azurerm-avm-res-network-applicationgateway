output "gateway_resource_id" {
  description = "Gateway deployed for the reference-resolution E2E scenario."
  value       = module.gateway.resource_id
}

output "observed_reference_ids" {
  description = "Internal reference IDs independently read back from Azure."
  value = {
    backend_pool     = one(data.azapi_resource.gateway.output.rules).properties.backendAddressPool.id
    backend_settings = one(data.azapi_resource.gateway.output.rules).properties.backendHttpSettings.id
    frontend_ip      = one(data.azapi_resource.gateway.output.listeners).properties.frontendIPConfiguration.id
    frontend_port    = one(data.azapi_resource.gateway.output.listeners).properties.frontendPort.id
    listener         = one(data.azapi_resource.gateway.output.rules).properties.httpListener.id
    probe            = one(data.azapi_resource.gateway.output.settings).properties.probe.id
  }
}

output "public_ip_address" {
  description = "Allocated external public IPv4 address."
  value       = azapi_resource.public_ip.output.properties.ipAddress
}

output "resource_group_name" {
  description = "Unique resource group used to verify cleanup."
  value       = azapi_resource.resource_group.name
}
