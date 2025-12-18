# PrismGB Raspberry Pi Zero 2 W Kiosk Setup

This guide will turn your Raspberry Pi Zero 2 W into a dedicated PrismGB appliance that boots straight into the application.

## Hardware Requirements

- **Raspberry Pi Zero 2 W** (1GB RAM, quad-core ARM Cortex-A53)
- **MicroSD card** (16GB+ recommended, Class 10 or better)
- **HDMI display** (any resolution, 1080p recommended)
- **USB-C power supply** (5V 2.5A minimum, 3A recommended)
- **USB-C to USB-A adapter** (for connecting Chromatic - must support data transfer)
- **Micro HDMI to HDMI cable** (for Pi Zero 2 W)

## Performance Notes

- **Pi Zero 2 W** is adequate but may have some performance limitations
- **Pi 4/5** recommended for better performance if available
- **x64 emulation** fallback available if ARM builds aren't ready

## Quick Setup

1. **Flash Raspberry Pi OS Lite (Bookworm)** to your SD card
2. **Enable SSH and configure Wi-Fi** (optional) using Raspberry Pi Imager
3. **Boot the Pi** and SSH in (or use keyboard/monitor)
4. **Run the setup script**:

```bash
curl -fsSL https://raw.githubusercontent.com/josstei/prismgb-app/main/raspberry-pi/setup.sh | bash
```

Or manually follow the steps below.

## Manual Setup Steps

### 1. Install PrismGB

```bash
# Download and install PrismGB ARM64 build
wget https://github.com/NicholasBM/prismgb-app/releases/latest/download/PrismGB-1.1.0-arm64.deb
sudo dpkg -i PrismGB-1.1.0-arm64.deb

# If ARM64 has issues, try ARM32:
# wget https://github.com/NicholasBM/prismgb-app/releases/latest/download/PrismGB-1.1.0-armv7l.deb
# sudo dpkg -i PrismGB-1.1.0-armv7l.deb

# Install dependencies if needed
sudo apt-get install -f
```

### 2. Configure Auto-login

```bash
sudo systemctl set-default multi-user.target
sudo systemctl enable getty@tty1.service
```

### 3. Set up Kiosk Environment

Choose **Option A (Wayland)** for better performance, or **Option B (X11)** if Wayland has issues:

#### Option A: Wayland Kiosk (Recommended)

```bash
# Install minimal Wayland compositor
sudo apt update
sudo apt install -y cage

# Copy kiosk service files
sudo cp /opt/prismgb/raspberry-pi/prismgb-kiosk-wayland.service /etc/systemd/system/
sudo systemctl enable prismgb-kiosk-wayland.service
```

#### Option B: X11 Minimal

```bash
# Install minimal X11 stack
sudo apt update
sudo apt install -y xserver-xorg xinit openbox

# Copy kiosk service files  
sudo cp /opt/prismgb/raspberry-pi/prismgb-kiosk-x11.service /etc/systemd/system/
sudo systemctl enable prismgb-kiosk-x11.service
```

### 4. Configure Auto-login and Boot

```bash
# Enable auto-login for pi user
sudo systemctl edit getty@tty1.service
```

Add this content:
```ini
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I $TERM
```

### 5. Optimize for Performance

```bash
# Reduce GPU memory split for headless operation
echo "gpu_mem=64" | sudo tee -a /boot/firmware/config.txt

# Disable unnecessary services
sudo systemctl disable bluetooth.service
sudo systemctl disable wifi-powersave@wlan0.service

# Set CPU governor to performance
echo 'GOVERNOR="performance"' | sudo tee /etc/default/cpufrequtils
```

### 6. Reboot

```bash
sudo reboot
```

## Troubleshooting

### Performance Issues
- Try ARM32 build instead of ARM64
- Increase GPU memory: `gpu_mem=128` in `/boot/firmware/config.txt`
- Disable hardware acceleration: `export PRISMGB_DISABLE_GPU=1`

### Display Issues
- Check HDMI cable and display compatibility
- Try forcing HDMI: `hdmi_force_hotplug=1` in `/boot/firmware/config.txt`

### USB Device Not Detected
- Ensure USB-C to USB-A adapter supports data transfer
- Check `lsusb` output for Chromatic device (VID: 374e, PID: 0101)

### App Crashes
- Check logs: `journalctl -u prismgb-kiosk-wayland.service -f`
- The service will automatically restart the app

## Manual Control

```bash
# Stop kiosk mode
sudo systemctl stop prismgb-kiosk-wayland.service

# Start kiosk mode
sudo systemctl start prismgb-kiosk-wayland.service

# Check status
sudo systemctl status prismgb-kiosk-wayland.service

# View logs
journalctl -u prismgb-kiosk-wayland.service -f
```

## Customization

Edit the service files in `/etc/systemd/system/` to customize:
- Display resolution
- Environment variables
- Restart behavior
- User permissions