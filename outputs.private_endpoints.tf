output "private_endpoint_ids" {
  description = "The IDs of module-managed private endpoints, keyed by private_endpoints input keys."
  value       = { for key, endpoint in azapi_resource.private_endpoints : key => endpoint.id }
}

output "private_endpoint_dns_zone_group_ids" {
  description = "The IDs of managed private DNS zone groups, keyed by private_endpoints input keys."
  value       = { for key, zone_group in module.private_dns_zone_groups : key => zone_group.resource_id }
}
