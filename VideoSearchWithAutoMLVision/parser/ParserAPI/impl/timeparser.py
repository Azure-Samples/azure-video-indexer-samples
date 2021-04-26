import time
from os.path import isfile
from os import getenv

from datetime import datetime
import re


class TimeParser:
    def __init__(self):
        """
        This is a constructor for the Time parser.
        It initiates a TimeParser with desired intervals
        e.g. interval_in__milliseconds=10000 creates intervals of 10 seconds in that video
        """

        interval = getenv("MILLISECONDS_INTERVAL")

        if interval is not None and interval != "":
            self.interval_in_milliseconds = int(
                getenv("MILLISECONDS_INTERVAL")
            )
        else:
            # Set default
            self.interval_in_milliseconds = 10000

    def get_related_intervals(self, start, end):
        # TODO: use binary search
        """
        This method returns a list of intervals based on start  and end time passed
        e.g.
        start:00:00:00
        end: 00:00:35
        returns [0000,01000,02000,03000] which represents  moments of:
        0 to 10 seconds
        10 to 20 seconds
        20 to 30 seconds
        30 to 40 seconds
        :param start: start time in milliseconds
        :param end: end time in milliseconds
        :return: list of intervals based on start  and end time passed
        """
        intervals = []
        if (
            end - start < self.interval_in_milliseconds
        ):  # CASE: when appearance is within time interval
            intervals.append(int(start) - int(start) % self.interval_in_milliseconds)
        for i in range(int(start), int(end)):
            if i % self.interval_in_milliseconds == 0:
                intervals.append(i)
        return intervals

    @staticmethod
    def string_time_to_milliseconds(string_time):
        """
        This method converts string time to milliseconds
        it uses regex to handle both of the following  cases formats:
        - %H:%M:%S
        - %H:%M:%S.%f
        :param string_time:
        :return: passed time converted to milliseconds
        """

        string_time = string_time.split(".")[0]

        if "." in string_time:
            date_time = datetime.strptime(string_time, "%H:%M:%S.%f")
        else:
            date_time = datetime.strptime(string_time, "%H:%M:%S")

        time_delta = date_time - datetime(1900, 1, 1)
        return time_delta.total_seconds() * 1000  # milliseconds

    @staticmethod
    def seconds_to_time_string(seconds):
        """
        This method converts seconds to %H:%M:%S format
        :param seconds:
        :return:
        """

        return str(time.strftime("%H:%M:%S", time.gmtime(seconds)))
