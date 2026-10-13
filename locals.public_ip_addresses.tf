locals {
  frontend_ip_configurations = var.frontend_ip_configurations == null ? null : [
    for frontend in var.frontend_ip_configurations : frontend == null ? null : merge(frontend, {
      public_ip_address = frontend.public_ip_address_key == null ? frontend.public_ip_address : {
        # Validation reports unknown keys; avoid masking that error with an invalid index.
        id = lookup(local.public_ip_address_ids, frontend.public_ip_address_key, null)
      }
    })
  ]
  public_ip_address_ids = { for key, ip in azapi_resource.public_ip_addresses : key => ip.id }
  public_ip_address_zones = {
    for key, ip in var.public_ip_addresses : key => ip == null ? null : (
      ip.zones == null ? (var.zones == null ? null : sort(var.zones)) : sort(ip.zones)
    )
  }
}
