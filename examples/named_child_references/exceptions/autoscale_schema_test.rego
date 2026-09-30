package Azure_Proactive_Resiliency_Library_v2

import rego.v1

test_named_child_reference_autoscale_accepts_arm_minimum if {
  named_child_reference_autoscale_valid({
    "values": {"body": {"properties": {"autoscaleConfiguration": {"minCapacity": 2}}}}
  })
}

test_named_child_reference_autoscale_rejects_minimum_one if {
  not named_child_reference_autoscale_valid({
    "values": {"body": {"properties": {"autoscaleConfiguration": {"minCapacity": 1}}}}
  })
}

test_named_child_reference_autoscale_rejects_missing_configuration if {
  not named_child_reference_autoscale_valid({
    "values": {"body": {"properties": {}}}
  })
}

test_named_child_reference_autoscale_rejects_snake_case if {
  not named_child_reference_autoscale_valid({
    "values": {"body": {"properties": {"autoscaleConfiguration": {"min_capacity": 2}}}}
  })
}
