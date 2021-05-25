variable shared_env {
  type = any
}
variable releases_storage_account_name {
  type = string
}
variable releases_storage_account_key {
  type = string
}
variable releases_container_name {
  type = string
}
variable releases_storage_sas {
  type = string
}
variable function_name {
  type = string
}
variable app_service_plan_id {
  type = string
}
variable app_settings {
  description = "The app settings to get set for the function"
  default     = {}
}
