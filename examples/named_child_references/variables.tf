variable "location" {
  type        = string
  default     = "eastus2"
  description = "Azure region for the isolated E2E deployment."
  nullable    = false
}

variable "public_ip_tags" {
  type        = map(string)
  default     = {}
  description = "Environment-required IP tag types and values. Supply through TF_VAR_public_ip_tags as a JSON map."
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = { purpose = "avm-named-reference-e2e" }
  description = "Tags applied to the temporary resources."
  nullable    = false
}

variable "use_reference_names" {
  type        = bool
  default     = true
  description = "Use named internal references. Setting false constructs equivalent explicit IDs for a compatibility plan."
  nullable    = false
}

variable "enable_telemetry" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}
