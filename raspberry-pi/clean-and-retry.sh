#!/bin/bash

# Clean and retry npm install script for Pi
# Handles ENOTEMPTY errors by completely clearing install directories

set -e

echo "🧹 Cleaning up npm directories and cache..."

# Remove node_modules completely
if [ -d "node_modules" ]; then
    echo "Removing node_modules directory..."
    rm -rf node_modules
fi

# Clear npm cache
echo "Clearing npm cache..."
npm cache clean --force

# Clear package-lock.json to avoid conflicts
if [ -f "package-lock.json" ]; then
    echo "Removing package-lock.json..."
    rm -f package-lock.json
fi

# Clear any temporary npm directories
rm -rf ~/.npm/_cacache
rm -rf ~/.npm/_logs

echo "✅ Cleanup complete. Starting fresh npm install..."

# Set npm config for Pi
npm config set maxsockets 1
npm config set fund false
npm config set audit false

# Set environment variables for Pi build
export ROLLUP_NO_NATIVE=1
export NODE_OPTIONS="--max-old-space-size=1024"

# Run npm install with verbose logging
echo "🔧 Installing packages..."
npm install --verbose --no-optional --legacy-peer-deps

echo "✅ Installation complete!"