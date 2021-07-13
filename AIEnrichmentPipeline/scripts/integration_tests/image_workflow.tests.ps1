param 
(
    [parameter(Mandatory = $true)] [String] $jsonOutputVariablesPath
)

. "$PSScriptRoot\utilities.ps1"

function Test-ImageWorkflow {
    param (
        [Parameter()]
        [string]
        $blobUri
    )
    $logicAppUri = $tfOutput.image_logic_app_details.value.logic_app_uri
    $resourceGroupName = $tfOutput.image_logic_app_details.value.resourcegroup
    $testCorrelationId = New-Guid
    Context "Invoking enrichment logic app with the test image $blobUri | CorrelationId: $testCorrelationId" {

        $body = Get-BlobInfoForTestFile -TestFileBlobUri $blobUri -ResourceGroupName $resourceGroupName -TfOutput $tfOutput

        $postResponse = Invoke-WebRequest -Method 'POST' -Uri $logicAppUri -Body ($body | ConvertTo-Json) -ContentType "application/json"
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

        It "Has an analyze payload" {
            $content.analyze.tags | Should -Not -BeNullOrEmpty
            $content.analyze.faces | Should -Not -BeNullOrEmpty
            $content.analyze.objects | Should -Not -BeNullOrEmpty
            $content.analyze.adult | Should -Not -BeNullOrEmpty
        }

        It "Has a describe payload" {
            $content.describe.description | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Image Enrichment Workflow Integration Tests" {
    $tfOutput = Get-IntTestInputs $jsonOutputVariablesPath

    Test-ImageWorkflow $tfOutput.integrationTestData.testImageJpgUrl
    Test-ImageWorkflow $tfOutput.integrationTestData.testImagePngUrl
    Test-ImageWorkflow $tfOutput.integrationTestData.testImageBmpUrl
}

