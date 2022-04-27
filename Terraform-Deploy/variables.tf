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
  type = string
  default = "<Your_Tenant_ID>"
}
variable "subscription_id" {
  type = string
  default = "<Your_Subscription_ID>"
}

variable "tags" {
  type = map
  default = {
    "env" : "development",
    "author" : "me@email.com"
  }
}
