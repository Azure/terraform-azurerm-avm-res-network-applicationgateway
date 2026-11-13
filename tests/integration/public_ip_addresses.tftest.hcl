# Real Azure: run only with explicit approval and an authenticated test subscription.
# The fixture's location default can be overridden with TF_VAR_location.
provider "azapi" {}

# Required by the module's existing AzureRM support-resource declarations only.
provider "azurerm" {
  features {}
}

provider "random" {}


run "deploy_managed_public_ipv4" {
  command = apply

  module {
    source = "./tests/integration/fixtures/public_ip_addresses"
  }

  assert {
    condition = (
      toset(keys(output.public_ip_addresses)) == toset(["edge"]) &&
      output.public_ip_addresses["edge"].resource_id == output.expected_public_ip_resource_id &&
      can(cidrnetmask("${output.public_ip_addresses["edge"].ip_address}/32")) &&
      output.public_ip_addresses["edge"].fqdn != null
    )
    error_message = "The real deployment must return the managed IPv4 resource ID, allocated IPv4 address, and requested DNS FQDN."
  }

  assert {
    condition = (
      output.gateway_provisioning_state == "Succeeded" &&
      lower(output.attached_public_ip_resource_id) == lower(output.public_ip_addresses["edge"].resource_id) &&
      output.observed_public_ip_address == output.public_ip_addresses["edge"].ip_address &&
      output.observed_public_ip_fqdn == output.public_ip_addresses["edge"].fqdn &&
      output.private_endpoint_resource_id != null &&
      output.private_dns_zone_group_resource_id != null &&
      contains(
        [for id in output.private_endpoint_connection_target_ids : lower(id)],
        lower(output.private_endpoint_resource_id)
      ) &&
      contains(
        [for id in output.private_dns_zone_ids : lower(id)],
        lower(output.expected_private_dns_zone_id)
      )
    )
    error_message = "Independent Azure reads must confirm gateway provisioning, public-IP attachment and values, and created private endpoint and DNS zone group IDs."
  }
}

run "second_plan_retains_identity" {
  command = plan

  module {
    source = "./tests/integration/fixtures/public_ip_addresses"
  }

  assert {
    condition = (
      output.gateway_resource_id == run.deploy_managed_public_ipv4.gateway_resource_id &&
      output.public_ip_addresses["edge"].resource_id == run.deploy_managed_public_ipv4.public_ip_addresses["edge"].resource_id &&
      output.public_ip_addresses["edge"].ip_address == run.deploy_managed_public_ipv4.public_ip_addresses["edge"].ip_address &&
      output.public_ip_addresses["edge"].fqdn == run.deploy_managed_public_ipv4.public_ip_addresses["edge"].fqdn &&
      output.attached_public_ip_resource_id == run.deploy_managed_public_ipv4.attached_public_ip_resource_id &&
      output.private_endpoint_resource_id == run.deploy_managed_public_ipv4.private_endpoint_resource_id &&
      output.private_dns_zone_group_resource_id == run.deploy_managed_public_ipv4.private_dns_zone_group_resource_id &&
      toset(output.private_dns_zone_ids) == toset(run.deploy_managed_public_ipv4.private_dns_zone_ids)
    )
    error_message = "An unchanged second plan must retain gateway/public-IP identity, address, DNS, attachment, and private endpoint resources."
  }

  # Terraform test does not expose the action list; identity is not a full zero-diff assertion.
}
