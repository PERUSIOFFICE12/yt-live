#!/bin/bash

ffmpeg -re -stream_loop -1 -i "https://archive.org/download/video_20250812_0903/video.mp4" \
-vf scale=1280:720 \
-r 30 \
-c:v libx264 -preset veryfast -b:v 1500k -maxrate 1500k -bufsize 3000k \
-c:a aac -b:a 128k -ar 44100 \
-f flv "rtmp://a.rtmp.youtube.com/live2/$YT_KEY"
