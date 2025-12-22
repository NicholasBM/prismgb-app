# PrismGB Raspberry Pi

**One-command installer for Raspberry Pi 4** - Stream Game Boy games with auto-fullscreen and auto-click!

## 🚀 Quick Install (Pi 4 Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/NicholasBM/prismgb-pi/main/raspberry-pi/install-pi.sh | bash
```

**What this does:**
- ✅ **Auto-detects Pi model** and uses optimized installer
- ✅ **Pi 4**: Full features with auto-click and auto-fullscreen
- ✅ **Pi Zero 2**: Basic kiosk mode (limited features)
- ✅ **Auto-boots to PrismGB** on TV/monitor
- ✅ **Plug-and-play** with ModRetro Chromatic

## 🎮 Supported Devices

### Primary Target: **Raspberry Pi 4**
- **Full auto-click and auto-fullscreen** when Chromatic connected
- **Better streaming performance** for capture/streaming
- **Reliable USB support** for multiple devices
- **1080p forced output** for optimal display

### Legacy Support: **Pi Zero 2 W**
- Basic kiosk mode only
- No auto-click/auto-fullscreen features
- Limited performance for streaming

## 🔧 Manual Pi 4 Install

If you want the Pi 4 installer specifically:

```bash
curl -fsSL https://raw.githubusercontent.com/NicholasBM/prismgb-pi/main/raspberry-pi/install-pi4.sh | bash
```

## Hardware Requirements

### For Pi 4 (Recommended)
- **Raspberry Pi 4** (4GB+ RAM recommended)
- **MicroSD card** (32GB+ recommended, Class 10 or better)
- **HDMI display** (1080p recommended)
- **USB-C power supply** (5V 3A minimum)
- **USB-A cable** for ModRetro Chromatic

### For Pi Zero 2 W (Legacy)
- **Raspberry Pi Zero 2 W** (1GB RAM)
- **MicroSD card** (16GB+ recommended)
- **Micro HDMI to HDMI cable**
- **USB-C to USB-A adapter** (must support data transfer)

## What You Get

After installation and reboot:
- **Auto-boots to PrismGB** fullscreen on your TV/monitor
- **Plug in Chromatic** → Automatically connects and goes fullscreen
- **Ready for streaming** with OBS or other capture software
- **Optimized performance** with 1080p output

## Troubleshooting

### Auto-click not working
```bash
sudo systemctl start prismgb-autoclick.service
sudo systemctl status prismgb-autoclick.service
```

### Check service logs
```bash
sudo journalctl -u prismgb-direct.service -f
sudo journalctl -u prismgb-autoclick.service -f
```

### Manual control
```bash
# Stop services
sudo systemctl stop prismgb-direct.service
sudo systemctl stop prismgb-autoclick.service

# Start services
sudo systemctl start prismgb-direct.service
sudo systemctl start prismgb-autoclick.service
```