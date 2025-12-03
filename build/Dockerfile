FROM --platform=linux/amd64 ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    git \
    curl \
    autoconf \
    automake \
    libtool \
    pkg-config \
    cmake \
    make \
    gcc \
    g++ \
    yasm \
    nasm \
    python3 \
    python3-pip \
    openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

# Set up Android SDK
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=${ANDROID_SDK_ROOT}
ENV PATH=${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools

# Download and install Android Command Line Tools
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    cd /opt && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip && \
    unzip -q commandlinetools-linux-11076708_latest.zip && \
    mv cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest && \
    rm commandlinetools-linux-11076708_latest.zip

# Accept licenses and install Android SDK components
RUN yes | sdkmanager --licenses && \
    sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# Install Android NDK r26d (supports 16KB page size)
RUN cd /opt && \
    wget https://dl.google.com/android/repository/android-ndk-r26d-linux.zip && \
    unzip android-ndk-r26d-linux.zip && \
    rm android-ndk-r26d-linux.zip

ENV ANDROID_NDK_ROOT=/opt/android-ndk-r26d
ENV PATH=${PATH}:${ANDROID_NDK_ROOT}:${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin

# Download FFmpeg-Kit React Native source
ARG FFMPEG_KIT_VERSION=react.native.v6.0.2
WORKDIR /build

RUN curl -L "https://github.com/arthenica/ffmpeg-kit/archive/refs/tags/${FFMPEG_KIT_VERSION}.tar.gz" -o ffmpeg-kit.tar.gz && \
    tar -xzf ffmpeg-kit.tar.gz && \
    rm ffmpeg-kit.tar.gz

# Find and enter the extracted directory
RUN cd /build && \
    EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "ffmpeg-kit-*" | head -n 1) && \
    if [ -z "$EXTRACTED_DIR" ]; then \
        echo "ERROR: Could not find extracted directory"; \
        exit 1; \
    fi && \
    echo "Found directory: $EXTRACTED_DIR" && \
    mv "$EXTRACTED_DIR"/* "$EXTRACTED_DIR"/.[!.]* . 2>/dev/null || true && \
    rm -rf "$EXTRACTED_DIR"

# Modify build scripts to add 16KB linker flag
RUN find /build -name "*.sh" -type f -exec sed -i 's/-Wl,-z,max-page-size=16384/-Wl,-z,max-page-size=0x4000/g' {} \; && \
    find /build -name "*.sh" -type f -exec grep -l "LDFLAGS" {} \; | xargs -I {} sed -i 's/LDFLAGS="/LDFLAGS="-Wl,-z,max-page-size=0x4000 /g' {} || true

# Initialize git repository (required by build script)
RUN cd /build && git init && git config user.email "build@ffmpeg-kit.local" && git config user.name "FFmpeg-Kit Builder"

WORKDIR /build

# Build script - compile FFmpeg with 16KB support and copy libraries
CMD git add . && git commit -m "Initial commit" || true && \
    echo "========== Starting FFmpeg-Kit build with GPL and 16KB support ==========" && \
    ./android.sh \
    --enable-gpl \
    --enable-x264 \
    --enable-x265 \
    --api-level=24 2>&1 | tee /tmp/build.log; \
    BUILD_EXIT=$?; \
    echo "Build exited with code: $BUILD_EXIT" && \
    echo "========== Copying compiled 16KB libraries to /output =========="; \
    mkdir -p /output/libs/armeabi-v7a /output/libs/arm64-v8a /output/libs/x86 /output/libs/x86_64 && \
    cp /build/prebuilt/android-arm/ffmpeg/lib/*.so /output/libs/armeabi-v7a/ 2>/dev/null && echo "Copied arm-v7a libs" || echo "No arm-v7a libs found" && \
    cp /build/prebuilt/android-arm64/ffmpeg/lib/*.so /output/libs/arm64-v8a/ 2>/dev/null && echo "Copied arm64-v8a libs" || echo "No arm64-v8a libs found" && \
    cp /build/prebuilt/android-x86/ffmpeg/lib/*.so /output/libs/x86/ 2>/dev/null && echo "Copied x86 libs" || echo "No x86 libs found" && \
    cp /build/prebuilt/android-x86_64/ffmpeg/lib/*.so /output/libs/x86_64/ 2>/dev/null && echo "Copied x86_64 libs" || echo "No x86_64 libs found" && \
    echo "========== Library summary ==========" && \
    find /output/libs -name "*.so" -exec ls -lh {} \; && \
    echo "========== Attempting AAR fix and packaging ==========" && \
    cd /build/android && \
    export APP_ALLOW_MISSING_DEPS=true && \
    /opt/android-ndk-r26d/ndk-build APP_ALLOW_MISSING_DEPS=true 2>&1 | tee /tmp/aar-build.log || echo "AAR build failed, but libraries are saved" && \
    find /build -name "*.aar" -exec cp {} /output/ffmpeg-kit-full-gpl-16kb-rn.aar \; 2>/dev/null && \
    if [ -f /output/ffmpeg-kit-full-gpl-16kb-rn.aar ]; then \
        echo "========== SUCCESS: AAR created! =========="; \
        ls -lh /output/ffmpeg-kit-full-gpl-16kb-rn.aar; \
    else \
        echo "========== AAR not created, but libraries saved in /output/libs/ =========="; \
    fi
