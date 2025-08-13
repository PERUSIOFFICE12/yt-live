#!/bin/bash

# Setări pentru debugging și restart automat
set -e  # Oprește scriptul la prima eroare
LOG_FILE="streaming.log"

# Funcție pentru logging
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Funcție pentru curățare la exit
cleanup() {
    log_message "Curățare procese..."
    pkill -f ffmpeg || true
}
trap cleanup EXIT

# Verifică dacă FFmpeg este instalat
if ! command -v ffmpeg &> /dev/null; then
    log_message "EROARE: FFmpeg nu este instalat!"
    exit 1
fi

# Descarcă video-ul dacă nu există
if [ ! -f video.mp4 ]; then
    log_message "Descărcare video..."
    if ! wget -O video.mp4 "https://archive.org/download/video_20250812_0903/video.mp4"; then
        log_message "EROARE: Nu s-a putut descărca video-ul!"
        exit 1
    fi
fi

# Verifică dimensiunea fișierului
if [ ! -s video.mp4 ]; then
    log_message "EROARE: Fișierul video este gol!"
    exit 1
fi

# Cheia ta de streaming YouTube Live
STREAM_KEY="b1u3-2mbf-3532-8u2u-5yfe"
log_message "Folosind cheia de streaming: ${STREAM_KEY:0:8}..."

# Verifică memoria disponibilă
AVAILABLE_MEM=$(free -m | awk 'NR==2{printf "%.1f", $7/1024}')
log_message "Memorie disponibilă: ${AVAILABLE_MEM}GB"

# Loop pentru restart automat
RESTART_COUNT=0
MAX_RESTARTS=5

while [ $RESTART_COUNT -lt $MAX_RESTARTS ]; do
    log_message "Încercare streaming #$((RESTART_COUNT + 1))"
    
    # Streaming cu setări optimizate
    timeout 3600 ffmpeg -nostdin -re -stream_loop -1 -i video.mp4 \
        -c:v libx264 \
        -preset ultrafast \
        -tune zerolatency \
        -maxrate 2500k \
        -bufsize 5000k \
        -pix_fmt yuv420p \
        -g 60 \
        -keyint_min 60 \
        -x264-params "nal-hrd=cbr" \
        -c:a aac \
        -b:a 128k \
        -ar 44100 \
        -ac 2 \
        -f flv \
        -flvflags no_duration_filesize \
        rtmp://a.rtmp.youtube.com/live2/$STREAM_KEY 2>&1 | tee -a "$LOG_FILE"
    
    EXIT_CODE=$?
    
    case $EXIT_CODE in
        0)
            log_message "Stream terminat cu succes"
            break
            ;;
        124)
            log_message "Timeout după 1 oră - restart normal"
            ;;
        137)
            log_message "Proces oprit forțat (SIGKILL) - posibil lipsă memorie"
            ;;
        *)
            log_message "Eroare FFmpeg (cod: $EXIT_CODE)"
            ;;
    esac
    
    RESTART_COUNT=$((RESTART_COUNT + 1))
    
    if [ $RESTART_COUNT -lt $MAX_RESTARTS ]; then
        log_message "Așteptare 10 secunde înainte de restart..."
        sleep 10
    fi
done

if [ $RESTART_COUNT -eq $MAX_RESTARTS ]; then
    log_message "EROARE: Prea multe restarturi eșuate!"
    exit 1
fi

log_message "Script terminat"
