import os
import time
from urllib.parse import urlparse
import requests

from VideoIndexerClient.Consts import Consts
from VideoIndexerClient.account_token_provider import get_arm_access_token, get_account_access_token_async


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

    def upload_url_async(self, video_name:str, video_url:str, excluded_ai:list[str],
                         wait_for_index:bool, video_description:str='', privacy='private') -> str:
        '''
        Uploads a video and starts the video index.
        Calls the uploadVideo API (https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Upload-Video)

        :param video_name: The name of the video
        :param video_url: Link to publicy accessed video URL
        :param excluded_ai: The ExcludeAI list to run
        :param wait_for_index: Should this method wait for index operation to complete
        :param video_description: The description of the video
        :param privacy: The privacy mode of the video
        :return: Video Id of the video being indexed, otherwise throws excpetion
        '''
        # check that video_url is valid
        parsed_url = urlparse(video_url)
        if not parsed_url.scheme or not parsed_url.netloc:
            raise Exception(f'Invalid video URL: {video_url}')

        self.get_account_async() # if account is not initialized, get it

        url = f'{self.consts.ApiEndpoint}/{self.account["location"]}/Accounts/{self.account["properties"]["accountId"]}/' + \
               'Videos'
        
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
    
    def file_upload_async(self, media_path:str, video_name:str, excluded_ai:list[str],
                          video_description:str='', privacy='private', partition='') -> str:
        '''
        Uploads a local file and starts the video index.
        Calls the uploadVideo API (https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Upload-Video)

        :param media_path: The path to the local file
        :param video_name: The name of the video
        :param excluded_ai: The ExcludeAI list to run
        :param video_description: The description of the video
        :param privacy: The privacy mode of the video
        :param partition: The partition of the video
        :return: Video Id of the video being indexed, otherwise throws excpetion
        '''
        if not os.path.exists(media_path):
            raise Exception(f'Could not find the local file {media_path}')

        self.get_account_async() # if account is not initialized, get it

        url = f'{self.consts.ApiEndpoint}/{self.account["location"]}/Accounts/{self.account["properties"]["accountId"]}/' + \
               'Videos'

        params = {
            'accessToken': self.vi_access_token,
            'name': video_name,
            'description': video_description,
            'privacy': privacy,
            'partition': partition
        }

        if len(excluded_ai) > 0:
            params['excludedAI'] = ','.join(excluded_ai) #TODO: check the format

        print('Uploading a local file using multipart/form-data post request..')

        response = requests.post(url, params=params, files={'file': open(media_path,'rb')})

        response.raise_for_status()

        if response.status_code != 200:
            print(f'Request failed with status code: {response.StatusCode}')

        video_id = response.json().get('id')
        
        return video_id
        
    def wait_for_index_async(self, video_id:str, language:str='English') -> None:
        '''
        Calls getVideoIndex API in 10 second intervals until the indexing state is 'processed'
        (https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Get-Video-Index).
        Prints video index when the index is complete, otherwise throws exception.

        :param video_id: The video ID to wait for
        :param language: The language to translate video insights
        '''
        self.get_account_async() # if account is not initialized, get it
        
        processing = True
        print(f'Waiting for video {video_id} to finish indexing.')

        while processing:
            url = f'{self.consts.ApiEndpoint}/{self.account["location"]}/Accounts/{self.account["properties"]["accountId"]}/' + \
                  f'Videos/{video_id}/Index'

            params = { 
                'accessToken': self.vi_access_token,
                'language': language
            }

            response = requests.get(url, params=params)

            response.raise_for_status()

            video_result = response.json()
            video_state = video_result.get('state')

            if video_state == 'Processed':
                processing = False
                print(f'The video index has completed. Here is the full JSON of the index for video ID {video_id}: \n{video_result}')
                return
            elif video_state == 'Failed':
                processing = False
                print(f"The video index failed for video ID {video_id}.")
                return
            
            print(f'The video index state is {video_state}')
            time.sleep(10) # wait 10 seconds before checking again

    def get_video_async(self, video_id:str) -> dict:
        '''
        Searches for the video in the account. Calls the searchVideo API
        (https://api-portal.videoindexer.ai/api-details#api=Operations&operation=Search-Videos)
        Prints the video metadata, otherwise throws excpetion

        :param video_id: The video ID
        '''
        self.get_account_async() # if account is not initialized, get it

        print(f'Searching videos in account {self.account["properties"]["accountId"]} for video ID {video_id}.')

        url = f'{self.consts.ApiEndpoint}/{self.account["location"]}/Accounts/{self.account["properties"]["accountId"]}/' + \
               'Videos/Search'

        params = {
            'videoId': video_id,
            'accessToken': self.vi_access_token
        }

        response = requests.get(url, params=params)

        response.raise_for_status()

        search_result = response.json()
        print(f'Here are the search results: \n{search_result}')

    def get_insights_widgets_url_async(self, video_id:str, widget_type:str, allow_edit:bool=False) -> None:
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
    
    def get_player_widget_url_async(self, video_id:str) -> None:
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