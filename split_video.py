
import os
import sys
from moviepy.video.io.ffmpeg_tools import ffmpeg_extract_subclip
from moviepy.editor import VideoFileClip

filename = "/Users/karin.brisker/kinderguard/resources/responsible_ai.mp4"

clip = VideoFileClip(filename)
duration = clip.duration

start_time = 0
end_time = 3

# Extract the filename without extension
basename = os.path.basename(filename).split('.')[0]

# Extract directory path
dir_path = os.path.dirname(filename)
ffmpeg_extract_subclip(filename, start_time, min(end_time, duration), targetname=f"{dir_path}/{basename}_partial.mp4")
