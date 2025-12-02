FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV ANDROID_NDK_VERSION=r26d
ENV ANDROID_NDK_ROOT=/opt/android-ndk

# Install dependencies
RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    libtool \
    pkg-config \
    curl \
    git \
    cmake \
    gcc \
    g++ \
    gperf \
    texinfo \
    yasm \
    nasm \
    bison \
    autogen \
    patch \
    make \
    wget \
    unzip \
    python3 \
    openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

# Download and install Android NDK r26d (supports 16KB page size)
RUN cd /opt && \
    wget -q https://dl.google.com/android/repository/android-ndk-${ANDROID_NDK_VERSION}-linux.zip && \
    unzip -q android-ndk-${ANDROID_NDK_VERSION}-linux.zip && \
    mv android-ndk-${ANDROID_NDK_VERSION} android-ndk && \
    rm android-ndk-${ANDROID_NDK_VERSION}-linux.zip

ENV PATH="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin:${PATH}"

WORKDIR /build

# Clone FFmpeg-Kit
ARG FFMPEG_KIT_VERSION=react.native.v6.0.2
RUN git clone --depth 1 --branch ${FFMPEG_KIT_VERSION} https://github.com/arthenica/ffmpeg-kit.git

WORKDIR /build/ffmpeg-kit

# Apply 16KB page size patches
RUN echo '#!/bin/bash\n\
echo "Applying 16KB page size patches..."\n\
\n\
# Patch build-ffmpeg script for arm64-v8a\n\
if [ -f "scripts/android/build-ffmpeg.sh" ]; then\n\
  sed -i "s/LDFLAGS=\"/LDFLAGS=\"-Wl,-z,max-page-size=0x4000 /g" scripts/android/build-ffmpeg.sh\n\
  echo "Patched build-ffmpeg.sh"\n\
fi\n\
\n\
# Patch build scripts in android directory\n\
find scripts/android -name "*.sh" -type f -exec sed -i "s/LDFLAGS=\"/LDFLAGS=\"-Wl,-z,max-page-size=0x4000 /g" {} \\;\n\
\n\
# Patch Android.mk files\n\
find . -name "Android.mk" -type f -exec sed -i "s/LOCAL_LDFLAGS :=/LOCAL_LDFLAGS := -Wl,-z,max-page-size=0x4000 /g" {} \\;\n\
\n\
echo "16KB page size patches applied successfully"\n\
' > apply-16kb-patch.sh && chmod +x apply-16kb-patch.sh

RUN ./apply-16kb-patch.sh

# Set environment for 16KB page size
ENV LDFLAGS="-Wl,-z,max-page-size=0x4000"

# Build script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "================================="\n\
echo "Building FFmpeg-Kit with 16KB page size support"\n\
echo "FFmpeg-Kit Version: ${FFMPEG_KIT_VERSION}"\n\
echo "Android NDK: ${ANDROID_NDK_VERSION}"\n\
echo "================================="\n\
\n\
export ANDROID_NDK_ROOT=/opt/android-ndk\n\
export LDFLAGS="-Wl,-z,max-page-size=0x4000"\n\
\n\
echo "Starting build..."\n\
./android.sh --full-gpl --api-level=24\n\
\n\
echo "Build completed!"\n\
\n\
# Find the AAR file\n\
AAR_FILE=$(find . -name "ffmpeg-kit-full-gpl*.aar" -type f | head -n 1)\n\
\n\
if [ -z "$AAR_FILE" ]; then\n\
  echo "ERROR: AAR file not found!"\n\
  exit 1\n\
fi\n\
\n\
echo "Found AAR: $AAR_FILE"\n\
ls -lh "$AAR_FILE"\n\
\n\
# Copy to output directory\n\
mkdir -p /output\n\
cp "$AAR_FILE" /output/ffmpeg-kit-full-gpl.aar\n\
\n\
echo "================================="\n\
echo "Verifying 16KB alignment..."\n\
echo "================================="\n\
\n\
# Verify 16KB alignment\n\
cd /output\n\
mkdir -p verify\n\
cd verify\n\
unzip -q ../ffmpeg-kit-full-gpl.aar\n\
\n\
echo "Checking arm64-v8a libraries:"\n\
for so_file in jni/arm64-v8a/*.so; do\n\
  if [ -f "$so_file" ]; then\n\
    echo "  $(basename $so_file)"\n\
    readelf -l "$so_file" | grep -A 2 "LOAD" | grep "Align" || true\n\
  fi\n\
done\n\
\n\
cd /output\n\
rm -rf verify\n\
\n\
echo "================================="\n\
echo "✅ Build complete!"\n\
echo "AAR file: /output/ffmpeg-kit-full-gpl.aar"\n\
echo "================================="\n\
' > /build-and-verify.sh && chmod +x /build-and-verify.sh

CMD ["/build-and-verify.sh"]
