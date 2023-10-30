# resource "null_resource" "generate_ssl_certificate" {
#   triggers = {
#     # Add a trigger to force the script to run when any of these values change.
#     always_run = "${timestamp()}"
#   }

#   provisioner "local-exec" {
#     command = "bash generate_ssl_certificate.sh"
#   }
#   depends_on = [ azurerm_resource_group.rg-group,azurerm_virtual_network.vnet,module.application-gateway ]
# }

resource "null_resource" "generate_ssl_certificate" {
  triggers = {
    script_content = sha1(file("generate_ssl_certificate.sh"))
  }

  provisioner "local-exec" {
    command = "bash generate_ssl_certificate.sh"
  }

  # This `depends_on` block ensures the script runs after specific resources.

  # This local-exec provisioner will only run once during initialization.
  # It's only needed to ensure the script runs initially, so it doesn't need
  # to run every time you apply changes.

}