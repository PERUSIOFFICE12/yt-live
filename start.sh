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

# Cheia de streaming YouTube Live din variabila de mediu
if [ -z "$YT_KEY" ]; then
    log_message "EROARE: Variabila de mediu YT_KEY nu este setată!"
    log_message "Rulează: export YT_KEY='cheia-ta-youtube'"
    exit 1
fi

STREAM_KEY="$YT_KEY"
log_message "Folosind cheia de streaming: ${STREAM_KEY:0:8}..."

# Verifică memoria disponibilă
AVAILABLE_MEM=$(free -m | awk 'NR==2{printf "%.1f", $7/1024}')
log_message "Memorie disponibilă: ${AVAILABLE_MEM}GB"

# Detectează informațiile video-ului
VIDEO_INFO=$(ffprobe -v quiet -print_format json -show_format -show_streams video.mp4)
log_message "Analizez video-ul pentru informații..."

# Loop infinit pentru restart automat - FĂRĂ TIMEOUT
RESTART_COUNT=0
MAX_RESTARTS=999999  # Practic infinit

while [ $RESTART_COUNT -lt $MAX_RESTARTS ]; do
    log_message "Încercare streaming #$((RESTART_COUNT + 1))"
    
    # Setări optimizate pentru 1920x1080p și streaming continuu
    ffmpeg -nostdin -hide_banner -loglevel info \
        -re -stream_loop -1 -i video.mp4 \
        -c:v libx264 \
        -preset veryfast \
        -tune zerolatency \
        -profile:v main \
        -level 4.0 \
        -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,fps=30" \
        -b:v 4500k \
        -maxrate 4500k \
        -minrate 4500k \
        -bufsize 9000k \
        -pix_fmt yuv420p \
        -g 60 \
        -keyint_min 60 \
        -sc_threshold 0 \
        -x264-params "nal-hrd=cbr:force-cfr=1:bframes=2:b-adapt=0:ref=1:subme=1:me_range=16:rc-lookahead=10:weightb=0:weightp=0:8x8dct=0:trellis=0" \
        -c:a aac \
        -b:a 160k \
        -ar 48000 \
        -ac 2 \
        -af "aresample=async=1:min_hard_comp=0.100000:first_pts=0" \
        -f flv \
        -flvflags no_duration_filesize+no_metadata \
        -rtmp_buffer 5000k \
        -rtmp_live live \
        -rtmp_pageurl "" \
        -rtmp_swfurl "" \
        -rtmp_tcurl "rtmp://a.rtmp.youtube.com/live2" \
        rtmp://a.rtmp.youtube.com/live2/$STREAM_KEY 2>&1 | tee -a "$LOG_FILE"
    
    EXIT_CODE=$?
    
    # Analizează codul de ieșire
    case $EXIT_CODE in
        0)
            log_message "Stream terminat neașteptat - restart în 5 secunde"
            ;;
        1)
            log_message "Eroare generală FFmpeg - restart în 10 secunde"
            sleep 10
            ;;
        130)
            log_message "Întrerupt de utilizator (Ctrl+C)"
            break
            ;;
        137)
            log_message "Proces oprit forțat (SIGKILL) - restart în 15 secunde"
            sleep 15
            ;;
        *)
            log_message "Eroare FFmpeg (cod: $EXIT_CODE) - restart în 10 secunde"
            sleep 10
            ;;
    esac
    
    RESTART_COUNT=$((RESTART_COUNT + 1))
    log_message "Restart automat #$RESTART_COUNT în 5 secunde..."
    sleep 5
    
    # Verifică conexiunea la internet înainte de restart
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        log_message "EROARE: Nu există conexiune la internet! Aștept 30 secunde..."
        sleep 30
        continue
    fi
    
    # Verifică dacă fișierul video mai există
    if [ ! -f video.mp4 ]; then
        log_message "EROARE: Fișierul video a dispărut! Încerc să-l descarc din nou..."
        if ! wget -O video.mp4 "https://archive.org/download/video_20250812_0903/video.mp4"; then
            log_message "EROARE: Nu s-a putut re-descărca video-ul!"
            sleep 30
            continue
        fi
    fi
done

log_message "Script terminat după $RESTART_COUNT restart-uri"
