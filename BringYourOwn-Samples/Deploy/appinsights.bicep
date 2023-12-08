param resourcePrefix string
param location string

resource azAppInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${resourcePrefix}-ai'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

var azAppInsightsInstrumentationKey = azAppInsights.properties.InstrumentationKey
output azAppInsightsInstrumentationKey string = azAppInsightsInstrumentationKey
