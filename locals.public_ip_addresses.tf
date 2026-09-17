locals {
  frontend_ip_configurations = var.frontend_ip_configurations == null ? null : [
    for frontend in var.frontend_ip_configurations : frontend == null ? null : {
      name = frontend.name
      properties = frontend.public_ip_address_key == null ? frontend.properties : merge(
        {
          private_ip_address           = null
          private_ip_allocation_method = null
          private_link_configuration   = null
          public_ip_address            = null
          subnet                       = null
        },
        frontend.properties,
        {
          public_ip_address = {
            # Validation reports unknown keys; avoid masking that error with an invalid index.
            id = lookup(local.public_ip_address_ids, frontend.public_ip_address_key, null)
          }
        }
      )
    }
  ]
  public_ip_address_ids = { for key, ip in azapi_resource.public_ip_addresses : key => ip.id }
}
