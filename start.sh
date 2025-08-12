#!/bin/bash

while true; do
  ffmpeg -re -stream_loop -1 -i "https://archive.org/download/video_20250812_0903/video.mp4" \
    -vf scale=1280:720 \
    -c:v libx264 -preset veryfast -maxrate 2000k -bufsize 4000k \
    -c:a aac -b:a 128k -ar 44100 \
    -f flv "rtmp://a.rtmp.youtube.com/live2/$YT_KEY"
done
