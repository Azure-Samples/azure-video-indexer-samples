variable "resource_group_name" {
  type = string
  default = "vi-dev-mediastore-rg"
}

variable "location" {
  type = string
  default = "west Us 2"
}

variable "prefix" {
  type = string
  default = "vimediastore"
}

resource "random_string" "random" {
  length  = 4
  special = false
  upper   = false
  number  = false
}

variable "tenant_id" {
  description = "The tenant id which should be used."
  type = string
}

variable "subscription_id" {
  description = "The subscription id which should be used."
  type = string
}

variable "tags" {
  type = map
  default = {
    "env" : "development",
    "author" : "me@email.com"
  }
}
