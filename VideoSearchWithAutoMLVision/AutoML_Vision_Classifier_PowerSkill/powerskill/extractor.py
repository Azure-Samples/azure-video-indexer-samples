import base64
import heapq
import io
import logging
import os
import string
from zipfile import ZipFile

import requests
from azureml.contrib.automl.dnn.vision.classification.inference.score import _score_with_model
from azureml.contrib.automl.dnn.vision.common.model_export_utils import run_inference
from dotenv import load_dotenv
from objdict import ObjDict

from powerskill.timer import timefunc

load_dotenv()


def set_log_level(debug):
    """
    :param debug: Boolean value
    :return: None
    """
    if bool(debug):
        logging.basicConfig(level=logging.DEBUG)


set_log_level(bool(os.environ['DEBUG']))


def get_base64_encoded_image(image_path):
    """
    Converts an image to base64
    :param image_path: the filename and path
    :return:
    """
    with open(image_path, "rb") as img_file:
        return base64.b64encode(img_file.read()).decode('utf-8')


def build_output_response(inputs, outputs, keyframes, error=None):
    """

    :param inputs: The inputs gathered from the extraction process
    :param outputs: The outputs object - power skill output
    :return: The json response object
    """
    values = ObjDict()
    values.values = []

    keyframe_dict = ObjDict()
    errors = ''
    keyframe_dict["keyFrameLabels"] = keyframes
    values.values.append({'recordId': inputs['values'][0]['recordId'], \
                          "errors": errors,
                          "data": keyframe_dict,
                          "warnings": ""})

    return values


def extract_label(result):
    """
    This function will extract the highest probability label from the inference
    :param result: The inference input
    :return: The highest probability label
    """
    # Get probs
    prob_labels = {}
    ind = result.find("probs")
    end_prob_ind = result[ind:].find("]")
    probs = result[ind + 8:ind + end_prob_ind + 1].replace("]", "").replace("[", "").split(",")
    probs = [float(i) for i in probs]
    # Get labels
    ind = result.find("labels")
    end_prob_ind = result[ind:].find("]")
    labels = result[ind + 8:ind + end_prob_ind + 1].replace("]", "").replace("[", "").split(",")
    for i, prob in enumerate(probs):
        prob_labels[prob] = labels[i].translate(str.maketrans('', '', string.punctuation))
    best_labels = heapq.nlargest(2, prob_labels)
    return [prob_labels[best_labels[0]].strip(), prob_labels[best_labels[1]].strip()]


@timefunc
def go_extract(inputs, classification_model, video_indexer):
    """
    :param args: inputs from web request
    :param classification_model: Our trained AzureML classification model
    :return:
    """

    try:
        outputs = {}
        output_response = {}
        label = 'Unknown'
        labels = {}
        keyframes = []

        logging.info(f"Inputs {inputs['values'][0]}")
        record_id = inputs['values'][0]['recordId']
        video_id = inputs['values'][0]['data']['keyFrames'][0]['videoId']
        keyframes = inputs['values'][0]['data']['keyFrames']
        logging.info(f"keyframe {keyframes}")

        # Get an access token for VI
        video_indexer.get_access_token()
        # Download the artifacts
        artifacts_url = video_indexer.get_video_artifacts(video_id)

        if artifacts_url.status_code != 200:
            raise(f"Could not download artifacts {artifacts_url.status_code} {artifacts_url.text}")

        # Extract the artifacts
        artifacts = requests.get(artifacts_url.text.replace('"', ''), stream=True)
        with ZipFile(io.BytesIO(artifacts.content)) as zip:
            zip.extractall('/usr/src/api/thumbnails/')

        for thumbnail in keyframes:

            # Let's go and predict the label for the keyframe
            encoded_image = get_base64_encoded_image(os.path.join('/usr/src/api/thumbnails/',
                                                                  thumbnail['keyframeThumbNail']))

            img = base64.b64decode(str(encoded_image).strip())
            result = str(run_inference(classification_model, img, _score_with_model))
            best_labels = extract_label(result)
            thumbnail["keyFrameThumbNailLabel"] = best_labels[0]

    except Exception as ProcessingError:
        logging.exception(ProcessingError)
        error = str(ProcessingError)
        output_response = build_output_response(inputs, outputs, keyframes)

    output_response = build_output_response(inputs, outputs, keyframes)
    logging.info(f"Output {output_response}")
    # cleanup

    for f in os.listdir('/usr/src/api/thumbnails/'):
        try:
            os.remove(os.path.join('/usr/src/api/thumbnails/', f))
        except Exception as TmpFileRemoved:
            continue
    return output_response
