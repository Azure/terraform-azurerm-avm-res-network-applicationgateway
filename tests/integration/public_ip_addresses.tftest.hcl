# Real Azure: run only with explicit approval and an authenticated test subscription.
# The fixture's location default can be overridden with TF_VAR_location.
provider "azapi" {}

# Required by the module's existing AzureRM support-resource declarations only.
provider "azurerm" {
  features {}
}

provider "random" {}
provider "modtm" {}

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
      output.observed_public_ip_fqdn == output.public_ip_addresses["edge"].fqdn
    )
    error_message = "Independent Azure reads must confirm successful gateway provisioning, the resolved attachment, and exported public-IP values."
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
      output.attached_public_ip_resource_id == run.deploy_managed_public_ipv4.attached_public_ip_resource_id
    )
    error_message = "An unchanged second plan must retain gateway/public-IP identity, address, DNS, and attachment."
  }

  # Terraform test does not expose the action list; identity is not a full zero-diff assertion.
}
