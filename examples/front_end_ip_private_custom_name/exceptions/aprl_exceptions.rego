package Azure_Proactive_Resiliency_Library_v2

import rego.v1

# APRL policy bug: policy checks min_capacity (snake_case) but azapi body uses minCapacity (camelCase).
# Tracked upstream: https://github.com/Azure/policy-library-avm/pull/58
# conftest exception rule names omit the deny_ prefix.
exception contains rules if {
  rules := ["application_gateway_ensure_autoscale_feature_has_been_enabled"]
}
