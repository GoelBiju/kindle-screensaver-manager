#!/bin/bash
# build-ffmpeg-kindle.sh - With zlib for PNG

set -e

echo "Building ffmpeg for Kindle with PNG support..."
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

echo "=== Building zlib for ARM first ==="
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
echo "=== Building ffmpeg with zlib ==="
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
    --enable-zlib \
    --extra-cflags="-march=armv6 -mfloat-abi=soft -I/tmp/arm-deps/include" \
    --extra-ldflags="-static -L/tmp/arm-deps/lib" \
    --prefix=/tmp/ffmpeg-install

make -j$(nproc)
make install

echo ""
echo "=== Checking for PNG encoder ==="
/tmp/ffmpeg-install/bin/ffmpeg -encoders 2>&1 | grep " png " && echo "✓ PNG encoder found!" || echo "✗ PNG encoder MISSING!"

echo ""
echo "=== Stripping binary ==="
arm-linux-gnueabi-strip /tmp/ffmpeg-install/bin/ffmpeg

echo ""
echo "Size before UPX:"
ls -lh /tmp/ffmpeg-install/bin/ffmpeg
du -h /tmp/ffmpeg-install/bin/ffmpeg

echo ""
echo "=== Compressing with UPX ==="
upx --best --lzma /tmp/ffmpeg-install/bin/ffmpeg

echo ""
echo "Size after UPX:"
ls -lh /tmp/ffmpeg-install/bin/ffmpeg
du -h /tmp/ffmpeg-install/bin/ffmpeg

cp /tmp/ffmpeg-install/bin/ffmpeg /output/
'

if [ -f "kindle-binaries/ffmpeg" ]; then
    echo ""
    echo "✓ Build complete!"
    echo "Size: $(du -h kindle-binaries/ffmpeg | cut -f1)"
else
    echo "✗ Failed"
    exit 1
fi#!/bin/bash
# build-ffmpeg-kindle.sh - With zlib for PNG

set -e

echo "Building ffmpeg for Kindle with PNG support..."
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

echo "=== Building zlib for ARM first ==="
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
echo "=== Building ffmpeg with zlib ==="
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
    --enable-zlib \
    --extra-cflags="-march=armv6 -mfloat-abi=soft -I/tmp/arm-deps/include" \
    --extra-ldflags="-static -L/tmp/arm-deps/lib" \
    --prefix=/tmp/ffmpeg-install

make -j$(nproc)
make install

echo ""
echo "=== Checking for PNG encoder ==="
/tmp/ffmpeg-install/bin/ffmpeg -encoders 2>&1 | grep " png " && echo "PNG encoder found!" || echo "✗ PNG encoder MISSING!"

echo ""
echo "=== Stripping binary ==="
arm-linux-gnueabi-strip /tmp/ffmpeg-install/bin/ffmpeg

echo ""
echo "Size before UPX:"
ls -lh /tmp/ffmpeg-install/bin/ffmpeg
du -h /tmp/ffmpeg-install/bin/ffmpeg

echo ""
echo "=== Compressing with UPX ==="
upx --best --lzma /tmp/ffmpeg-install/bin/ffmpeg

echo ""
echo "Size after UPX:"
ls -lh /tmp/ffmpeg-install/bin/ffmpeg
du -h /tmp/ffmpeg-install/bin/ffmpeg

cp /tmp/ffmpeg-install/bin/ffmpeg /output/
'

if [ -f "kindle-binaries/ffmpeg" ]; then
    echo ""
    echo "Build complete!"
    echo "Size: $(du -h kindle-binaries/ffmpeg | cut -f1)"
else
    echo "Failed"
    exit 1
fi
