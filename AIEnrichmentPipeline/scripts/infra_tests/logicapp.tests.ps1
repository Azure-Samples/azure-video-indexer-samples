param 
(
    [parameter(Mandatory = $true)] [String] $jsonOutputVariablesPath
)

Describe "LogicApp Infra Verification Tests" {

    $tfOutput = Get-Content -Raw -Path $jsonOutputVariablesPath | ConvertFrom-Json

    Context "LogicApp '$($tfOutput.video_logic_app_details.value.name)'" {

        $logicApp = Get-AzLogicApp -ResourceGroupName $tfOutput.video_logic_app_details.value.resourcegroup -Name $tfOutput.video_logic_app_details.value.name -ErrorAction SilentlyContinue 

        It "Exists" {
            $logicApp | Should -Not -Be $null
        }

        It "Location set to azure region location" {
            $logicApp.Location | Should -Be $tfOutput.resource_group_location.value
        }
    }
}