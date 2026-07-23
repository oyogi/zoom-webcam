#!/bin/bash

v4l2-ctl -d /dev/video1 --set-ctrl=brightness=150

gst-launch-1.0 \
    v4l2src device=/dev/video1 ! \
    image/jpeg,width=1280,height=720,framerate=30/1 ! \
    jpegdec ! \
    videocrop top=160 bottom=160 left=440 right=440 ! \
    videoscale ! \
    video/x-raw,width=720,height=720 ! \
    videoconvert ! \
    video/x-raw,format=YUY2 ! \
    queue ! \
    pipewiresink stream-properties="p,media.class=Video/Source,media.role=Camera,node.description=Zoom_Cam"
