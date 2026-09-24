#!/bin/bash
docker rm -f ffmpeg-camera 2>/dev/null
docker run --rm -d --name ffmpeg-camera --device /dev/video0 --network host jrottenberg/ffmpeg \
    -f v4l2 -i /dev/video0 -c:v libx264 -preset ultrafast -tune zerolatency -b:v 500k \
    -f tee -map 0:v "[f=rtsp:rtsp_transport=tcp]rtsp://localhost:8554/ngo_1|[f=rtsp:rtsp_transport=tcp]rtsp://localhost:8554/ngo_2|[f=rtsp:rtsp_transport=tcp]rtsp://localhost:8554/ngo_3"
