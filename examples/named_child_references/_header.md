# Keyed child-reference E2E example

Deploys an isolated Application Gateway, public IP, VNet and subnet using
case-insensitive type-specific reference keys for frontend IP/port, listener,
backend pool, backend HTTP settings and health probe. Each key selects the
matching component's configured `name`; it is not a separate alias. Azure
readback postconditions verify the resulting child IDs. All supporting Azure
resources use AzAPI.

The gateway subnet is delegated to `Microsoft.Network/applicationGateways`.
The gateway uses autoscaling with minimum capacity 2 and maximum capacity 3,
and both the gateway and Standard public IP use availability zones 1, 2 and 3.
Use a region that supports these zones.

Run `avm test e2e --example named_child_references` from the module root for
deployment, no-change planning and automatic teardown. This creates billable
resources; use an approved test subscription and region.

Supply environment-required public IP classifications through the
`TF_VAR_public_ip_tags` JSON-map environment variable. No environment-specific
value is embedded in the example.

For a manual compatibility comparison, deploy with the default
`use_reference_keys = true`, then run a second no-change plan with
`-var=use_reference_keys=false -detailed-exitcode` against the same state.
Both the unchanged keyed configuration and equivalent ID configuration must
return exit code 0, not 2. Destroy the example after the comparison.

The backend pool is intentionally empty. This exercises real Azure
control-plane deployment and reference resolution, not application HTTP
traffic, TLS certificates, or every optional gateway feature.

The example-scoped policy file temporarily replaces the upstream autoscale
check's incorrect `min_capacity` lookup with an enforced `minCapacity` check.
The other resiliency policies remain enabled. Remove this compatibility rule
after [the upstream fix](https://github.com/Azure/policy-library-avm/pull/58)
is available in the policy version used by authoring.
