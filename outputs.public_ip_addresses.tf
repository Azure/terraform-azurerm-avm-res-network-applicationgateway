output "public_ip_addresses" {
  description = "Module-managed public IPs, keyed by public_ip_addresses input keys. Each value contains resource_id, ip_address and fqdn (null when no DNS label is configured). External IPs are excluded."
  value = {
    for key, ip in azapi_resource.public_ip_addresses : key => {
      # Import (the documented ownership migration) reads state before configured exports apply.
      fqdn        = try(ip.output.fqdn, null)
      ip_address  = try(ip.output.ip_address, null)
      resource_id = ip.id
    }
  }
}
