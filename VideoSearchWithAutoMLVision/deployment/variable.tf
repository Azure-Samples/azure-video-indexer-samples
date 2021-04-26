variable "subscription_id" {
  description = "Subscription ID to deploy resources to."
}

variable "resource_group_name" {
  description = "Resource group to deploy resources to."
}

variable "location" {
  description = "Azure region to deploy resources to."
}

variable "search_clips_interval_milliseconds" {
  description = "Desired length of clips returned as search results (in milliseconds)"
  default     = "10000"
}

variable "parser_api_key" {
  description = "Key to set up for auth with the parser API"
}

variable "parser_docker_registry_url" {
  description = "URL to the docker registry from which to pull the image used to set up the parser API"
  default     = "shanepeckham"
}

variable "classifierpowerskill_api_key" {
  description = "Custom auth key with which to deploy the AutoML classifier power skill."
}
