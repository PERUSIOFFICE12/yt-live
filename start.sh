#!/bin/bash

# Dacă fișierul nu există, îl descarcă
if [ ! -f video.mp4 ]; then
    wget -O video.mp4 "https://archive.org/download/video_20250812_0903/video.mp4"
fi

# Rulează live pe loop infinit
ffmpeg -re -stream_loop -1 -i video.mp4 \
  -vf scale=1920:1080 \
  -c:v libx264 -preset veryfast -maxrate 3000k -bufsize 6000k \
  -c:a aac -b:a 128k -ar 44100 \
  -f flv "rtmp://a.rtmp.youtube.com/live2/$YT_KEY"
