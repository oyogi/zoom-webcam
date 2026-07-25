#!/bin/bash

v4l2-ctl -d /dev/video0 --set-ctrl=brightness=150

flatpak run io.mpv.Mpv av://v4l2:/dev/video0 \
    --demuxer-lavf-o=video_size=1280x720,framerate=30,input_format=mjpeg \
    --profile=low-latency \
    --untimed \
    --no-osc --no-osd-bar --no-input-default-bindings \
    --border=no \
    --vf=crop=400:400 \
    --video-aspect-override=no \
    --autofit=360x360 \
    --geometry=-20-20
