#!/bin/bash

# PrismGB Installer - Redirects to Pi 4 version
# Pi 4 is now the recommended platform for better performance

echo "🎮 PrismGB Installer"
echo ""
echo "📋 Raspberry Pi 4 is now the recommended platform for:"
echo "   ✅ Better streaming performance"
echo "   ✅ More reliable USB support" 
echo "   ✅ Faster Electron rendering"
echo "   ✅ Better Chromatic compatibility"
echo ""

# Check Pi model
PI_MODEL=$(cat /proc/cpuinfo | grep "Model" | head -1)
echo "🔍 Detected: $PI_MODEL"
echo ""

if echo "$PI_MODEL" | grep -q "Raspberry Pi 4"; then
    echo "✅ Pi 4 detected! Using optimized Pi 4 installer..."
    echo ""
    curl -fsSL https://raw.githubusercontent.com/NicholasBM/prismgb-pi/main/raspberry-pi/install-pi4.sh | bash
elif echo "$PI_MODEL" | grep -q "Raspberry Pi Zero 2"; then
    echo "⚠️  Pi Zero 2 W detected. Pi 4 is recommended for better performance."
    echo ""
    read -p "Continue with Pi Zero 2 installer? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📦 Using Pi Zero 2 installer (limited features)..."
        # Keep the existing Pi Zero installer code here
        curl -fsSL https://raw.githubusercontent.com/NicholasBM/prismgb-pi/main/raspberry-pi/install-pi-zero.sh | bash
    else
        echo "❌ Installation cancelled. Consider upgrading to Pi 4 for best experience."
        exit 1
    fi
else
    echo "⚠️  Unknown Pi model. Pi 4 is strongly recommended."
    echo ""
    read -p "Try Pi 4 installer anyway? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        curl -fsSL https://raw.githubusercontent.com/NicholasBM/prismgb-pi/main/raspberry-pi/install-pi4.sh | bash
    else
        echo "❌ Installation cancelled."
        exit 1
    fi
fi