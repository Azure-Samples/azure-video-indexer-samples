variable "tags" {
  description = "Tags to apply to created resources"
  type        = map(string)
  default = {
    AccountCode        = "enrichmentpipeline-L-D01-T001",
    Budget             = "50000",
    BudgetType         = "One-Time",
    ClientBusinessUnit = "CSE",
    ClientServiceOwner = "Briggs Crew",
    EnvironmentType    = "MVP",
    TagProfile         = "AzShared"
  }
}

variable datalake_enrichmentdata_container_name {
  default = "enrichment-data"
}

variable datalake_input_container_name {
  default = "input"
}

variable resource_group_name {
  default = "enrichmentpipeline-DEV"
}

variable resource_group_location {
  default = "northeurope"
}

variable vi_api_key {
  description = "The API key for accessing the VI API. Docs on how to obtain here: https://docs.microsoft.com/en-us/azure/media-services/video-indexer/video-indexer-use-apis#subscribe-to-the-api"
}

variable vi_api_url {
  description = "The VI API URL. For ex.: https://api.videoindexer.ai"
  default     = "https://api.videoindexer.ai"
}

variable "computer_vision_version" {
  description = "The version of Azure ComputerVision you wish to use for image analysis. This must be in format x.x"
  type        = string
  default     = "3.1"
}
