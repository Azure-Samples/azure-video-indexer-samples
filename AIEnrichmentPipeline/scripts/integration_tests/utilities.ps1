function Get-IntTestInputs {
	param (
		[string]$tfOutputPath
	)
	
	$TfOutput = Get-Content -Raw -Path $tfOutputPath | ConvertFrom-Json
	$testDataContainerName = "test-data"
	$inputContainerName = "input"
	$enrichmentDataContainerName = "enrichment-data"

	$storageAccountName = $TfOutput.core_storage_account.value.name
	$storageAccountKey = Get-AzStorageAccountKey -ResourceGroupName $TfOutput.core_storage_account.value.resource_group_name -AccountName $storageAccountName
	$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey[0].Value

	# Create containers
	Invoke-CreateStorageContainerIfNotExists -containerName $testDataContainerName -storageCtx $ctx
	Invoke-CreateStorageContainerIfNotExists -containerName $inputContainerName -storageCtx $ctx
	Invoke-CreateStorageContainerIfNotExists -containerName $enrichmentDataContainerName -storageCtx $ctx

	# Upload test data if not set
	$testImageJpg = Invoke-CreateBlobContentIfMissing  -File "./scripts/integration_tests/test_data/test_image.jpg" `
		-Container $testDataContainerName `
		-Blob "test_image_large.jpg" `
		-Context $ctx
	
	$testImagePng = Invoke-CreateBlobContentIfMissing  -File "./scripts/integration_tests/test_data/test_image.png" `
		-Container $testDataContainerName `
		-Blob "test_image_large.png" `
		-Context $ctx
	
	$testImageBmp = Invoke-CreateBlobContentIfMissing  -File "./scripts/integration_tests/test_data/test_image.bmp" `
		-Container $testDataContainerName `
		-Blob "test_image_large.bmp" `
		-Context $ctx

	$testVideo = Invoke-CreateBlobContentIfMissing  -File "./scripts/integration_tests/test_data/test_video.mp4" `
		-Container $testDataContainerName `
		-Blob "test_video.mp4" `
		-Context $ctx

	$testTxtOctet = Invoke-CreateBlobContentIfMissing  -File "./scripts/integration_tests/test_data/test_data.txt" `
		-Container $testDataContainerName `
		-Blob "test_data_octet.txt" `
		-Properties @{ContentType = "application/octet-stream" } `
		-Context $ctx

	$testTxtPlain = Invoke-CreateBlobContentIfMissing  -File "./scripts/integration_tests/test_data/test_data.txt" `
		-Container $testDataContainerName `
		-Blob "test_data_plain.txt" `
		-Properties @{ContentType = "text/plain" } `
		-Context $ctx
	
	$testTxtEmpty = Invoke-CreateBlobContentIfMissing  -File "./scripts/integration_tests/test_data/empty.txt" `
		-Container $testDataContainerName `
		-Blob "empty.txt" `
		-Properties @{ContentType = "text/plain" } `
		-Context $ctx
	
	# Update testInputs to link to test data
	$integrationTestData = @{
		testImageJpgUrl    = $testImageJpg.ICloudBlob.Uri
		testImagePngUrl    = $testImagePng.ICloudBlob.Uri
		testImageBmpUrl    = $testImageBmp.ICloudBlob.Uri
		testVideoUrl    = $testVideo.ICloudBlob.Uri
		testTxtOctetUrl = $testTxtOctet.ICloudBlob.Uri
		testTxtPlainUrl = $testTxtPlain.ICloudBlob.Uri
		testTxtEmptyUrl = $testTxtEmpty.ICloudBlob.Uri
	}
	$TfOutput | Add-Member -NotePropertyName "integrationTestData" -NotePropertyValue $integrationTestData
	$TfOutput | Add-Member -NotePropertyName "core_storage_test_data_container_name" -NotePropertyValue @{ value = "test-data" }
	$TfOutput | Add-Member -NotePropertyName "core_storage_input_container_name" -NotePropertyValue @{ value = "input" }
	$TfOutput | Add-Member -NotePropertyName "core_storage_enrichment_data_container_name" -NotePropertyValue @{ value = "enrichment-data" }

	return $TfOutput
}

function Invoke-CreateBlobContentIfMissing {
	param (
		$File,
		$Container,
		$Blob,
		$Properties,
		$Context
	)

	# Just return the reference if the blob already exists
	if (Get-AzStorageBlob -Blob $Blob -Container $Container -Context $Context -ErrorAction SilentlyContinue) {
		Write-Host -ForegroundColor Gray "Skipping testdata $Blob already exists" 
		return Get-AzStorageBlob -Blob $Blob -Container $Container -Context $Context
	}

	Write-Host -ForegroundColor Yellow "Uploading test data $Blob as doesn't exist"
	return Set-AzStorageBlobContent -File $File `
		-Container $Container `
		-Blob $Blob `
		-Properties $Properties `
		-Context $Context -Force
}

function Invoke-CreateStorageContainerIfNotExists {
	param (
		[Parameter(Mandatory = $true)]
		$containerName,
		[Parameter(Mandatory = $true)]
		$storageCtx
	)
	
	if (Get-AzStorageContainer -Name $containerName -Context $storageCtx -ErrorAction SilentlyContinue) {  
		Write-Host -ForegroundColor Gray $containerName "- container already exists."
	}  
	else {  
		Write-Host -ForegroundColor Yellow $containerName "- container does not exist."   
		## Create a new Azure Storage Account  
		New-AzStorageContainer -Name $containerName -Context $storageCtx  
	}       
}

function Get-BlobInfoForTestFile {
	param (
		[string]$TestFileBlobUri,
		[string]$ResourceGroupName,
		[object]$TfOutput
	)

	$filename = $TestFileBlobUri.Split("/")[-1]
	$fileCategory = $filename.Split(".")[-1]
	$sasTokenStartTime = (Get-Date).AddMinutes(-10)
	$sasTokenEndTime = $sasTokenStartTime.AddDays(1)
	$storageAccountName = $TfOutput.core_storage_account.value.name
	$testDataContainerName = $TfOutput.core_storage_test_data_container_name.value
	$storageAccountKey = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -AccountName $storageAccountName
	$storageAccountContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey[0].Value
	$storageBlobUri = $TestFileBlobUri
	$storageBlobSasToken = New-AzStorageBlobSASToken -Container $testDataContainerName -Blob $fileName -Permission rwd -StartTime $sasTokenStartTime -ExpiryTime $sasTokenEndTime -context $storageAccountContext
	$storageBlobSasUri = [string]$storageBlobUri + $storageBlobSasToken
	$testSystemVersion = "0.0.0.1+$(New-Guid)"
 

	return @{
		canonicalUri  = $storageBlobUri
		correlationId = $testCorrelationId
		fileName      = $fileName
		fileCategory  = $fileCategory
		sasUri        = $storageBlobSasUri
		sasExpiry     = $sasTokenEndTime
		systemVersion = $testSystemVersion
	}
}

function Get-LogicAppResponse {
	[parameter(Mandatory = $true)] [string] $LogicappUri

	$response = Invoke-WebRequest -Method 'GET' -Uri $logicappUri
	Write-Host "LogicApp GET status code: $($response.StatusCode)" 
	
	if ($response.StatusCode -ge 500) {
		throw "LogicApp GET $LogicappUri returned error status code $($response.StatusCode)"
	}

	return $response
}

function Wait-ForLogicAppToComplete {
	param (
		[parameter(Mandatory = $true)] [string] $LogicappUri,
		[parameter(Mandatory = $true)] [int] $TimeoutMinutes
	)

	$startDate = Get-Date

	do {
		$response = Get-LogicAppResponse -LogicappUri $LogicappUri
		if ($response.StatusCode -eq 200) {
			return $response;
		}
	
		Start-Sleep -s 10
	} while ($startDate.AddMinutes($TimeoutMinutes) -gt (Get-Date))
}