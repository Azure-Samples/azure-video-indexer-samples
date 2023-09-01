# %%
import requests
import os
from dotenv import load_dotenv, find_dotenv
from urllib.parse import urlencode
import time
import json
from azure.identity import DefaultAzureCredential
from azure.core.credentials import AccessToken
import argparse

parser = argparse.ArgumentParser(
    description='Upload and index a video using Azure Video Indexer')
parser.add_argument('-u', '--url', required=True,
                    help='URL of the video to be uploaded and indexed')
parser.add_argument('-n', '--name', required=True, help='Name of the video')
parser.add_argument('-d', '--description', required=True,
                    help='Description of the video')

args = parser.parse_args()
video_url = args.url
video_name = args.name
video_description = args.description

load_dotenv(find_dotenv())


ACCOUNT_ID = os.environ['ACCOUNT_ID']
SUBSCRIPTION_ID = os.environ['SUBSCRIPTION_ID']
RESOURCE_GROUP = os.environ['RESOURCE_GROUP']
ACCOUNT_NAME = os.environ['ACCOUNT_NAME']

AZURE_RESOURCE_MANAGER = "https://management.azure.com"
API_VERSION = "2022-08-01"
API_URL = "https://api.videoindexer.ai"


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
            # print(json_response_body) # response looks like this {'accessToken':''}
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


# def verify_status(response, expected_status_code):
#     if expected_status_code*100 <= response.status_code < (expected_status_code*100)+100:
#         print("Response status",response.status_code)
#         raise Exception(
#             f"Request failed with status code: {response.status_code}")


def upload_video(account_id: str, account_location: str, account_access_token: str, api_url: str, video_info: dict):
    query_params = urlencode({
        "accessToken": account_access_token,
        "name": video_info['name'],
        "description": video_info['description'],
        "privacy": "private",
        "partition": "partition",
        # Do not include VideoUrl when uploading Video using StreamContent
        "videoUrl": video_info['url'],
    })

    header = {
        "Content-Type": "multipart/form-data"
    }

    try:
        response = requests.post(
            url=f'{api_url}/{account_location}/Accounts/{account_id}/Videos?{query_params}')
        response = response.json()
        return response
    except Exception as ex:
        print(str(ex))
        raise


def wait_for_index(account_id: str, account_location: str, account_access_token: str, api_url: str, video_id: str):
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
            url=f'{api_url}/{account_location}/Accounts/{account_id}/Videos/{video_id}/Index?{query_params}')

        response = response.json()

        print('Waiting for index response: ', response)

        if response['state'] == 'Processed':
            with open(f'output/{video_id}.json', 'w') as f:
                json.dump(response, f)
            print('Indexing completed')
            break
        elif response['state'] == 'Failed':
            print('Indexing failed')
            raise Exception(f'Indexing failed for video {video_id}')
        print(
            f'Indexing not completed yet, waiting 10 seconds. Time elapsed: {i*10} seconds')
        time.sleep(10)
        i += 1


def get_video(account_id: str, account_location: str, video_access_token: str, api_url: str, video_id: str):
    print(
        f'\nSearching videos in account {ACCOUNT_NAME} for video ID {video_id}.')
    query_params = urlencode({
        "accessToken": video_access_token,
        "id": video_id
    })
    try:
        request_url = f"{api_url}/{account_location}/Accounts/{account_id}/Videos/Search?{query_params}"
        response = requests.get(
            url=request_url)
        response = response.json()

        return response
    except Exception as ex:
        print(str(ex))
        raise


def get_insights_widget_url(account_id: str, account_location: str, video_access_token: str, api_url: str, video_id: str):
    query_params = urlencode({
        "accessToken": video_access_token,
        "widgetType": "Keywords",
        "allowEdit": "true"
    })
    try:
        request_url = f"{api_url}/{account_location}/Accounts/{account_id}/Videos/{video_id}/InsightsWidget?{query_params}"
        response = requests.get(url=request_url, allow_redirects=False)
        insights_url = response.headers['Location']
        return insights_url
    except Exception as ex:
        print(str(ex))
        raise


def get_player_widget_url(account_id: str, account_location: str, video_access_token: str, api_url: str, video_id: str):
    query_params = urlencode({
        "accessToken": video_access_token
    })
    try:
        request_url = f"{api_url}/{account_location}/Accounts/{account_id}/Videos/{video_id}/PlayerWidget?{query_params}"
        response = requests.get(url=request_url, allow_redirects=False)
        player_url = response.headers['Location']
        return player_url
    except Exception as ex:
        print(str(ex))
        raise


if __name__ == "__main__":
    videoIndexerResourceProviderClient = VideoIndexerResourceProviderClient()
    # get account info
    account = videoIndexerResourceProviderClient.get_account()
    # extract account info
    account_location = account['location']
    account_id = account['properties']['accountId']
    # get account access token
    account_access_token = videoIndexerResourceProviderClient.get_access_token(
        permission="Contributor", scope="Account")
    # upload video
    video_info = {
        "name": video_name,
        "description": video_description,
        "url": video_url
    }
    video_response = upload_video(account_id, account_location,
                                  account_access_token, api_url=API_URL, video_info=video_info)
    
    video_id = video_response['id']
    # wait for video to be indexed
    wait_for_index(account_id, account_location, account_access_token,
                   api_url=API_URL, video_id=video_id)
    # when video is indexed, get video access token
    video_access_token = videoIndexerResourceProviderClient.get_access_token(
        permission="Contributor", scope="Video", video_id=video_id)

    # get video
    video = get_video(account_id, account_location,
                      video_access_token, api_url=API_URL, video_id=video_id)
    

    # now that video is indexed, get video insights widget url
    insights_widget_url = get_insights_widget_url(account_id=account_id, account_location=account_location,
                                                  video_access_token=video_access_token, api_url=API_URL, video_id=video_id)
    # and the player widget url
    player_widget_url = get_player_widget_url(account_id=account_id, account_location=account_location,
                                              video_access_token=video_access_token, api_url=API_URL, video_id=video_id)

    print(f'Insights widget URL: {insights_widget_url}')
    print(f'Player widget URL: {player_widget_url}')


