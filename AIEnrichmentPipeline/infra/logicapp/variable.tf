variable "shared_env" {
  type = any
}
variable "parameters" {
  description = "The parameters passed to the workflow"
  default     = {}
}
variable "law_id" {}
variable "law_key" {}
variable "workflow_name" {}