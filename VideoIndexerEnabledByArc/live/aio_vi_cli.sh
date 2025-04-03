#!/bin/bash

#################################################
# AIO Video Indexer CLI
# CLI for interacting with Azure Video Indexer and IoT Operations
#################################################

set -e -o pipefail
# set -x

# set your parameters here

# Cluster parameters
clusterName="vi-arc-6-wus2-connected-aks"
clusterResourceGroup="vi-arc-6-wus2-rg"
accountName="vi-arc-dev"
accountResourceGroup="vi-arc-dev-rg"
liveStreamEnabled="true"
mediaFilesEnabled="true"

# AIO parameters
assetName="my-asset-name"
assetEndpointName="my-asset-endpoint-profile-name"
targetAddress="rtsp://100.2.2.2:8554"
username="admin"
password="Lidar2107!"
useSecret="true"

# Video indexer parameters
cameraName="my-camera-name"
presetName="my-preset-name"

# Script variables, automatically set
skipPrompt=false
accessToken=""
subscriptionId=""
subscriptionName=""
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
BLUE="\033[0;34m"
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
    echo "  create camera       Create a resource."
    echo "  upgrade extension   Upgrade a resource."
    echo "  show extension      Show a resource."
    echo
    echo "Options:"
    echo "  -y|--yes                     Should continue without prompt for confirmation."
    echo "  -h|--help                    Show this help message and exit."

    exit 0
}

parse_arguments() {
    skipPrompt=false

    while [[ $# -gt 0 ]]; do
      case "$1" in
        -y|--yes)
            skipPrompt=true
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
}

######################
# Azure Helper Functions
######################

az_check_logged_in() {
    log_debug "Checking if logged in to Azure CLI"
    if ! az account show &>/dev/null; then
        log_error "Not logged in to Azure CLI. Please run 'az login' first."
        exit 1
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

set_subscription_variables() {
    log_info "Setting subscription variables"
    az_check_logged_in
    
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
    
    log_success "All dependencies found"
}

init_access_token() {
    if [[ -n "$accessToken" ]]; then
        log_debug "Access token already initialized."
        return
    fi

    log_info "Initializing access token"
    
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

    extensionId=$(echo "$extension" | jq -r '.id'| tr -d '\r\n')
    extensionUrl=$(echo "$extension" | jq -r '.configurationSettings["videoIndexer.endpointUri"]' | tr -d '\r\n')
    accountId=$(echo "$extension" | jq -r '.configurationSettings["videoIndexer.accountId"]' | tr -d '\r\n')
    
    if [[ -z "$extensionId" ]]; then
        log_error_exit "Error: extensionId is empty."
    fi

    if [[ -z "$extensionUrl" ]]; then
        log_error_exit "Error: extensionUrl is empty."
    fi

    local azToken
    azToken=$(az account get-access-token --resource https://management.azure.com/ --query accessToken -o tsv | tr -d '\r\n')

    if [[ -z "$azToken" ]]; then
        log_error_exit "Error: Failed to retrieve Azure management token."
    fi

    local requestBody
    requestBody="{
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
        --body "$requestBody")

    accessToken=$(echo "$response" | jq -r '.accessToken')

    if [[ -z "$accessToken" || "$accessToken" == "null" ]]; then
        log_error_exit "Error: Failed to retrieve access token."
    fi
    
    log_success "Access token successfully generated"
}

######################
# Asset Management
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

    if [[ "$useSecret" == "true" ]]; then
        local aep_secret_name="$assetEndpointName-secret"
        local namespace="azure-iot-operations"
        
        if ! kubectl get secret "$aep_secret_name" -n "$namespace" >/dev/null 2>&1; then
            log_info "Creating secret $aep_secret_name"
            
            kubectl create secret generic "$aep_secret_name" -n "$namespace" \
            --from-literal=username=$username \
            --from-literal=password=$password
            
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
        "targetAddress": "$targetAddress",
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
    
    log_debug "Location: $aioLocation"
    log_debug "Custom Location: $aioCustomLocation"

    local mediaServerConfig
    mediaServerConfig=$(get_media_server_config)
    
    local mediaServerAddress mediaServerPort
    mediaServerAddress=$(echo "$mediaServerConfig" | jq -r '.host' | tr -d '\r\n')
    mediaServerPort=$(echo "$mediaServerConfig" | jq -r '.port' | tr -d '\r\n')
    
    log_debug "Media Server Address: $mediaServerAddress"
    log_debug "Media Server Port: $mediaServerPort"

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
                \"mediaServerPath\": \"live/stream/$cameraName\"
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
# Camera Management
######################

create_preset() {
    local builtInInsightTypes=(
        '{"Id":"00000000-0000-0000-0000-000000000003","modelType":"YoloX","InsightName":"People"}'
        '{"Id":"00000000-0000-0000-0000-000000000004","modelType":"YoloX","InsightName":"Vehicle"}'
    )

    local insightTypes=()

    for insightType in "${builtInInsightTypes[@]}"; do
        local Id
        Id=$(echo "$insightType" | jq -r '.Id')
        insightTypes+=("{\"Id\":\"$Id\"}")
    done

    local body
    body=$(cat <<BODY
    {
        "Name": "$presetName",
        "InsightTypes": "[${insightTypes[*]}]"
    }
BODY
)
    local url="$extensionUrl/Accounts/$accountId/live/presets"
    local response presetId
    response=$(curl -s -k -X POST "$url" \
         -H "Content-Type: application/json" \
         -H "Authorization: Bearer $accessToken" \
         -d "$body")

    presetId=$(echo "$response" | jq -r '.Id')
    
    if [[ -z "$presetId" || "$presetId" == "null" ]]; then
        log_error "Failed to create preset. Response: $response"
        exit 1
    fi
    
    echo "$presetId"
}

commands_create_camera() {
    log_info "Creating camera '$cameraName'"
    init_access_token

    local mediaServerConfig
    mediaServerConfig=$(get_media_server_config)
    
    local mediaServerAddress mediaServerPort
    mediaServerAddress=$(echo "$mediaServerConfig" | jq -r '.host' | tr -d '\r\n')
    mediaServerPort=$(echo "$mediaServerConfig" | jq -r '.port' | tr -d '\r\n')
    
    log_debug "Media Server Address: $mediaServerAddress"
    log_debug "Media Server Port: $mediaServerPort"
    
    local presetId
    log_info "Creating preset '$presetName'"
    presetId=$(create_preset) || { echo "create_preset failed."; exit 1; }
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

    echo -e "\n${BOLD}${BLUE}Video Indexer Extension Details:${RESET}\n"
    echo "$extension" | jq -C '.'
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
    check_dependencies
    set_subscription_variables
    print_summary
    prompt_confirmation
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
    
    # Store remaining args for parse_arguments
    remaining_args=("$@")
}

run_command() {
    log_info "Running command: $command $subCommand"
    
    case "$command" in
    create)
        case "$subCommand" in
        camera)
            prerequisites_validation
            commands_create_camera
            ;;
        asset)
            prerequisites_validation
            aio_create_asset
            ;;
        asset-endpoint)
            prerequisites_validation
            aio_create_asset_endpoint
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
            set_subscription_variables
            commands_show_extension
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
    
    # Trap for cleanup
    trap 'log_error "Script interrupted"; exit 1' INT TERM
    trap 'echo "Error at line $LINENO"' ERR

    run_command
    
    log_success "Operation completed successfully"
}

main "$@"