#!/bin/bash

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Extract 16KB libraries and repackage AAR${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Create working directory
WORK_DIR="/Users/karol/Projects/ffmpeg-kit-full-gpl/repackage"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Step 1: Copy 16KB compiled libraries from output directory
echo -e "${BLUE}Step 1: Copying 16KB compiled libraries from output directory...${NC}"

# Create output directories
mkdir -p so_files/armeabi-v7a
mkdir -p so_files/arm64-v8a
mkdir -p so_files/x86
mkdir -p so_files/x86_64

# Copy .so files from output directory
echo "Copying arm-v7a libraries..."
cp -v /Users/karol/Projects/ffmpeg-kit-full-gpl/output/libs/armeabi-v7a/*.so so_files/armeabi-v7a/

echo "Copying arm64-v8a libraries..."
cp -v /Users/karol/Projects/ffmpeg-kit-full-gpl/output/libs/arm64-v8a/*.so so_files/arm64-v8a/

echo "Copying x86 libraries..."
cp -v /Users/karol/Projects/ffmpeg-kit-full-gpl/output/libs/x86/*.so so_files/x86/

echo "Copying x86_64 libraries..."
cp -v /Users/karol/Projects/ffmpeg-kit-full-gpl/output/libs/x86_64/*.so so_files/x86_64/

echo -e "${GREEN}✓ Copied compiled libraries${NC}"
ls -lh so_files/*/

# Step 2: Download official FFmpeg-Kit React Native full-gpl AAR (v6.0.0 from your GitHub)
echo ""
echo -e "${BLUE}Step 2: Downloading official FFmpeg-Kit React Native full-gpl AAR...${NC}"
AAR_URL="https://github.com/celeryhq/ffmpeg-kit-full-gpl/raw/refs/heads/main/ffmpeg-kit-full-gpl.aar"
curl -L "$AAR_URL" -o original.aar

echo -e "${GREEN}✓ Downloaded original AAR (React Native v6.0.0)${NC}"

# Step 3: Extract AAR
echo ""
echo -e "${BLUE}Step 3: Extracting AAR...${NC}"
mkdir -p aar_extracted
cd aar_extracted
unzip -q ../original.aar

echo -e "${GREEN}✓ Extracted AAR${NC}"

# Step 4: Replace .so files
echo ""
echo -e "${BLUE}Step 4: Replacing native libraries with 16KB versions...${NC}"

# Replace libraries for each architecture
for arch in armeabi-v7a arm64-v8a x86 x86_64; do
    if [ -d "jni/$arch" ] && [ -d "../so_files/$arch" ]; then
        echo "Replacing $arch libraries..."
        cp -v ../so_files/$arch/*.so jni/$arch/ 2>/dev/null || echo "No .so files found for $arch"
    fi
done

echo -e "${GREEN}✓ Replaced native libraries${NC}"

# Step 5: Repackage AAR
echo ""
echo -e "${BLUE}Step 5: Repackaging AAR with 16KB libraries...${NC}"
cd ..
rm -f ffmpeg-kit-full-gpl-16kb-rn.aar
cd aar_extracted
zip -r -q ../ffmpeg-kit-full-gpl-16kb-rn.aar *
cd ..

echo -e "${GREEN}✓ Repackaged AAR${NC}"

# Step 6: Move to output directory
mkdir -p /Users/karol/Projects/ffmpeg-kit-full-gpl/output
mv ffmpeg-kit-full-gpl-16kb-rn.aar /Users/karol/Projects/ffmpeg-kit-full-gpl/output/

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Success!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
ls -lh /Users/karol/Projects/ffmpeg-kit-full-gpl/output/ffmpeg-kit-full-gpl-16kb-rn.aar
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Test the AAR in your React Native app"
echo "2. Upload to GitHub if it works"
