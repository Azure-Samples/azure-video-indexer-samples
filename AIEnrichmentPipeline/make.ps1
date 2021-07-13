# Import functions used by this make file
. ./makeFunctions.ps1

# Load .env file 
# install `Set-PsEnv` if not found: https://github.com/rajivharris/Set-PsEnv
if (-not (Get-Module -ListAvailable -Name Set-PsEnv)) {
    Install-Module -Name Set-PsEnv -Force
}
Set-PsEnv

task default -depends "tf-checks", "pwsh-checks", "dotnet-build", "logicapp-checks"


##
## .net tasks
##

# Fixing dotnet formatting
task "dotnet-format" {
    Write-Header  ">> Format dotnet assets."
    exec { dotnet format "./functions" -f }
}

### This removes the obj/bin folder from dotnet. Useful if you see permissions errors during dotnet builds
task "dotnet-clean" {
    Write-Header  ">> Cleanup dotnet assets."
    exec { rm -rf ./functions/enrichmentpipeline.Functions.*/bin/ }
    exec { rm -rf ./functions/enrichmentpipeline.Functions.*/obj/  }
    exec { rm -rf ./functions/releases  }
}

### Test dotnet functions
task "dotnet-test" {
    Write-Header  ">> Test dotnet assets."
    exec { dotnet restore ./functions --configfile ./functions/nuget.config }
    exec { dotnet test ./functions --logger "trx;LogFileName=./$testfile.trx"}
}

### Build dotnet functions
task "dotnet-build" -depends "dotnet-test"  -precondition { return ($env:NO_BUILD ?? $false) -eq $false } {
    # Create folder for published zips to live in
    New-Item -Path './functions/releases/' -ItemType Directory -Force
    
    foreach ($funcpath in Get-ChildItem ./functions -Directory) {
        if (($funcpath -like '*enrichmentpipeline.Functions*') -and (Test-Path -path $funcpath'/host.json'))
        {
            # Call dotnet publish in functions folders only 
            Write-Header  ">> Building and Publishing $funcpath"

            $revisionId = Get-SourceRevisionId
            $versionInfo = Get-BuildVersion
         
            exec { dotnet publish $funcpath -c Release /p:InformationalVersion="$versionInfo+$revisionId" }

            $zipfile = $funcpath.BaseName.Substring($funcpath.BaseName.LastIndexOf('.')+1).ToLower();
            
            Write-Header  ">> Creating  $zipfile.zip"
            # Zip up the publish output ready for functions deployment
            Get-ChildItem -Path $funcpath/bin/Release/netcoreapp3.1/publish | Compress-Archive -DestinationPath ./functions/releases/$zipfile.zip -Force   
        }
    }
}

##
## Logic app tasks
##

### Validate the logic app
task "logicapp-checks" {
    foreach ($workflow in Get-ChildItem ./logicapp -Directory) {
        Write-Header  ">> Check testworkflow json is valid @ $workflow"
        Get-Content -raw "$workflow/armtemplate.json" | Test-json
    }
}

## 
## Terraform Tasks
##

### Fix formatting issues with Terraform
task "tf-format" {
    Write-Header  ">> Terraform fmt."
    exec { terraform fmt -recursive }
}

### Output connection details from terraform
task "tf-output" {
    Write-Header  ">> Terraform output."
    Set-Location ./infra
    exec { terraform output }
}

### Plan Terraform
task "tf-plan" {
    Write-Header  ">> Terraform plan."
    Set-Location ./infra

    exec { terraform init }
    exec { terraform plan }
    Set-Location ./..
}

### Check terraform for issues 
task "tf-checks" -depends "dotnet-build" {
    Set-Location ./infra

    Write-Header  ">> Terraform version"
    exec { terraform -version }

    Write-Header  ">> Terraform Format (if this fails use 'terraform fmt' command to resolve"
    exec { terraform fmt -recursive -diff -check }

    Write-Header  ">> tflint"
    exec { tflint }

    Write-Header  ">> Terraform init"
    exec { terraform init -input=false -backend=false }

    Write-Header  ">> Terraform validate"
    exec { terraform validate }

    Set-Location ./..
}

### Run a tf-deploy and then execute the tests
task "deploy-and-check" -depends "tf-deploy", "test-deployment" {}

### Deploy the Terraform
task "tf-deploy" -depends "tf-checks" {
    Set-Location ./infra

    # Remove the Azure backend for local testing
    (Get-Content ./providers.tf).replace('backend "azurerm" {}', '#backend "azurerm" {}') | Set-Content ./providers.tf

    try {
        exec { terraform apply -auto-approve }
        exec { terraform output -json | Set-Content ./tfoutput.json}
    } finally {
        # Put back the Azure backend for committing so CI uses it
        (Get-Content ./providers.tf).replace('#backend "azurerm" {}', 'backend "azurerm" {}') | Set-Content ./providers.tf
    }

    Set-Location ./..
}

### Destroy the Terraform deployed resources
task "tf-destroy" {
    Set-Location ./infra
    
    # Remove the Azure backend for local testing
    (Get-Content ./providers.tf).replace('backend "azurerm" {}', '#backend "azurerm" {}') | Set-Content ./providers.tf

    try {
        exec { terraform destroy }
    } 
    catch {
        Write-Host "An error occured destroying the resources"
        Write-Host $_
    } finally {
        # Put back the Azure backend for committing so CI uses it
        (Get-Content ./providers.tf).replace('#backend "azurerm" {}', 'backend "azurerm" {}') | Set-Content ./providers.tf
    }

    Set-Location ./..
}

### Tain a resource so it gets re-created on the next tf-deploy: https://www.terraform.io/docs/commands/taint.html
task "tf-taint" {
    # Example syntax: Invoke-psake make.ps1 tf-taint -parameters @{"ResourceAddress"="module.orchestration_workflow.azurerm_logic_app_workflow.logicapp";} 
    # NOTE: If you taint a logic app... be sure to taint the internal workflow too: Invoke-psake ./make.ps1 tf-taint -parameters @{"ResourceAddress"="module.orchestration_workflow.azurerm_template_deployment.workflow";}
    Set-Location ./infra

    Write-Host "Tainting $ResourceAddress"

    # Remove the Azure backend for local testing
    (Get-Content ./providers.tf).replace('backend "azurerm" {}', '#backend "azurerm" {}') | Set-Content ./providers.tf

    try {
        exec { terraform taint $ResourceAddress}
    } 
    catch {
        Write-Host "An error occured tainiting the resource $ResourceAddress"
        Write-Host $_
    } finally {
        # Put back the Azure backend for committing so CI uses it
        (Get-Content ./providers.tf).replace('#backend "azurerm" {}', 'backend "azurerm" {}') | Set-Content ./providers.tf
    }

    Write-Host "You can now run tf-deploy and the resource will be re-created."

    Set-Location ./..
}

## 
## Script/General Tasks
##

### Check powershell scripts for errors
task "pwsh-checks" {
    Write-Header  ">> Powershell Script Analyzer"
    # Ignore DSC config files as can't be linted in devcontainer. Future: Install Linux DSC and linting should be possible
    $saResults = Get-ChildItem -Filter "*.ps1" -Path . -Recurse -Exclude "*_config.ps1" | Invoke-ScriptAnalyzer -Settings PSGallery -ExcludeRule "*_config.ps1"
    if ($saResults) {
        $saResults | Format-Table  
        Write-Error -Message 'One or more Script Analyzer errors/warnings where found. Build cannot continue!'        
    }
}

## 
## Post deployment testing Tasks
##
task "test-deployment" -depends "infra-tests", "integration-tests" {}

task "infra-tests" {
    Install-ModuleIfNotInstalled -Name Pester -RequiredVersion 4.10.1

    Test-AzurePowerShellConnected
    $jsonOutputVariablesPath = Get-LocalTerraformOutputIfParamNotSet $jsonOutputVariablesPath
    $testFilePath = Get-TestPathOrDefault -TestFile $testFilePath -DefaultFile "*" -TestPathPrefix "./scripts/infra_tests"

    Invoke-Pester @{ Path = $testFilePath; Parameters = @{ jsonOutputVariablesPath = $jsonOutputVariablesPath; } } -EnableExit  -OutputFile "./Test-Infra-Pester.xml" -OutputFormat 'NUnitXML'
}

task "integration-tests" {
    Install-ModuleIfNotInstalled -Name Pester -RequiredVersion 4.10.1
    Install-ModuleIfNotInstalled -Name PSServiceBus -RequiredVersion 1.2.0

    Test-AzurePowerShellConnected
    $jsonOutputVariablesPath = Get-LocalTerraformOutputIfParamNotSet $jsonOutputVariablesPath
    $testFilePath = Get-TestPathOrDefault -TestFile $testFilePath -DefaultFile "*" -TestPathPrefix "./scripts/integration_tests"

    if ($env:RUN_TESTS_PARALLEL -eq "true") {
        Invoke-ParallelTests $testFilePath
    } else {
        Invoke-Pester @{ Path = $testFilePath; Parameters = @{ jsonOutputVariablesPath = $jsonOutputVariablesPath; } } -EnableExit -OutputFile "./Test-Integration-Pester.xml" -OutputFormat 'NUnitXML'
    }
}