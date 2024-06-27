import os
import json
from pprint import pprint
from pathlib import Path
import time
from typing import Optional

from dotenv import dotenv_values

from vi_search.constants import BASE_DIR, DATA_DIR
from vi_search.language_models.language_models import LanguageModels
from vi_search.prep_scenes import get_sections_generator
from vi_search.prompt_content_db.prompt_content_db import PromptContentDB, VECTOR_FIELD_NAME
from vi_search.vi_client.video_indexer_client import init_video_indexer_client, VideoIndexerClient


def index_videos(client: VideoIndexerClient,
                 videos: list[str] | list[Path],
                 extensions: list = ['.mp4', '.mov', '.avi'],
                 privacy: str = 'private',
                 excluded_ai=None) -> dict[str, str]:
    start = time.time()
    videos_ids = {}
    for video_file in videos:
        video_file = Path(video_file)

        if not video_file.exists():
            print(f"Video file not found: {video_file}. Skipping...")
            continue

        if (video_file).suffix not in extensions:
            print(f"Unsupported video format: {video_file}. Skipping...")
            continue

        print(f"Processing video: {video_file}")

        video_id = client.file_upload_async(video_file, excluded_ai=excluded_ai, privacy=privacy)
        videos_ids[str(video_file)] = video_id

    print(f"Videos uploaded: {videos_ids}, took {time.time() - start} seconds")
    return videos_ids


def wait_for_videos_processing(client: VideoIndexerClient, videos_ids: dict, get_insights: bool = False,
                               timeout: int = 600) -> Optional[dict[str, dict]]:
    start = time.time()

    videos_left = list(videos_ids.keys())
    insights = {}
    while True:
        # Copy the list to avoid modifying it while iterating
        for video_file in videos_left[:]:
            res = client.is_video_processed(videos_ids[video_file])
            if res:
                print(f"Video {video_file} processing completed.")
                videos_left.remove(video_file)
                if get_insights:
                    insights[video_file] = client.get_video_async(videos_ids[video_file])

        elapsed = time.time() - start
        if elapsed > timeout:
            raise TimeoutError(f"Timeout reached. Videos left to process: {videos_left}")

        if elapsed % 20 == 0:
            print(f"Elapsed time: {time.time() - start} seconds. Waiting for videos to process: {videos_left}")

        if not videos_left:
            break

        time.sleep(1)

    print(f"Videos processing completed, took {time.time() - start} seconds")

    if get_insights:
        return insights


class CustomEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Path):
            return str(obj)
        return super().default(obj)  # Use default serialization for other types


def prepare_db(db_name, data_dir, language_models: LanguageModels, prompt_content_db: PromptContentDB,
               use_videos_ids_cache=True, video_ids_cache_file='videos_ids_cache.json', verbose=False):

    videos = list(data_dir.glob('*.mp4'))
    video_ids_cache_file = Path(video_ids_cache_file)

    ### Initialization ###
    try:
        config = dotenv_values(BASE_DIR / ".env")
    except FileNotFoundError:
        ''' Expects a file with the following text (Taken from Azure Portal):
                AccountName='YOUR_VI_ACCOUNT_NAME'
                ResourceGroup='RESOURCE_GROUP_NAME'
                SubscriptionId='SUBSCRIPTION_ID'
        '''
        raise FileNotFoundError("Please provide .env file with Video Indexer keys")

    client = init_video_indexer_client(config)

    ### Indexing Videos or getting indexed videos IDs ###
    if use_videos_ids_cache and video_ids_cache_file.exists():
        print(f"Using cached videos IDs from {video_ids_cache_file}")
        videos_ids = json.loads(video_ids_cache_file.read_text())
    else:
        # Setting privacy to 'public' allows much simpler access to the videos by the UI (No need for VI keys),
        # this should be used with *caution*.
        videos_ids = index_videos(client, videos=videos, privacy='public')
        if use_videos_ids_cache:
            print(f"Saving videos IDs to {video_ids_cache_file}")
            video_ids_cache_file.write_text(json.dumps(videos_ids, cls=CustomEncoder))

    wait_for_videos_processing(client, videos_ids, timeout=600)

    ### Getting indexed videos prompt content ###
    videos_prompt_content = client.get_collection_prompt_content(list(videos_ids.values()))

    if verbose:
        for video_id, prompt_content in videos_prompt_content.items():
            print(f"Video ID: {video_id}")
            pprint(prompt_content)
            print()

    ### Prepare language models ###

    embeddings_size = language_models.get_embeddings_size()

    ### Adding prompt content sections ###
    account_details = client.get_account_details()
    sections_generator = get_sections_generator(videos_prompt_content, account_details, embedding_cb=language_models.get_text_embeddings,
                                                embeddings_col_name=VECTOR_FIELD_NAME)

    ### Creating new DB ###
    prompt_content_db.create_db(db_name, vector_search_dimensions=embeddings_size)
    prompt_content_db.add_sections_to_db(sections_generator, upload_batch_size=100, verbose=verbose)

    print("Done adding sections to DB. Exiting...")


def main():
    '''
    Two options to run this script:
    1. Put your videos in the data directory and run the script.
    2. Create JSON file with the following structure:
           {"VIDEO_1_NAME": "VIDEO_1_ID",
            "VIDEO_2_NAME": "VIDEO_2_ID"}
       and run the script while calling `prepate_db()` with arguments:
            `use_videos_ids_cache=True`
            `video_ids_cache_file="path_to_json_file"`.

        Important note: If you choose ChromaDB as a your prompt content DB, you need to make sure the DB location which
                        is by default on local disk is accessible by the Azure Function App.
    '''
    print("This program will prepare a vector DB for LLM queries using the Video Indexer prompt content API")

    verbose = True

    # For UI parsing keep the name in the format: "vi-<your-name>-index"
    db_name = os.environ.get("PROMPT_CONTENT_DB_NAME", "vi-prompt-content-example-index")

    search_db = os.environ.get("PROMPT_CONTENT_DB", "azure_search")
    if search_db == "chromadb":
        from vi_search.prompt_content_db.chroma_db import ChromaDB
        prompt_content_db = ChromaDB()
    elif search_db == "azure_search":
        from vi_search.prompt_content_db.azure_search import AzureVectorSearch
        prompt_content_db = AzureVectorSearch()
    else:
        raise ValueError(f"Unknown search_db: {search_db}")

    lang_model = os.environ.get("LANGUAGE_MODEL", "openai")
    if lang_model == "openai":
        from vi_search.language_models.azure_openai import OpenAI
        language_models = OpenAI()
    elif lang_model == "dummy":
        from vi_search.language_models.dummy_lm import DummyLanguageModels
        language_models = DummyLanguageModels()
    else:
        raise ValueError(f"Unknown language model: {lang_model}")

    prepare_db(db_name, DATA_DIR, language_models, prompt_content_db, verbose=verbose)


if __name__ == "__main__":
    main()
