#!/bin/bash
# build-ffmpeg-kindle.sh - Minimal with proper JPEG support

set -e

echo "Building MINIMAL ffmpeg for Kindle..."
rm -rf kindle-binaries
mkdir -p kindle-binaries

docker run --rm -v "$(pwd)/kindle-binaries:/output" debian:bullseye bash -c '
set -e

apt-get update -qq
apt-get install -y -qq \
    build-essential \
    gcc-arm-linux-gnueabi \
    g++-arm-linux-gnueabi \
    wget \
    xz-utils \
    yasm \
    pkg-config \
    upx-ucl

echo "=== Building zlib for ARM ==="
cd /tmp
wget -q https://zlib.net/fossils/zlib-1.3.tar.gz
tar xf zlib-1.3.tar.gz
cd zlib-1.3

CC=arm-linux-gnueabi-gcc \
AR=arm-linux-gnueabi-ar \
RANLIB=arm-linux-gnueabi-ranlib \
./configure --prefix=/tmp/arm-deps --static

make -j$(nproc)
make install

echo ""
echo "=== Building MINIMAL ffmpeg ==="
cd /tmp
wget -q https://ffmpeg.org/releases/ffmpeg-6.1.tar.xz
tar xf ffmpeg-6.1.tar.xz
cd ffmpeg-6.1

PKG_CONFIG_PATH=/tmp/arm-deps/lib/pkgconfig \
./configure \
    --enable-cross-compile \
    --cross-prefix=arm-linux-gnueabi- \
    --arch=arm \
    --target-os=linux \
    --enable-static \
    --disable-shared \
    --disable-debug \
    --disable-runtime-cpudetect \
    --enable-zlib \
    --disable-doc \
    --disable-htmlpages \
    --disable-manpages \
    --disable-podpages \
    --disable-txtpages \
    --disable-network \
    --disable-protocols \
    --enable-protocol=file \
    --disable-devices \
    --disable-indevs \
    --disable-outdevs \
    --disable-avdevice \
    --disable-postproc \
    --disable-swresample \
    --disable-avfilter \
    --enable-filter=scale,crop,format \
    --disable-bsfs \
    --disable-encoders \
    --enable-encoder=png \
    --disable-decoders \
    --enable-decoder=png,mjpeg,jpeg2000,bmp,gif \
    --disable-hwaccels \
    --disable-muxers \
    --enable-muxer=image2 \
    --disable-demuxers \
    --enable-demuxer=image2 \
    --disable-parsers \
    --enable-parser=png,mjpeg,bmp \
    --disable-ffplay \
    --disable-ffprobe \
    --enable-small \
    --extra-cflags="-march=armv6 -mfloat-abi=soft -Os -I/tmp/arm-deps/include" \
    --extra-ldflags="-static -L/tmp/arm-deps/lib" \
    --prefix=/tmp/ffmpeg-install

make -j$(nproc)
make install

echo ""
echo "=== Verifying decoders ==="
echo "PNG:" && /tmp/ffmpeg-install/bin/ffmpeg -decoders 2>&1 | grep " png " || echo "Missing!"
echo "MJPEG:" && /tmp/ffmpeg-install/bin/ffmpeg -decoders 2>&1 | grep " mjpeg " || echo "Missing!"
echo "JPEG2000:" && /tmp/ffmpeg-install/bin/ffmpeg -decoders 2>&1 | grep " jpeg2000 " || echo "Missing!"

echo ""
echo "=== Verifying PNG encoder ==="
/tmp/ffmpeg-install/bin/ffmpeg -encoders 2>&1 | grep " png "

echo ""
echo "=== Stripping ==="
arm-linux-gnueabi-strip --strip-all /tmp/ffmpeg-install/bin/ffmpeg

echo ""
echo "Before UPX: $(du -h /tmp/ffmpeg-install/bin/ffmpeg | cut -f1)"

echo ""
echo "=== Compressing with UPX ==="
upx --best --lzma /tmp/ffmpeg-install/bin/ffmpeg

echo ""
echo "After UPX: $(du -h /tmp/ffmpeg-install/bin/ffmpeg | cut -f1)"

cp /tmp/ffmpeg-install/bin/ffmpeg /output/
'

if [ -f "kindle-binaries/ffmpeg" ]; then
    echo ""
    echo "✓ Build complete!"
    echo "Final size: $(du -h kindle-binaries/ffmpeg | cut -f1)"
else
    echo "✗ Failed"
    exit 1
fi