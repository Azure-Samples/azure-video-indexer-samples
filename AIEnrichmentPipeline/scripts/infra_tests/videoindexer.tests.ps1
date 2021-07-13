param 
(
    [parameter(Mandatory = $true)] [String] $jsonOutputVariablesPath
)

Describe "Video Indexer Infra Verification Tests" {

    $tfOutput = Get-Content -Raw -Path $jsonOutputVariablesPath | ConvertFrom-Json

    Context "storage account '$($tfOutput.video_indexer_storage_account_name.value)'" {

        $storageAccount = Get-AzStorageAccount -ResourceGroupName $tfOutput.media_services_resource_group_name.value -Name $tfOutput.video_indexer_storage_account_name.value -ErrorAction SilentlyContinue 

        It "Exists" {
            $storageAccount | Should -Not -Be $null
        }

        It "Set to V2 Storage type" {
            $storageAccount.Kind | Should -Be 'StorageV2'
        }
    
        It "Set for Hot access" {
            $storageAccount.AccessTier | Should -Be 'Hot'
        } 
    
        It "Sku set to Standard_LRS" {
            $storageAccount.Sku.Name | Should -Be 'Standard_LRS'
        }
    }

    Context "media services account '$($tfOutput.media_services_account_name.value)'" {

        $mediaServicesAccount = Get-AzMediaService -ResourceGroupName $tfOutput.media_services_resource_group_name.value -AccountName $tfOutput.media_services_account_name.value -ErrorAction SilentlyContinue 

        It "Exists" {
            $mediaServicesAccount | Should -Not -Be $null
        }

        It "Is connected to the correct storage account" {
            $mediaServicesAccount.StorageAccounts[0].AccountName | Should -Be $tfOutput.video_indexer_storage_account_name.value
        }

    }
}
