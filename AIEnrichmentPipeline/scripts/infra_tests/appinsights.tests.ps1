param 
(
    [parameter(Mandatory = $true)] [String] $jsonOutputVariablesPath
)

Describe "Validating App Insights Service is up and running" {

    $tfOutput = Get-Content -Raw -Path $jsonOutputVariablesPath | ConvertFrom-Json

    $app_insights = Get-AzApplicationInsights -ResourceGroupName $tfOutput.core_appinsights_resource_group.value -Name $tfOutput.core_appinsights_name.value
    $appinsights_name = $tfOutput.core_appinsights_name.value
    
    Context "Polling App Insights: $appinsights_name" {
        
        It "AI request returns a valid response" {
            $app_insights| Should -Not -Be $null
        }

        It "AI name is the same" {
            $app_insights.Name| Should -Be $appinsights_name
        }
    }
}