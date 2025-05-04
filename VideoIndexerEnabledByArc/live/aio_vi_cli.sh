#!/bin/bash

#################################################
# AIO Video Indexer CLI
# CLI for interacting with Azure Video Indexer and IoT Operations
#################################################

# set -e -o pipefail
# set -x

# set your parameters here

# Cluster parameters
clusterName="vi-arc-6-wus2-connected-aks"
clusterResourceGroup="vi-arc-6-wus2-rg"
# accountName="VI-FE-ARC-2"
# accountResourceGroup="vi-fe-arc"
accountName="vi-arc-dev"
accountResourceGroup="vi-arc-dev-rg"
liveStreamEnabled="true"
mediaFilesEnabled="true"

# VI parameters
cameraName="my-camera-name"
presetName="my-preset-name"

# AIO parameters
cameraAddress="rtsp://localhost:8554" # "<set-camera-address>"
useCameraSecret="false"
cameraUsername="<set-camera-username-if-useCameraSecret-is-true>"
cameraPassword="<set-camera-password-if-useCameraSecret-is-true>"

# DO NOT SET - Script variables will automatically set
azToken=""
accessToken=""
subscriptionId=""
subscriptionName=""
assetName=""
assetEndpointName=""
tenantId=""
aioBaseURL=""
extensionId=""
extensionUrl=""
accountId=""

######################
# Logging
######################

# Color codes for pretty logging
RESET="\033[0m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
BOLD="\033[1m"

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

log_success() {
    echo -e "${GREEN}${BOLD}[SUCCESS]${RESET} $*"
}

log_error_exit() { 
    log_error "$1"
    exit 1
}

######################
# Usage and Help
######################

show_help() {
    echo "Usage: $0 <command> <subcommand> [options]"
    echo
    echo "Commands:"
    echo "  create aio camera     Create asset endpoint profile, asset, preset and camera"
    echo "  create aio aep        Create asset endpoint profile."
    echo "  create aio asset      Create asset."
    echo "  create vi camera      Create a camera and preset in vi."
    echo "  create vi preset      Create a preset in vi."
    echo "  upgrade extension     Upgrade extension."
    echo "  show extension        Show extension"
    echo "  show account          Show user account."
    echo
    echo "Options:"
    echo "  -y|--yes                     Should continue without prompt for confirmation."
    echo "  -h|--help                    Show this help message and exit."
    echo "  -s|--skip                    Skip prerequisites check."
    echo "  -it|--interactive            Enable interactive mode."

    exit 0
}

parse_arguments() {
    skipPrompt=false
    skipPrerequisites=false
    interactiveMode=false

    while [[ $# -gt 0 ]]; do
      case "$1" in
        -y|--yes)
            skipPrompt=true
            shift
            ;;
        -s|--skip)
            skipPrerequisites=true
            shift
            ;;
        -it|--interactive)
            interactiveMode=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            log_error_exit "Unknown option: $1"
            ;;
        esac
    done

    if $interactiveMode; then
        log_info "Interactive mode enabled. Prompting for parameters..."
        
        # Prompt for Cluster Parameters
        read -p "Enter Cluster Name: " clusterName
        read -p "Enter Cluster Resource Group: " clusterResourceGroup
        

        # Prompt for AIO Parameters
        read -p "Enter Camera Address (RTSP URL): " cameraAddress
        read -p "Use Camera Secret? (true/false): " useCameraSecret

        if [[ "$useCameraSecret" == "true" ]]; then
            read -p "Enter Camera Username: " cameraUsername
            read -p "Enter Camera Password: " cameraPassword
        fi
    fi
}

######################
# Azure Helper Functions
######################

az_install() {
    log_info "Checking if Azure CLI (az) is installed..."

    if ! command -v az > /dev/null 2>&1; then
        log_info "Azure CLI is not installed. Installing..."

        curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

        if az --version > /dev/null 2>&1; then
            log_success "Azure CLI successfully installed."
        else
            log_error_exit "Failed to install Azure CLI."
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
    log_info "Setting variables..."
    
    assetName="$cameraName-asset"
    assetEndpointName="$cameraName-asset-endpoint"
    subscriptionId=$(az_get_subscription_prop "id" | tr -d '\r\n')
    subscriptionName=$(az_get_subscription_prop "name" | tr -d '\r\n')
    tenantId=$(az_get_subscription_prop "tenantId")
    aioBaseURL="https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$clusterResourceGroup/providers/Microsoft.DeviceRegistry"
    
    az account set --subscription "$subscriptionId"
    log_success "Subscription set to: ${BOLD}${subscriptionName}${RESET} (${subscriptionId})"
}

check_dependencies() {
    local missing_deps=false
    
    log_info "Checking dependencies"
    
    # Check for required tools
    for cmd in az jq curl kubectl; do
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
                kubectl)
                    log_info "To install kubectl, visit: https://kubernetes.io/docs/tasks/tools/install-kubectl/"
                    ;;
            esac
        fi
    done
    
    if [[ "$missing_deps" == "true" ]]; then
        log_error_exit "Please install the missing dependencies and try again"
    fi
    
    log_info "All dependencies found"
}

init_access_token() {
    if [[ -n "$accessToken" ]]; then
        return
    fi

    log_info "Initializing access token"
    
    local extension
    extension=$(az k8s-extension list \
        --cluster-name "$clusterName" \
        --cluster-type connectedClusters \
        --resource-group "$clusterResourceGroup" \
        --query "[?extensionType == 'microsoft.videoindexer'] | [0]" \
        --output json 2>&1)
    
    if [[ $? -ne 0 && $extension =~ "ERROR" && $extension =~ "connection" ]]; then
        log_error_exit "Failed to retrieve extension. please check your network connection"
    fi
    if [[ -z "$extension" || "$extension" == "null" ]]; then
        log_error_exit "No Video Indexer extension found for cluster '$clusterName' in resource group '$clusterResourceGroup'"
    fi

    extensionId=$(echo "$extension" | jq -r '.id'| tr -d '\r\n')
    extensionUrl=$(echo "$extension" | jq -r '.configurationSettings["videoIndexer.endpointUri"]' | tr -d '\r\n')
    accountId=$(echo "$extension" | jq -r '.configurationSettings["videoIndexer.accountId"]' | tr -d '\r\n')
    
    if [[ -z "$extensionId" ]]; then
        log_error_exit "Error: extensionId is empty."
    fi

    if [[ -z "$extensionUrl" ]]; then
        log_error_exit "Error: extensionUrl is empty."
    fi

    azToken=$(az account get-access-token --resource https://management.azure.com/ --query accessToken -o tsv | tr -d '\r\n')

    if [[ -z "$azToken" ]]; then
        log_error_exit "Error: Failed to retrieve Azure management token."
    fi

    validate_user_account "$accountId"

    local body
    body="{
        \"permissionType\": \"Contributor\",
        \"scope\": \"Account\",
        \"extensionId\": \"$extensionId\"
    }"

    log_debug "Generating extension access token"
    
    # Generate extension access token
    local response
    response=$(az rest --method post \
        --uri "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$accountResourceGroup/providers/Microsoft.VideoIndexer/accounts/$accountName/generateExtensionAccessToken?api-version=2023-06-02-preview" \
        --headers "accept=application/json" "Authorization=Bearer $azToken" "Content-Type=application/json" \
        --body "$body")

    accessToken=$(echo "$response" | jq -r '.accessToken')

    if [[ -z "$accessToken" || "$accessToken" == "null" ]]; then
        log_error_exit "Error: Failed to retrieve access token."
    fi
    
    log_success "Access token successfully generated"
}

get_user_account() {
    response=$(az rest \
        --method get \
        --uri "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$accountResourceGroup/providers/Microsoft.VideoIndexer/accounts/$accountName?api-version=2023-06-02-preview" \
        --headers "accept=application/json" "Authorization=Bearer $azToken" "Content-Type=application/json")
    
    echo "$response"
}

show_user_account() {
    response=$(get_user_account)
    log_info "User account details:"
    echo "$response" | jq -C '.'
}

get_user_account_id() {
    response=$(get_user_account)
    echo "$response"  | jq -r '.properties.accountId' | tr -d '\r\n'
}

validate_user_account() {
    local extensionAccount="$1"
    local userAccount

    if [[ -z "$extensionAccount" ]]; then
        log_error_exit "Missing extension account parameter"
    fi
    
    userAccount=$(get_user_account_id)
    
    if [[ $? -ne 0 || -z "$userAccount" ]]; then
        log_error_exit "Failed to retrieve user account"
    fi
    
    if [[ "$extensionAccount" != "$userAccount" ]]; then
        log_error_exit "Extension account '$extensionAccount' is different from user account '$userAccount', make sure you are using the correct account"
    fi
}

######################
# AIO
######################

aio_create_asset_endpoint() {
    log_info "Creating asset endpoint profile '$assetEndpointName' in resource group '$clusterResourceGroup'"

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
    
    log_debug "Location: $aioLocation"
    log_debug "Custom Location: $aioCustomLocation"
    
    local authentication='{"method": "Anonymous"}'

    if [[ "$useCameraSecret" == "true" ]]; then
        local aep_secret_name="$assetEndpointName-secret"
        local namespace="azure-iot-operations"
        
        if ! kubectl get secret "$aep_secret_name" -n "$namespace" > /dev/null 2>&1; then
            log_info "Creating secret $aep_secret_name"
            
            kubectl create secret generic "$aep_secret_name" -n "$namespace" \
            --from-literal=username=$cameraUsername \
            --from-literal=password=$cameraPassword \
            
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

    local url="$aioBaseURL/assetEndpointProfiles/$assetEndpointName?api-version=2024-11-01"
    log_debug "Request URL: $url"
    log_debug "Request body: $body"

    az rest \
    --method PUT \
    --url "$url" \
    --headers '{"Content-Type": "application/json"}' \
    --body "$body" \
    --only-show-errors

    log_success "Asset endpoint successfully created"
}

aio_create_asset() {
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
    
    local mediaServerAddress mediaServerPort
    mediaServerAddress=$(echo "$response" | jq -r '.host' | tr -d '\r\n')
    mediaServerPort=$(echo "$response" | jq -r '.port' | tr -d '\r\n')

    if [[ -z "$mediaServerAddress" || "$mediaServerAddress" == "null" ]]; then
        log_error_exit "Failed to retrieve media server configuration. Response: $response"
    fi
    
    log_debug "Media Server Address: rtsp://$mediaServerAddress:$mediaServerPort"

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
    log_debug "Request URL: $url"
    log_debug "Request body: $body"

    az rest \
    --method PUT \
    --url "$url" \
    --headers '{"Content-Type": "application/json"}' \
    --body "$body" \
    --only-show-errors

    log_success "Asset successfully created"
}

get_media_server_config() {
    local url="$extensionUrl/Accounts/$accountId/live/mediaServer/config"

    local response
    response=$(curl -s -k -X GET "$url" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $accessToken")
    
    echo "$response"
}

######################
# Video Indexer
######################

create_preset() {
    if [[ -z "$presetName" ]]; then
        log_error "Missing required presetName"
        exit 1
    fi

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
    
    local url="$extensionUrl/Accounts/$accountId/live/presets"
    log_info "Creating preset '$presetName'"

    local response
    response=$(curl -s -k -X POST "$url" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $accessToken" \
        -d "$body")

    echo "$response"
}

commands_create_preset() {
    response=$(create_preset)
    log_info "Preset created:"
    echo "$response"
}

commands_create_camera() {
    aio_create_asset_endpoint
    aio_create_asset
    commands_create_camera_vi
}

commands_create_camera_vi() {
    if $interactiveMode; then
        read -p "Enter Camera Name: " cameraName
        read -p "Enter Preset Name: " presetName
    fi
    log_info "Creating camera '$cameraName'"

    local response
    response=$(get_media_server_config)

    local mediaServerAddress mediaServerPort
    mediaServerAddress=$(echo "$response" | jq -r '.host' | tr -d '\r\n')
    mediaServerPort=$(echo "$response" | jq -r '.port' | tr -d '\r\n')

    if [[ -z "$mediaServerAddress" || "$mediaServerAddress" == "null" ]]; then
        log_error_exit "Failed to retrieve media server configuration. Response: $response"
    fi
    
    log_debug "Media Server Address: $mediaServerAddress"
    log_debug "Media Server Port: $mediaServerPort"
    
    local presetId
    log_info "Creating preset '$presetName'"
    response=$(create_preset)
    presetId=$(echo "$response" | jq -r '.Id')

    if [[ -z "$presetId" || "$presetId" == "null" ]]; then
        log_error_exit "Failed to create preset. Response: $response"
    fi
    log_success "Preset created with ID: $presetId"
    
    local body
    body=$(cat <<BODY
    {
        "Name": "$cameraName",
        "Description": "$cameraName",
        "RtspUrl": "rtsp://$mediaServerAddress:$mediaServerPort/$cameraName",
        "PresetId": "$presetId",
        "LiveStreamingEnabled": true,
        "RecordingEnabled": true
    }
BODY
)

    local response cameraId
    local url="$extensionUrl/Accounts/$accountId/live/cameras"
    response=$(curl -s -k -X POST "$url" \
         -H "Content-Type: application/json" \
         -H "Authorization: Bearer $accessToken" \
         -d "$body")
         
    cameraId=$(echo "$response" | jq -r '.Id')
    
    if [[ -z "$cameraId" || "$cameraId" == "null" ]]; then
        log_error "Failed to create camera. Response: $response"
        exit 1
    fi
    
    log_success "Camera created with ID: $cameraId"
}

######################
# Extension Management
######################

commands_upgrade_extension() {
    log_info "Upgrading Video Indexer extension"
    
    local extension
    extension=$(az k8s-extension list \
    --cluster-name "$clusterName" \
    --cluster-type connectedClusters \
    --resource-group "$clusterResourceGroup" \
    --query "[?extensionType == 'microsoft.videoindexer'] | [0]" \
    --output json)
    
    if [[ -z "$extension" || "$extension" == "null" ]]; then
        log_error_exit "No Video Indexer extension found for cluster '$clusterName' in resource group '$clusterResourceGroup'"
    fi

    az k8s-extension update \
    --name videoindexer \
    --cluster-name ${clusterName} \
    --cluster-type connectedClusters \
    --resource-group ${clusterResourceGroup} \
    --config "videoIndexer.liveStreamEnabled=$liveStreamEnabled" \
    --config "videoIndexer.mediaFilesEnabled=$mediaFilesEnabled" \
    --only-show-errors

    log_success "Video Indexer extension successfully upgraded"
}

commands_show_extension() {
    log_info "Showing Video Indexer extension details"
    
    local extension
    extension=$(az k8s-extension list \
    --cluster-name "$clusterName" \
    --cluster-type connectedClusters \
    --resource-group "$clusterResourceGroup" \
    --query "[?extensionType == 'microsoft.videoindexer'] | [0]" \
    --output json)
    
    if [[ -z "$extension" || "$extension" == "null" ]]; then
        log_error_exit "No Video Indexer extension found for cluster '$clusterName' in resource group '$clusterResourceGroup'"
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
    echo "            VI <> AIO Params               "
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

prerequisites_validation() {
    if ! $skipPrerequisites; then
        check_dependencies
        az_install
        az_check_version
        az_install_extensions
        az_check_token
        az_login
    else
         log_info "Skipping prerequisites validation..."
    fi

    set_variables
    init_access_token
    print_summary
    prompt_confirmation
}

validate_input() {
    local args=()
    
    for arg in "$@"; do
        [[ "$arg" == --* || "$arg" == -* ]] && break
        args+=("$arg")
    done

    if [[ ${#args[@]} -lt 2 ]]; then
        log_error "Missing subcommand for command '${args[*]}'."
        show_help
    fi

    command="${args[0]}"
    subCommand="${args[1]}"
    subType="${args[2]:-}"  # optional

    shift "${#args[@]}"
    remaining_args=("$@")
}


run_command() {
    log_info "Running command: $command $subCommand $subType"
    
    case "$command" in
    create)
        case "$subCommand" in
        aio)
            case "$subType" in
            camera)
                prerequisites_validation
                commands_create_camera
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
                log_error "Unknown subType '$subType' for '$subCommand'"
                show_help
                ;;
            esac
            ;;
        vi)
            case "$subType" in
            camera)
                prerequisites_validation
                commands_create_camera_vi
                ;;
            preset)
                prerequisites_validation
                commands_create_preset
                ;;
            *)
                log_error "Unknown subcommand '$subType' for '$subCommand'"
                show_help
                ;;
            esac
            ;;
       
        *)
            log_error "Unknown subcommand '$subCommand' for '$command'"
            show_help
            ;;
        esac
        ;;
    upgrade)
        case "$subCommand" in
        extension)
            prerequisites_validation
            commands_upgrade_extension
            register_resource_providers
            ;;
        *)
            log_error "Unknown subcommand '$subCommand' for '$command'"
            show_help
            ;;
        esac
        ;;
    show)
        case "$subCommand" in
        extension)
            prerequisites_validation
            commands_show_extension
            ;;
        account)
            prerequisites_validation
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
    log_info "Starting AIO Video Indexer CLI"
    
    if [[ $# -eq 0 ]]; then
        show_help
    fi
    
    validate_input "$@"
    parse_arguments "${remaining_args[@]}"
    
    trap 'log_error_exit "Script interrupted"' INT TERM
    trap 'log_error "Error at line $LINENO"' ERR

    run_command
    
    log_success "Operation completed successfully"
}

main "$@"
