ffmpeg -re -i "https://archive.org/download/video_20250812_0903/video.mp4" \
  -vf "loop=loop=-1:size=FRAME_COUNT:start=0,scale=1280:720,fps=30" \
  -c:v libx264 -preset veryfast -maxrate 1500k -bufsize 3000k \
  -c:a aac -b:a 96k -ar 44100 \
  -f flv "rtmp://a.rtmp.youtube.com/live2/$YT_KEY"
