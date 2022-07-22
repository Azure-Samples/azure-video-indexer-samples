import logging
import azure.functions as func
import requests
import json
import os
import base64
import datetime

# Function triggered by Blob Storage Input
def main(req: func.HttpRequest) -> str: #func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    # Get parameters from HTTP requests
    id = req.params.get('id')
    state = req.params.get('state')

    if id and state:
        # Get video insights from Video Indexer
        data = get_video_insights(id)
        if os.environ["DEBUG"] =='true':
            logging.info(data)

        # Perfom data processing
        processed_data, time_entities = process_video_data(data)

        #Push data to Search index
        push_video_data(processed_data, time_entities)

        # Return data as result of the HTTP call to chain multiple operations
        return json.dumps(processed_data)

    else:
        return json.dumps({
            'id' : id,
            'state' : 'error processing video data'
        })


# Get Video Insights from Video Indexer
def get_video_insights(video_id: str):
    # Get Video Indexer configuration
    endpoint    = os.environ["video_indexer_endpoint"]
    account_id  = os.environ["video_indexer_account_id"]
    location    = os.environ["video_indexer_location"]
    api_key     = os.environ["video_indexer_api_key"]

    headers = {
    'Ocp-Apim-Subscription-Key' : api_key
    }

    # Create token url # NEEDED ONLY FOR PRIVATE VIDEOs
    video_token_url = endpoint + "/auth/" + location + "/Accounts/" + account_id +"/Videos/" + video_id +"/AccessToken?allowEdit=true"
    video_token_url = f"{endpoint}/auth/{location}/Accounts/{account_id}/Videos/{video_id}/AccessToken?allowEdit=true"

    # Get Video level access token # ONLY FOR PRIVATE VIDEOs
    video_access_token = requests.get(video_token_url, headers=headers).json()

    # Create video URL
    video_url = f"{endpoint}/{location}/Accounts/{account_id}/Videos/{video_id}/Index?reTranslate=False&includeStreamingUrls=True&accessToken={video_access_token}"

    # Get Video Data
    search_video = requests.get(video_url, headers=headers)
    video_data = search_video.json()

    return video_data


# Custom processing to extract few insights
def process_video_data(video_data: dict):

    # Extract some fields to be indexed. Any other custom logic can be applied instead
    video_index = {}
    video_index['id'] = video_data['id']
    video_index['metadata_storage_name'] = video_data['name']
    video_index['durationInSeconds'] = video_data['durationInSeconds']

    # Create link to watch the video
    account_id = video_data['accountId']
    video_id = video_data['id']

    location_url_prefix = os.environ["video_indexer_location_url_prefix"]
    video_index['video_indexer_url'] = f"https://api.videoindexer.ai/{location_url_prefix}/Accounts/{account_id}/Videos/{video_id}/PlayerWidget?accessToken={token}"
    
    # Create path on Azure Blob Storage for video insights file
    keys            = get_storage_details(os.environ['videoknowledgemining_STORAGE'])
    protocol        = keys['DefaultEndpointsProtocol']
    endpoint_suffix = keys['EndpointSuffix']
    storage_account = keys['AccountName']
    container       = os.environ["blob_container"]
    metadata_storage_path = str(base64.urlsafe_b64encode((f"{protocol}://{storage_account}.{endpoint_suffix}/{container}/{video_id}.json").encode("utf-8")))
    video_index['metadata_storage_path'] = metadata_storage_path[2:len(metadata_storage_path)-1]

    # Extract insights from Video Indexer
    video_data = video_data['videos'][0]
    video_index['language'] = video_data['language']

    video_index['transcript'] = list(map(lambda x: x['text'],video_data['insights'].get('transcript',[])))
    video_index['merged_content'] = "\n".join(video_index['transcript'])
    video_index['ocr'] = list(map(lambda x: x['text'],video_data['insights'].get('ocr',[])))
    video_index['keywords'] = list(map(lambda x: x['text'],video_data['insights'].get('keywords',[])))

    video_index['topics'] = list(map(lambda x: x['name'], video_data['insights'].get('topics',[])))
    video_index['faces'] = list(map(lambda x: x['name'], video_data['insights'].get('faces',[])))
    video_index['labels'] = list(map(lambda x: x['name'], video_data['insights'].get('labels',[])))
    video_index['brands'] = list(map(lambda x: x['name'], video_data['insights'].get('brands',[])))
    video_index['namedLocations'] = list(map(lambda x: x['name'], video_data['insights'].get('namedLocations',[])))
    video_index['namedPeople'] = list(map(lambda x: x['name'],video_data['insights'].get('namedPeople',[])))
    try:
        video_index['sentiments'] = sum(list(map(lambda x: x['averageScore'],video_data['insights'].get('sentiments',[])))) / len(list(map(lambda x: x['averageScore'],video_data['insights'].get('sentiments',[]))))
    except ZeroDivisionError:
        video_index['sentiments'] = 0
    
    time_entities = map_time_entites(video_data)

    return video_index, time_entities


# Push data on Search Index
def push_video_data(video_data: dict, video_time_references: list):
    # POST https://[service name].search.windows.net/indexes/[index name]/docs/index?api-version=[api-version]   
    #     Content-Type: application/json   
    #     api-key: [admin key] 

    # Get Azure Cognitive Search configuration
    search_account      = os.environ["search_account"]
    search_index        = os.environ["search_index"]
    search_api_version  = os.environ["search_api_version"]
    search_key          = os.environ["search_api_key"]

    headers = {
        'api-key' : search_key,
        'Content-Type' : 'application/json'
    }

    # Define Azure Cognitive Search endpoint
    endpoint = f"https://{search_account}.search.windows.net/indexes/{search_index}/docs/index?api-version={search_api_version}"

    # Adding search action to mergeOrUpload documents for Azure Cognitive Search Push API
    search_data = {
        'value': []
    }
    video_data['@search.action'] = 'mergeOrUpload'
    search_data['value'].append(video_data)

    # Push data on Azure Cognitive Search index
    response = requests.post(url = endpoint, data = json.dumps(search_data), headers= headers)
    if os.environ["DEBUG"]== 'true':
        logging.info(response.json()) 

    # PUSH Time references data
    # Define Azure Cognitive Search endpoint
    endpoint = f"https://{search_account}.search.windows.net/indexes/{search_index}-time-references/docs/index?api-version={search_api_version}"

    # Adding search action to mergeOrUpload documents for Azure Cognitive Search Push API
    search_data = {
        'value': []
    }
    for time_ref in video_time_references:
        time_ref['@search.action'] = 'mergeOrUpload'
    search_data['value'] = video_time_references

    # Push data on Azure Cognitive Search index
    response = requests.post(url = endpoint, data = json.dumps(search_data), headers= headers)
    if os.environ["DEBUG"] == 'true':
        logging.info(response.json())



    return response

# Extract storage details from connection_string
def get_storage_details(connection_string: str):
    #connection_string = "DefaultEndpointsProtocol=https;AccountName={YOUR_ACCOUNT_NAME};AccountKey={YOUR_ACCOUNT_KEY};EndpointSuffix=core.windows.net"
    listInput = connection_string.split(';')
    keys = dict(map(lambda x : x.split('=')[0:2], listInput))
    keys['AccountKey'] += "=="
    return keys

# Extract all time references for interesting entites
def map_time_entites(data: dict):
    # Read entites to be mapped on time references
    video_id = data['id']
    data = data['insights']
    entites = list(os.environ['entities'].split(','))
    time_entities = []
    for ent in entites:
        for e in data.get(ent, []):
            x = {}
            x['video_id'] = video_id
            x['entity'] = ent
            x['id'] = str(video_id) + str(ent) + str(e['id'])
            x['text'] = e.get('name', e.get('text', ''))
            time = e['instances'][0]['start'].replace(':','.').split('.')
            x['startTime'] = int(datetime.timedelta(
                                        hours=int(time[0]) if len(time) > 0 else 0,
                                        minutes=int(time[1] if len(time) > 1 else 0),
                                        seconds=int(time[2] if len(time) > 2 else 0),
                                        milliseconds=int(time[3] if len(time) > 3 else 0)
                                        ).total_seconds())
            
            time_entities.append(x)

    return time_entities
