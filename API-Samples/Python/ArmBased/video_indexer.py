# %%
import requests
import os
from dotenv import load_dotenv, find_dotenv
from urllib.parse import urlencode
import time
import json
from azure.identity import DefaultAzureCredential
from azure.core.credentials import AccessToken

load_dotenv(find_dotenv())


ACCOUNT_ID = os.environ['ACCOUNT_ID']
SUBSCRIPTION_ID = os.environ['SUBSCRIPTION_ID']
RESOURCE_GROUP = os.environ['RESOURCE_GROUP']
ACCOUNT_NAME = os.environ['ACCOUNT_NAME']

AZURE_RESOURCE_MANAGER = "https://management.azure.com"
API_URL = "https://api.videoindexer.ai"
API_VERSION = "2022-08-01"


class VideoIndexerResourceProviderClient:
    def __init__(self):
        self.arm_access_token = self.get_arm_access_token()

    def get_arm_access_token(self):
        credential = DefaultAzureCredential()
        token = credential.get_token(f'{AZURE_RESOURCE_MANAGER}/.default')
        return token.token

    def get_access_token(self, permission: str, scope: str, video_id: str = None, project_id: str = None):
        if video_id and project_id:
            access_token_request = {
                "permissionType": permission,
                "scope": scope,
                "videoId": video_id
            }
        elif video_id:
            access_token_request = {
                "permissionType": permission,
                "scope": scope,
                "videoId": video_id
            }
        elif project_id:
            access_token_request = {
                "permissionType": permission,
                "scope": scope,
                "projectId": project_id
            }
        else:
            access_token_request = {
                "permissionType": permission,
                "scope": scope
            }
        print(f"\nGetting access token: {access_token_request}")
        try:
            json_request_body = json.dumps(access_token_request)
            headers = {
                "Authorization": f"Bearer {self.arm_access_token}",
                "Content-Type": "application/json"
            }
            request_url = f"{AZURE_RESOURCE_MANAGER}/subscriptions/{SUBSCRIPTION_ID}/resourcegroups/{RESOURCE_GROUP}/providers/Microsoft.VideoIndexer/accounts/{ACCOUNT_NAME}/generateAccessToken?api-version={API_VERSION}"
            response = requests.post(
                url=request_url, data=json_request_body, headers=headers)
            # verify_status(response, 2)
            json_response_body = response.json()
            # response looks like this {'accessToken':''}
            print(json_response_body)
            # print(f"Got access token: {scope} {video_id}, {permission}")

            return json_response_body["accessToken"]
        except Exception as ex:
            print(str(ex))
            raise

    def get_account(self):
        try:
            request_url = f"{AZURE_RESOURCE_MANAGER}/subscriptions/{SUBSCRIPTION_ID}/resourcegroups/{RESOURCE_GROUP}/providers/Microsoft.VideoIndexer/accounts/{ACCOUNT_NAME}?api-version={API_VERSION}"
            headers = {
                "Authorization": f"Bearer {self.arm_access_token}"
            }
            response = requests.get(url=request_url, headers=headers)
            # verify_status(response, 2)
            json_response_body = response.json()
            return json_response_body
        except Exception as ex:
            print(str(ex))
            raise

# Videos
def upload_video(account_id: str, account_location: str, account_access_token: str, video_info: dict):
    query_params = urlencode({
        "accessToken": account_access_token,
        "name": video_info['name'],
        "description": video_info['description'],
        "privacy": "private",
        "partition": "partition",
        # Do not include VideoUrl when uploading Video using StreamContent
        "videoUrl": video_info['url'],
    })

    try:
        response = requests.post(
            url=f'{API_URL}/{account_location}/Accounts/{account_id}/Videos?{query_params}')
        response = response.json()
        return response
    except Exception as ex:
        print(str(ex))
        raise

    header = {
        "Content-Type": "multipart/form-data"
    }


def get_video(account_id: str, account_location: str, video_access_token: str, video_id: str):
    print(
        f'\nSearching videos in account {ACCOUNT_NAME} for video ID {video_id}.')
    query_params = urlencode({
        "accessToken": video_access_token,
        "id": video_id
    })
    try:
        request_url = f"{API_URL}/{account_location}/Accounts/{account_id}/Videos/Search?{query_params}"
        response = requests.get(
            url=request_url)
        response = response.json()
        return response
    except Exception as ex:
        print(str(ex))
        raise


def list_videos(account_id: str, account_location: str, account_access_token: str):
    '''
        Access token scope should be Account and permission should be RestrictedViewer
    '''
    query_params = urlencode({
        "accessToken": account_access_token
    })
    try:
        request_url = f"{API_URL}/{account_location}/Accounts/{account_id}/Videos?{query_params}"
        response = requests.get(url=request_url, allow_redirects=False)
        response = response.json()
        return response
    except Exception as ex:
        print(str(ex))
        raise


def delete_video(account_id: str, account_location: str, account_access_token: str, video_id: str):
    query_params = urlencode({
        "accessToken": account_access_token
    })
    try:
        request_url = f"{API_URL}/{account_location}/Accounts/{account_id}/Videos/{video_id}?{query_params}"
        response = requests.delete(url=request_url, allow_redirects=False)
        response = response.json()
        return response
    except Exception as ex:
        print(str(ex))
        raise
    # Index


def wait_for_index(account_id: str, account_location: str, account_access_token: str, video_id: str):
    '''
        Waits for the video to be indexed, if indexing fails, raises an exception
    '''
    print(f'Waiting for index for video {video_id} to be ready...')
    i = 0
    while(True):
        query_params = urlencode({
            "accessToken": account_access_token,
            "language": "English"
        })
        response = requests.get(
            url=f'{API_URL}/{account_location}/Accounts/{account_id}/Videos/{video_id}/Index?{query_params}')
        response = response.json()

        # print('Waiting for index response: ', response)

        if response['state'] == 'Processed':
            output_dir = 'output/wait_for_index'
            os.makedirs(output_dir, exist_ok=True)
            with open(os.path.join(output_dir, f'{video_id}.json'), 'w') as f:
                json.dump(response, f)
            print('Indexing completed')
            break
        elif response['state'] == 'Failed':
            print('Indexing failed')
            raise Exception(f'Indexing failed for video {video_id}')

        print(
            f'Indexing not completed yet, waiting 10 seconds. Time elapsed: {i*60} seconds')
        print(
            f'Processing progress: {response["videos"][0]["processingProgress"]}'
        )
        time.sleep(60)
        i += 1


def get_video_index(account_id: str, account_location: str, video_access_token: str, video_id: str):
    print(f'\nGetting video index for video ID {video_id}.')
    query_params = urlencode({
        "accessToken": video_access_token,
        "language": "English",
        # "callbackUrl": "api.studiobox.com/finished"
        "includeStreamingUrls": "true",
        "includedSummarizedInsights": "Keywords",
    })

    try:
        request_url = f"{API_URL}/{account_location}/Accounts/{account_id}/Videos/{video_id}/Index?{query_params}"
        response = requests.get(url=request_url)
        response = response.json()

        # Create the directory if it doesn't exist
        output_dir = 'output/get_video_index'
        os.makedirs(output_dir, exist_ok=True)

        with open(os.path.join(output_dir, f'{video_id}.json'), 'w') as f:
            json.dump(response, f)

        return response
    except Exception as ex:
        print(str(ex))
        raise


def get_video_thumbnail(account_id: str, account_location: str, video_access_token: str, video_id: str):
    print(f'\nGetting video index for video ID {video_id}.')
    query_params = urlencode({
        "accessToken": video_access_token,
        "language": "English",
        # "callbackUrl":, webhook url
        "includeStreamingUrls": "true",
        "includedSummarizedInsights": "Keywords",
    })

    try:
        request_url = f"{API_URL}/{account_location}/Accounts/{account_id}/Videos/{video_id}/Thumbnails?{query_params}"
        response = requests.get(url=request_url)
        response = response.json()

        # Create the directory if it doesn't exist
        output_dir = 'output/get_video_thumbnail'
        os.makedirs(output_dir, exist_ok=True)

        with open(os.path.join(output_dir, f'{video_id}.json'), 'w') as f:
            json.dump(response, f)

        return response
    except Exception as ex:
        print(str(ex))
        raise


# Widgets
def get_insights_widget_url(account_id: str, account_location: str, video_access_token: str, video_id: str):
    print(f'\nGetting insights widget URL for video ID {video_id}.')
    query_params = urlencode({
        "accessToken": video_access_token,
        "widgetType": "Keywords",
        "allowEdit": "true"
    })
    try:
        request_url = f"{API_URL}/{account_location}/Accounts/{account_id}/Videos/{video_id}/InsightsWidget?{query_params}"
        response = requests.get(url=request_url, allow_redirects=False)
        insights_url = response.headers['Location']
        return insights_url
    except Exception as ex:
        print(str(ex))
        raise


def get_player_widget_url(account_id: str, account_location: str, video_access_token: str, video_id: str):
    print(f'\nGetting player widget URL for video ID {video_id}.')
    query_params = urlencode({
        "accessToken": video_access_token
    })
    try:
        request_url = f"{API_URL}/{account_location}/Accounts/{account_id}/Videos/{video_id}/PlayerWidget?{query_params}"
        response = requests.get(url=request_url, allow_redirects=False)
        player_url = response.headers['Location']
        return player_url
    except Exception as ex:
        print(str(ex))
        raise

