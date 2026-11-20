mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}
mock_provider "azurerm" {}
mock_provider "random" {}

variables {
  enable_telemetry = false
  location         = "westus2"
  name             = "gateway"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg"
}

run "omitted_certificates_remain_null" {
  command = apply

  assert {
    condition = (
      azapi_resource.this.body.properties.sslCertificates == null &&
      local.resource_sensitive_body.properties.sslCertificates == null
    )
    error_message = "Omitted certificates must remain null in both request bodies."
  }
}

run "empty_certificates_remain_empty" {
  command = apply

  variables {
    ssl_certificates = []
  }

  assert {
    condition = (
      length(azapi_resource.this.body.properties.sslCertificates) == 0 &&
      length(local.resource_sensitive_body.properties.sslCertificates) == 0
    )
    error_message = "An explicitly empty certificate list must remain empty in both request bodies."
  }
}

run "separates_secrets_from_public_certificate_metadata" {
  command = apply

  variables {
    ssl_certificates = [
      null,
      { name = "metadata-only" },
      {
        name                = "key-vault"
        key_vault_secret_id = "https://example.vault.azure.net/secrets/certificate"
      },
      {
        name     = "uploaded"
        data     = "test-certificate-data"
        password = "test-only-password"
      },
      {
        name     = "empty-password"
        data     = "test-certificate-data"
        password = ""
      },
    ]
  }

  assert {
    condition = alltrue([
      for certificate in azapi_resource.this.body.properties.sslCertificates :
      certificate == null ? true : (
        certificate.properties == null ? true : (
          !contains(keys(certificate.properties), "data") &&
          !contains(keys(certificate.properties), "password")
        )
      )
    ])
    error_message = "Certificate data and passwords must never be present in the persisted body."
  }

  assert {
    condition = alltrue([
      local.resource_sensitive_body.properties.sslCertificates[0] == null,
      local.resource_sensitive_body.properties.sslCertificates[1].properties == null,
      azapi_resource.this.body.properties.sslCertificates[2].properties.keyVaultSecretId == "https://example.vault.azure.net/secrets/certificate",
      local.resource_sensitive_body.properties.sslCertificates[3].name == "uploaded",
      local.resource_sensitive_body.properties.sslCertificates[3].properties.data == "test-certificate-data",
      local.resource_sensitive_body.properties.sslCertificates[3].properties.password == "test-only-password",
      local.resource_sensitive_body.properties.sslCertificates[4].properties.password == "",
    ])
    error_message = "The write-only body must preserve certificate ordering, names, data, and passwords while Key Vault references remain public."
  }

  assert {
    condition     = azapi_resource.this.sensitive_body_version["properties.sslCertificates"] == sha256(jsonencode(local.resource_sensitive_body.properties.sslCertificates))
    error_message = "The write-only certificate list must have a non-secret change fingerprint."
  }
}

run "certificate_data_rotation_changes_version" {
  command = plan

  variables {
    ssl_certificates = [{
      name     = "uploaded"
      data     = "rotated-test-certificate-data"
      password = "test-only-password"
    }]
  }

  assert {
    condition = azapi_resource.this.sensitive_body_version["properties.sslCertificates"] != sha256(jsonencode([{
      name = "uploaded"
      properties = {
        data     = "test-certificate-data"
        password = "test-only-password"
      }
    }]))
    error_message = "Changing only certificate data must change its write-only version."
  }
}

run "certificate_password_rotation_changes_version" {
  command = plan

  variables {
    ssl_certificates = [{
      name     = "uploaded"
      data     = "test-certificate-data"
      password = "rotated-test-only-password"
    }]
  }

  assert {
    condition = azapi_resource.this.sensitive_body_version["properties.sslCertificates"] != sha256(jsonencode([{
      name = "uploaded"
      properties = {
        data     = "test-certificate-data"
        password = "test-only-password"
      }
    }]))
    error_message = "Changing only the certificate password must change its write-only version."
  }
}
