import json
import logging

from impl.timeparser import TimeParser

# Establish module-specific logger
log = logging.getLogger(__name__)


class Parser:
    """
    This class in responsible to Parse VI JSON file into
    intervals based on the defined interval in TimeParser.
    The result will be uploaded as an Azure Search index.
    """

    def __init__(self):
        self.time_parser = TimeParser()

    def parse_vi_json(self, vi_json: dict) -> list:
        """
        This method parses VI insights JSON files and organises content from videos[0]["insights"]
        into intervals of fixed duration (e.g. 10000 milliseconds).
        :param vi_json:
        :return: list of intervals
        """
        display_name = vi_json["name"]
        for video in vi_json["videos"]:

            parsed_content = []

            insights = video["insights"]
            intervals = self.create_intervals(video, display_name)

            if "transcript" in insights:
                try:
                    parsed_content.extend(
                        self.parse_transcript(insights["transcript"], video["id"])
                    )
                except Exception as e:
                    log.error(
                        f"The following error occurred parsing the transcript from video with ID {video['id']}: {e}"
                    )
            if "ocr" in insights:
                try:
                    parsed_content.extend(
                        self.parse_ocr(insights["ocr"], video["id"])
                    )
                except Exception as e:
                    log.error(
                        f"The following error occurred parsing OCR content from video with ID {video['id']}: {e}"
                    )
            if "keywords" in insights:
                try:
                    parsed_content.extend(
                        self.parse_keywords(insights["keywords"], video["id"])
                    )
                except Exception as e:
                    log.error(
                        f"The following error occurred parsing keywords content from video with ID {video['id']}: {e}"
                    )
            if "topics" in insights:
                try:
                    parsed_content.extend(
                        self.parse_topics(insights["topics"], video["id"])
                    )
                except Exception as e:
                    log.error(
                        f"The following error occurred parsing topics content from video with ID {video['id']}: {e}"
                    )
            if "faces" in insights:
                try:
                    parsed_content.extend(
                        self.parse_faces(insights["faces"], video["id"])
                    )
                except Exception as e:
                    log.error(
                        f"The following error occurred parsing faces content from video with ID {video['id']}: {e}"
                    )
            if "labels" in insights:
                try:
                    parsed_content.extend(
                        self.parse_labels(insights["labels"], video['id'])
                    )
                except Exception as e:
                    log.error(
                        f"The following error occurred parsing labels content from video with ID {video['id']}: {e}"
                    )
            if "namedLocations" in insights:
                try:
                    parsed_content.extend(
                        self.parse_named_people_locations(insights["namedLocations"], video['id'], named_people=False)
                    )
                except Exception as e:
                    log.error(
                        f"The following error occurred parsing named locations content from video with ID {video['id']}: {e}"
                    )
            if "namedPeople" in insights:
                try:
                    parsed_content.extend(
                        self.parse_named_people_locations(insights["namedPeople"], video["id"])
                    )
                except Exception as e:
                    log.error(
                        f"The following error occurred parsing named people content from video with ID {video['id']}: {e}"
                    )
            if "audioEffects" in insights:
                try:
                    parsed_content.extend(
                        self.parse_audio_effects(insights["audioEffects"], video["id"])
                    )
                except Exception as e:
                    log.error(
                        f"The following error occurred parsing audio effects content from video with ID {video['id']}: {e}"
                    )
            if "sentiments" in insights:
                try:
                    parsed_content.extend(
                        self.parse_sentiments(insights["sentiments"], video["id"])
                    )
                except Exception as e:
                    log.error(
                        f"The following error occurred parsing sentiments content from video with ID {video['id']}: {e}"
                    )
            if "emotions" in insights:
                try:
                    parsed_content.extend(
                        self.parse_emotions(insights["emotions"], video["id"])
                    )
                except Exception as e:
                    log.error(
                        f"The following error occurred parsing emotions content from video with ID {video['id']}: {e}"
                    )
            if "visualContentModeration" in insights:
                try:
                    parsed_content.extend(
                        self.parse_visual_content_moderation(
                            insights["visualContentModeration"],
                            video['id']
                        )
                    )
                except Exception as e:
                    log.error(
                        f"The following error occurred parsing moderation content from video with ID {video['id']}: {e}"
                    )
            if "framePatterns" in insights:
                try:
                    parsed_content.extend(
                        self.parse_frame_patterns(
                            insights["framePatterns"],
                            video["id"]
                        )
                    )
                except Exception as e:
                    log.error(
                        f"The following error occurred parsing frame patterns content from video with ID {video['id']}: {e}"
                    )
            if "brands" in insights:
                try:
                    parsed_content.extend(
                        self.parse_brands(
                            insights["brands"],
                            video["id"]
                        )
                    )
                except Exception as e:
                    log.error(
                        f"The following error occurred parsing brands content from video with ID {video['id']}: {e}"
                    )
            if "shots" in insights:
                intervals = self.parse_shot_keyframes(insights["shots"], intervals)

            intervals = self.match_output_object_to_interval(intervals, parsed_content)

            return intervals

    def create_intervals(self, video: dict, display_name: str) -> dict:
        """
        This method creates a dictionary of intervals
        :param video:
        :param display_name:
        :return:
        """
        dictionary_of_intervals = dict()
        video_id = video["id"] if "id" in video else ""
        account_id = video["accountId"] if "accountId" in video else ""
        external_id = video["externalId"] if "externalId" in video else ""
        meta_data = video["metadata"] if "metadata" in video else ""
        duration_in_milliseconds = int(
            self.time_parser.string_time_to_milliseconds(video["insights"]["duration"])
        )
        for i in range(0, duration_in_milliseconds):
            if i % self.time_parser.interval_in_milliseconds == 0:
                start_time = self.time_parser.seconds_to_time_string(i / 1000)
                end_time = (
                    self.time_parser.seconds_to_time_string(duration_in_milliseconds)
                    if i + self.time_parser.interval_in_milliseconds
                    >= duration_in_milliseconds
                    else self.time_parser.seconds_to_time_string(
                        (i + self.time_parser.interval_in_milliseconds) / 1000
                    )
                )
                dictionary_of_intervals[i] = {
                    "id": video_id
                    + "-"
                    + str(int(i / self.time_parser.interval_in_milliseconds)),
                    "accountId": account_id,
                    "externalId": external_id,
                    "name": display_name,
                    "metaData": meta_data,
                    "startTime": start_time,
                    "endTime": end_time,
                }
        return dictionary_of_intervals

    @staticmethod
    def insert_items_to_intervals_cleaner(occurred_intervals, item_tuple, intervals):
        """
        This method inserts occurred intervals into the
        dictionary of intervals (that covers all  the video)
        :param occurred_intervals:
        :param item_tuple: a tuple of Item .
         e.g. : ("faces", {"face": face["name"],
                 "assets": "{...}"})
        :return:
        """
        for i in [interval for interval in occurred_intervals if interval in intervals.keys()]:
            if item_tuple[0] in intervals[i]:
                intervals[i][item_tuple[0]].append(item_tuple[3])
            else:
                intervals[i][item_tuple[0]] = [item_tuple[3]]
        return intervals

    @staticmethod
    def insert_items_to_intervals(occurred_intervals, item_tuple, intervals):
        """ TODO: remove when all functions are converted
        This method inserts occurred intervals into the
        dictionary of intervals (that covers all  the video)
        :param occurred_intervals:
        :param item_tuple: a tuple of Item .
         e.g. : ("faces", {"face": face["name"],
                 "assets": "{...}"})
        :return:
        """
        # TODO: had to stop cases where the value of i was equal to the video end point
        # in milliseconds, and therefore didn't appear in intervals, causing a keyError
        # when indexing on intervals[i]
        # This results in an index of 1133 documents where before a 1134 document index was produced
        # It could be that a final interval that should be there is missing from intervals.
        # This could be caused by our dismissal of fractional milliseconds in the timing code,
        # which perhaps should instead be rounded up.

        # NOTE: sometimes this appears to work in producing the full set of documents, sometimes
        # the resulting index is missing 1 document.

        # Previous code:
        # for i in occurred_intervals:

        for i in [interval for interval in occurred_intervals if interval in intervals.keys()]:
            if item_tuple[0] in intervals[i]:
                intervals[i][item_tuple[0]].append(item_tuple[1])
            else:
                intervals[i][item_tuple[0]] = [item_tuple[1]]
        return intervals

    def match_output_object_to_interval(self, intervals, output_objects):

        for output_obj in output_objects:
            output_type, start, end, output = output_obj

            start = self.time_parser.string_time_to_milliseconds(start)
            end = self.time_parser.string_time_to_milliseconds(end)

            # add logging
            if start > end:
                log.error("match_output_object_to_interval: start > end")
                continue

            # naive search
            occurred_intervals = self.time_parser.get_related_intervals(
                start, end
            )

            intervals = self.insert_items_to_intervals_cleaner(
                occurred_intervals, output_obj, intervals
            )

        return intervals

    def parse_transcript(self, transcripts: list, video_id: str, min_confidence: float = 0.5) -> list:
        """
        this method parses transcript
        :param transcripts:
        :param intervals:
        :return:
        """

        output_transcripts = []
        for transcript in transcripts:

            # Content checking
            if "text" not in transcript.keys():
                log.debug(f"Transcript entry {transcript['id']} had no 'text' for video with id {video_id}.")
                log.info(f"Skipping transcript {transcript['id']} for video {video_id}.")
                continue
            if transcript["text"] == "":
                log.debug(f"Transcript entry {transcript['id']} has empty 'text' for video with id {video_id}.")
                log.info(f"Skipping transcript {transcript['id']} for video {video_id}.")
                continue
            if transcript["confidence"] < min_confidence:
                log.debug(f"Transcript {transcript['id']} for video with id {video_id} did not meet min_confidence.")
                log.info(f"Skipping transcript {transcript['id']} for video {video_id}.")
                continue
            if "instances" not in transcript.keys():
                log.debug(f"Found no instances for transcript {transcript['id']} for video {video_id}.")
                log.info(f"Skipping transcript {transcript['id']} for video {video_id}.")
                continue

            for instance in transcript["instances"]:

                try:
                    transcript_object = {
                        "transcript": transcript["text"],
                        "assets": json.dumps(
                            {
                                "id": transcript["id"],
                                "speakerId": transcript["speakerId"],
                                "language": transcript["language"],
                                "start": instance["start"],
                                "end": instance["end"],
                            }
                        )
                    }
                except KeyError as e:
                    log.error(
                        f"Missing information or incorrect keys used when creating transcript_object for transcript with id {transcript['id']} from video {video_id}."
                    )
                    raise e

                output_transcripts.append(
                    ("transcripts", instance["start"], instance["end"], transcript_object)
                )

        return output_transcripts

    def parse_ocr(self, ocrs: list, video_id: str, min_confidence: float = 0.5) -> list:
        """
        This method parses ocrs
        :param ocrs:
        :param min_confidence:
        :return:
        """

        output_ocr = []
        for ocr in ocrs:

            # Content checking
            if "text" not in ocr.keys():
                log.debug(f"ocr entry {ocr['id']} had no 'text' for video with id {video_id}.")
                log.info(f"Skipping ocr {ocr['id']} for video {video_id}.")
                continue
            if ocr["text"] == "":
                log.debug(f"ocr entry {ocr['id']} has empty 'text' for video with id {video_id}.")
                log.info(f"Skipping ocr {ocr['id']} for video {video_id}.")
                continue
            if ocr["confidence"] < min_confidence:
                log.debug(f"ocr {ocr['id']} for video with id {video_id} did not meet min_confidence.")
                log.info(f"Skipping ocr {ocr['id']} for video {video_id}.")
                continue
            if "instances" not in ocr.keys():
                log.debug(f"Found no instances for ocr {ocr['id']} for video {video_id}.")
                log.info(f"Skipping ocr {ocr['id']} for video {video_id}.")
                continue

            for instance in ocr["instances"]:

                try:
                    ocr_object = {
                        "ocr": ocr["text"],
                        "assets": json.dumps(
                            {
                                "id": ocr["id"],
                                "left": ocr["left"],
                                "top": ocr["top"],
                                "width": ocr["width"],
                                "height": ocr["height"],
                                "language": ocr["language"],
                                "start": instance["start"],
                                "end": instance["end"],
                            }
                        ),
                    }
                except KeyError as e:
                    log.error(
                        f"Missing information or incorrect keys used when creating ocr_object for ocr with id {ocr['id']} from video {video_id}."
                    )
                    raise e

                output_ocr.append(
                    ("ocrs", instance["start"], instance["end"], ocr_object)
                )

        return output_ocr

    def parse_keywords(self, keywords: list, video_id: str, min_confidence: float = 0.5) -> list:
        """
        This  method parses keywords into an output format
        :param keywords:
        :param min_confidence:
        :return:
        """

        keyword_output = []
        for keyword in keywords:

            if "text" not in keyword.keys():
                log.debug(f"Keyword entry {keyword['id']} had no 'text' for video with id {video_id}.")
                log.info(f"Skipping keyword {keyword['id']} for video {video_id}.")
                continue
            if keyword["text"] == "":
                log.debug(f"Keyword entry {keyword['id']} has empty 'text' for video with id {video_id}.")
                log.info(f"Skipping keyword {keyword['id']} for video {video_id}.")
                continue
            if keyword["confidence"] < min_confidence:
                log.debug(f"Keyword {keyword['id']} for video with id {video_id} did not meet min_confidence.")
                log.info(f"Skipping transcript {keyword['id']} for video {video_id}.")
                continue
            if "instances" not in keyword.keys():
                log.debug(f"Found no instances for keyword {keyword['id']} for video {video_id}.")
                log.info(f"Skipping keyword {keyword['id']} for video {video_id}.")
                continue

            for instance in keyword["instances"]:

                # following will appear in the search json document file.
                try:
                    keyword_object = {
                        "keyword": keyword["text"],
                        "assets": json.dumps(
                            {
                                "id": keyword["id"],
                                "language": keyword["language"],
                                "start": instance["start"],
                                "end": instance["end"],
                            }
                        ),
                    }
                except KeyError as e:
                    log.error(
                        f"Missing information or incorrect keys used when creating keyword_object for keyword with id {keyword['id']} from video {video_id}."
                    )
                    raise e

                keyword_output.append(
                    ("keywords", instance["start"], instance["end"], keyword_object)
                )

        return keyword_output

    def parse_topics(self, topics: list, video_id: str, min_confidence: float = 0.5) -> list:
        """
        this  method parses topics and add related
        data to dictionary of intervals
        :param topics:
        :param intervals:
        :return:
        """
        topics_output = []

        for topic in topics:

            if topic["name"] == "":
                log.debug(f"Topic entry {topic['id']} had no 'name' for video with id {video_id}.")
                log.info(f"Skipping topic {topic['id']} for video {video_id}.")
                continue

            if topic["confidence"] < min_confidence:
                log.debug(f"Topic {topic ['id']} for video with id {video_id} did not meet min_confidence.")
                log.info(f"Skipping topic {topic['id']} for video {video_id}.")
                continue

            if topic["name"] != "" and topic["confidence"] > min_confidence:
                for instance in topic["instances"]:

                    try:

                        topic_object = {
                            "topic": topic["name"],
                            "assets": json.dumps(
                                {
                                    "id": topic["id"],
                                    "referenceId": topic["referenceId"]
                                    if "referenceId" in topic
                                    else "",
                                    "referenceType": topic["referenceType"]
                                    if "referenceType" in topic
                                    else "",
                                    "iptcName": topic["iptcName"] if "iptcName" in topic else "",
                                    "iabName": topic["iabName"] if "iabName" in topic else "",
                                    "language": topic["language"] if "language" in topic else "",
                                    "start": instance["start"],
                                    "end": instance["end"],
                                }
                            ),
                        }
                    except KeyError as e:
                        log.error(
                            f"Missing information or incorrect keys used when creating topic_object for topic with id {topic['id']} from video {video_id}."
                        )
                        raise e

                    topics_output.append(
                        ("topics", instance["start"], instance["end"], topic_object)
                    )

        return topics_output

    def parse_faces(self, faces: list, video_id: str, min_confidence: float = 0.5):
        """
        this  method parses faces and add related
        data to dictionary of intervals
        it extracts faces from insights and thumbnails
        :param faces:
        :param intervals:
        :return:
        """

        faces_output = []
        for face in faces:
            if face["name"] == "":
                log.debug(f"Face entry {face['id']} had no 'name' for video with id {video_id}.")
                log.info(f"Skipping face {face['id']} for video {video_id}.")
                continue
            if face["confidence"] < min_confidence:
                log.debug(f"Face {face['id']} for video with id {video_id} did not meet min_confidence.")
                log.info(f"Skipping face {face['id']} for video {video_id}.")
                continue
            for instance in face["instances"]:

                try:
                    face_object = {
                        "face": face["name"],
                        "assets": json.dumps(
                            {
                                "id": face["id"],
                                "description": face["description"]
                                if "description" in face
                                else "",
                                "thumbnailId": face["thumbnailId"]
                                if "thumbnailId" in face
                                else "",
                                "knownPersonId": face["knownPersonId"]
                                if "knownPersonId" in face
                                else "",
                                "title": face["title"] if "title" in face else "",
                                "imageUrl": face["imageUrl"] if "imageUrl" in face else "",
                                "thumbnailsIds": instance["thumbnailsIds"]
                                if "thumbnailsIds" in instance
                                else "",
                                "start": instance["start"],
                                "end": instance["end"],
                            }
                        ),
                    }

                except KeyError as e:
                    log.error(
                        f"Missing information or incorrect keys used when creating face_object for face with id {face['id']} from video {video_id}."
                    )
                    raise e

                faces_output.append(
                    ("faces", instance["start"], instance["end"], face_object)
                )

            if "thumbnails" in face.keys():
                for thumbnail in face["thumbnails"]:
                    thumbnail_url = thumbnail["fileName"]
                    for instance in thumbnail["instances"]:

                        try:
                            thumbnail_object = {
                                "thumbnail": thumbnail_url,
                                "assets": json.dumps(
                                    {
                                        "id": face["id"],
                                        "description": face["description"]
                                        if "description" in face
                                        else "",
                                        "thumbnailId": face["thumbnailId"]
                                        if "thumbnailId" in face
                                        else "",
                                        "knownPersonId": face["knownPersonId"]
                                        if "knownPersonId" in face
                                        else "",
                                        "title": face["title"] if "title" in face else "",
                                        "imageUrl": face["imageUrl"]
                                        if "imageUrl" in face
                                        else "",
                                        "thumbnailsIds": thumbnail["id"],
                                        "start": instance["start"],
                                        "end": instance["end"],
                                    }
                                ),
                            }
                        except KeyError as e:
                            log.error(
                                f"Missing information or incorrect keys used when creating thumbnail_object for thumbnail {thumbnail['id']} for face with id {face['id']} from video {video_id}."
                            )
                            raise e

                        faces_output.append(
                            ("thumbnails", instance["start"], instance["end"], thumbnail_object)
                        )

        return faces_output

    def parse_labels(self, labels: list, video_id: str) -> list:
        """
        this  method parses labels and add related
        data to dictionary of intervals
        :param labels:
        :param intervals:
        :return:
        """

        label_outputs = []

        for label in labels:
            if label["name"] == "":
                log.debug(f"Label entry {label['id']} has empty 'name' for video with id {video_id}.")
                log.info(f"Skipping label {label['id']} for video {video_id}.")
                continue

            for instance in label["instances"]:

                try:
                    label_object = {
                        "label": label["name"],
                        "assets": json.dumps(
                            {
                                "id": label["id"],
                                "referenceId": label["referenceId"]
                                if "referenceId" in label
                                else "",
                                "language": label["language"] if "language" in label else "",
                                "start": instance["start"],
                                "end": instance["end"],
                            }
                        ),
                    }
                except KeyError as e:
                    log.error(
                        f"Missing information or incorrect keys used when creating label_object for label {label['id']} from video {video_id}."
                    )
                    raise e

                label_outputs.append(
                    ("labels", instance["start"], instance["end"], label_object)
                )

        return label_outputs

    def parse_named_people_locations(
            self,
            inputs: list,
            video_id: str,
            min_confidence: float = 0.5,
            named_people: bool = True
    ) -> list:
        """
        this  method parses namedLocations and add
        related data to dictionary of intervals
        :param named_people:
        :param intervals:
        :return:
        """

        named_people_location_outputs = []

        for name in inputs:
            if name["name"] == "":
                log.debug(f"Named {'person' if named_people else 'location'} entry {name['id']} has empty 'name' for video with id {video_id}.")
                log.info(f"Skipping named {'person' if named_people else 'location'} {name['id']} for video {video_id}.")
                continue

            if name["confidence"] < min_confidence:
                log.debug(f"Named {'person' if named_people else 'location'} {name['id']} for video with id {video_id} did not meet min_confidence.")
                log.info(f"Skipping named {'person' if named_people else 'location'} {name['id']} for video {video_id}.")
                continue

            for instance in name["instances"]:

                try:
                    label_object = {
                        "namedPerson" if named_people else "namedLocation": name["name"],
                        "assets": json.dumps(
                            {
                                "id": name["id"],
                                "referenceId": name["referenceId"]
                                if "referenceId" in name
                                else "",
                                "referenceUrl": name["referenceUrl"]
                                if "referenceUrl" in name
                                else "",
                                "description": name["description"]
                                if "description" in name
                                else "",
                                "confidence": name["confidence"]
                                if "confidence" in name
                                else "",
                                "instanceSource": instance["instanceSource"],
                                "start": instance["start"],
                                "end": instance["end"],
                            }
                        ),
                    }
                except KeyError as e:
                    log.error(
                        f"Missing information or incorrect keys used when creating label_object for named {'person' if named_people else 'location'} {name['id']} from video {video_id}."
                    )
                    raise e

                named_people_location_outputs.append(
                    ("namedPeople" if named_people else "namedLocations", instance["start"], instance["end"], label_object)
                )

        return named_people_location_outputs


    def parse_audio_effects(self, inputs: list, video_id: str) -> list:
        """
        this  method parses audioEffects and add
        related data to dictionary of intervals
        :param audio_effects:
        :param intervals:
        :return:
        """

        audio_effect_outputs = []

        for audio_effect in inputs:
            if audio_effect["type"] == "":
                log.debug(f"Missing 'type' value for audio effect {audio_effect['id']} in video {video_id}.")
                log.info(f"Skipping audio effect {audio_effect['id']} for video {video_id}.")
                continue

            for instance in audio_effect["instances"]:
                try:
                    label_object = {
                        "audioEffect": audio_effect["type"],
                        "assets": json.dumps(
                            {
                                "id": audio_effect["id"],
                                "start": instance["start"],
                                "end": instance["end"],
                            }
                        ),
                    }

                except KeyError as e:
                    log.error(
                        f"Missing information or incorrect keys used when creating label_object for audio effect {audio_effect['id']} from video {video_id}."
                    )
                    raise e

                audio_effect_outputs.append(
                    ("audioEffects", instance["start"], instance["end"], label_object)
                )

        return audio_effect_outputs


    def parse_sentiments(self, inputs: list, video_id: str, min_score: float = 0.5) -> list:
        """
        this  method parses sentiments and add
        related data to dictionary of intervals
        :param sentiments:
        :param intervals:
        :return:
        """

        sentiments_outputs = []

        for sentiment in inputs:
            if sentiment["sentimentType"] == "":
                log.debug(f"Missing 'sentimentType' for sentiment entry {sentiment['id']} for video with id {video_id}.")
                log.info(f"Skipping sentiment {sentiment['id']} for video {video_id}.")
                continue
            if sentiment["averageScore"] < min_score:
                log.debug(f"Sentiment {sentiment['id']} from video {video_id} did not meet min_score.")
                log.info(f"Skipping {sentiment['id']} for video {video_id}.")
                continue

            for instance in sentiment["instances"]:

                try:

                    label_object = {
                        "sentimentType": sentiment["sentimentType"],
                        "assets": json.dumps(
                            {
                                "id": sentiment["id"],
                                "averageScore": sentiment["averageScore"]
                                if "averageScore" in sentiment
                                else "",
                                "start": instance["start"],
                                "end": instance["end"],
                            }
                        ),
                    }
                except KeyError as e:
                    log.error(
                        f"Missing information or incorrect keys used when creating label_object for sentiment {sentiment['id']} from video {video_id}."
                    )
                    raise e

                sentiments_outputs.append(
                    ("sentiments", instance["start"], instance["end"], label_object)
                )

        return sentiments_outputs

    def parse_emotions(self, inputs: list, video_id: str) -> list:
        """
        this  method parses emotions and add
        related data to dictionary of intervals
        :param emotions:
        :param intervals:
        :return:
        """

        emotion_outputs = []

        for emotion in inputs:
            if emotion["type"] == "":
                log.debug(f"Emotion {emotion['id']} has empty 'type' field for video {video_id}.")
                log.info(f"Skipping emotion {emotion['id']} for video {video_id}.")
                continue

            for instance in emotion["instances"]:
                try:
                    label_object = {
                        "emotion": emotion["type"],
                        "assets": json.dumps(
                            {
                                "id": emotion["id"],
                                "start": instance["start"],
                                "end": instance["end"],
                            }
                        ),
                    }
                except KeyError as e:
                    log.error(
                        f"Missing information or incorrect keys used when creating label_object for emotion {emotion['id']} from video {video_id}."
                    )
                    raise e

                emotion_outputs.append(
                    ("emotions", instance["start"], instance["end"], label_object)
                )

        return emotion_outputs

    def parse_visual_content_moderation(self, inputs: list, video_id: str) -> list:
        """
        this  method parses visual_contents and
        add related data to dictionary of intervals
        :param visual_contents:
        :param intervals:
        :return:
        """

        moderation_outputs = []

        for content in inputs:
            for instance in content["instances"]:
                try:

                    label_object = {
                        "adultScore": str(content["adultScore"]),
                        "assets": json.dumps(
                            {
                                "id": content["id"],
                                "start": instance["start"],
                                "end": instance["end"],
                            }
                        ),
                    }
                except KeyError as e:
                    log.error(
                        f"Missing information or incorrect keys used when creating label_object for visual content moderation (adultScore) {content['id']} for video {video_id}."
                    )
                    raise e

                moderation_outputs.append(
                    ("adultScores", instance["start"], instance["end"], label_object)
                )

            for instance in content["instances"]:
                try:
                    label_object = {
                        "racyScore": str(content["racyScore"]),
                        "assets": json.dumps(
                            {
                                "id": content["id"],
                                "start": instance["start"],
                                "end": instance["end"],
                            }
                        ),
                    }
                except KeyError as e:
                    log.error(
                        f"Missing information or incorrect keys used when creating label_object for visual content moderation (racyScore) {content['id']} for video {video_id}."
                    )
                    raise e

                moderation_outputs.append(
                    ("racyScores", instance["start"], instance["end"], label_object)
                )

        return moderation_outputs


    def parse_frame_patterns(self, inputs: list, video_id: str, min_confidence: float = 0.5) -> list:
        """
        this  method parses framePatterns and add
        related data to dictionary of intervals
        :param frame_patterns:
        :param intervals:
        :return:
        """

        frame_patterns_output = []

        for pattern in inputs:
            if pattern["confidence"] < min_confidence:
                log.debug(f"Confidence for frame pattern {pattern['id']} for video {video_id} was below min_confidence.")
                log.info(f"Skipping frame pattern {pattern['id']} for video {video_id}.")
                continue
            for instance in pattern["instances"]:
                try:
                    frame_patterns_object = {
                        "assets": json.dumps(
                            {
                                "id": pattern["id"],
                                "start": instance["start"],
                                "end": instance["end"],
                            }
                        )
                    }
                except KeyError as e:
                    log.error(
                        f"Missing information or incorrect keys used when creating label_object for frame pattern {pattern['id']} for video {video_id}."
                    )
                    raise e

                frame_patterns_output.append(
                    ("framePatterns", instance["start"], instance["end"], frame_patterns_object)
                )

        return frame_patterns_output

    def parse_brands(self, inputs: list, video_id: str, min_confidence: float = 0.5) -> list:
        """
        this  method parses brands and add related
        data to dictionary of intervals
        :param brands:
        :param intervals:
        :return:
        """

        brands_output = []

        for brand in inputs:
            if brand["name"] == "":
                log.debug(f"Brand {brand['id']} has empty 'type' field for video {video_id}.")
                continue
            if brand["confidence"] < min_confidence:
                log.debug(f"Confidence for brand {brand['id']} for video {video_id} was below min_confidence.")
                log.info(f"Skipping brand {brand['id']} for video {video_id}.")
                continue
            for instance in brand["instances"]:

                try:
                    brands_object = {
                        "brand": brand["name"],
                        "assets": json.dumps(
                            {
                                "id": brand["id"],
                                "confidence": brand["confidence"],
                                "referenceId": brand["referenceId"],
                                "referenceType": brand["referenceType"],
                                "description": brand["description"],
                                "brandType": instance["brandType"],
                                "start": instance["start"],
                                "end": instance["end"],
                            }
                        ),
                    }
                except KeyError as e:
                    log.error(
                        f"Missing information or incorrect keys used when creating label_object for brand {brand['id']} for video {video_id}."
                    )
                    raise e

                brands_output.append(
                    ("brands", instance["start"], instance["end"], brands_object)
                )

        return brands_output

    def parse_shot_keyframes(self, shots, intervals):
        """
        this  method parses shots and keyframes and returns the thumbnails
        data to dictionary of intervals
        :param shots:
        :param intervals:
        :return:
        """
        for shot in shots:
            # Take the first instance - check if good for future
            for keyFrame in shot['keyFrames']:
                start = self.time_parser.string_time_to_milliseconds(
                    keyFrame["instances"][0]["start"]
                )
                end = self.time_parser.string_time_to_milliseconds(keyFrame["instances"][0]["end"])
                occurred_intervals = self.time_parser.get_related_intervals(
                    start, end
                )
                assets = {
                    "thumbnail": keyFrame["instances"][0]["thumbnailId"],
                    "start": keyFrame["instances"][0]["start"],
                    "end": keyFrame["instances"][0]["end"],
                }
                key_frame_object = {
                    "keyFrame": str(keyFrame["id"]),
                    "assets": assets,
                }

                tuples = ("keyFrames", key_frame_object)
                intervals = self.insert_items_to_intervals(
                    occurred_intervals, tuples, intervals
                )
        return intervals

    def parse_custom_model(self, custom_model_json, intervals, model_property):
        for item in custom_model_json:
            for prediction in item["imagePrediction"]["predictions"]:
                if prediction["probability"] != "" and prediction["probability"] > 0.5:
                    start = self.time_parser.string_time_to_milliseconds(
                        item["thumbnailMetadata"]["starttime"]
                    )
                    if "endtime" in item["thumbnailMetadata"]:
                        end = self.time_parser.string_time_to_milliseconds(
                            item["thumbnailMetadata"]["endtime"]
                        )
                    else:
                        end = self.time_parser.string_time_to_milliseconds(
                            item["thumbnailMetadata"]["starttime"]
                        )
                    occurred_intervals = self.time_parser.get_related_intervals(
                        start, end
                    )
                    assets = item["thumbnailMetadata"]
                    assets["probability"] = prediction["probability"]
                    custom_item_object = {
                        model_property["tagName"]: prediction["tagName"],
                        "assets": json.dumps(assets),
                    }
                    tuples = (model_property["tagGroup"], custom_item_object)
                    intervals = self.insert_items_to_intervals(
                        occurred_intervals, tuples, intervals
                    )
        return intervals
