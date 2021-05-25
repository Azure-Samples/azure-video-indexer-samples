output "video_logic_app_details" {
  value = module.video_workflow.logic_app_details
}

output "image_logic_app_details" {
  value = module.image_workflow.logic_app_details
}

output "orchestration_logic_app_details" {
  value = module.orchestration_workflow.logic_app_details
}

output "digitaltextfile_logic_app_details" {
  value = module.digitaltextfile_workflow.logic_app_details
}

output "video_indexer_account_id" {
  value = module.video_indexer.account_id
}

output "video_indexer_sp_name" {
  value = module.video_indexer.sp_name
}

output "video_indexer_storage_account_name" {
  value = module.video_indexer.media_storage_account_name
}

output "media_services_account_name" {
  value = module.video_indexer.media_services_account_name
}

output "media_services_resource_group_name" {
  value = module.video_indexer.resource_group_name
}

output "core_storage_account" {
  value = module.core.storage_account
}

output "workflowtrigger_function_details" {
  value = module.workflowtrigger_function.function_details
}

output "exporter_queue_name" {
  value = module.core.exporter_queue_name
}

output "exporter_namespace_name" {
  value = module.core.exporter_queue_namespace_name
}

output "trigger_queue_name" {
  value = module.core.trigger_queue_name
}

output "trigger_namespace_name" {
  value = module.core.trigger_queue_namespace_name
}

output "core_appinsights_name" {
  value = module.core.appinsights_name
}

output "core_appinsights_resource_group" {
  value = module.core.appinsights_resource_group
}

output "resource_group_location" {
  value = var.resource_group_location
}
