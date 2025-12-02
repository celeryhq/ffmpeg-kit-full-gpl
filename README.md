# FFmpeg-Kit with 16KB Page Size Support

Pre-built FFmpeg-Kit AAR for Android with 16KB page size support.

## Quick Build (Docker)

```bash
./build.sh
```

That's it! The AAR will be in `output/ffmpeg-kit-full-gpl.aar` after 45-60 minutes.

## Requirements

- Docker Desktop running
- ~10GB free disk space
- 45-60 minutes build time

## What It Does

1. Downloads Android NDK r26d (16KB support)
2. Clones FFmpeg-Kit source code
3. Applies 16KB page size patches (`-Wl,-z,max-page-size=0x4000`)
4. Builds full-gpl AAR with all codecs
5. Verifies 16KB alignment
6. Outputs to `output/ffmpeg-kit-full-gpl.aar`

## Custom Version

Build a different FFmpeg-Kit version:

```bash
./build.sh v6.0.LTS
```

Available versions:
- `react.native.v6.0.2` (default, recommended for React Native/Expo)
- `v6.0.LTS`
- `v6.0`