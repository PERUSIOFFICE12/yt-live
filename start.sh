#!/bin/bash

# Dacă fișierul nu există, îl descarcă
if [ ! -f video.mp4 ]; then
    wget -O video.mp4 "https://archive.org/download/video_20250812_0903/video.mp4"
fi

# Rulează live pe loop infinit
ffmpeg -nostdin -re -stream_loop -1 -i video.mp4 \
-c:v libx264 -preset veryfast -maxrate 3000k -bufsize 6000k -pix_fmt yuv420p \
-c:a aac -b:a 128k -ar 44100 \
-f flv rtmp://a.rtmp.youtube.com/live2/b1u3-2mbf-3532-8u2u-5yfe
