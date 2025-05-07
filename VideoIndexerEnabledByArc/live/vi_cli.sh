#!/bin/bash

#################################################
# Video Indexer CLI for interacting with 
# Azure Video Indexer and Azure IoT Operations
#################################################

set_script_variables() {
    clusterName="${VI_CLUSTER_NAME:-}"
    clusterResourceGroup="${VI_CLUSTER_RESOURCE_GROUP:-}"
    accountName="${VI_ACCOUNT_NAME:-}"
    accountResourceGroup="${VI_ACCOUNT_RESOURCE_GROUP:-}"
    liveStreamEnabled=false
    mediaFilesEnabled=false
    cameraName=""
    cameraId=""
    cameraAddress=""
    cameraUsername=""
    cameraPassword=""
    presetName=""
    presetId=""
    assetName=""
    assetEndpointName=""
    accessToken=""
    subscriptionId=""
    subscriptionName=""
    tenantId=""
    aioBaseURL=""
    extensionId=""
    extensionUrl=""
    extensionAccountId=""
    skipPrompt=false
    interactiveMode=false
    aioEnabled=false

    # Color codes for pretty logging
    RESET="\033[0m"
    RED="\033[0;31m"
    GREEN="\033[0;32m"
    YELLOW="\033[0;33m"
    CYAN="\033[0;36m"
    BOLD="\033[1m"
}

show_help() {
    echo "Usage: $0 <command> <subcommand> [options]"
    echo
    echo "Commands:"
    echo "  create camera              Create a camera."
    echo "  create preset              Create a preset."
    echo "  create aep                 Create asset endpoint profile."
    echo "  create asset               Create asset."
    echo "  delete camera              Delete a camera in vi."
    echo "  delete preset              Delete a preset in vi."
    echo "  upgrade extension          Upgrade extension."
    echo "  show cameras               Show cameras."
    echo "  show presets               Show presets."
    echo "  show token                 Show access token."
    echo "  show extension             Show extension"
    echo "  show account               Show user account."
    echo
    echo "Options:"
    echo "  -y|--yes                        Should continue without prompt for confirmation."
    echo "  -h|--help                       Show this help message and exit."
    echo "  -it|--interactive               Enable interactive mode."
    echo "  -aio|--aio-enabled              Enable AIO."
    echo "  -live|--live-enabled            Enable live stream."
    echo "  -media|--media-enabled          Enable media files."
    echo "  --clusterName <name>            Name of the cluster."
    echo "  --clusterResourceGroup <name>   Resource group of the cluster."
    echo "  --accountName <name>            Name of the Video Indexer account."
    echo "  --accountResourceGroup <name>   Resource group of the Video Indexer account."
    echo "  --cameraName <name>             Name of the camera."
    echo "  --cameraAddress <address>       RTSP address of the camera."
    echo "  --presetName <name>             Name of the preset."
    echo "  --presetId <id>                 ID of the preset."
    echo "  --cameraId <id>                 ID of the camera."
    echo "  --cameraUsername (optional)     Username for the camera (AIO only)."
    echo "  --cameraPassword (optional)     Password for the camera (AIO only)."
    echo
    echo "Examples:"
    echo "  create camera -aio         Create asset endpoint profile, asset, and camera"
    echo "  create camera -it          Create camera with interactive prompts"
    exit 0
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -y|--yes)
            skipPrompt=true
            shift
            ;;
        -it|--interactive)
            interactiveMode=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        -aio|--aio-enabled)
            aioEnabled=true
            shift
            ;;
        -live|--live-enabled)
            liveStreamEnabled=true
            shift
            ;;
        -media|--media-enabled)
            mediaFilesEnabled=true
            shift
            ;;
        --clusterName)
            clusterName="$2"
            shift 2
            ;;
        --clusterResourceGroup)
            clusterResourceGroup="$2"
            shift 2
            ;;
        --accountName)
            accountName="$2"
            shift 2
            ;;
        --accountResourceGroup)
            accountResourceGroup="$2"
            shift 2
            ;;
        --cameraName) 
            cameraName="$2"
            shift 2
            ;;
        --cameraId)
            cameraId="$2"
            shift 2
            ;;
        --presetId)
            presetId="$2"
            shift 2
            ;;
        --cameraAddress)
            cameraAddress="$2"
            shift 2
            ;;
        --presetName)
            presetName="$2"
            shift 2
            ;;
        --cameraUsername)
            cameraUsername="$2"
            shift 2
            ;;
        --cameraPassword)
            cameraPassword="$2"
            shift 2
            ;;
        *)
            log_error_exit "Unknown option: $1"
            ;;
        esac
    done
}

log_debug() {
    echo -e "${CYAN}[DEBUG]${RESET} $*"
}

log_info() {
    echo -e "${GREEN}[INFO]${RESET} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${RESET} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${RESET} $*"
}

log_error_exit() { 
    log_error "$1"
    exit 1
}

######################
# Azure Helper Functions
######################

az_install() {
    log_info "Checking if Azure CLI (az) is installed..."

    if ! command -v az > /dev/null 2>&1; then
        log_info "Azure CLI is not installed."
        read -p "Do you want to install Azure CLI? (true/false): " installAzureCLI
        
        if "$installAzureCLI"; then
            log_info "Installing Azure CLI..."
            curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

            if az --version > /dev/null 2>&1; then
                log_info "Azure CLI successfully installed."
            else
                log_error_exit "Failed to install Azure CLI."
            fi
        else
            log_error_exit "Azure CLI is required. Please install it."
        fi
    else
        log_info "Azure CLI is already installed."
    fi
}

az_check_version() {
    log_debug "Checking Azure CLI version..."

    required_version="2.64.0"
    az_cli_version=$(az --version 2>/dev/null | grep -oP 'azure-cli\s+\K[\d.]+' || echo "")

    if [[ -z "$az_cli_version" ]]; then
        log_error_exit "Azure CLI is not installed. Please install it."
    fi

    if [[ $(printf '%s\n' "$required_version" "$az_cli_version" | sort -V | head -n1) == "$required_version" ]]; then
        log_debug "Azure CLI version $az_cli_version is installed and meets the requirement."
    else
        log_error_exit "Azure CLI version $az_cli_version is installed, but version $required_version or higher is required."
    fi
}

az_install_extensions() {
    log_debug "Checking and updating Azure CLI extensions"

    local extensions=("azure-iot-ops" "connectedk8s" "k8s-extension" "customlocation")

    for extension in "${extensions[@]}"; do
        az_install_or_update_extension "$extension"
    done
}

az_install_or_update_extension() {
    local extension_name="$1"
    
    # Check if the extension is already installed
    local installed_extension
    installed_extension=$(az extension list --output json | jq -r --arg name "$extension_name" '.[] | select(.name == $name)' || echo "")
    
    if [[ -n "$installed_extension" ]]; then
        # Get the installed version
        local installed_version
        installed_version=$(echo "$installed_extension" | jq -r '.version')
        log_debug "$extension_name is installed with version $installed_version."
        
        # Get the latest stable version
        local latest_version
        latest_version=$(az extension list-versions --name "$extension_name" --output json | jq -r '[.[] | select(.preview == false)] | last.version' 2>/dev/null)

        # Extract only the numeric part of the version (e.g., "1.1.0" from "1.1.0 (max compatible version)")
        latest_version=$(echo "$latest_version" | grep -oP '^\d+\.\d+\.\d+')

        if [[ -z "$latest_version" ]]; then
            log_debug "Failed to retrieve the latest stable version for $extension_name. Skipping update."
            return
        fi

        log_debug "Latest stable version available for $extension_name is $latest_version."
        
        if [[ "$installed_version" != "$latest_version" ]]; then
            log_debug "Updating $extension_name to version $latest_version..."
            az extension update --name "$extension_name"
        else
            log_debug "$extension_name is up-to-date."
        fi
    else
        log_debug "$extension_name is not installed. Installing..."
        az extension add --name "$extension_name"
    fi
}

az_check_token() {
    access_token=$(az account get-access-token --resource https://management.azure.com/ --query accessToken -o tsv | tr -d '\r\n')

    if [[ "$access_token" == *"The refresh token has expired"* ]]; then
        log_debug "No valid access token found. You may not be logged in."
        az login
    fi
}

az_login() {
    log_debug "Az Login"

    if ! az account show > /dev/null 2>&1; then
        log_debug "No account info found. Logging in..."
        az login
    fi
}

az_get_subscription_prop() {
    local prop
    prop=$(az account show --query "$1" --output tsv 2>/dev/null | tr -d '\r\n' || echo "")

    if [[ -z "$prop" ]]; then
        log_error_exit "Failed to retrieve the Azure subscription $1"
    fi

    echo "$prop"
}

set_variables() {
    subscriptionId=$(az_get_subscription_prop "id" | tr -d '\r\n')
    subscriptionName=$(az_get_subscription_prop "name" | tr -d '\r\n')
    tenantId=$(az_get_subscription_prop "tenantId")
    aioBaseURL="https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$clusterResourceGroup/providers/Microsoft.DeviceRegistry"
    
    az account set --subscription "$subscriptionId"
    log_info "Subscription set to: ${BOLD}${subscriptionName}${RESET} (${subscriptionId})"
}

check_required_tools() {
    missing_deps=false
    
    log_info "Checking dependencies"
    
    for cmd in az jq curl; do
        if ! command -v $cmd &> /dev/null; then
            log_error "Required dependency '$cmd' not found"
            missing_deps=true
            
            case $cmd in
                az)
                    log_info "To install Azure CLI, visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
                    ;;
                jq)
                    log_info "To install jq, run: apt-get install jq (or your system's equivalent)"
                    ;;
            esac
        fi
    done
    
    if $missing_deps; then
        log_error_exit "Please install the missing dependencies and try again"
    fi
    
    log_info "All dependencies found"
}

init_access_token() {
    if [[ -n "$accessToken" ]]; then
        return
    fi

    log_info "Initializing access token"

    if $interactiveMode; then
        get_parameter_value "Enter Cluster Name" clusterName
        get_parameter_value "Enter Cluster Resource Group" clusterResourceGroup
    fi

    validate_args --clusterName "$clusterName" --clusterResourceGroup "$clusterResourceGroup"
    
    local extension
    extension=$(get_vi_extension)
    if [[ $? -ne 0 ]]; then
        log_error_exit "Failed to retrieve Video Indexer extension: $extension"
    fi

    extensionId=$(echo "$extension" | jq -r '.id'| tr -d '\r\n')
    extensionUrl=$(echo "$extension" | jq -r '.configurationSettings["videoIndexer.endpointUri"]' | tr -d '\r\n')
    extensionAccountId=$(echo "$extension" | jq -r '.configurationSettings["videoIndexer.accountId"]' | tr -d '\r\n')
    
    if [[ -z "$extensionId" ]]; then
        log_error_exit "Error: extensionId is empty."
    fi
    if [[ -z "$extensionUrl" ]]; then
        log_error_exit "Error: extensionUrl is empty."
    fi
    if [[ -z "$extensionAccountId" ]]; then
        log_error_exit "Error: accountId is empty."
    fi

    log_info "Extension Found"
    log_info "Validating user account..."
    validate_user_account "$extensionAccountId"
    log_info "User account valid"

    local body
    body="{
        \"permissionType\": \"Contributor\",
        \"scope\": \"Account\",
        \"extensionId\": \"$extensionId\"
    }"

    log_info "Generating extension access token"
    
    local response
    response=$(az rest \
        --method post \
        --uri "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$accountResourceGroup/providers/Microsoft.VideoIndexer/accounts/$accountName/generateExtensionAccessToken?api-version=2023-06-02-preview" \
        --body "$body")

    if [[ $? -ne 0 ]]; then
        log_error_exit "Failed to generate access token: $response"
    fi

    if [[ -z "$response" || "$response" == "null" ]]; then
        log_error_exit "Failed to generate access token."
    fi

    accessToken=$(echo "$response" | jq -r '.accessToken')

    if [[ -z "$accessToken" || "$accessToken" == "null" ]]; then
        log_error_exit "Failed to retrieve access token."
    fi
    
    log_info "Access token successfully generated"
}

get_user_account() {
    response=$(az rest \
        --method get \
        --uri "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$accountResourceGroup/providers/Microsoft.VideoIndexer/accounts/$accountName?api-version=2023-06-02-preview")
    
    echo "$response"
}

function get_parameter_value () {
    local question="$1"
    local variable="$2"
    local current_value="${!variable}"

    local prompt="$question"
    if [[ -n $current_value ]]; then
        prompt+=" or use provided [$current_value]"
    fi
    prompt+=": "

    read -p "$prompt" input
    if [[ -n $input ]]; then
        eval "$variable=\"$input\""
    fi
}

show_user_account() {
    if $interactiveMode; then
        get_parameter_value "Enter Account Name" accountName
        get_parameter_value "Enter Account Resource Group" accountResourceGroup
    fi
    validate_args --accountName "$accountName" --accountResourceGroup "$accountResourceGroup"
    response=$(get_user_account)
    if [[ $? -ne 0 ]]; then
        log_error_exit "Failed to retrieve user account: $response"
    fi
    if [[ -z "$response" || "$response" == "null" ]]; then
        log_error_exit "Failed to retrieve user account."
    fi
    log_info "User account details:"
    echo "$response" | jq -C '.'
}

validate_user_account() {
    local extensionAccountId="$1"
    local userAccountId

    if $interactiveMode; then
        get_parameter_value "Enter Account Name" accountName
        get_parameter_value "Enter Account Resource Group" accountResourceGroup
    fi

    validate_args --accountName "$accountName" --accountResourceGroup "$accountResourceGroup"
    
    response=$(get_user_account)

    if [[ $? -ne 0 ]]; then
        log_error_exit "Failed to retrieve user account: $response"
    fi
    if [[ -z "$response" || "$response" == "null" ]]; then
        log_error_exit "Failed to retrieve user account."
    fi
    
    userAccountId=$(echo "$response" | jq -r '.properties.accountId' | tr -d '\r\n')
    
    if [[ $? -ne 0 || -z "$userAccountId" ]]; then
        log_error_exit "Failed to retrieve user account"
    fi
    
    if [[ "$extensionAccountId" != "$userAccountId" ]]; then
        log_error_exit "Extension account '$extensionAccountId' is different from user account '$userAccountId', make sure you are using the correct account"
    fi
}

######################
# AIO
######################

aio_create_camera_assets() {
    aio_create_asset_endpoint
    aio_create_asset
}

aio_create_asset_endpoint() {

    assetEndpointName="$cameraName-asset-endpoint"
    local aioCluster aioLocation aioCustomLocation
    aioCluster=$(az iot ops list -g "$clusterResourceGroup" -o json)
    
    if [[ -z "$aioCluster" || "$aioCluster" == "[]" ]]; then
        log_error_exit "No AIO instance found in resource group '$clusterResourceGroup'"
    fi
    
    aioLocation=$(echo "$aioCluster" | jq -r ".[0].location" | tr -d '\r\n')
    aioCustomLocation=$(echo "$aioCluster" | jq -r ".[0].extendedLocation.name" | tr -d '\r\n')

    if [[ -z "$aioLocation" ]]; then
        log_error_exit "Failed to retrieve location from $clusterResourceGroup"
    fi
    if [[ -z "$aioCustomLocation" ]]; then
        log_error_exit "Failed to retrieve custom location from $clusterResourceGroup"
    fi
    
    local authentication='{"method": "Anonymous"}'

    if $interactiveMode; then
        get_parameter_value "Enter Camera Address (RTSP URL)" cameraAddress
        get_parameter_value "Enter Camera Username (optional)" cameraUsername
        get_parameter_value "Enter Camera Password (optional)" cameraPassword
    fi

    if [[ -n "$cameraUsername" && -n "$cameraPassword" ]]; then
        local aep_secret_name="$assetEndpointName-secret"
        local namespace="azure-iot-operations"

        # TODO: install kubectl
        
        if ! kubectl get secret "$aep_secret_name" -n "$namespace" > /dev/null 2>&1; then
            log_info "Creating secret $aep_secret_name"
            
            kubectl create secret generic "$aep_secret_name" -n "$namespace" \
            --from-literal=username="$cameraUsername" \
            --from-literal=password="$cameraPassword" \
            
            log_debug "Secret created:"
            kubectl get secret "$aep_secret_name" -n "$namespace" -o yaml | log_debug
        else
            log_info "Secret $aep_secret_name already exists."
        fi

        authentication=$(cat <<BODY 
        {
            "method": "UsernamePassword",
            "usernamePasswordCredentials": {
                "passwordSecretName": "$aep_secret_name/password",
                "usernameSecretName": "$aep_secret_name/username"
            }
        }
BODY
)
    fi
    
    local body
    body=$(cat <<BODY
    {
    "location": "$aioLocation",
    "extendedLocation": {
        "type": "CustomLocation",
        "name": "$aioCustomLocation"
    },
    "tags": {
        "createdBy": "vi-arc-extension"
    },
    "properties": {
        "targetAddress": "$cameraAddress",
        "endpointProfileType": "Microsoft.Media",
        "authentication": $authentication,
        "additionalConfiguration": "{\"\$schema\": \"https://aiobrokers.blob.core.windows.net/aio-media-connector/1.0.0.json\"}"
    }}
BODY
)

    log_info "Creating asset endpoint profile '$assetEndpointName' in resource group '$clusterResourceGroup'"
    local url="$aioBaseURL/assetEndpointProfiles/$assetEndpointName?api-version=2024-11-01"

    response=$(az rest \
    --method PUT \
    --url "$url" \
    --headers '{"Content-Type": "application/json"}' \
    --body "$body" \
    --only-show-errors)

    if [[ $? -ne 0 ]]; then
        log_error_exit "Failed to create asset endpoint profile. Response: $response"
    fi

    log_info "Asset endpoint successfully created"
}

aio_delete_asset () {
    assetName="$cameraName-asset"
    log_info "deleting media asset $assetName"

    az iot ops asset delete \
    -n "$assetName" \
    -g "$clusterResourceGroup"

    log_info "deleted media asset $assetName"
}

aio_delete_asset_endpoint () {
    assetEndpointName="$cameraName-asset-endpoint"
    log_info "deleting media asset endpoint $assetEndpointName"
    
    az iot ops asset endpoint delete \
    -n "$assetEndpointName" \
    -g "$clusterResourceGroup"

    log_info "deleted media asset endpoint $assetEndpointName"
}

aio_create_asset() {
    assetName="$cameraName-asset"
    log_info "Creating asset '$assetName'"
    
    local aioCluster aioLocation aioCustomLocation
    aioCluster=$(az iot ops list -g "$clusterResourceGroup" -o json)
    
    if [[ -z "$aioCluster" || "$aioCluster" == "[]" ]]; then
        log_error_exit "No IoT Operations instances found in resource group '$clusterResourceGroup'"
    fi
    
    aioLocation=$(echo "$aioCluster" | jq -r ".[0].location" | tr -d '\r\n')
    aioCustomLocation=$(echo "$aioCluster" | jq -r ".[0].extendedLocation.name" | tr -d '\r\n')

    if [[ -z "$aioLocation" ]]; then
        log_error_exit "Failed to retrieve location from $clusterResourceGroup"
    fi
    if [[ -z "$aioCustomLocation" ]]; then
        log_error_exit "Failed to retrieve custom location from $clusterResourceGroup"
    fi

    local response
    response=$(get_media_server_config)
    if [[ $? -ne 0 ]]; then
        log_error_exit "Failed to retrieve media server configuration. Response: $response"
    fi

    local mediaServerAddress mediaServerPort
    mediaServerAddress=$(echo "$response" | jq -r '.host' | tr -d '\r\n')
    mediaServerPort=$(echo "$response" | jq -r '.port' | tr -d '\r\n')
    cameraAddress="rtsp://$mediaServerAddress:$mediaServerPort/$cameraName"
    log_debug "Media Server Address: $cameraAddress"

    local body
    body=$(cat <<BODY 
    {
    "location": "$aioLocation",
    "extendedLocation": {
        "type": "CustomLocation",
        "name": "$aioCustomLocation"
    },
    "tags": {
        "createdBy": "vi-arc-extension"
    },
    "properties": {
        "enabled": true,
        "externalAssetId": "IED77001286S",
        "displayName": "$assetName",
        "description": "$assetName",
        "assetEndpointProfileRef": "$assetEndpointName",
        "datasets": [{
            "name": "$assetName-stream-to-rtsp",
            "dataPoints": [{
                "name": "stream-to-rtsp",
                "dataSource": "stream-to-rtsp",
                "observabilityMode": "None",
                "dataPointConfiguration": "{
                    \"taskType\": \"stream-to-rtsp\",
                    \"autostart\": true,
                    \"mediaServerAddress\": \"$mediaServerAddress\",
                    \"mediaServerPort\": $mediaServerPort,
                    \"mediaServerPath\": \"$cameraName\"
                }"
            }]
    }]}}
BODY
)

    local url="$aioBaseURL/assets/$assetName?api-version=2024-11-01"

    response=$(az rest \
    --method PUT \
    --url "$url" \
    --headers '{"Content-Type": "application/json"}' \
    --body "$body" \
    --only-show-errors)

    if [[ $? -ne 0 ]]; then
        log_error_exit "Failed to create asset. Response: $response"
    fi

    log_info "Asset successfully created"
}

aio_delete_camera() {
    aio_delete_asset
    aio_delete_asset_endpoint
}

get_media_server_config() {
    local url="$extensionUrl/Accounts/$extensionAccountId/live/mediaServer/config"

    local response
    response=$(curl -s -k -X GET "$url" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $accessToken")
    
    if [[ $? -ne 0 ]]; then
        echo "Failed to retrieve media server configuration. Response: $response"
        exit 1
    fi
    echo "$response"
}

######################
# Video Indexer
######################

create_preset() {

    body=$(cat <<BODY
    {
        "Name": "$presetName",
        "InsightTypes": [
            {"Id":"00000000-0000-0000-0000-000000000003"},
            {"Id":"00000000-0000-0000-0000-000000000004"}
        ]
    }
BODY
)
    
    local url="$extensionUrl/Accounts/$extensionAccountId/live/presets"

    local response
    response=$(curl -s -k -X POST "$url" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $accessToken" \
        -d "$body")

    echo "$response"
}

commands_create_preset() {
    if $interactiveMode; then
        get_parameter_value "Enter Preset Name" presetName
    fi

    validate_args --presetName "$presetName"

    response=$(create_preset)
    if [[ $? -ne 0 ]]; then
        log_error_exit "Failed to create preset. Response: $response"
    fi
    presetId=$(echo "$response" | jq -r '.id')
    log_info "Preset created."
    echo "$response"
}

commands_delete_preset() {
    if $interactiveMode; then
        get_parameter_value "Enter Preset id" presetId
    fi

    validate_args --presetId "$presetId"

    local url="$extensionUrl/Accounts/$extensionAccountId/live/presets/$presetId"
    log_info "Deleting preset '$presetId'"

    curl -s -k -X DELETE "$url" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $accessToken"
}

commands_show_presets() {
    local url="$extensionUrl/Accounts/$extensionAccountId/live/presets"
    response=$(curl -s -k -X GET "$url" \
         -H "Content-Type: application/json" \
         -H "Authorization: Bearer $accessToken")

    echo "$response" | jq -C '.'
}

commands_create_camera() {
    if $interactiveMode; then
        get_parameter_value "Enter Camera Name" cameraName
        get_parameter_value "Enter Preset Name (optional)" presetName
    fi

    validate_args --cameraName "$cameraName"

    if $aioEnabled; then
        aio_create_camera_assets
    fi
    create_camera
}

delete_camera() {
    if $interactiveMode; then
        get_parameter_value "Enter camera id" cameraId
    fi

    validate_args --cameraId "$cameraId"
   
    local url="$extensionUrl/Accounts/$extensionAccountId/live/camerasx/$cameraId"
    curl -s -k -X DELETE "$url" \
         -H "Content-Type: application/json" \
         -H "Authorization: Bearer $accessToken"
    
    log_info "Camera '$cameraId' deleted"
}

commands_delete_camera() {
    if $aioEnabled; then
        aio_delete_camera
    else
        delete_camera
    fi
}

commands_show_cameras() {
    local url="$extensionUrl/Accounts/$extensionAccountId/live/cameras"
    response=$(curl -s -k -X GET "$url" \
         -H "Content-Type: application/json" \
         -H "Authorization: Bearer $accessToken")

    echo "$response" | jq -C '.'
}

create_camera() {

    if $aioEnabled; then
        local response
        response=$(get_media_server_config)
        if [[ $? -ne 0 ]]; then
            log_error_exit "Failed to retrieve media server configuration. Response: $response"
        fi

        local mediaServerAddress mediaServerPort
        mediaServerAddress=$(echo "$response" | jq -r '.host' | tr -d '\r\n')
        mediaServerPort=$(echo "$response" | jq -r '.port' | tr -d '\r\n')
        cameraAddress="rtsp://$mediaServerAddress:$mediaServerPort/$cameraName"
        log_debug "Media Server Address: $cameraAddress"
    else
        if $interactiveMode; then
            get_parameter_value "Enter Camera Address (RTSP URL)" cameraAddress
        fi
    fi

    validate_args --cameraAddress "$cameraAddress"
    
    presetId=null
    if [[ -n "$presetName" ]]; then
        log_info "Creating preset '$presetName'"
        response=$(create_preset)
        if [[ $? -ne 0 ]]; then
            log_error_exit "Failed to create preset. Response: $response"
        fi
        presetId=$(echo "$response" | jq -r '.id')
        presetId="\"$presetId\""
        log_info "Preset created with ID: $presetId"
    fi
    
    local body
    body=$(cat <<BODY
    {
        "Name": "$cameraName",
        "Description": "$cameraName",
        "RtspUrl": "$cameraAddress",
        "PresetId": $presetId,
        "LiveStreamingEnabled": true,
        "RecordingEnabled": true
    }
BODY
)
    
    log_info "Creating camera..."
    echo "$body"
    
    local response cameraId
    local url="$extensionUrl/Accounts/$extensionAccountId/live/cameras"
    response=$(curl -s -k -X POST "$url" \
         -H "Content-Type: application/json" \
         -H "Authorization: Bearer $accessToken" \
         -d "$body")

    if [[ $? -ne 0 ]]; then
        log_error_exit "Failed to create camera. Response: $response"
    fi
    if [[ -z "$response" || "$response" == "null" ]]; then
        log_error_exit "Failed to create camera."
    fi
 
    cameraId=$(echo "$response" | jq -r '.id')
    
    if [[ -z "$cameraId" || "$cameraId" == "null" ]]; then
        log_error_exit "Failed to create camera. Response: $response"
    fi
    
    log_info "Camera created with ID: $cameraId"
}

######################
# Extension Management
######################

get_vi_extension() {
    local response
    response=$(az k8s-extension list \
        --cluster-name "$clusterName" \
        --cluster-type connectedClusters \
        --resource-group "$clusterResourceGroup" \
        --query "[?extensionType == 'microsoft.videoindexer'] | [0]" \
        --output json 2>&1)

    if [[ $? -ne 0 ]]; then
        echo "$response"
        exit 1
    fi
    if [[ -z "$response" || "$response" == "null" ]]; then
        echo "No Video Indexer extension found for cluster '$clusterName' in resource group '$clusterResourceGroup'"
        exit 1
    fi

    echo "$response"
}

commands_upgrade_extension() {
    log_info "Upgrading Video Indexer extension"

    if $interactiveMode; then
        get_parameter_value "Enable Live Stream? (true/false)" liveStreamEnabled
        get_parameter_value "Enable Media Files? (true/false)" mediaFilesEnabled
    fi

    extension=$(get_vi_extension)
    if [[ $? -ne 0 ]]; then
        log_error_exit "Failed to retrieve Video Indexer extension: $extension"
    fi
    extensionName=$(echo "$extension" | jq -r '.name'| tr -d '\r\n')

    az k8s-extension update \
    --name "$extensionName" \
    --cluster-name "$clusterName" \
    --cluster-type connectedClusters \
    --resource-group "$clusterResourceGroup" \
    --config "videoIndexer.liveStreamEnabled=$liveStreamEnabled" \
    --config "videoIndexer.mediaFilesEnabled=$mediaFilesEnabled" \
    --yes

    if [[ $? -ne 0 ]]; then
        log_error_exit "Failed to upgrade Video Indexer extension"
    fi

    register_resource_providers
    log_info "Video Indexer extension successfully upgraded"
}

commands_show_extension() {
    
    log_info "Showing Video Indexer extension details"
    
    if $interactiveMode; then
        get_parameter_value "Enter Cluster Name" clusterName
        get_parameter_value "Enter Cluster Resource Group" clusterResourceGroup
    fi
    
    validate_args --clusterName "$clusterName" --clusterResourceGroup "$clusterResourceGroup"

    local extension
    extension=$(get_vi_extension)
    if [[ $? -ne 0 ]]; then
        log_error_exit "Failed to retrieve Video Indexer extension: $extension"
    fi

    echo "$extension" | jq -C '.'
}

register_resource_providers() {
    log_debug "Registering the required resource providers"
    
    providers=(
        "Microsoft.ExtendedLocation"
        "Microsoft.Kubernetes"
        "Microsoft.KubernetesConfiguration"
        "Microsoft.IoTOperations"
        "Microsoft.DeviceRegistry"
        "Microsoft.SecretSyncController"
    )

    for provider in "${providers[@]}"; do
        registration_state=$(az provider show --namespace "$provider" --query "registrationState" -o tsv | tr -d '\r\n' || echo "")
        
        if [[ "$registration_state" != "Registered" ]]; then
            log_debug "Registering provider: $provider"
            az provider register -n "$provider"
        else
            log_debug "Provider $provider is already registered"
        fi
    done
}

######################
# Utility Functions
######################

print_summary() {
    echo -e "\n"
    echo "==========================================="
    echo "            VI CLI Params               "
    echo "==========================================="
    printf "| %-22s | %-40s |\n" "Command" "$command $subCommand"
    printf "| %-22s | %-40s |\n" "ClusterName" "$clusterName"
    printf "| %-22s | %-40s |\n" "Cluster Resource Group" "$clusterResourceGroup"
    printf "| %-22s | %-40s |\n" "Account Name" "$accountName"
    printf "| %-22s | %-40s |\n" "Account Resource Group" "$accountResourceGroup"
    printf "| %-22s | %-40s |\n" "Subscription Name" "$subscriptionName"
    printf "| %-22s | %-40s |\n" "Subscription ID" "$subscriptionId"
    printf "| %-22s | %-40s |\n" "Tenant ID" "$tenantId"
    echo "==========================================="
}

prompt_confirmation() {
    if $skipPrompt; then
        log_info "Skipping prompt confirmation (--yes flag provided)"
        return
    fi
    
    local response
    echo
    read -p "$(echo -e "${YELLOW}Are you sure you want to proceed? (yes/no):${RESET} ")" response
    echo
    
    case "$response" in
        y|Y|yes|YES|Yes)
            log_info "Proceeding with operation"
            ;;
        *)
            log_info "Operation canceled by user"
            exit 0
            ;;
    esac
}

check_dependencies(){
    check_required_tools
    az_install
    az_check_version
    az_install_extensions
    az_check_token
    az_login
}

prerequisites_validation() {
    generate_access_token="${1:-true}"

    set_variables

    if $generate_access_token; then
        init_access_token
    fi

    if [[ -n "$clusterResourceGroup" && "$aioEnabled" ]]; then
        aioBaseURL="https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$clusterResourceGroup/providers/Microsoft.DeviceRegistry"
    fi

    print_summary
    prompt_confirmation
}

validate_args() {

    while [[ $# -gt 0 ]]; do
        local arg_name="$1"
        local arg_value="$2"
        
        if [[ -z "$arg_value" ]]; then
            log_error_exit "Usage: missing argument $arg_name, you can pass it as $arg_name or use '-it' flag for interactive mode"
        fi
        shift 2
    done
}

validate_input() {
    local input_command="$1"
    shift

    if [[ -z "$input_command" ]]; then
        log_error "No command provided."
        show_help
    fi

    if [[ $# -lt 1 || "$1" =~ ^-- ]]; then
        log_error "Missing subcommand for command '$input_command'."
        show_help
    fi

    command="$input_command"
    subCommand="$1"
    shift
    
    remaining_args=("$@")
}

run_command() {
    log_info "Running command: $command $subCommand"
    
    case "$command" in
    check)
       case "$subCommand" in
       dependencies)
            check_dependencies
            ;;
        *)
            log_error "Unknown subcommand '$subCommand' for '$command'"
            show_help
            ;;
        esac
        ;;
    create)
        case "$subCommand" in
        camera)
            prerequisites_validation
            commands_create_camera
            ;;
        preset)
            prerequisites_validation
            commands_create_preset
            ;;
        aep)
            prerequisites_validation
            aio_create_asset_endpoint
            ;;
        asset)
            prerequisites_validation
            aio_create_asset
            ;;
        *)
            log_error "Unknown subcommand '$subCommand' for '$command'"
            show_help
            ;;
        esac
        ;;
    delete)
        case "$subCommand" in
        camera)
            prerequisites_validation
            commands_delete_camera
            ;;
        preset)
            prerequisites_validation
            commands_delete_preset
        ;;
        *)
            log_error "Unknown subcommand '$subCommand' for '$command'"
            show_help
        esac
        ;;
    upgrade)
        case "$subCommand" in
        extension)
            prerequisites_validation
            commands_upgrade_extension
            ;;
        *)
            log_error "Unknown subcommand '$subCommand' for '$command'"
            show_help
            ;;
        esac
        ;;
    show)
        case "$subCommand" in
        cameras)
            prerequisites_validation
            commands_show_cameras
            ;;
        presets)
            prerequisites_validation
            commands_show_presets
            ;;
        token)
            prerequisites_validation
            if [[ -n "$accessToken" ]]; then
                log_info "Extension Access token:"
                echo "$accessToken"
            fi
            ;;
        extension)
            prerequisites_validation false
            commands_show_extension
            ;;
        account)
            prerequisites_validation false
            show_user_account
            ;;
        *)
            log_error "Unknown subcommand '$subCommand' for '$command'"
            show_help
            ;;
        esac
        ;;
    *)
        log_error "Unknown command '$command'"
        show_help
        ;;
    esac
}

######################
# Main Function
######################

main() {
    set_script_variables
    log_info "Starting Video Indexer CLI"
    
    if [[ $# -eq 0 ]]; then
        show_help
    fi
    
    validate_input "$@"
    parse_arguments "${remaining_args[@]}"
    
    trap 'log_error_exit "Script interrupted"' INT TERM
    trap 'log_error "Error at line $LINENO"' ERR

    run_command
    
    log_info "Operation completed successfully"
}

main "$@"
