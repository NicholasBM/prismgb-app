# PrismGB Raspberry Pi 4 TV Display - Complete Setup

**One-command installer with all fixes and optimizations included!**

![Pi 4 Ready](https://img.shields.io/badge/Pi%204-Optimized-brightgreen) ![Auto Fullscreen](https://img.shields.io/badge/Auto-Fullscreen-blue) ![Production Ready](https://img.shields.io/badge/Status-Production%20Ready-success)

## 🚀 Quick Install

**For Raspberry Pi 4 (Recommended):**
```bash
curl -sSL https://raw.githubusercontent.com/NicholasBM/prismgb-app/main/raspberry-pi/install-pi4.sh | bash
sudo reboot
```

**That's it!** Your Pi 4 will boot straight to PrismGB in fullscreen mode.

## ✨ What's Included

This installer includes **all the fixes and optimizations** discovered during development:

✅ **Working USB Detection** - lsusb-based detection that actually works  
✅ **Production Mode Fix** - Forces local file loading instead of dev server  
✅ **Auto-Fullscreen** - Automatically goes fullscreen 5 seconds after boot  
✅ **Pi 4 Optimizations** - GPU memory and display optimizations  
✅ **Stable Service** - Proper systemd service with auto-restart  
✅ **Performance Tuned** - Smooth, responsive interface  

## 🎮 Features

- **Auto-boots to PrismGB** on your TV
- **Auto-fullscreen** in 5 seconds
- **Smooth performance** on Pi 4
- **USB detection** ready for Chromatic
- **No keyboard/mouse needed** after setup
- **Professional TV experience**

## 🔧 Hardware Requirements

### Minimum
- **Raspberry Pi 4** (2GB+ RAM recommended)
- **Micro HDMI to HDMI cable**
- **MicroSD card** (16GB+)
- **USB-C power supply** (3A recommended)

### For Chromatic Gaming
- **Mod Retro Chromatic** device
- **USB-A to USB-C cable**
- Optional: **Powered USB hub** (if needed for power)

## 🎯 Success Criteria

Your setup is working correctly when:

✅ **Pi boots to PrismGB interface on TV**  
✅ **Interface goes fullscreen automatically**  
✅ **Shows "No device connected"** (until Chromatic plugged in)  
✅ **Interface is smooth and responsive**  
✅ **USB devices are detected** when connected  

## 🔍 Troubleshooting

### PrismGB Not Appearing
```bash
# Check service status
sudo systemctl status prismgb-direct

# View logs
journalctl -u prismgb-direct -f

# Restart service
sudo systemctl restart prismgb-direct
```

### Performance Issues
The Pi 4 installer includes optimizations, but if you experience issues:
- Ensure you're using a **fast SD card** (Class 10, A1 rated)
- Use a **quality power supply** (3A USB-C)
- Check **HDMI cable quality**

### USB Detection Issues
```bash
# Test USB detection
lsusb

# Check if devices appear when plugged in
dmesg | tail -10
```

## 🆚 Pi 4 vs Pi Zero 2 W

| Feature | Pi Zero 2 W | Pi 4 |
|---------|-------------|------|
| **Performance** | Functional but slow | Smooth and fast |
| **RAM** | 512MB | 2GB/4GB/8GB |
| **USB Power** | Limited | Much better |
| **Interface** | Sluggish | Responsive |
| **Price** | ~$15 | ~$35-75 |
| **Recommendation** | Budget option | **Recommended** |

## 🔄 What's Fixed

This installer solves all the issues encountered during development:

### USB Detection
- ❌ **Original**: Native USB module failed to compile
- ✅ **Fixed**: lsusb-based detection that works reliably

### Production Mode
- ❌ **Original**: Tried to load from dev server (localhost:3000)
- ✅ **Fixed**: Forces local file loading in production mode

### User Experience
- ❌ **Original**: Required manual fullscreen activation
- ✅ **Fixed**: Auto-fullscreen 5 seconds after boot

### Performance
- ❌ **Original**: Default settings caused sluggish UI
- ✅ **Fixed**: Pi 4 optimizations for smooth experience

### Stability
- ❌ **Original**: Service crashes and restart issues
- ✅ **Fixed**: Robust service with proper error handling

## 📋 Manual Installation Steps

If you prefer to understand what the installer does:

<details>
<summary>Click to expand manual steps</summary>

1. **Update system**:
   ```bash
   sudo apt update
   sudo apt install -y nodejs npm xserver-xorg xinit openbox xdotool
   ```

2. **Install Electron**:
   ```bash
   sudo npm install -g electron
   ```

3. **Download PrismGB**:
   ```bash
   wget -O /tmp/prismgb.tar.gz "https://github.com/NicholasBM/prismgb-app/releases/download/v1.1.5/prismgb-pi-installer.tar.gz"
   cd /tmp && tar -xzf prismgb.tar.gz
   sudo cp -r prismgb-pi-installer/* /
   ```

4. **Apply fixes** (USB detection, WindowManager, etc.)
5. **Create service** and enable auto-start
6. **Apply Pi 4 optimizations**

</details>

## 🎮 Using with Chromatic

Once installed:

1. **Connect Chromatic** via USB
2. **PrismGB will detect it** and show "Connected"
3. **Click the pulsing diamond** to start gaming
4. **Enjoy Game Boy games on your TV!**

## 🚀 Advanced Configuration

### Custom Resolution
Edit `/boot/firmware/config.txt`:
```bash
hdmi_group=2
hdmi_mode=82  # 1920x1080 60Hz
```

### SSH Access
```bash
sudo systemctl enable ssh
```

### Disable Auto-Start (for troubleshooting)
```bash
sudo systemctl disable prismgb-direct
```

## 📞 Support

### Getting Help
1. **Check logs**: `journalctl -u prismgb-direct -f`
2. **Test manually**: `DISPLAY=:0 /opt/prismgb/prismgb`
3. **Open GitHub issue** with hardware details and logs

### Contributing
Found an issue or improvement? Please contribute back to help others!

---

**Status**: ✅ Production Ready  
**Tested on**: Raspberry Pi 4 (2GB/4GB), Raspberry Pi OS (64-bit)  
**Last updated**: December 2025

**This installer represents the complete solution** - all the trial and error, fixes, and optimizations packaged into a single command that just works! 🎉