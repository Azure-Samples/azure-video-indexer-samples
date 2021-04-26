import logging
import os

from dotenv import load_dotenv
from objdict import ObjDict
import json
import requests
from impl.timer import timefunc
from impl.parser import Parser

load_dotenv()


def set_log_level(debug):
    """
    :param debug: Boolean value
    :return: None
    """
    if bool(debug):
        logging.basicConfig(level=logging.DEBUG)


set_log_level(bool(os.environ['DEBUG']))


def build_parse_output_response(inputs, outputs, errors=None):
    """

    :param inputs: The inputs gathered from the extraction process
    :param outputs: The outputs object - power skill output
    :return: The json response object
    """
    values = ObjDict()
    values.values = []

    for input, output, error in zip(inputs['values'], outputs['data'], errors):
        values.values.append({'recordId': input['recordId'],
                            "errors": error,
                            "data": output,
                            })

    return values


@timefunc
def parse(inputs):
    """
    Read the video indexer insights file.
    Split into intervals
    Augment with classifications from an external service
    :param args:
    :return:
    """
    outputs = {'data': []}
    errors = []
    try:
        parser = Parser()
        values = inputs['values']
        for insight_file_data in values:
            video_insights_json = insight_file_data['data']

            # convert insight to searchable docs
            acs_json = parser.parse_vi_json(video_insights_json)

            # convert to a scene list from dictionary keyed on scene id
            scenes = list(acs_json.values())

            outputs['data'].append({
                "scenes": scenes
            })
            errors.append('')

    except Exception as ProcessingError:
        logging.exception(ProcessingError)
        errors.append(str(ProcessingError))

    output_response = build_parse_output_response(inputs, outputs, errors)

    logging.debug(output_response)

    return output_response
