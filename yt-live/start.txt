#!/bin/bash
while true
do
  ffmpeg -re -stream_loop -1 -i video.mp4 \
    -c:v libx264 -preset veryfast -maxrate 3000k -bufsize 6000k \
    -c:a aac -b:a 128k -ar 44100 \
    -f flv "rtmp://a.rtmp.youtube.com/live2/$YT_KEY"
done
