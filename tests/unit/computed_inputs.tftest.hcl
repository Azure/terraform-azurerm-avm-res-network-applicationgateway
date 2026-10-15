mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}
mock_provider "azurerm" {}
mock_provider "random" {}

run "plans_with_upstream_computed_parent_and_names" {
  command = plan

  module {
    source = "./tests/unit/fixtures/computed"
  }
}
