# Orchestration Workflow

If you need to replace the `root.resources.properties.actions` section because you are updating the logic app definition, these are the values that must be replaced (what you get from the Logic App Template export will not be correct).

`Create_file_category_specific_enrichment_data.cases.Case_DigitalText.actions.digitaltextfileworkflow.inputs.host.workflow.id`
Replace `[parameters('workflows_digitaltextfileworkflow_externalid')]` with `[parameters('digitaltextfileworkflowid')]`

`Create_file_category_specific_enrichment_data.cases.Case_Image.actions.imageworkflow.inputs.host.workflow.id`
Replace `[parameters('workflows_imageworkflow_externalid')]` with `[parameters('imageworkflowid')]`

`Create_file_category_specific_enrichment_data.cases.Case_Video.actions.videoworkflow.inputs.host.workflow.id`
Replace `[parameters('workflows_videoworkflow_externalid')]` with `[parameters('videoworkflowid')]`