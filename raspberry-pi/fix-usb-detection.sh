#!/bin/bash

# Fix usb-detection compilation for ARM64
set -e

echo "🔧 Fixing usb-detection for ARM64..."

# Remove existing build artifacts
rm -rf node_modules/usb-detection/build

# Set correct environment variables for ARM64
export CC=gcc
export CXX=g++
export AR=ar
export STRIP=strip
export npm_config_target_arch=arm64
export npm_config_arch=arm64
export npm_config_target_platform=linux
export npm_config_build_from_source=true

# Create a custom binding.gyp that removes -m64 flag
cd node_modules/usb-detection

# Backup original
cp binding.gyp binding.gyp.bak

# Create ARM64-compatible binding.gyp
cat > binding.gyp << 'EOF'
{
  "targets": [
    {
      "target_name": "detection",
      "sources": [ "src/detection.cpp" ],
      "include_dirs": [
        "<!(node -e \"require('nan')\")"
      ],
      "conditions": [
        ["OS=='linux'", {
          "libraries": ["-ludev"],
          "cflags": ["-fPIC"],
          "cflags_cc": ["-fPIC"]
        }],
        ["OS=='mac'", {
          "link_settings": {
            "libraries": [
              "-framework IOKit",
              "-framework CoreFoundation"
            ]
          }
        }]
      ]
    }
  ]
}
EOF

echo "✅ Fixed binding.gyp for ARM64"

# Rebuild the module
echo "🔨 Rebuilding usb-detection..."
npx node-gyp rebuild --arch=arm64

echo "✅ usb-detection rebuilt successfully!"
cd ../..