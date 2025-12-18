# Building PrismGB for ARM (Raspberry Pi)

## Cross-compilation Limitation

PrismGB uses native Node.js modules (like `usb-detection`) that cannot be cross-compiled from macOS/Windows to ARM Linux. You have two options:

## Option 1: Build on ARM Hardware (Recommended)

Build directly on a Raspberry Pi or ARM Linux system:

```bash
# On Raspberry Pi or ARM Linux system
git clone https://github.com/josstei/prismgb-app.git
cd prismgb-app
npm install
npm run build:linux
```

This will create ARM-native builds in the `release/` directory.

## Option 2: Use Pre-built Electron Binaries

Modify the build to skip native module rebuilding (less reliable):

```bash
# Add to package.json build config
"electronRebuild": false
```

## Option 3: Docker Cross-compilation

Use Docker with ARM emulation:

```bash
# Build ARM64 version using Docker
docker run --platform=linux/arm64 -v $(pwd):/workspace -w /workspace node:22 bash -c "
  npm install && 
  npm run build:linux
"

# Build ARM32 version using Docker  
docker run --platform=linux/arm/v7 -v $(pwd):/workspace -w /workspace node:22 bash -c "
  npm install && 
  npm run build:linux
"
```

## Recommended Approach

For now, I recommend:

1. **Use the existing x64 Linux build** on Raspberry Pi 4/5 (they can run x64 via emulation)
2. **Build natively on Pi** if you need true ARM performance
3. **Use the kiosk setup scripts** regardless of architecture

The kiosk setup will work with any Linux build of PrismGB.