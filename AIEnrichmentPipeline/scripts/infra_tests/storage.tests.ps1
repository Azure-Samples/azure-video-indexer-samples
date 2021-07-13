param 
(
    [parameter(Mandatory = $true)] [String] $jsonOutputVariablesPath
)

Describe "LogicApp Infra Verification Tests" {

    $tfOutput = Get-Content -Raw -Path $jsonOutputVariablesPath | ConvertFrom-Json

    Context "Storage account '$($tfOutput.core_storage_account.value.name)'" {

        $storageAccount = Get-AzStorageAccount -ResourceGroupName $tfOutput.core_storage_account.value.resource_group_name -Name $tfOutput.core_storage_account.value.name -ErrorAction SilentlyContinue 

        It "Exists" {
            $storageAccount | Should -Not -Be $null
        }

        It "Set to V2 Storage type" {
            $storageAccount.Kind | Should -Be 'StorageV2'
        }
    
        It "Set for Hot access" {
            $storageAccount.AccessTier | Should -Be 'Hot'
        }

        It "Location set to core azure region location due to VNET issues" {
            
            $storageAccount.Location | Should -Be $tfOutput.resource_group_location.value
        }
    }
}