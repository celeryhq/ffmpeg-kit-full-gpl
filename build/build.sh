#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}FFmpeg-Kit React Native 16KB Build${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Configuration
IMAGE_NAME="ffmpeg-kit-rn-16kb-builder"
FFMPEG_VERSION="${1:-react.native.v6.0.2}"

echo -e "${YELLOW}Configuration:${NC}"
echo "  FFmpeg-Kit Version: ${FFMPEG_VERSION}"
echo "  Docker Image: ${IMAGE_NAME}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  echo -e "${RED}ERROR: Docker is not running!${NC}"
  echo "Please start Docker Desktop and try again."
  exit 1
fi

echo -e "${GREEN}✓ Docker is running${NC}"
echo ""

# Build Docker image
echo -e "${BLUE}Step 1: Building Docker image...${NC}"
echo "This will take a few minutes (one-time setup)"
docker build \
  --build-arg FFMPEG_KIT_VERSION=${FFMPEG_VERSION} \
  -t ${IMAGE_NAME}:${FFMPEG_VERSION} \
  -t ${IMAGE_NAME}:latest \
  .

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ Docker image built successfully${NC}"
else
  echo -e "${RED}ERROR: Failed to build Docker image${NC}"
  exit 1
fi
echo ""

# Run the build
echo -e "${BLUE}Step 2: Building FFmpeg-Kit React Native with 16KB support...${NC}"
echo "This will take 45-60 minutes."
echo ""

# Create output directory
mkdir -p output

# Run the build container
docker run \
  --rm \
  -v "$(pwd)/output:/output" \
  ${IMAGE_NAME}:${FFMPEG_VERSION}

if [ $? -eq 0 ]; then
  echo ""
  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN}✅ Build completed successfully!${NC}"
  echo -e "${GREEN}========================================${NC}"
  echo ""
  echo -e "${YELLOW}Output:${NC}"
  ls -lh output/ffmpeg-kit-full-gpl-16kb-rn.aar
  echo ""
  echo -e "${YELLOW}Next steps:${NC}"
  echo "1. Test the AAR in your React Native app"
  echo "2. Upload to GitHub if it works correctly"
  echo ""
else
  echo -e "${RED}ERROR: Build failed${NC}"
  exit 1
fi
