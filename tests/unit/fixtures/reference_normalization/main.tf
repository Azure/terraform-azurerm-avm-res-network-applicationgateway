terraform {
  required_version = ">= 1.12, < 2.0"

  required_providers {
    # tflint-ignore: terraform_unused_required_providers
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    # tflint-ignore: terraform_unused_required_providers
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.117, < 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

resource "random_id" "reference" {
  byte_length = 4
}

module "sut" {
  source = "../../../.."

  location                    = "westus2"
  name                        = "gateway"
  parent_id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg"
  authentication_certificates = [{ name = "KnownCertificate" }]
  backend_http_settings_collection = [{
    name = "settings"
    authentication_certificates = [{
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/external/providers/Microsoft.Network/probes/${random_id.reference.hex}"
    }]
    probe = { probe_key = "knownprobe" }
  }]
  enable_telemetry = false
  probes           = [{ name = "KnownProbe" }]
}

output "gateway_name" {
  value = module.sut.name
}
