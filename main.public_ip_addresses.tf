resource "azapi_resource" "public_ip_addresses" {
  for_each = var.public_ip_addresses

  location  = var.location
  name      = each.value.name
  parent_id = coalesce(each.value.parent_id, var.parent_id)
  type      = var.resource_types.network_public_ip_addresses
  body = {
    properties = {
      ddosSettings = {
        ddosProtectionPlan = each.value.ddos_protection_plan_resource_id == null ? null : {
          id = each.value.ddos_protection_plan_resource_id
        }
        protectionMode = each.value.ddos_protection_mode
      }
      dnsSettings = each.value.domain_name_label == null && each.value.reverse_fqdn == null ? null : {
        domainNameLabel = each.value.domain_name_label
        reverseFqdn     = each.value.reverse_fqdn
      }
      idleTimeoutInMinutes = each.value.idle_timeout_in_minutes
      ipTags = [for type, tag in each.value.ip_tags : {
        ipTagType = type
        tag       = tag
      }]
      publicIPAddressVersion   = each.value.ip_version
      publicIPAllocationMethod = "Static"
      publicIPPrefix = each.value.public_ip_prefix_resource_id == null ? null : {
        id = each.value.public_ip_prefix_resource_id
      }
    }
    sku = {
      name = "Standard"
      tier = "Regional"
    }
    zones = each.value.zones == null ? (var.zones == null ? null : sort(var.zones)) : sort(each.value.zones)
  }
  ignore_body_changes  = length(var.ignore_body_changes.network_public_ip_addresses) > 0 ? var.ignore_body_changes.network_public_ip_addresses : null
  ignore_null_property = true
  # AzAPI does not otherwise require replacement when an immutable location changes.
  replace_triggers_external_values = {
    location = lower(replace(var.location, " ", ""))
  }
  replace_triggers_refs = [
    "properties.publicIPAddressVersion",
    "properties.publicIPPrefix.id",
    "zones",
  ]
  response_export_values = {
    fqdn       = "properties.dnsSettings.fqdn"
    ip_address = "properties.ipAddress"
  }
  retry                     = var.retry
  schema_validation_enabled = true
  # TFFR9 permits consumer-settable expressions; remove this exemption when the released checker accepts them.
  # Per-IP tags override inherited module tags without disabling the gateway's tagging rule.
  # tflint-ignore: avm_azapi_resource_tags_required
  tags = merge(coalesce(var.tags, {}), each.value.tags)

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}
