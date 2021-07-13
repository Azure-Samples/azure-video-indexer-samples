param 
(
    [parameter(Mandatory = $true)] [String] $jsonOutputVariablesPath
)

. "$PSScriptRoot\utilities.ps1"

Describe "Digital text file Workflow Integration Tests With Octet Stream" {
    $tfOutput = Get-IntTestInputs $jsonOutputVariablesPath
    $testCorrelationId = New-Guid

    $logicAppUri = $tfOutput.digitaltextfile_logic_app_details.value.logic_app_uri
    $resourceGroupName = $tfOutput.digitaltextfile_logic_app_details.value.resourcegroup

    Context "Invoking Digital text file workflow logic app with octet stream | CorrelationId: $testCorrelationId" {
            
        $body = Get-BlobInfoForTestFile -TestFileBlobUri $tfOutput.integrationTestData.testTxtOctetUrl -ResourceGroupName $resourceGroupName -TfOutput $tfOutput

        $postResponse = Invoke-WebRequest -Method 'POST' -Uri $logicAppUri -Body ($body | ConvertTo-Json) -ContentType "application/json"
        $location = $postResponse.Headers.Location

        It "starts as expected" {
            $postResponse.StatusCode | Should -Be 202
        }

        It "completes" {
            $result = Wait-ForLogicAppToComplete -LogicappUri $location[0] -TimeoutMinutes 30
            $result.StatusCode | Should -Be 200
        }

        $getResponse = Invoke-WebRequest -Method 'GET' -Uri $location[0]
        $content = $getResponse.Content | ConvertFrom-Json
        
        It "Correlation Id matches" {
            $content.enrichment.values.correlationId | Should -Be $testCorrelationId
        }
    }

    $testCorrelationId = New-Guid

    Context "Invoking Digital text file workflow logic app with plain text | CorrelationId: $testCorrelationId" {
            
        $body = Get-BlobInfoForTestFile -TestFileBlobUri $tfOutput.integrationTestData.testTxtPlainUrl -ResourceGroupName $resourceGroupName -TfOutput $tfOutput
        $body.batchFolder = 'test-data'
        $body.textPath = $body.fileName

        $postResponse = Invoke-WebRequest -Method 'POST' -Uri $logicAppUri -Body ($body | ConvertTo-Json) -ContentType "application/json"
        $location = $postResponse.Headers.Location
        It "starts as expected" {
            $postResponse.StatusCode | Should -Be 202
        }
        It "completes" {
            # TO DO - Replace this with standard logic app run history polling from Utilities
            $status = 0
            For ($i = 0; $i -le 30000; $i++) {
                Write-Debug "LogicApp polling attempt: $i" 
                $getResponse = Invoke-WebRequest -Method 'GET' -Uri $location[0]
                Write-Debug "LogicApp GET status code: $($getResponse.StatusCode)" 
    
                $status = $getResponse.StatusCode
                if ($getResponse.StatusCode -eq 200) {
                    break;
                }
    
                Start-Sleep -s 10
            }
            $status | Should -Be 200
        }
        $getResponse = Invoke-WebRequest -Method 'GET' -Uri $location[0]
        $content = $getResponse.Content | ConvertFrom-Json
        
        It "Correlation Id matches" {
            $content.enrichment.values.correlationId | Should -Be $testCorrelationId
        }
    }
}
