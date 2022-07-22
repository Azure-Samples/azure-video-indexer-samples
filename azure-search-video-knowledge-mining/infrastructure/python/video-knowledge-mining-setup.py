import requests
import json
from pprint import pprint
from dotenv import load_dotenv
import os
from azure.common.credentials import ServicePrincipalCredentials
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.storage import StorageManagementClient
from azure.mgmt.storage.models import StorageAccountCreateParameters, SkuName, Sku, Kind
from azure.storage.blob import BlobServiceClient, BlobClient, ContainerClient

# Load Environment configuration
load_dotenv()

# Load data for Azure Authentication
subscription_id = os.environ["subscription_id"]
client_id = os.environ["client_id"]
secret = os.environ["secret"]
tenant = os.environ["tenant"]

# Variable configuration
    # Resource Group Configuration
        resource_group = os.environ["resource_group"]
        location = os.environ["location"]
    # Azure Storage Account Configuration
        storage_account_name = os.environ["storage_account_name"]
        container_name_video_drop = os.environ["container_name_video_drop"]
        container_name_video_insights = os.environ["container_name_video_insights"]
    # Azure Cognitive Search Configuration
        cognitive_search_name = os.environ["cognitive_search_name"]
        cognitive_search_sku = os.environ["cognitive_search_sku"]
        search_key = os.environ["search_key"]
        index_name = os.environ["index_name"]

# Create Azure Credential object
credentials = ServicePrincipalCredentials(
    client_id= client_id,
    secret=secret,
    tenant=tenant
)

client = ResourceManagementClient(credentials, subscription_id)

# Create Resource Group
resource_group_param = {"location" : location}
client.resource_groups.create_or_update(resource_group, resource_group_param)


# Create Azure Storage Account
storage_account_param =  StorageAccountCreateParameters(sku=Sku(name=SkuName.standard_ragrs), kind=Kind.storage,location = location)
storage_client = StorageManagementClient(credentials, subscription_id)
storage_async_operation = storage_client.storage_accounts.create(resource_group, storage_account_name,storage_account_param)
storage_account = storage_async_operation.result()

# Get Azure Storage Account key and create connection string
storage_keys = storage_client.storage_accounts.list_keys(resource_group, storage_account_name)
storage_keys = {v.key_name: v.value for v in storage_keys.keys}
account_key = storage_keys['key1']
connection_str = f"DefaultEndpointsProtocol=https;AccountName={storage_account_name};AccountKey={account_key};EndpointSuffix=core.windows.net"

# Create containers
blob_service_client = BlobServiceClient.from_connection_string(connection_str)
container_client = blob_service_client.create_container(container_name_video_drop)
container_client = blob_service_client.create_container(container_name_video_insights)


# Create Azure Cognitive Search
cognitive_search_api_version = "2015-08-19"
cognitive_search_params = {
    "sku" : {"name" : cognitive_search_sku },
    "location" : location
}
create_async_op = client.resources.create_or_update(resource_group, "Microsoft.Search", "","searchServices", cognitive_search_name, cognitive_search_api_version, cognitive_search_params)
create_async_op.wait()


# Create Azure Cognitive Search Indexes
headers = {
    'api-key' : search_key,
    'Content-Type' : 'application/json'
}

# Define Azure Cognitive Search - Main index
with open('./video-knowledge-mining-index.json') as json_file:
    data = json.load(json_file)

url = f"https://{cognitive_search_name}.search.windows.net/indexes/{index_name}?api-version=2019-05-06"

response = requests.put(url=url, data= json.dumps(data), headers=headers)
pprint(response.json())

# Define Azure Cognitive Search - Time references index
with open('./video-knowledge-mining-index-time-references.json') as json_file:
    data = json.load(json_file)

index_name = index_name + "-time-references"

url = f"https://{search_service}.search.windows.net/indexes/{index_name}?api-version=2019-05-06"

response = requests.put(url=url, data= json.dumps(data), headers=headers)
pprint(response.json())