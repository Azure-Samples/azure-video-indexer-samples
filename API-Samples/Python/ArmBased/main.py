import argparse
from video_indexer import VideoIndexerResourceProviderClient, upload_video, get_video, list_videos, wait_for_index, get_video_index, get_video_thumbnail, get_insights_widget_url, get_player_widget_url


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

# API_URL = "https://api.videoindexer.ai"

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
                                  account_access_token, video_info=video_info)

    video_id = video_response['id']
    # wait for video to be indexed
    wait_for_index(account_id, account_location, account_access_token, video_id=video_id)
    # when video is indexed, get video access token
    video_access_token = videoIndexerResourceProviderClient.get_access_token(
        permission="Contributor", scope="Video", video_id=video_id)

    # get video
    video = get_video_index(account_id, account_location,
                            video_access_token, video_id=video_id)

    # now that video is indexed, get video insights widget url
    insights_widget_url = get_insights_widget_url(account_id=account_id, account_location=account_location,
                                                  video_access_token=video_access_token, video_id=video_id)
    # and the player widget url
    player_widget_url = get_player_widget_url(account_id=account_id, account_location=account_location,
                                              video_access_token=video_access_token, video_id=video_id)

    print(f'Insights widget URL: {insights_widget_url}')
    print(f'Player widget URL: {player_widget_url}')
