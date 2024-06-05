import uuid


def generate_uuid():
    return str(uuid.uuid4())


def prompt_content_generator(videos_prompt_content: dict[str, dict]):
    for video_id, prompt_content in videos_prompt_content.items():
        video_name = prompt_content['name']
        partition = prompt_content['partition']
        for section_index, section in enumerate(prompt_content['sections']):
            yield video_id, video_name, partition, section_index, section


def get_sections_generator(videos_prompt_content, account_details, embedding_cb, embeddings_col_name="content_vector"):
    ''' Returns a generator of sections. '''

    for video_id, video_name, partition, section_index, section in prompt_content_generator(videos_prompt_content):
        content = section['content']

        proc_section = {
            "id": generate_uuid(),

            "section_idx": section_index,
            "start_time": section['start'],
            "end_time": section['end'],
            # "scene_idx": section['id'],  # Not sure what this field holds
            "content": content,

            "account_id": account_details['account_id'],
            "location": account_details["location"],
            "video_id": video_id,
            "partition": str(partition),
            "video_name": video_name
            }

        if embedding_cb is not None:
            proc_section.update({embeddings_col_name: embedding_cb(content)})

        yield proc_section
