package Azure_Proactive_Resiliency_Library_v2

import rego.v1

# The upstream AzAPI rule reads min_capacity instead of ARM's minCapacity.
# https://github.com/Azure/policy-library-avm/pull/58
# Replace only that broken check; retain enforcement with the corrected rule below.
exception contains rules if {
  rules := ["application_gateway_ensure_autoscale_feature_has_been_enabled"]
}

named_child_reference_autoscale_valid(resource) if {
  is_number(resource.values.body.properties.autoscaleConfiguration.minCapacity)
  resource.values.body.properties.autoscaleConfiguration.minCapacity > 1
}

deny_named_child_reference_autoscale_uses_arm_schema contains reason if {
  resource := data.utils.resource(input, "azapi_resource")[_]
  data.utils.is_azure_type(resource.values, "Microsoft.Network/applicationGateways")
  not named_child_reference_autoscale_valid(resource)

  reason := sprintf("'%s' must configure ARM autoscaleConfiguration.minCapacity greater than 1.", [resource.address])
}
