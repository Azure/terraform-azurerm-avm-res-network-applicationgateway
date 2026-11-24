module "avm_interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "~> 0.6"

  enable_telemetry = false
  location         = var.location
  private_endpoints = {
    for key, endpoint in var.private_endpoints : key => merge(endpoint, {
      name             = coalesce(endpoint.name, format("pep-appGateway-%s", uuidv5("url", "${azapi_resource.this.id}/${key}")))
      subresource_name = coalesce(endpoint.subresource_name, "appGateway")
    })
  }
  private_endpoints_manage_dns_zone_group = var.private_endpoints_manage_dns_zone_group
  private_endpoints_scope                 = azapi_resource.this.id
  role_assignment_definition_scope        = azapi_resource.this.id
}

resource "azapi_resource" "private_endpoints" {
  for_each = var.private_endpoints

  location  = coalesce(each.value.location, azapi_resource.this.location)
  name      = module.avm_interfaces.private_endpoints_azapi[each.key].name
  parent_id = azapi_resource.this.parent_id
  type      = var.resource_types.network_private_endpoints
  body      = module.avm_interfaces.private_endpoints_azapi[each.key].body

  ignore_body_changes    = length(var.ignore_body_changes.network_private_endpoints) > 0 ? var.ignore_body_changes.network_private_endpoints : null
  replace_triggers_refs = [
    "properties.subnet.id",
    "properties.privateLinkServiceConnections[0].properties.privateLinkServiceId",
  ]
  response_export_values = []
  retry                  = var.retry
  tags                   = module.avm_interfaces.private_endpoints_azapi[each.key].tags == null ? var.tags : module.avm_interfaces.private_endpoints_azapi[each.key].tags

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

module "private_dns_zone_groups" {
  source   = "./modules/private_dns_zone_group"
  for_each = {
    for key, endpoint in var.private_endpoints : key => endpoint
    if endpoint != null && var.private_endpoints_manage_dns_zone_group && length(endpoint.private_dns_zone_resource_ids) > 0
  }

  name                = module.avm_interfaces.private_dns_zone_groups_azapi[each.key].name
  parent_id           = azapi_resource.private_endpoints[each.key].id
  body                = module.avm_interfaces.private_dns_zone_groups_azapi[each.key].body
  resource_types      = var.resource_types.network_private_endpoints_private_dns_zone_groups
  retry               = var.retry
  timeouts            = var.timeouts
  ignore_body_changes = var.ignore_body_changes.network_private_endpoints_private_dns_zone_groups
}

resource "azapi_resource" "private_endpoint_role_assignments" {
  for_each = module.avm_interfaces.role_assignments_private_endpoint_azapi

  name      = each.value.name
  parent_id = azapi_resource.private_endpoints[each.value.pe_key].id
  type      = var.resource_types.authorization_role_assignments
  body      = each.value.body

  ignore_body_changes    = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  replace_triggers_refs = [
    "properties.principalId",
    "properties.roleDefinitionId",
  ]
  response_export_values = []
  retry                  = var.retry

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

resource "azapi_resource" "private_endpoint_locks" {
  for_each = module.avm_interfaces.lock_private_endpoint_azapi

  name      = each.value.name
  parent_id = azapi_resource.private_endpoints[each.value.pe_key].id
  type      = var.resource_types.authorization_locks
  body      = each.value.body

  ignore_body_changes    = length(var.ignore_body_changes.authorization_locks) > 0 ? var.ignore_body_changes.authorization_locks : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [
    module.private_dns_zone_groups,
    azapi_resource.private_endpoint_role_assignments,
  ]
}
