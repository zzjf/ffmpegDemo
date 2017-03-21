#!/bin/sh

version=3.2

if [ ! -d "./FFmpeg-iOS-build-script" ]; then
  git clone https://github.com/kewlbear/FFmpeg-iOS-build-script
  cd ./FFmpeg-iOS-build-script
  ./build-ffmpeg.sh
  ./build-ffmpeg.sh lipo
  cd ffmpeg-${version}
  ./configure --disable-optimizations && make -j3
fi
