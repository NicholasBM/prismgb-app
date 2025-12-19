#!/bin/bash

# Cross-compile ARM64 release package for Raspberry Pi
# Run this on your x64 development machine

set -e

echo "🏗️  Cross-compiling PrismGB for Raspberry Pi (ARM64)..."

# Clean previous builds
rm -rf dist/ node_modules/.cache/

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Set environment for ARM64 cross-compilation
export npm_config_target_arch=arm64
export npm_config_arch=arm64  
export npm_config_target_platform=linux
export npm_config_cache=/tmp/.npm-arm64
export ELECTRON_CACHE=/tmp/.electron-arm64

# Get Electron version and download ARM64 binaries
echo "⬇️  Preparing Electron ARM64 binaries..."
ELECTRON_VERSION=$(npx electron --version | sed 's/v//')
echo "Electron version: $ELECTRON_VERSION"

# Disable native compilation for cross-compile
export ROLLUP_NO_NATIVE=1
export ESBUILD_BINARY_PATH=""

# Build ARM64 package using existing script
echo "🔨 Building ARM64 package..."
npm run build:linux-arm

echo "✅ ARM64 cross-compilation complete!"
echo "📦 Package location: dist/"
ls -la dist/*.deb dist/*.AppImage 2>/dev/null || echo "Check dist/ folder for output files"

echo ""
echo "🚀 Next steps:"
echo "1. Upload the .deb file to GitHub releases"
echo "2. Users run: curl -sSL https://raw.githubusercontent.com/YourRepo/main/raspberry-pi/install-pi.sh | bash"