
# ---------------------------------------------------------------------------- 
# Copyright (c) Microsoft Corporation. All rights reserved. 
# ----------------------------------------------------------------------------
<#
 #
 # This module exposes functions to login to Azure
 # 
 #>

# Stop on first error: https://stackoverflow.com/questions/9948517/how-to-stop-a-powershell-script-on-the-first-error
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction']='Stop'

# Enforce TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


#Common Variables
$templateFile = "./avam.template.json"
$parameterFile="./avam.template.parameters.json"
$resourceGroupName="vi-dev-ts-rg"
$location="East Us"
Write-Host "====Creating Avam Resource from Arm Template Demo===="

Write-Host "Create Resouce Group For AVAM"
New-AzResourceGroup `
  -Name $resourceGroupName `
  -Location $location

Write-Host "Deploy Avam Template"
New-AzResourceGroupDeployment `
  -Name avam-demo `
  -ResourceGroupName $resourceGroupName `
  -TemplateFile $templateFile `
  -TemplateParameterFile $parameterFile
