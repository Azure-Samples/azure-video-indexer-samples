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
        if project_id != None and video_id != None:
            access_token_request = {
                "permissionType": permission,
                "scope": scope,
                "videoId": video_id,
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


# def verify_status(response, expected_status_code):
#     if expected_status_code*100 <= response.status_code < (expected_status_code*100)+100:
#         print("Response status",response.status_code)
#         raise Exception(
#             f"Request failed with status code: {response.status_code}")


def upload_video(account_id: str, account_location: str, account_access_token: str, api_url: str, video_info: dict):
    query_params = urlencode({
        "accessToken": account_access_token,
        "name": video_info.name,
        "description": video_info.description,
        "privacy": "private",
        "partition": "partition",
        # Do not include VideoUrl when uploading Video using StreamContent
        "videoUrl": video_info.url,
    })

    response = requests.post(
        url=f'{api_url}/{account_location}/Accounts/{account_id}/Videos?{query_params}')

    print(response.json())


def wait_for_index(account_id: str, account_location: str, account_access_token: str, api_url: str, video_id: str):
    '''
        Waits for the video to be indexed,
    '''
    print(f'Waiting for index for video {video_id} to be ready...')
    i = 0
    while(True):
        query_params = urlencode({
            "accessToken": account_access_token,
            "language": "English"
        })
        response = requests.get(
            url=f'{api_url}/{account_location}/Accounts/{account_id}/Videos/Index?{query_params}')

        response = response.json()

        if response['state'] == 'Processed':
            print('Indexing completed')
            break
        elif response['state'] == 'Failed':
            print('Indexing failed')
            raise Exception(f'Indexing failed for video {video_id}')

        print(
            f'Indexing not completed yet, waiting 10 seconds. Time elapsed: {i*10} seconds')
        time.sleep(10)
        i += 1


if __name__ == "__main__":
    videoIndexerResourceProviderClient = VideoIndexerResourceProviderClient()
    # get account info
    account = videoIndexerResourceProviderClient.get_account()
    # extract account info
    account_location = account['location']
    account_id = account['properties']['accountId']
    # get video access token
    account_access_token = videoIndexerResourceProviderClient.get_access_token(
        permission="Contributor", scope="Account")
    # upload video
