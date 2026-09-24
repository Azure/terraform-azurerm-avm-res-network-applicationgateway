resource "azapi_resource" "this" {
  location             = var.location
  name                 = var.name
  parent_id            = var.parent_id
  type                 = var.resource_types.network_application_gateways
  body                 = local.resource_body
  ignore_body_changes  = length(var.ignore_body_changes.network_application_gateways) > 0 ? var.ignore_body_changes.network_application_gateways : null
  ignore_null_property = true
  list_unique_id_property = {
    "properties.frontendIPConfigurations"                        = "name"
    "properties.backendAddressPools"                             = "name"
    "properties.backendHttpSettingsCollection"                   = "name"
    "properties.frontendPorts"                                   = "name"
    "properties.backendAddressPools.properties.backendAddresses" = "ipAddress"
  }
  response_export_values = [
    "identity.principalId",
    "identity.tenantId",
  ]
  retry                     = var.retry
  schema_validation_enabled = true
  tags                      = var.tags

  dynamic "identity" {
    for_each = local.managed_identities.system_assigned_user_assigned

    content {
      type         = identity.value.type
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  lifecycle {
    ignore_changes = [body.properties.firewallPolicy]

    precondition {
      condition     = length(local.invalid_child_reference_shape_paths) == 0
      error_message = "Internal child references must use either id or their nested *_key, not both. Redirect path rule references require path_rule_key together with url_path_map_key and cannot combine id with either key. Invalid references: ${join(", ", local.invalid_child_reference_shape_paths)}."
    }
    precondition {
      condition     = length(local.invalid_child_reference_key_paths) == 0
      error_message = "Internal child reference keys, including parent URL path map keys, must be nonblank single component names without '/'. Invalid references: ${join(", ", local.invalid_child_reference_key_paths)}."
    }
    precondition {
      condition     = length(local.unresolved_child_reference_paths) == 0
      error_message = "Each internal reference key must case-insensitively match exactly one corresponding component's configured name. Path rule keys must identify exactly one URL path map and one path rule within it. Missing or ambiguous references: ${join(", ", local.unresolved_child_reference_paths)}."
    }
  }
}

moved {
  from = azurerm_application_gateway.this
  to   = azapi_resource.this
}

resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azapi_resource.this.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azapi_resource.this.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.diagnostic_settings

  name                           = each.value.name != null ? each.value.name : "diag-${var.name}"
  target_resource_id             = azapi_resource.this.id
  eventhub_authorization_rule_id = each.value.event_hub_authorization_rule_resource_id
  eventhub_name                  = each.value.event_hub_name
  log_analytics_destination_type = each.value.log_analytics_destination_type
  log_analytics_workspace_id     = each.value.workspace_resource_id
  partner_solution_id            = each.value.marketplace_partner_resource_id
  storage_account_id             = each.value.storage_account_resource_id

  dynamic "enabled_log" {
    for_each = each.value.log_categories

    content {
      category = enabled_log.value
    }
  }
  dynamic "enabled_log" {
    for_each = each.value.log_groups

    content {
      category_group = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = each.value.metric_categories

    content {
      category = metric.value
    }
  }
}
