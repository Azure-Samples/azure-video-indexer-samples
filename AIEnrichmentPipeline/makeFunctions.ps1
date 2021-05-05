function Write-Header($text) { 
    Write-Host ">> `n>>>>>>> $text `n>>" -ForegroundColor Magenta
}
function Get-SourceRevisionId {
    # Inject the GitSha to the DLL to track version
    return git rev-parse HEAD
}
function Get-BuildVersion {
    # buildversion provided by CI; defaults to 0.0.0.1 for development builds
    return "0.0.0.1"
}
function Test-AzurePowerShellConnected {
    Write-Host "Checking Azure powershell is connected"
    if (-not (Get-AzContext -ListAvailable)) {
        Write-Host "Connection to your azure account required: Complete the signin for Azure Powershell"
        Connect-AzAccount
    }
}
function Get-LocalTerraformOutputIfParamNotSet {
    param (
        $jsonOutputVariablesPath
    )

    Write-Host "Checking TF param set"

    if (-not $jsonOutputVariablesPath) {
        Write-Host "No JSON output provided attempting to use local terraform state from `tf-deploy` task"
        $jsonOutputVariablesPath = "./infra/tfoutput.json"
    }

    Write-Output $jsonOutputVariablesPath
}

function Get-TestPathOrDefault {
    param (
        [string]$TestFile,
        [string]$DefaultFile,
        [string]$TestPathPrefix
    )

    Write-Host "Checking if test path has been overriden"

    if (-not $TestFile) {
        Write-Host "No test override specified, using default value"
        $TestFile = $DefaultFile
    }

    if (-not $TestFile.StartsWith($TestPathPrefix)) {
        Write-Host "Test path does not include the prefix, I will add it"
        $TestFile = Join-Path -Path $TestPathPrefix -ChildPath $TestFile
    }

    Write-Host $testFile
    return $TestFile
}

# Start a jobs running each of the test files
function Invoke-ParallelTests {
    param (
        [string]$testFilePath
    )
    $testFiles = Get-ChildItem $testFilePath
    $resultFileNumber = 0
    foreach ($testFile in $testFiles) {
        $resultFileNumber++
        $testName = Split-Path $testFile -leaf

        # Create the job, be sure to pass argument in from the ArgumentList which 
        # are needed for inside the script block, they are NOT automatically passed.
        Start-Job `
            -ArgumentList $testFile, $resultFileNumber, $jsonOutputVariablesPath `
            -Name $testName `
            -ScriptBlock {
            param($testFile, $resultFileNumber, $jsonOutputVariablesPath)

            # Start trace for local debugging if TEST_LOG=true
            # the traces will show you output in the ./testlogs folder and the files
            # are updated as the tests run so you can follow along
            if ($env:TEST_LOGS -eq "true") {
                Start-Transcript -Path "./testlogs/$(Split-Path $testFile -leaf).integrationtest.log"
            }

            # Run the test file
            Write-Host "$testFile to result file #$resultFileNumber"
            $result = Invoke-Pester @{ Path = "$testFile"; Parameters = @{ jsonOutputVariablesPath = $jsonOutputVariablesPath; } } -OutputFile "./Test-Integration-Pester$resultFileNumber.xml" -OutputFormat 'NUnitXML' -PassThru

            if ($result.FailedCount -gt 0) {
                throw "1 or more assertions failed"
            }
        } 
    }

    # Poll to give insight into which jobs are still running so you can spot long running ones       
    do {
        Write-Host ">> Still running tests @ $(Get-Date -Format "HH:mm:ss")" -ForegroundColor Blue
        Get-Job | Where-Object { $_.State -eq "Running" } | Format-Table -AutoSize 
        $currentFailedTests = Get-Job | Where-Object { $_.State -ne "Running" -and $_.State -ne "Completed" } 
        if (($currentFailedTests | Measure-Object).Count -gt 0) {
            Write-Host ">> Failed tests @ $(Get-Date -Format "HH:mm:ss")" -ForegroundColor Red
            $currentFailedTests | Format-Table -AutoSize 
        }
        Start-Sleep -Seconds 15
    } while ((get-job | Where-Object { $_.State -eq "Running" } | Measure-Object).Count -gt 0)

    # Catch edge cases by wait for all of them to finish
    Get-Job | Wait-Job

    $failedJobs = Get-Job | Where-Object { -not ($_.State -eq "Completed") }

    # Receive the results of all the jobs, don't stop at errors
    Get-Job | Receive-Job -AutoRemoveJob -Wait -ErrorAction 'Continue'

    if ($failedJobs.Count -gt 0) {
        Write-Host "Failed Jobs" -ForegroundColor Red
        $failedJobs
        throw "One or more tests failed"
    }
}

function Install-ModuleIfNotInstalled {
    param (
        [parameter(Mandatory = $true)] [string]$Name,
        [parameter(Mandatory = $true)] [string]$RequiredVersion
    )

    $installed = (Get-Module -ListAvailable -Name $Name).Where({$_.Version -Match $RequiredVersion}).Count -gt 0

    if (-Not $installed) {
        Write-Host "Module $Name @ Version $RequiredVersion not found... Installing" -ForegroundColor Yellow
        Install-Module -Name $Name -RequiredVersion $RequiredVersion -Force
    } else {
        Write-Host "Module $Name @ Version $RequiredVersion found... Skipped install" -ForegroundColor Green
    }
}
