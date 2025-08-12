FROM alpine:latest

RUN apk add --no-cache ffmpeg bash

WORKDIR /app

COPY . .

CMD ["bash", "start.sh"]
