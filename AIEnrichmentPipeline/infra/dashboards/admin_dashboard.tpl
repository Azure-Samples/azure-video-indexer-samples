{
  "lenses": {
    "0": {
      "order": 0,
      "parts": {
        "0": {
          "position": {
            "x": 0,
            "y": 0,
            "colSpan": 12,
            "rowSpan": 2
          },
          "metadata": {
            "inputs": [],
            "type": "Extension/HubsExtension/PartType/MarkdownPart",
            "settings": {
              "content": {
                "settings": {
                  "content": "After submitting a run through the system this dashboard will provide a very high-level view of the results.\n\nEach run through the system has an associated Correlation ID and there are two queries shown below:\n\n1) A chart showing runs that have errors that come from the Azure Functions or Logic Apps and shows the error count (we now know we need to investigate those items further). \n\n2) A table listing all runs through the system in the chosen time range.\n",
                  "title": "System Run Overview",
                  "subtitle": "Correlation ID",
                  "markdownSource": 1
                }
              }
            }
          }
        },
        "1": {
          "position": {
            "x": 0,
            "y": 2,
            "colSpan": 6,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [
              {
                "name": "resourceTypeMode",
                "isOptional": true
              },
              {
                "name": "ComponentId",
                "isOptional": true
              },
              {
                "name": "Scope",
                "value": {
                  "resourceIds": [
                    "/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/microsoft.insights/components/enrichmentpipeline-appinsights"
                  ]
                },
                "isOptional": true
              },
              {
                "name": "PartId",
                "value": "4a012f84-39ec-4aa0-8144-a030565857a7",
                "isOptional": true
              },
              {
                "name": "Version",
                "value": "2.0",
                "isOptional": true
              },
              {
                "name": "TimeRange",
                "value": "P7D",
                "isOptional": true
              },
              {
                "name": "DashboardId",
                "isOptional": true
              },
              {
                "name": "DraftRequestParameters",
                "isOptional": true
              },
              {
                "name": "Query",
                "value": "// number of exceptions in functions where we have a valid correlation id\r\nlet appTrace = \r\napp(\"${appinsightsid}\").exceptions\r\n| where notempty(customDimensions.CorrelationId)\r\n| project corr=tostring(customDimensions.CorrelationId),from='fn';\r\nlet laTrace = \r\nworkspace(\"${lawid}\").AzureDiagnostics\r\n| where notempty(trackedProperties_correlationId_g)\r\n| where status_s == \"Failed\"\r\n| project corr=trackedProperties_correlationId_g,from='la';\r\nunion\r\nappTrace, laTrace\r\n| summarize Error_Count=count() by Correlation_Id=corr,from\r\n| render columnchart \r\n\r\n",
                "isOptional": true
              },
              {
                "name": "ControlType",
                "value": "FrameControlChart",
                "isOptional": true
              },
              {
                "name": "SpecificChart",
                "value": "StackedColumn",
                "isOptional": true
              },
              {
                "name": "PartTitle",
                "value": "Analytics",
                "isOptional": true
              },
              {
                "name": "PartSubTitle",
                "value": "enrichmentpipeline-appinsights",
                "isOptional": true
              },
              {
                "name": "Dimensions",
                "value": {
                  "xAxis": {
                    "name": "Correlation_Id",
                    "type": "string"
                  },
                  "yAxis": [
                    {
                      "name": "Error_Count",
                      "type": "long"
                    }
                  ],
                  "splitBy": [
                    {
                      "name": "from",
                      "type": "string"
                    }
                  ],
                  "aggregation": "Sum"
                },
                "isOptional": true
              },
              {
                "name": "LegendOptions",
                "value": {
                  "isEnabled": true,
                  "position": "Bottom"
                },
                "isOptional": true
              },
              {
                "name": "IsQueryContainTimeRange",
                "value": false,
                "isOptional": true
              }
            ],
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart",
            "settings": {}
          }
        },
        "2": {
          "position": {
            "x": 6,
            "y": 2,
            "colSpan": 6,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [
              {
                "name": "resourceTypeMode",
                "isOptional": true
              },
              {
                "name": "ComponentId",
                "isOptional": true
              },
              {
                "name": "Scope",
                "value": {
                  "resourceIds": [
                    "/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/microsoft.insights/components/enrichmentpipeline-appinsights"
                  ]
                },
                "isOptional": true
              },
              {
                "name": "PartId",
                "value": "0d981a45-e9f5-4c72-b981-4eb7b71176cb",
                "isOptional": true
              },
              {
                "name": "Version",
                "value": "2.0",
                "isOptional": true
              },
              {
                "name": "TimeRange",
                "value": "P7D",
                "isOptional": true
              },
              {
                "name": "DashboardId",
                "isOptional": true
              },
              {
                "name": "DraftRequestParameters",
                "isOptional": true
              },
              {
                "name": "Query",
                "value": "let corrIdTrace =\r\napp(\"${appinsightsid}\").traces\r\n| where isnotempty(customDimensions.CorrelationId) and message contains \"Started: WorkflowTriggerFunction\"\r\n| project Correlation_ID=tostring(customDimensions.CorrelationId);\r\ncorrIdTrace\r\n| render table\r\n\r\n",
                "isOptional": true
              },
              {
                "name": "ControlType",
                "value": "AnalyticsGrid",
                "isOptional": true
              },
              {
                "name": "SpecificChart",
                "isOptional": true
              },
              {
                "name": "PartTitle",
                "value": "Analytics",
                "isOptional": true
              },
              {
                "name": "PartSubTitle",
                "value": "enrichmentpipeline-appinsights",
                "isOptional": true
              },
              {
                "name": "Dimensions",
                "isOptional": true
              },
              {
                "name": "LegendOptions",
                "isOptional": true
              },
              {
                "name": "IsQueryContainTimeRange",
                "value": false,
                "isOptional": true
              }
            ],
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart",
            "settings": {
              "content": {
                "GridColumnsWidth": {
                  "corr": "384px"
                }
              }
            }
          }
        }
      }
    }
  },
  "metadata": {
    "model": {
      "timeRange": {
        "value": {
          "relative": {
            "duration": 24,
            "timeUnit": 1
          }
        },
        "type": "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange"
      },
      "filterLocale": {
        "value": "en-us"
      },
      "filters": {
        "value": {
          "MsPortalFx_TimeRange": {
            "model": {
              "format": "utc",
              "granularity": "auto",
              "relative": "24h"
            },
            "displayCache": {
              "name": "UTC Time",
              "value": "Past 24 hours"
            },
            "filteredPartIds": [
              "StartboardPart-LogsDashboardPart-1e4722fb-7cf0-4f34-862d-779d47ef600f",
              "StartboardPart-LogsDashboardPart-1e4722fb-7cf0-4f34-862d-779d47ef6013"
            ]
          }
        }
      }
    }
  }
}