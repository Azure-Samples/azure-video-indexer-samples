param 
(
    [parameter(Mandatory = $true)] [String] $jsonOutputVariablesPath
)

. "$PSScriptRoot\utilities.ps1"

Describe "Video Workflow Integration Tests" {
    $tfOutput = Get-IntTestInputs $jsonOutputVariablesPath

    $testCorrelationId = New-Guid
    $blobUri = $tfOutput.integrationTestData.testVideoUrl

    $logicAppUri = $tfOutput.video_logic_app_details.value.logic_app_uri
    $resourceGroupName = $tfOutput.video_logic_app_details.value.resourcegroup

    Context "Invoking enrichment logic app with the test video | CorrelationId: $testCorrelationId" {

        $body = Get-BlobInfoForTestFile -TestFileBlobUri $blobUri -ResourceGroupName $resourceGroupName -TfOutput $tfOutput

        $postResponse = Invoke-WebRequest -Method 'POST' -Uri $logicAppUri -Body ($body|ConvertTo-Json) -ContentType "application/json"
        $location = $postResponse.Headers.Location

        It "starts as expected" {

            $postResponse.StatusCode | Should -Be 202
        }

        It "completes" {
            $result = Wait-ForLogicAppToComplete -LogicappUri $location[0] -TimeoutMinutes 30
            $result.StatusCode | Should -Be 200
        }

        $getResponse = Invoke-WebRequest -Method 'GET' -Uri $location[0]
        $content = $getResponse.Content | ConvertFrom-Json

        It "Has summarized Insights on response" {
            $content.summarizedInsights | Should -Not -BeNullOrEmpty
        }
        
        It "Matches Name of test file on response" {
            $content.name | Should -Be $body.fileName
        }

        It "Processes only one video on response" {
            $content.videos.count | Should -Be 1
        }
    }
}
