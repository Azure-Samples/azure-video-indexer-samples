import logging

import requests


class VideoIndexerAPI():
    def __init__(self, vi_api_key, vi_location, vi_account_id):
        self.vi_api_key = vi_api_key
        self.vi_location = vi_location
        self.vi_account_id = vi_account_id
        self.access_token = None

    def get_access_token(self):
        """
        Here we get an access token for the video indexer instance
        :return:
        """
        logging.info('Getting video indexer access token...')
        headers = {
            'Ocp-Apim-Subscription-Key': self.vi_api_key
        }

        params = {
            'allowEdit': 'true'
        }
        access_token_req = requests.get(
            'https://api.videoindexer.ai/auth/{loc}/Accounts/{acc_id}/AccessToken'.format(
                loc=self.vi_location,
                acc_id=self.vi_account_id
            ),
            params=params,
            headers=headers
        )

        access_token = access_token_req.text[1:-1]
        logging.info('Access Token successfully retrieved')
        self.access_token = access_token
        return access_token

    def get_thumbnail(self, video_id, thumbnail_id):
        """
        Get a thumbnail from the video
        :param video_id: Id of the video
        :param thumbnail_id: Id of the thumbnail
        :return: The image
        """
        logging.info('Getting video thumbnail..')

        headers = {
            'accessToken': self.access_token
        }

        params = {
            'location': self.vi_location,
            'accountId': self.vi_account_id,
            'videoId': video_id,
            'thumbnailId': thumbnail_id,
            'format': 'Jpeg'
        }

        thumbnail_req = requests.get(
            'https://api.videoindexer.ai/{loc}/Accounts/{acc_id}/videos/{vid_id}/Thumbnails/{thumb_id}'.format(
                loc=self.vi_location,
                acc_id=self.vi_account_id,
                vid_id=video_id,
                thumb_id=thumbnail_id

            ),
            params=params,
            headers=headers
        )

        logging.info('Thumbnail: {}'.format(thumbnail_req))
        return thumbnail_req

    def get_video_artifacts(self, video_id):
        """
        Here we download all thumbnails for the video so that we can run
        inference on the keyframes
        :param video_id: Id of the video
        :return: A zip of downloaded artifacts
        """
        print('Getting video artifacts..')

        headers = {
            'accessToken': self.access_token
        }

        params = {
            'location': self.vi_location,
            'accountId': self.vi_account_id,
            'videoId': video_id,
            'type': 'KeyframesThumbnails'
        }

        artifacts_req = requests.get(
            'https://api.videoindexer.ai/{loc}/Accounts/{acc_id}/videos/{vid_id}/ArtifactUrl?type={artifact_type}'.format(
                loc=self.vi_location,
                acc_id=self.vi_account_id,
                vid_id=video_id,
                artifact_type='KeyframesThumbnails'

            ),
            params=params,
            headers=headers
        )

        logging.info('KeyFrame Thumbnail: {}'.format(artifacts_req))
        return artifacts_req

    def list_videos(self):
        print('Getting videos..')

        headers = {
            'accessToken': self.access_token
        }

        params = {
            'location': self.vi_location,
            'accountId': self.vi_account_id
        }

        list_videos_req = requests.get(
            'https://api.videoindexer.ai/{loc}/Accounts/{acc_id}/videos'.format(
                loc=self.vi_location,
                acc_id=self.vi_account_id
            ),
            params=params,
            headers=headers
        ).json()

        logging.info('Videos: {}'.format(list_videos_req))
        return list_videos_req
