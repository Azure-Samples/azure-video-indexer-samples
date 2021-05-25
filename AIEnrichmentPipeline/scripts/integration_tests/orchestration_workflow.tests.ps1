param 
(
    [parameter(Mandatory = $true)] [String] $jsonOutputVariablesPath
)

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\utilities.ps1"

$tfOutput = Get-IntTestInputs $jsonOutputVariablesPath
$inputContainerName = $tfOutput.core_storage_input_container_name.value
$testExecutionId = New-Guid
$startDate = Get-Date
$testFileRootDirectory = "testdata/orchestrationworkflow"
$textFileName = "text.txt"
$duplicateTextFileName = "duplicatetext.txt"
$imageFileName = "image.jpg"
$videoFileName = "video.mp4"
$uniqueContents = ('This file was created by the OrchestrationWorkflow integration test on {0}. TestExecutionId {1}' -f $startDate, $testExecutionId)
$testFileTestDirectory = $testFileRootDirectory +"/" +$testExecutionId
$workflowName = $tfOutput.orchestration_logic_app_details.value.name

# Create storage context 
$storageAccountName = $tfOutput.core_storage_account.value.name
$resourceGroupName = $tfOutput.orchestration_logic_app_details.value.resourcegroup
$storageAccountKey = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -AccountName $storageAccountName
$storageAccountContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey[0].Value
function Get-OrchestrationResult {
    param(
        [Parameter(Mandatory)]
        [string]
        $TestFileName,
        [Parameter(Mandatory)]
        [string]
        $ActionName,
        [Parameter(Mandatory)]
        [string]
        $TestExecutionIdParam
    )

    do {
        # Get logic app trigger history
        # NOTE: this will only return the 30 most recent runs, which is not enough if the system is under load. Need to use the NextLink to get the next page. See https://github.com/Azure/azure-powershell/issues/9141
        $logicAppRunHistory = Get-AzLogicAppRunHistory -ResourceGroupName $resourceGroupName -Name $workflowName

        # Loop through run history and check each one to see if it contains the file that was uploaded in the previous test step
        foreach ($run in $logicAppRunHistory) {
            # Make sure that we have an output link as there may be failed runs in the history
            if ($null -eq $run.Trigger.OutputsLink) {
                Write-Host 'Detected null - skipping.'
                continue;
            }

            # Check that the run succeeded, we only care about suceeded runs.
            # Get-AzlogicAppRunHistory just gives us a link to a json document which contains the output links, therefore we have to go and get the json document seperately.
            $outputLinksContent = (Invoke-WebRequest -Method 'GET' -Uri $run.Trigger.OutputsLink.Uri).Content | ConvertFrom-Json

            # Decode body.ContentData from base 64 string
            $contentData = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($outputLinksContent.body.ContentData)) | ConvertFrom-Json

            # Check that the run is the file we are looking for by matching TestExecutionIdParam and TestFileName
            if (($contentData.canonicalUri -like "*$TestExecutionIdParam*") -And ($contentData.fileName -eq $TestFileName)) {

                # If we have a failed job, we fail the test by throwing
                if ($run.Status -eq "Failed") {
                    throw "Orchestration LogicApp run failed"
                }

                # If the job succeeded then we can check the output
                if ($run.Status -eq "Succeeded") {
                    # We have a matching run. Get the action output
                    $runAction = Get-AzLogicAppRunAction -ResourceGroupName $resourceGroupName -Name $workflowName -RunName $run.Name -ActionName $ActionName
                    if ($null -ne $runAction.OutputsLink.Uri) 
                    {
                        $runActionContent = (Invoke-WebRequest -Method 'GET' -Uri $runAction.OutputsLink.Uri).Content | ConvertFrom-Json
                    } else {
                        $runActionContent = $null
                    }

                    # Uncomment below to dump the result to the terminal
                    #Write-host ($runActionContent | ConvertTo-Json -Depth 4)

                    return @{
                        Response = $runActionContent;
                        Run      = $run;
                    }
                }
            }
        }

        $current = Get-Date
        $diff = New-TimeSpan -Start $startDate -End $current
        Write-Host "Retrying after a snooze. This typically takes 4-8 minutes to complete. So far it has taken $diff"
        Start-Sleep -s 30
    } while ($startDate.AddMinutes(10) -gt (Get-Date))

    throw "Timeout for $TestFileName"
}

Describe "Orchestration Workflow Integration Tests | $testExecutionId" {
    # This step creates test files and uploads them to storage which will trigger the WorkflowTrigger function
    BeforeAll {            
        # Create text file with unique contents and place it in the test folder
        $uniqueTextFilePath = $testFileTestDirectory + "/" + $textFileName
        $uniqueContents | New-Item -Path $uniqueTextFilePath -ItemType File -Force

        # Create image file with unique contents and place it in the test folder
        $uniqueImageFilePath = $testFileTestDirectory + "/" + $imageFileName
        # Use this as an alternative image creation API if via.placeholder.com is unavailable: $imageTempMediaUrl = ('https://temp.media/?height=400&width=1600&text={0}&category=&color=' -f $testExecutionId)
        $imageTempMediaUrl = ('https://via.placeholder.com/1600x400.jpg&text={0}' -f $testExecutionId)
        Invoke-WebRequest $imageTempMediaUrl -OutFile $uniqueImageFilePath -SkipCertificateCheck

        # Create video file with unique contents and place it in the test folder
        $uniqueVideoFilePath = $testFileTestDirectory + "/" + $videoFileName
        $videoTempMediaUrl = ('https://via.placeholder.com/2000x1000.jpg&text={0}vid' -f $testExecutionId)
        Invoke-WebRequest $videoTempMediaUrl -OutFile $uniqueVideoFilePath -SkipCertificateCheck

        # Upload all files to storage
        $filesToUpload = Get-ChildItem $testFileTestDirectory -Recurse -File
        foreach ($fileToUpload in $filesToUpload) {
            $blob = $testFileTestDirectory +"/" +$fileToUpload.name
            Set-AzStorageBlobContent `
                -Container $inputContainerName `
                -File $fileToUpload.fullname `
                -Blob $blob `
                -Context $storageAccountContext `
                -Force
        } 
    }

    # This step checks that the orchestration wokrflow was triggered and completed sucessfully for the three unique files created in the BeforeAll step
    Context "Check $workflowName has been triggered and completed test files" {

        Context "File $imageFileName Processed" {
            $composeResultSimpleActionResult = Get-OrchestrationResult -TestFileName $imageFileName -ActionName "Compose_result" -TestExecutionIdParam $testExecutionId

            It "Has populated BlobInfo.correlationid" {
                $composeResultSimpleActionResult.Response.blobinfo.correlationid | Should -Not -BeNullOrEmpty
            }
            It "Has populated BlobInfo.filename" {
                $composeResultSimpleActionResult.Response.blobinfo.filename | Should -Not -BeNullOrEmpty
            }
            It "Has populated enrichmentUrl" {
                $composeResultSimpleActionResult.Response.enrichmentUrl | Should -Not -BeNullOrEmpty
            }
        }

        Context "File $textFileName Processed" {
            $composeResultSimpleActionResult = Get-OrchestrationResult -TestFileName $textFileName -ActionName "Compose_result" -TestExecutionIdParam $testExecutionId

            It "Has populated BlobInfo.correlationid" {
                $composeResultSimpleActionResult.Response.blobinfo.correlationid | Should -Not -BeNullOrEmpty
            }
            It "Has populated BlobInfo.filename" {
                $composeResultSimpleActionResult.Response.blobinfo.filename | Should -Not -BeNullOrEmpty
            }
            It "Has populated enrichmentUrl" {
                $composeResultSimpleActionResult.Response.enrichmentUrl | Should -Not -BeNullOrEmpty
            }
        }

        Context "File $videoFileName Processed" {
            $composeResultSimpleActionResult = Get-OrchestrationResult -TestFileName $videoFileName -ActionName "Compose_result" -TestExecutionIdParam $testExecutionId

            It "Has populated BlobInfo.correlationid" {
                $composeResultSimpleActionResult.Response.blobinfo.correlationid | Should -Not -BeNullOrEmpty
            }
            It "Has populated BlobInfo.filename" {
                $composeResultSimpleActionResult.Response.blobinfo.filename | Should -Not -BeNullOrEmpty
            }
            It "Has populated enrichmentUrl" {
                $composeResultSimpleActionResult.Response.enrichmentUrl | Should -Not -BeNullOrEmpty
            }
        }
    }

    # This step uploads a copy of the text file saved as a different name, which will trigger the duplicates path
    Context "Check $workflowName has been triggered and completed for duplicate files" {
        # Create text file with unique contents and place it in the test folder
        $duplicateTextFilePath = $testFileTestDirectory + "/" + $duplicateTextFileName
        $fileToUpload = $uniqueContents | New-Item -Path $duplicateTextFilePath -ItemType File -Force 
        $blob = $testFileTestDirectory +"/" +$fileToUpload.name

        # Upload to Azure which will trigger the workflow
        Set-AzStorageBlobContent `
            -Container $inputContainerName `
            -File $fileToUpload.fullname `
            -Blob $blob `
            -Context $storageAccountContext `
            -Force

        # Assert that the text file was classed as a duplicate
        Context "File $duplicateTextFileName processed as a duplicate" {
            $composeResultSimpleActionResult = Get-OrchestrationResult -TestFileName $duplicateTextFileName -ActionName "Compose_result" -TestExecutionIdParam $testExecutionId           
            $setIsDuplicateToTrueActionResult = Get-OrchestrationResult -TestFileName $duplicateTextFileName -ActionName "Set_IsDuplicate_to_True" -TestExecutionIdParam $testExecutionId

            It "Has populated BlobInfo.correlationid" {
                $composeResultSimpleActionResult.Response.blobinfo.correlationid | Should -Not -BeNullOrEmpty
            }
            It "Has populated BlobInfo.filename" {
                $composeResultSimpleActionResult.Response.blobinfo.filename | Should -Not -BeNullOrEmpty
            }            
            It "Has populated enrichmentUrl" {
                $composeResultSimpleActionResult.Response.enrichmentUrl | Should -Not -BeNullOrEmpty
            }
            It "Is a duplicate" {
                $setIsDuplicateToTrueActionResult.Response.body.value | Should -Be $true
            }
        }
    }

    AfterAll {
        Write-Host "Deleting test files"
        Remove-AzDataLakeGen2Item -Context $storageAccountContext -FileSystem $inputContainerName -Path "$testFileTestDirectory/" -Force
        Remove-Item -LiteralPath $testFileTestDirectory -Force -Recurse
    }
}