from pathlib import Path
import re
import requests
import time
from typing import Optional
from urllib.parse import urlparse

from .consts import Consts
from .account_token_provider import get_arm_access_token, get_account_access_token_async


def extract_video_id_from_conflict_message(message) -> Optional[str]:
    ''' Extract the video ID from the message using regex. '''

    match = re.search(r"video id: '([a-zA-Z0-9]+)'", message)
    if match:
        video_id = match.group(1)
        return video_id
    else:
        print("No video ID found")
        return None


class VideoIndexerClient:
    def __init__(self) -> None:
        self.arm_access_token = ''
        self.vi_access_token = ''
        self.account = None
        self.consts = None

    def authenticate_async(self, consts:Consts) -> None:
        self.consts = consts
        # Get access tokens
        self.arm_access_token = get_arm_access_token(self.consts)
        self.vi_access_token = get_account_access_token_async(self.consts, self.arm_access_token)

    def get_account_async(self) -> None:
        '''
        Get information about the account
        '''
        if self.account is not None:
            return self.account

        headers = {
            'Authorization': 'Bearer ' + self.arm_access_token,
            'Content-Type': 'application/json'
        }

        url = f'{self.consts.AzureResourceManager}/subscriptions/{self.consts.SubscriptionId}/resourcegroups/' + \
              f'{self.consts.ResourceGroup}/providers/Microsoft.VideoIndexer/accounts/{self.consts.AccountName}' + \
              f'?api-version={self.consts.ApiVersion}'

        response = requests.get(url, headers=headers)

        response.raise_for_status()

        self.account = response.json()
        print(f'[Account Details] Id:{self.account["properties"]["accountId"]}, Location: {self.account["location"]}')

    def get_account_details(self) -> dict:
        self.get_account_async()
        return {"account_id": self.account["properties"]["accountId"], "location": self.account["location"]}

    def upload_url_async(self, video_name: str, video_url: str, excluded_ai: Optional[list[str]] = None,
                         wait_for_index: bool = False, video_description: str = '', privacy='private') -> str:
        '''
        Uploads a video and starts the video index.
        Calls the uploadVideo API (https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Upload-Video)

        :param video_name: The name of the video
        :param video_url: Link to publicly accessed video URL
        :param excluded_ai: The ExcludeAI list to run
        :param wait_for_index: Should this method wait for index operation to complete
        :param video_description: The description of the video
        :param privacy: The privacy mode of the video
        :return: Video Id of the video being indexed, otherwise throws exception
        '''
        if excluded_ai is None:
            excluded_ai = []

        # check that video_url is valid
        parsed_url = urlparse(video_url)
        if not parsed_url.scheme or not parsed_url.netloc:
            raise Exception(f'Invalid video URL: {video_url}')

        self.get_account_async() # if account is not initialized, get it

        url = f'{self.consts.ApiEndpoint}/{self.account["location"]}/Accounts/{self.account["properties"]["accountId"]}/Videos'

        params = {
            'accessToken': self.vi_access_token,
            'name': video_name,
            'description': video_description,
            'privacy': privacy,
            'videoUrl': video_url
        }

        if len(excluded_ai) > 0:
            params['excludedAI'] = ','.join(excluded_ai)

        response = requests.post(url, params=params)

        response.raise_for_status()

        video_id = response.json().get('id')
        print(f'Video ID {video_id} was uploaded successfully')

        if wait_for_index:
            self.wait_for_index_async(video_id)

        return video_id

    def file_upload_async(self, media_path: str | Path, video_name: Optional[str] = None,
                          excluded_ai: Optional[list[str]] = None, video_description: str = '', privacy='private',
                          partition='') -> str:
        '''
        Uploads a local file and starts the video index.
        Calls the uploadVideo API (https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Upload-Video)

        :param media_path: The path to the local file
        :param video_name: The name of the video, if not provided, the file name will be used
        :param excluded_ai: The ExcludeAI list to run
        :param video_description: The description of the video
        :param privacy: The privacy mode of the video
        :param partition: The partition of the video
        :return: Video Id of the video being indexed, otherwise throws exception
        '''
        if excluded_ai is None:
            excluded_ai = []

        if isinstance(media_path, str):
            media_path = Path(media_path)

        if video_name is None:
            video_name = media_path.stem

        if not media_path.exists():
            raise Exception(f'Could not find the local file {media_path}')

        self.get_account_async() # if account is not initialized, get it

        url = f'{self.consts.ApiEndpoint}/{self.account["location"]}/Accounts/{self.account["properties"]["accountId"]}/Videos'

        params = {
            'accessToken': self.vi_access_token,
            'name': video_name[:80],  # TODO: Is there a limit on the video name? If so, notice the used and also update `upload_url_async()` accordingly
            'description': video_description,
            'privacy': privacy,
            'partition': partition
        }

        if len(excluded_ai) > 0:
            params['excludedAI'] = ','.join(excluded_ai)

        print('Uploading a local file using multipart/form-data post request..')

        response = requests.post(url, params=params, files={'file': open(media_path,'rb')})

        if response.status_code == 409:
            video_id = extract_video_id_from_conflict_message(response.json()['Message'])
            if video_id is not None:
                print(f'File {media_path} already exists. Video ID {video_id}. Skipping upload...')
                return video_id

        response.raise_for_status()

        if response.status_code != 200:
            print(f'Request failed with status code: {response.StatusCode}')

        video_id = response.json().get('id')

        return video_id

    def wait_for_index_async(self, video_id: str, language: str = 'English', timeout_sec: Optional[int] = None) -> None:
        '''
        Calls getVideoIndex API in 10 second intervals until the indexing state is 'processed'
        (https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Get-Video-Index).
        Prints video index when the index is complete, otherwise throws exception.

        :param video_id: The video ID to wait for
        :param language: The language to translate video insights
        :param timeout_sec: The timeout in seconds
        '''
        self.get_account_async() # if account is not initialized, get it

        url = f'{self.consts.ApiEndpoint}/{self.account["location"]}/Accounts/{self.account["properties"]["accountId"]}/' + \
            f'Videos/{video_id}/Index'

        params = {
            'accessToken': self.vi_access_token,
            'language': language
        }

        print(f'Checking if video {video_id} has finished indexing...')
        processing = True
        start_time = time.time()
        while processing:
            response = requests.get(url, params=params)

            response.raise_for_status()

            video_result = response.json()
            video_state = video_result.get('state')

            if video_state == 'Processed':
                processing = False
                print(f'The video index has completed. Here is the full JSON of the index for video ID {video_id}: \n{video_result}')
                break
            elif video_state == 'Failed':
                processing = False
                print(f"The video index failed for video ID {video_id}.")
                break

            print(f'The video index state is {video_state}')

            if timeout_sec is not None and time.time() - start_time > timeout_sec:
                print(f'Timeout of {timeout_sec} seconds reached. Exiting...')
                break

            time.sleep(10) # wait 10 seconds before checking again

    def is_video_processed(self, video_id: str) -> bool:
        self.get_account_async() # if account is not initialized, get it

        url = f'{self.consts.ApiEndpoint}/{self.account["location"]}/Accounts/{self.account["properties"]["accountId"]}/' + \
                f'Videos/{video_id}/Index'
        params = {
            'accessToken': self.vi_access_token,
        }
        response = requests.get(url, params=params)
        response.raise_for_status()

        video_result = response.json()
        video_state = video_result.get('state')

        return video_state == 'Processed'

    def get_video_async(self, video_id: str) -> dict:
        '''
        Searches for the video in the account. Calls the searchVideo API
        (https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Search-Videos)
        Prints the video metadata, otherwise throws an exception

        :param video_id: The video ID
        '''
        self.get_account_async() # if account is not initialized, get it

        print(f'Searching videos in account {self.account["properties"]["accountId"]} for video ID {video_id}.')

        url = f'{self.consts.ApiEndpoint}/{self.account["location"]}/Accounts/{self.account["properties"]["accountId"]}/' + \
               f'Videos/{video_id}/Index'

        params = {
            'accessToken': self.vi_access_token
        }

        response = requests.get(url, params=params)

        response.raise_for_status()

        search_result = response.json()
        print(f'Here are the search results: \n{search_result}')
        return search_result

    def generate_prompt_content_async(self, video_id: str) -> None:
        '''
        Calls the promptContent API
        Initiate generation of new prompt content for the video.
        If the video already has prompt content, it will be replaced with the new one.

        :param video_id: The video ID
        '''
        self.get_account_async() # if account is not initialized, get it

        url = f'{self.consts.ApiEndpoint}/{self.account["location"]}/Accounts/{self.account["properties"]["accountId"]}/' + \
              f'Videos/{video_id}/PromptContent'

        headers = {
            "Content-Type": "application/json"
            }

        params = {
            'accessToken': self.vi_access_token
        }

        response = requests.post(url, headers=headers, params=params)

        response.raise_for_status()
        print(f"Prompt content generation for {video_id=} started...")

    def get_prompt_content_async(self, video_id: str, raise_on_not_found: bool = True) -> Optional[dict]:
        '''
        Calls the promptContent API
        Get the prompt content for the video.
        Raises an exception or returns None if the prompt content is not found according to the `raise_on_not_found`.

        :param video_id: The video ID
        :param raise_on_not_found: If True, raises an exception if the prompt content is not found.
        :return: The prompt content for the video, otherwise None
        '''
        self.get_account_async() # if account is not initialized, get it

        url = f'{self.consts.ApiEndpoint}/{self.account["location"]}/Accounts/{self.account["properties"]["accountId"]}/' + \
              f'Videos/{video_id}/PromptContent'

        headers = {
            "Content-Type": "application/json"
            }

        params = {
            'accessToken': self.vi_access_token
        }

        response = requests.get(url, params=params)
        if not raise_on_not_found and response.status_code == 404:
            return None

        response.raise_for_status()

        return response.json()

    def get_prompt_content(self, video_id: str, timeout_sec: Optional[int] = 60, check_alreay_exists: bool = True) -> dict:
        '''
        Gets the prompt content for the video, waits until the prompt content is ready.
        If the prompt content is not ready within the timeout, it will raise an exception.

        :param video_id: The video ID
        :param timeout_sec: The timeout in seconds
        :param check_already_exists: If True, checks if the prompt content already exists
        :return: The prompt content for the video
        '''

        if check_alreay_exists:
            prompt_content = self.get_prompt_content_async(video_id, raise_on_not_found=False)
            if prompt_content is not None:
                print(f'Prompt content already exists for video ID {video_id}.')
                return prompt_content

        self.generate_prompt_content_async(video_id)

        start_time = time.time()
        while True:
            prompt_content = self.get_prompt_content_async(video_id, raise_on_not_found=False)
            if prompt_content is not None:
                print(f'Prompt content ready for video ID {video_id}.')
                break

            if timeout_sec is not None and time.time() - start_time > timeout_sec:
                print(f'Timeout of {timeout_sec} seconds reached. Exiting...')
                raise TimeoutError(f'Prompt content for video ID {video_id} is not ready within {timeout_sec} seconds.')

            print('Prompt content is not ready yet. Waiting 5 seconds before checking again...')
            time.sleep(5)

        return prompt_content

    def get_collection_prompt_content(self, videos_ids: list[str], timeout_sec: Optional[int] = 300,
                                      check_alreay_exists: bool = True) -> dict:
        '''
        Gets the prompt content for a list of videos, waits until the prompt content is ready.
        If the prompt content is not ready within the timeout, it will raise an exception.

        :param videos_ids: List of video IDs
        :param timeout_sec: The timeout in seconds
        :param check_already_exists: If True, checks if the prompt content already exists
        :return: The prompt content for the videos
        '''
        # Avoid modifying the input while iterating
        videos_ids = videos_ids.copy()

        # Get prompt content for the videos that are already processed
        prompt_content_dict = {}
        if check_alreay_exists:
            for video_id in videos_ids[:]:
                prompt_content = self.get_prompt_content_async(video_id, raise_on_not_found=False)
                if prompt_content is not None:
                    print(f'Prompt content ready for video ID {video_id}.')
                    prompt_content_dict[video_id] = prompt_content
                    videos_ids.remove(video_id)

        # Initiate prompt content generation for the remaining videos
        for video_id in videos_ids:
            self.generate_prompt_content_async(video_id)

        start_time = time.time()
        while videos_ids:
            video_id = videos_ids[0]
            prompt_content = self.get_prompt_content_async(video_id, raise_on_not_found=False)
            if prompt_content is not None:
                print(f'Prompt content ready for video ID {video_id}.')
                prompt_content_dict[video_id] = prompt_content
                videos_ids.remove(video_id)
                continue

            if timeout_sec is not None and time.time() - start_time > timeout_sec:
                print(f'Timeout of {timeout_sec} seconds reached. Exiting...')
                raise TimeoutError(f'Prompt content for video ID {video_id} is not ready within {timeout_sec} seconds.')

            interval = 5
            print(f'Prompt content for {video_id} is not ready yet. Waiting {interval} seconds before checking again...')
            time.sleep(interval)

        return prompt_content_dict

    def get_insights_widgets_url_async(self, video_id: str, widget_type: str, allow_edit: bool = False) -> None:
        '''
        Calls the getVideoInsightsWidget API
        (https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Get-Video-Insights-Widget)
        It first generates a new access token for the video scope.
        Prints the VideoInsightsWidget URL, otherwise throws exception.

        :param video_id: The video ID
        :param widget_type: The widget type
        :param allow_edit: Allow editing the video insights
        '''
        self.get_account_async() # if account is not initialized, get it

        # generate a new access token for the video scope
        video_scope_access_token = get_account_access_token_async(self.consts, self.arm_access_token,
                                                                  permission_type='Contributor', scope='Video',
                                                                  video_id=video_id)

        print(f'Getting the insights widget URL for video {video_id}')

        params = {
            'widgetType': widget_type,
            'allowEdit': str(allow_edit).lower(),
            'accessToken': video_scope_access_token
        }

        url = f'{self.consts.ApiEndpoint}/{self.account["location"]}/Accounts/{self.account["properties"]["accountId"]}/' + \
              f'Videos/{video_id}/InsightsWidget'

        response = requests.get(url, params=params)

        response.raise_for_status()

        insights_widget_url = response.url
        print(f'Got the insights widget URL: {insights_widget_url}')

    def get_player_widget_url_async(self, video_id: str) -> None:
        '''
        Calls the getVideoPlayerWidget API
        (https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Get-Video-Player-Widget)
        It first generates a new access token for the video scope.
        Prints the VideoPlayerWidget URL, otherwise throws exception

        :param video_id: The video ID
        '''
        self.get_account_async()

        # generate a new access token for the video scope
        video_scope_access_token = get_account_access_token_async(self.consts, self.arm_access_token,
                                                                  permission_type='Contributor', scope='Video',
                                                                  video_id=video_id)

        print(f'Getting the player widget URL for video {video_id}')

        params = {
            'accessToken': video_scope_access_token
        }

        url = f'{self.consts.ApiEndpoint}/{self.account["location"]}/Accounts/{self.account["properties"]["accountId"]}/' + \
              f'Videos/{video_id}/PlayerWidget'

        response = requests.get(url, params=params)

        response.raise_for_status()

        url = response.url
        print(f'Got the player widget URL: {url}')



def init_video_indexer_client(config: dict) -> VideoIndexerClient:
    AccountName = config.get('AccountName')
    ResourceGroup = config.get('ResourceGroup')
    SubscriptionId = config.get('SubscriptionId')

    ApiVersion = '2024-01-01'
    ApiEndpoint = 'https://api.videoindexer.ai'
    AzureResourceManager = 'https://management.azure.com'

    # Create and validate consts
    consts = Consts(ApiVersion, ApiEndpoint, AzureResourceManager, AccountName, ResourceGroup, SubscriptionId)

    # Authenticate

    # Create Video Indexer Client
    client = VideoIndexerClient()

    # Get access tokens (arm and Video Indexer account)
    client.authenticate_async(consts)

    client.get_account_async()

    return client
