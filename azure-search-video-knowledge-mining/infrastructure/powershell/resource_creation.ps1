# Azure Login
az login

# Subscription selection
$subscription_id = "YOUR_SUBSCRIPTION"
az account set --subscription $subscription_id


# Variable setting
    # Unique prefix / suffix (if you want to prepend or append some unique identifier to rerource names)
    $prefix = ""
    $suffix = ""
    $basic_name = "videokm" # Name to be assigned to all resource created within this script

    # Resource Group
    $resource_group = $prefix + $basic_name + $suffix
    $location = "westeurope"
    
    # Azure Storage Account
    $storage_account = $prefix + $basic_name  + $suffix
    $access_tier = "Hot"
    $kind = "StorageV2"
    $storage_container_video_drop = "video-drop"
    $storage_container_insights = "video-insights"

    # Azure Cognitive Search
    $cognitive_search = $prefix + $basic_name + $suffix
    $cognitive_search_sku = "basic"
    $cognitive_search_api_Version = "2019-05-06"
    $cognitive_search_index = $prefix + "conversational-index-test" + $suffix
  

# Create Resource Group
az group create --location $location --name $resource_group


# Azure Storage Account 
    # Create Storage Account
    az storage account create --name $storage_account --resource-group $resource_group --access-tier $access_tier --kind $kind

        # Get blob storage Key and AccountId
        $storage_account_key = az storage account keys list --account-name $storage_account --query [0].value -o tsv
        $storage_account_id = az storage account list --resource-group $resource_group --query [0].id -o tsv

        # Create a container to store videos
        az storage container create --account-name $storage_account --name $storage_container_video_drop
        # Create a container to store videos' insights
        az storage container create --account-name $storage_account --name $storage_container_insights



# Azure Cognitive Search
    # Create Cognitive Search
    az search service create --name $cognitive_search --resource-group $resource_group --sku $cognitive_search_sku
  

        # Get Azure Cogntive Search Key
        $cognitive_search_key = az search admin-key show --resource-group $resource_group --service-name $cognitive_search -o tsv --query primaryKey

        # Azure Cognitive Search Request Header and Parameters
        $header = @{'Content-Type' = 'application/json'; 'api-key' = $cognitive_search_key}

        
            # Create Index
            # POST https://[servicename].search.windows.net/indexes?api-version=[api-version]  
            #   Content-Type: application/json   
            #   api-key: [admin key] 

            
            # Create index for insights
            $json_index = Get-Content 'video-knowledge-mining-index.json' 

            $cognitive_search_api_endpoint_index = "https://"+ $cognitive_search + ".search.windows.net/indexes/" + $cognitive_search_index + "?api-version=" + $cognitive_search_api_Version
            $response = Invoke-WebRequest -Uri $cognitive_search_api_endpoint_index -Method 'PUT' -Body $json_index -Headers $header

            # Create index for time references
            $json_index = Get-Content 'video-knowledge-mining-index-time-references.json' 
            $cognitive_search_index = $cognitive_search_index + "-time-references"

            $cognitive_search_api_endpoint_index = "https://"+ $cognitive_search + ".search.windows.net/indexes/" + $cognitive_search_index + "?api-version=" + $cognitive_search_api_Version
            $response = Invoke-WebRequest -Uri $cognitive_search_api_endpoint_index -Method 'PUT' -Body $json_index -Headers $header
