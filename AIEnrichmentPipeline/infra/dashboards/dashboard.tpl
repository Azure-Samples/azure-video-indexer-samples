{
  "lenses": {
    "0": {
      "order": 0,
      "parts": {
        "0": {
          "position": {
            "x": 0,
            "y": 0,
            "colSpan": 4,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "aggregationType": 7,
                        "metricVisualization": {
                          "color": "#EC008C",
                          "displayName": "Failed requests",
                          "resourceDisplayName": "enrichmentpipeline-appinsights"
                        },
                        "name": "requests/failed",
                        "namespace": "microsoft.insights/components",
                        "resourceMetadata": {
                          "id": "/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/Microsoft.Insights/components/enrichmentpipeline-appinsights"
                        }
                      }
                    ],
                    "openBladeOnClick": {
                      "destinationBlade": {
                        "bladeName": "ResourceMenuBlade",
                        "extensionName": "HubsExtension",
                        "options": {
                          "parameters": {
                            "id": "/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/Microsoft.Insights/components/enrichmentpipeline-appinsights",
                            "menuid": "failures"
                          }
                        },
                        "parameters": {
                          "id": "/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/Microsoft.Insights/components/enrichmentpipeline-appinsights",
                          "menuid": "failures"
                        }
                      },
                      "openBlade": true
                    },
                    "title": "Failed requests",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 3
                    }
                  }
                },
                "isOptional": true
              },
              {
                "name": "sharedTimeRange",
                "isOptional": true
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "aggregationType": 7,
                        "metricVisualization": {
                          "color": "#EC008C",
                          "displayName": "Failed requests",
                          "resourceDisplayName": "enrichmentpipeline-appinsights"
                        },
                        "name": "requests/failed",
                        "namespace": "microsoft.insights/components",
                        "resourceMetadata": {
                          "id": "/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/Microsoft.Insights/components/enrichmentpipeline-appinsights"
                        }
                      }
                    ],
                    "openBladeOnClick": {
                      "destinationBlade": {
                        "bladeName": "ResourceMenuBlade",
                        "extensionName": "HubsExtension",
                        "options": {
                          "parameters": {
                            "id": "/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/Microsoft.Insights/components/enrichmentpipeline-appinsights",
                            "menuid": "failures"
                          }
                        },
                        "parameters": {
                          "id": "/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/Microsoft.Insights/components/enrichmentpipeline-appinsights",
                          "menuid": "failures"
                        }
                      },
                      "openBlade": true
                    },
                    "title": "Failed requests",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 3,
                      "disablePinning": true
                    }
                  }
                }
              }
            },
            "filters": {
              "MsPortalFx_TimeRange": {
                "model": {
                  "format": "local",
                  "granularity": "auto",
                  "relative": "4320m"
                }
              }
            }
          }
        },
        "1": {
          "position": {
            "x": 4,
            "y": 0,
            "colSpan": 4,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "options",
                "isOptional": true
              },
              {
                "name": "sharedTimeRange",
                "isOptional": true
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "aggregationType": 1,
                        "metricVisualization": {
                          "displayName": "Exceptions"
                        },
                        "name": "exceptions/count",
                        "namespace": "microsoft.insights/components/kusto",
                        "resourceMetadata": {
                          "id": "/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/Microsoft.Insights/components/enrichmentpipeline-appinsights"
                        }
                      }
                    ],
                    "title": "Sum Exceptions for enrichmentpipeline-appinsights",
                    "titleKind": 1,
                    "visualization": {
                      "axisVisualization": {
                        "x": {
                          "axisType": 2,
                          "isVisible": true
                        },
                        "y": {
                          "axisType": 1,
                          "isVisible": true
                        }
                      },
                      "chartType": 2,
                      "disablePinning": true,
                      "legendVisualization": {
                        "hideSubtitle": false,
                        "isVisible": true,
                        "position": 2
                      }
                    }
                  }
                }
              }
            },
            "filters": {
              "MsPortalFx_TimeRange": {
                "model": {
                  "format": "utc",
                  "granularity": "auto",
                  "relative": "4320m"
                }
              }
            }
          }
        },
        "2": {
          "position": {
            "x": 8,
            "y": 0,
            "colSpan": 2,
            "rowSpan": 1
          },
          "metadata": {
            "inputs": [
              {
                "name": "ComponentId",
                "value": {
                  "IsAzureFirst": false,
                  "LinkedApplicationType": 0,
                  "Name": "enrichmentpipeline-appinsights",
                  "ResourceGroup": "${rgname}",
                  "ResourceId": "/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/Microsoft.Insights/components/enrichmentpipeline-appinsights",
                  "ResourceType": "microsoft.insights/components",
                  "SubscriptionId": "${subscriptionid}"
                }
              },
              {
                "name": "ResourceIds",
                "value": [
                  "/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/Microsoft.Insights/components/enrichmentpipeline-appinsights"
                ],
                "isOptional": true
              },
              {
                "name": "Type",
                "value": "tsg",
                "isOptional": true
              },
              {
                "name": "TimeContext",
                "isOptional": true
              },
              {
                "name": "ConfigurationId",
                "value": "community-Workbooks/TSG/Performance Counter TSG",
                "isOptional": true
              },
              {
                "name": "ViewerMode",
                "value": false,
                "isOptional": true
              },
              {
                "name": "GalleryResourceType",
                "value": "microsoft.insights/components",
                "isOptional": true
              },
              {
                "name": "NotebookParams",
                "isOptional": true
              },
              {
                "name": "Location",
                "isOptional": true
              },
              {
                "name": "Version",
                "value": "1.0",
                "isOptional": true
              }
            ],
            "type": "Extension/AppInsightsExtension/PartType/NotebookPinnedPart",
            "viewState": {
              "content": {
                "configurationId": "community-Workbooks/TSG/Performance Counter TSG"
              }
            }
          }
        },
        "3": {
          "position": {
            "x": 14,
            "y": 0,
            "colSpan": 4,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${subscriptionid}/resourceGroups/${rgname}-ml/providers/Microsoft.Web/serverfarms/mlappserviceplan"
                        },
                        "name": "MemoryPercentage",
                        "aggregationType": 4,
                        "metricVisualization": {
                          "displayName": "Memory Percentage",
                          "resourceDisplayName": "mlappserviceplan"
                        }
                      }
                    ],
                    "title": "Memory Percentage",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2
                    },
                    "openBladeOnClick": {
                      "openBlade": true
                    }
                  }
                },
                "isOptional": true
              },
              {
                "name": "sharedTimeRange",
                "isOptional": true
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${subscriptionid}/resourceGroups/${rgname}-ml/providers/Microsoft.Web/serverfarms/mlappserviceplan"
                        },
                        "name": "MemoryPercentage",
                        "aggregationType": 4,
                        "metricVisualization": {
                          "displayName": "Memory Percentage",
                          "resourceDisplayName": "mlappserviceplan"
                        }
                      }
                    ],
                    "title": "Memory Percentage",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "disablePinning": true
                    },
                    "openBladeOnClick": {
                      "openBlade": true
                    }
                  }
                }
              }
            },
            "filters": {
              "MsPortalFx_TimeRange": {
                "model": {
                  "format": "local",
                  "granularity": "1m",
                  "relative": "60m"
                }
              }
            }
          }
        },
        "4": {
          "position": {
            "x": 8,
            "y": 1,
            "colSpan": 2,
            "rowSpan": 1
          },
          "metadata": {
            "inputs": [
              {
                "name": "ComponentId",
                "value": {
                  "IsAzureFirst": false,
                  "LinkedApplicationType": 0,
                  "Name": "enrichmentpipeline-appinsights",
                  "ResourceGroup": "${rgname}",
                  "ResourceId": "/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/Microsoft.Insights/components/enrichmentpipeline-appinsights",
                  "ResourceType": "microsoft.insights/components",
                  "SubscriptionId": "${subscriptionid}"
                }
              },
              {
                "name": "ResourceIds",
                "value": [
                  "/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/Microsoft.Insights/components/enrichmentpipeline-appinsights"
                ],
                "isOptional": true
              },
              {
                "name": "Type",
                "value": "workbook",
                "isOptional": true
              },
              {
                "name": "TimeContext",
                "isOptional": true
              },
              {
                "name": "ConfigurationId",
                "value": "Community-Workbooks/Failures/New Failures Analysis",
                "isOptional": true
              },
              {
                "name": "ViewerMode",
                "value": false,
                "isOptional": true
              },
              {
                "name": "GalleryResourceType",
                "value": "microsoft.insights/components",
                "isOptional": true
              },
              {
                "name": "NotebookParams",
                "isOptional": true
              },
              {
                "name": "Location",
                "isOptional": true
              },
              {
                "name": "Version",
                "value": "1.0",
                "isOptional": true
              }
            ],
            "type": "Extension/AppInsightsExtension/PartType/NotebookPinnedPart",
            "viewState": {
              "content": {
                "configurationId": "Community-Workbooks/Failures/New Failures Analysis"
              }
            }
          }
        },
        "5": {
          "position": {
            "x": 0,
            "y": 3,
            "colSpan": 10,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [
              {
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "aggregationType": 1,
                        "metricVisualization": {
                          "displayName": "Actions Completed ",
                          "resourceDisplayName": "digitaltextfileworkflow"
                        },
                        "name": "ActionsCompleted",
                        "namespace": "microsoft.logic/workflows",
                        "resourceMetadata": {
                          "id": "/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/Microsoft.Logic/workflows/digitaltextfileworkflow"
                        }
                      },
                      {
                        "aggregationType": 1,
                        "metricVisualization": {
                          "displayName": "Actions Completed ",
                          "resourceDisplayName": "imageworkflow"
                        },
                        "name": "ActionsCompleted",
                        "namespace": "microsoft.logic/workflows",
                        "resourceMetadata": {
                          "id": "/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/Microsoft.Logic/workflows/imageworkflow"
                        }
                      },
                      {
                        "aggregationType": 1,
                        "metricVisualization": {
                          "displayName": "Actions Completed ",
                          "resourceDisplayName": "orchestrationworkflow"
                        },
                        "name": "ActionsCompleted",
                        "namespace": "microsoft.logic/workflows",
                        "resourceMetadata": {
                          "id": "/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/Microsoft.Logic/workflows/orchestrationworkflow"
                        }
                      },
                      {
                        "aggregationType": 1,
                        "metricVisualization": {
                          "displayName": "Actions Completed ",
                          "resourceDisplayName": "videoworkflow"
                        },
                        "name": "ActionsCompleted",
                        "namespace": "microsoft.logic/workflows",
                        "resourceMetadata": {
                          "id": "/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/Microsoft.Logic/workflows/videoworkflow"
                        }
                      },
                      {
                        "aggregationType": 1,
                        "metricVisualization": {
                          "displayName": "Requests",
                          "resourceDisplayName": "duplicatesdetection-swlrx"
                        },
                        "name": "Requests",
                        "namespace": "microsoft.web/sites",
                        "resourceMetadata": {
                          "id": "/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/Microsoft.Web/sites/duplicatesdetection-swlrx"
                        }
                      },
                      {
                        "aggregationType": 1,
                        "metricVisualization": {
                          "displayName": "Requests",
                          "resourceDisplayName": "nuixvalidator-zlqlk"
                        },
                        "name": "Requests",
                        "namespace": "microsoft.web/sites",
                        "resourceMetadata": {
                          "id": "/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/Microsoft.Web/sites/nuixvalidator-zlqlk"
                        }
                      },
                      {
                        "aggregationType": 4,
                        "metricVisualization": {
                          "displayName": "Requests",
                          "resourceDisplayName": "workflowtrigger-elnzm"
                        },
                        "name": "Requests",
                        "namespace": "microsoft.web/sites",
                        "resourceMetadata": {
                          "id": "/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/Microsoft.Web/sites/workflowtrigger-elnzm"
                        }
                      }
                    ],
                    "timespan": {
                      "grain": 1,
                      "relative": {
                        "duration": 43200000
                      },
                      "showUTCTime": false
                    },
                    "title": "Sum Actions Completed  for digitaltextfileworkflow, Sum Actions Completed  for imageworkflow, and 5 other metrics",
                    "titleKind": 1,
                    "visualization": {
                      "axisVisualization": {
                        "x": {
                          "axisType": 2,
                          "isVisible": true
                        },
                        "y": {
                          "axisType": 1,
                          "isVisible": true
                        }
                      },
                      "chartType": 1,
                      "legendVisualization": {
                        "hideSubtitle": false,
                        "isVisible": true,
                        "position": 2
                      }
                    }
                  }
                },
                "isOptional": true
              },
              {
                "name": "sharedTimeRange",
                "isOptional": true
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "aggregationType": 1,
                        "metricVisualization": {
                          "displayName": "Actions Completed ",
                          "resourceDisplayName": "digitaltextfileworkflow"
                        },
                        "name": "ActionsCompleted",
                        "namespace": "microsoft.logic/workflows",
                        "resourceMetadata": {
                          "id": "/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/Microsoft.Logic/workflows/digitaltextfileworkflow"
                        }
                      },
                      {
                        "aggregationType": 1,
                        "metricVisualization": {
                          "displayName": "Actions Completed ",
                          "resourceDisplayName": "imageworkflow"
                        },
                        "name": "ActionsCompleted",
                        "namespace": "microsoft.logic/workflows",
                        "resourceMetadata": {
                          "id": "/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/Microsoft.Logic/workflows/imageworkflow"
                        }
                      },
                      {
                        "aggregationType": 1,
                        "metricVisualization": {
                          "displayName": "Actions Completed ",
                          "resourceDisplayName": "orchestrationworkflow"
                        },
                        "name": "ActionsCompleted",
                        "namespace": "microsoft.logic/workflows",
                        "resourceMetadata": {
                          "id": "/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/Microsoft.Logic/workflows/orchestrationworkflow"
                        }
                      },
                      {
                        "aggregationType": 1,
                        "metricVisualization": {
                          "displayName": "Actions Completed ",
                          "resourceDisplayName": "videoworkflow"
                        },
                        "name": "ActionsCompleted",
                        "namespace": "microsoft.logic/workflows",
                        "resourceMetadata": {
                          "id": "/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/Microsoft.Logic/workflows/videoworkflow"
                        }
                      },
                      {
                        "aggregationType": 1,
                        "metricVisualization": {
                          "displayName": "Requests",
                          "resourceDisplayName": "duplicatesdetection-swlrx"
                        },
                        "name": "Requests",
                        "namespace": "microsoft.web/sites",
                        "resourceMetadata": {
                          "id": "/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/Microsoft.Web/sites/duplicatesdetection-swlrx"
                        }
                      },
                      {
                        "aggregationType": 1,
                        "metricVisualization": {
                          "displayName": "Requests",
                          "resourceDisplayName": "nuixvalidator-zlqlk"
                        },
                        "name": "Requests",
                        "namespace": "microsoft.web/sites",
                        "resourceMetadata": {
                          "id": "/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/Microsoft.Web/sites/nuixvalidator-zlqlk"
                        }
                      },
                      {
                        "aggregationType": 4,
                        "metricVisualization": {
                          "displayName": "Requests",
                          "resourceDisplayName": "workflowtrigger-elnzm"
                        },
                        "name": "Requests",
                        "namespace": "microsoft.web/sites",
                        "resourceMetadata": {
                          "id": "/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/Microsoft.Web/sites/workflowtrigger-elnzm"
                        }
                      }
                    ],
                    "title": "Sum Actions Completed  for digitaltextfileworkflow, Sum Actions Completed  for imageworkflow, and 5 other metrics",
                    "titleKind": 1,
                    "visualization": {
                      "axisVisualization": {
                        "x": {
                          "axisType": 2,
                          "isVisible": true
                        },
                        "y": {
                          "axisType": 1,
                          "isVisible": true
                        }
                      },
                      "chartType": 1,
                      "disablePinning": true,
                      "legendVisualization": {
                        "hideSubtitle": false,
                        "isVisible": true,
                        "position": 2
                      }
                    }
                  }
                }
              }
            },
            "filters": {
              "MsPortalFx_TimeRange": {
                "model": {
                  "format": "local",
                  "granularity": "auto",
                  "relative": "720m"
                }
              }
            }
          }
        },
        "6": {
          "position": {
            "x": 10,
            "y": 3,
            "colSpan": 4,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${subscriptionid}/resourceGroups/${rgname}-ml/providers/Microsoft.Web/serverfarms/mlappserviceplan"
                        },
                        "name": "CpuPercentage",
                        "aggregationType": 4,
                        "metricVisualization": {
                          "displayName": "CPU Percentage",
                          "resourceDisplayName": "mlappserviceplan"
                        }
                      }
                    ],
                    "title": "CPU Percentage",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2
                    },
                    "openBladeOnClick": {
                      "openBlade": true
                    }
                  }
                },
                "isOptional": true
              },
              {
                "name": "sharedTimeRange",
                "isOptional": true
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${subscriptionid}/resourceGroups/${rgname}-ml/providers/Microsoft.Web/serverfarms/mlappserviceplan"
                        },
                        "name": "CpuPercentage",
                        "aggregationType": 4,
                        "metricVisualization": {
                          "displayName": "CPU Percentage",
                          "resourceDisplayName": "mlappserviceplan"
                        }
                      }
                    ],
                    "title": "CPU Percentage",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "disablePinning": true
                    },
                    "openBladeOnClick": {
                      "openBlade": true
                    }
                  }
                }
              }
            },
            "filters": {
              "MsPortalFx_TimeRange": {
                "model": {
                  "format": "local",
                  "granularity": "1m",
                  "relative": "60m"
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
              "relative": "7d"
            },
            "displayCache": {
              "name": "UTC Time",
              "value": "Past 7 days"
            },
            "filteredPartIds": [
              "StartboardPart-MonitorChartPart-eb9cdc46-1798-4fe9-ac54-602e231b80d4",
              "StartboardPart-MonitorChartPart-eb9cdc46-1798-4fe9-ac54-602e231b80d6",
              "StartboardPart-MonitorChartPart-eb9cdc46-1798-4fe9-ac54-602e231b80dc",
              "StartboardPart-MonitorChartPart-eb9cdc46-1798-4fe9-ac54-602e231b80de",
              "StartboardPart-MonitorChartPart-eb9cdc46-1798-4fe9-ac54-602e231b80e0",
              "StartboardPart-MonitorChartPart-eb9cdc46-1798-4fe9-ac54-602e231b80e2",
              "StartboardPart-MonitorChartPart-eb9cdc46-1798-4fe9-ac54-602e231b80e4",
              "StartboardPart-MonitorChartPart-eb9cdc46-1798-4fe9-ac54-602e231b80e6",
              "StartboardPart-MonitorChartPart-eb9cdc46-1798-4fe9-ac54-602e231b80e8"
            ]
          }
        }
      }
    }
  }
}