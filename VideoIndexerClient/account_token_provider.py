import requests
from azure.identity import DefaultAzureCredential

from VideoIndexerClient.Consts import Consts


def get_arm_access_token(consts:Consts) -> str:
    '''
    Get an access token for the Azure Resource Manager
    Make sure you're logged in with `az` first

    :param consts: Consts object
    :return: Access token for the Azure Resource Manager
    '''
    credential = DefaultAzureCredential()
    scope = f"{consts.AzureResourceManager}/.default" 
    token = credential.get_token(scope)
    return token.token


def get_account_access_token_async(consts, arm_access_token, permission_type='Contributor', scope='Account',
                                   video_id=None):
    '''
    Get an access token for the Video Indexer account
    
    :param consts: Consts object
    :param arm_access_token: Access token for the Azure Resource Manager
    :param permission_type: Permission type for the access token
    :param scope: Scope for the access token
    :param video_id: Video ID for the access token, if scope is Video. Otherwise, not required
    :return: Access token for the Video Indexer account
    '''

    headers = {
        'Authorization': 'Bearer ' + arm_access_token,
        'Content-Type': 'application/json'
    }

    url = f'{consts.AzureResourceManager}/subscriptions/{consts.SubscriptionId}/resourceGroups/{consts.ResourceGroup}' + \
          f'/providers/Microsoft.VideoIndexer/accounts/{consts.AccountName}/generateAccessToken?api-version={consts.ApiVersion}'

    params = {
        'permissionType': permission_type,
        'scope': scope
    }
    
    if video_id is not None:
        params['videoId'] = video_id

    response = requests.post(url, json=params, headers=headers)
    
    # check if the response is valid
    response.raise_for_status()
    
    access_token = response.json().get('accessToken')

    return access_token