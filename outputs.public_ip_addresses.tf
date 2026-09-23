output "public_ip_addresses" {
  description = "Module-managed public IPs, keyed by public_ip_addresses input keys. Each value contains resource_id, ip_address and fqdn (null when no DNS label is configured). External IPs are excluded."
  value = {
    for key, ip in azapi_resource.public_ip_addresses : key => {
      fqdn        = ip.output.fqdn
      ip_address  = ip.output.ip_address
      resource_id = ip.id
    }
  }
}
