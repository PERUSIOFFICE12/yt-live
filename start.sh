#!/bin/bash

# Descarcă video-ul o singură dată
wget -O video.mp4 "https://archive.org/download/video_20250812_0903/video.mp4"

# Rulează live pe infinite loop
ffmpeg -re -stream_loop -1 -i video.mp4 \
  -vf scale=1920:1080 \
  -c:v libx264 -preset veryfast -maxrate 1500k -bufsize 3000k \
  -c:a aac -b:a 96k -ar 44100 \
  -f flv "rtmp://a.rtmp.youtube.com/live2/$YT_KEY"
