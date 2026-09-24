mock_provider "azapi" {}
mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}

run "plans_with_upstream_computed_parent_and_names" {
  command = plan

  module {
    source = "./tests/unit/fixtures/computed"
  }
}
