# PrismGB Raspberry Pi Installation

## One-Command Install

Run this single command on your Raspberry Pi Zero 2 W:

```bash
curl -sSL https://raw.githubusercontent.com/NicholasBM/prismgb-app/main/raspberry-pi/install-pi.sh | bash
```

That's it! PrismGB will:
- ✅ Download and install automatically
- ✅ Set up kiosk mode 
- ✅ Configure USB permissions for Chromatic
- ✅ Auto-start on boot

## What it does

1. **Downloads** the pre-built ARM64 package
2. **Installs** PrismGB and dependencies
3. **Configures** auto-boot to PrismGB
4. **Sets up** USB detection for Mod Retro Chromatic

## Requirements

- Raspberry Pi Zero 2 W (or any Pi with ARM64)
- Raspberry Pi OS (64-bit)
- Internet connection for download

## Manual Control

After installation, you can control PrismGB:

```bash
# Check status
sudo systemctl status prismgb-kiosk

# Stop kiosk mode
sudo systemctl stop prismgb-kiosk

# Start kiosk mode  
sudo systemctl start prismgb-kiosk

# View logs
journalctl -u prismgb-kiosk -f

# Reboot to kiosk
sudo reboot
```

## Troubleshooting

If installation fails:
1. Make sure you're on Raspberry Pi OS 64-bit
2. Check internet connection
3. Try running the install script again

For support, open an issue on GitHub.