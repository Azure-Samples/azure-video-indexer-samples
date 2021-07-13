from dataclasses import dataclass
import requests
from time import sleep
import json


# Create a class with attributes that relate to VideoIndexer credentials
@dataclass
class VideoIndexer:
    subscription_key: str = "SUBSCRIPTION KEY GOES HERE"
    account_id: str = "ACCOUNT ID GOES HERE"
    location: str = "TRIAL"  # change this if you have a paid subscription tied to a specific location

    @classmethod
    def get_account_access_token(cls):
        """
        Get an access token from the Video Indexer API. These expire every hour and are required in order to use the
        service.
        :return access_token: string.
        """

        url = "https://api.videoindexer.ai/Auth/{}/Accounts/{}/AccessToken?allowEdit=true".format(
            cls.location, cls.account_id
        )
        headers = {
            "Ocp-Apim-Subscription-Key": cls.subscription_key,
        }
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            access_token = response.json()
            return access_token
        else:
            print("[*] Error when calling video indexer API.")
            print("[*] Response : {} {}".format(response.status_code, response.reason))

    @classmethod
    def send_to_video_indexer(cls, video_url, video_id, access_token):
        """
        Send a video to be analysed by video indexer.
        :param video_id: string, identifier for the video..
        :param video_url: string, public url for the video.
        :param access_token: string, required to use the API.
        :return video_indexer_id: string, used to access video details once indexing complete.
        """

        # Set request headers and url
        headers = {
            "Content-Type": "multipart/form-data",
        }
        video_indexer_url = (
            "https://api.videoindexer.ai/{}/Accounts/{}"
            "/Videos?name={}&privacy=Private&videoUrl={}&indexingPreset=AdvancedVideo&accessToken={"
            "}&sendSuccessEmail=True&streamingPreset=NoStreaming"
        ).format(cls.location, cls.account_id, video_id, video_url, access_token)

        # Make request and catch errors
        response = requests.post(url=video_indexer_url, headers=headers)
        if response.status_code == 200:
            video_indexer_id = response.json()["id"]
            return video_indexer_id
        # If the access token has expired get a new one
        if response.status_code == 401:
            print("[*] Access token has expired, retrying with new token.")
            access_token = cls.get_access_token()
            video_indexer_new_url = """https://api.videoindexer.ai/{}/Accounts/{}/Videos?name={}&privacy=Private&videoUrl={}&accessToken={}&sendSuccessEmail=True&streamingPreset=NoStreaming""".format(
                cls.location,
                cls.account_id,
                video_id,
                video_url,
                access_token,
            )
            response = requests.post(url=video_indexer_new_url, headers=headers)
            if response.status_code == 200:
                video_indexer_id = response.json()["id"]
                return video_indexer_id
            else:
                print("[*] Error after retrying.")
                print(
                    "[*] Response : {} {}".format(response.status_code, response.reason)
                )
        # If you are sending too many requests
        if response.status_code == 429:
            print("[*] Throttled for sending too many requests.")
            time_to_wait = response.headers["Retry-After"]
            print("[*] Retrying after {} seconds".format(time_to_wait))
            sleep(int(time_to_wait))
            response = requests.post(url=video_indexer_url, headers=headers)
            if response.status_code == 200:
                video_indexer_json_output = response.json()
                return video_indexer_json_output
            else:
                print("[*] Error after retrying following throttling.")
                print(
                    "[*] Response : {} {}".format(response.status_code, response.reason)
                )
        else:
            print("[*] Error when calling video indexer API.")
            print("[*] Response : {} {}".format(response.status_code, response.reason))

    @classmethod
    def get_indexed_video_data(cls, video_id, access_token):
        """
        Retrieves data on the video after analysis from the Video Indexer API.
        :param video_id: string, unique identifier for the indexed video.
        :param access_token: string, required to use the API.
        :return video_indexer_json_output: JSON, analysed video data.
        """

        # Set request url
        url = "https://api.videoindexer.ai/{}/Accounts/{}/Videos/{}/Index?accessToken={}".format(
            cls.location, cls.account_id, video_id, access_token
        )

        # Make request and handle unauthorized error
        response = requests.get(url=url, headers=headers)
        if response.status_code == 200:
            video_indexer_json_output = response.json()
            return video_indexer_json_output

        # If the access token has expired get a new one
        if response.status_code == 401:
            print("[*] Access token has expired, retrying with new token.")
            access_token = cls.get_access_token()
            video_indexer_new_url = "https://api.videoindexer.ai/{}/Accounts/{}/Videos/{}/Index?accessToken={}".format(
                cls.location, cls.account_id, video_id, access_token
            )
            response = requests.post(url=video_indexer_new_url, headers=headers)
            if response.status_code == 200:
                video_indexer_json_output = response.json()
                return video_indexer_json_output
            else:
                print("[*] Error after retrying.")
                print(
                    "[*] Response : {} {}".format(response.status_code, response.reason)
                )
        else:
            print("[*] Error when calling video indexer API.")
            print("[*] Response : {} {}".format(response.status_code, response.reason))


if __name__ == "__main__":
    vi = VideoIndexer()

    # To send videos
    my_access_token = vi.get_access_token()
    response_id = vi.send_to_video_indexer(
        video_url="your public url goes here",
        video_id="your video name goes here",
        access_token=my_access_token,
    )

    # To retrieve videos
    indexer_response = vi.get_indexed_video_data(
        video_id="your video name goes here", access_token=my_access_token
    )
    if indexer_response["state"] == "Processed":
        with open("video_indexer_response.json", "w") as f:
            json.dump(indexer_response, f)
    else:
        print("[*] Video has not finished processing")
