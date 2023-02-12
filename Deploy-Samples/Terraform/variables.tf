variable "name" {
  description = "The application name, used to name all resources."
  type        = string
  default     = "tfvidemo"
}

variable "environment" {
  description = "The environment name, used to name all resources."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "stg", "int", "prd"], var.environment)
    error_message = "Invalid input for \"environment\", options: \"dev\", \"stg\", \"int\" and \"prd\"."
  }
}

variable "location" {
  description = "The location of all resources."
  type        = string
  default     = "westeurope"
}

variable "tenant_id" {
  description = "The tenant id which should be used to deploy resources."
  type        = string
  default     = "<Your-Tenant-Id>"
}

variable "subscription_id" {
  description = "The subscription id which should be used to deploy resources."
  type        = string
  default     = "<Your-Subscription-Id>"
}
