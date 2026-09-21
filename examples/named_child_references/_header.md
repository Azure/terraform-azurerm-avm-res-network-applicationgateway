# Named child-reference E2E example

Deploys an isolated Application Gateway, public IP, VNet and subnet using
case-insensitive named references for frontend IP/port, listener, backend pool,
backend HTTP settings and health probe. Azure readback postconditions verify
the resulting child IDs. All supporting Azure resources use AzAPI.

Run `avm test e2e --example named_child_references` from the module root for
deployment, no-change planning and automatic teardown. This creates billable
resources; use an approved test subscription and region.

Supply environment-required public IP classifications through the
`TF_VAR_public_ip_tags` JSON-map environment variable. No environment-specific
value is embedded in the example.

For a manual compatibility comparison, deploy with the default
`use_reference_names = true`, then run a second no-change plan with
`-var=use_reference_names=false -detailed-exitcode` against the same state.
Both the unchanged named configuration and equivalent ID configuration must
return exit code 0, not 2. Destroy the example after the comparison.

The backend pool is intentionally empty. This exercises real Azure
control-plane deployment and reference resolution, not application HTTP
traffic, TLS certificates, or every optional gateway feature.
