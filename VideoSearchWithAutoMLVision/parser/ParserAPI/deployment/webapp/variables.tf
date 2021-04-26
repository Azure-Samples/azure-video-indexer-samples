variable "docker_registry_url" {
}

variable "docker_registry_username" {
 default = ""
}

variable "docker_registry_password" {
 default = ""
}

variable "docker_image" {
  default = "shanepeckham/parserapi:v1"
}

variable "debug" {
  default = false
}

variable "key" {
}

variable "milliseconds_interval" {
}

variable "resource_group" {
  description = "This is the name of an existing resource group to deploy to"
}

variable "location" {
  description = "This is the region of an existing resource group you want to deploy to"
  default = "eastus2"
}

variable "general_storage_account_name" {
  description = "General storage account used for the project."
}

variable "app_service_plan_id" {
  description = "ID of the app service plan resource to deploy on."
}

variable "resource_suffix" {
  description = "Optional suffix to append to resource names to avoid naming collisions."
  default = ""
}