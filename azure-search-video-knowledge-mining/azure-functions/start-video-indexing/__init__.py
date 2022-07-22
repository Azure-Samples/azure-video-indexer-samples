import logging
import azure.functions as func
import os
import requests
import urllib.parse
from datetime import datetime, timedelta
from azure.storage.blob import BlobServiceClient, BlobClient, ContainerClient, generate_container_sas

# Function triggered by Blob Storage Input
def main(myblob: func.InputStream):
    logging.info(f"Python blob trigger function processed blob {myblob.name}")
    if ".mp4" in myblob.name:
        logging.info(f"Start processing {myblob.name}")
        # Generate Shared Access Signature to access the video on Azure Blob Storage
        sas_url = get_sas_url(myblob.uri)
        logging.info(sas_url)
        # Call Video Indexer service with Shared Access Signature to index the video
        video_result = start_video_indexing(myblob.name ,sas_url)
        logging.info(video_result)

# Define function to create Shared Access Signature
def get_sas_url(uri: str):
    # Get Azure Blob Storage configuration
    blob_account            = os.environ["blob_account"]
    blob_key                = os.environ["blob_key"]
    blob_container_source   = os.environ["blob_container_source"]

    # Generate Shared Access Signature with read permission
    sas_token = generate_container_sas(blob_account,blob_container_source, blob_key, permission="r", expiry=datetime.utcnow() + timedelta(hours=3))
    return uri + '?' + sas_token
    

# Call Video Indexer to perform video processing
def start_video_indexing(video_name: str, video_url: str):
    # Get Video Indexer configuration
    endpoint        = os.environ["video_indexer_endpoint"]
    account_id      = os.environ["video_indexer_account_id"]
    location        = os.environ["video_indexer_location"]
    api_key         = os.environ["video_indexer_api_key"]
    # Get Azure Function URL to set as callback from video indexer
    function_url    = os.environ["function_url"]
    
    headers = {
    'Ocp-Apim-Subscription-Key' : api_key
    }

    # url = "https://api.videoindexer.ai/Auth/" + location + "/Accounts?generateAccessTokens&allowEdit"
    # response = requests.get(url, headers=headers)

    # Retrieve access token to perform operation on Video Indexer
    response = requests.get(endpoint + "/auth/" + location + "/Accounts/" + account_id + "/AccessToken?allowEdit=true", headers=headers)
    access_token = response.json()

    # Call Video Indexer to start processing the video
    video_url = urllib.parse.quote(video_url)
    video_name = video_name.split('/')[-1] # extract just video name, remove container and folder path
    video_name = urllib.parse.quote(video_name)
    function_url = urllib.parse.quote(function_url)
    privacy = "Private" # Set visibility for the video [Private, Public]

    upload_video_url = f"{endpoint}/{location}/Accounts/{account_id}/Videos?accessToken={access_token}&name={video_name}&videoUrl={video_url}&privacy={privacy}&callbackUrl={function_url}"
    logging.info(upload_video_url)
    upload_result = requests.post(upload_video_url, headers=headers)

    return upload_result.json()