# PrismGB Raspberry Pi Setup - Summary

## What's Ready

✅ **Kiosk Configuration Files**
- Wayland kiosk service (recommended)
- X11 kiosk service (fallback)
- Auto-login configuration
- Performance optimizations

✅ **Setup Scripts**
- Automated installation script (`setup.sh`)
- Manual setup instructions (`README.md`)
- Performance tuning guide (`performance-tuning.md`)

✅ **Build Configuration**
- ARM64 and ARM32 build targets added to `package.json`
- Build scripts: `npm run build:rpi`

## Solution: Source Package Approach ✅

Instead of pre-built ARM binaries, we package the source code and build on the Pi:

✅ **Source Package System**
- `create-source-package.sh` - Creates deployable source package
- `build-on-pi.sh` - Builds PrismGB natively on the Pi
- Setup script automatically handles source package deployment
- No cross-compilation issues!

**How it works:**
1. Run `npm run package:rpi-source` on your Mac
2. Copy `prismgb-source-{version}.tar.gz` to Pi
3. Extract and run `./build-on-pi.sh`
4. PrismGB builds natively with ARM-optimized binaries

## Quick Start

### Option 1: Use Existing x64 Build (Easiest)

The current x64 Linux build will work on Raspberry Pi 4/5 via emulation:

```bash
# On Raspberry Pi
curl -fsSL https://raw.githubusercontent.com/josstei/prismgb-app/main/raspberry-pi/setup.sh | bash
```

The script will automatically fall back to x64 if ARM builds aren't available.

### Option 2: Build ARM Version on Raspberry Pi

```bash
# On Raspberry Pi
git clone https://github.com/josstei/prismgb-app.git
cd prismgb-app
npm install
npm run build:linux

# Then run setup
cd raspberry-pi
chmod +x setup.sh
./setup.sh
```

### Option 3: Build ARM Version with Docker

```bash
# On your Mac (requires Docker Desktop with ARM emulation)
docker run --platform=linux/arm64 -v $(pwd):/workspace -w /workspace node:22 bash -c "
  npm install && npm run build:linux
"
```

## Files Created

```
raspberry-pi/
├── README.md                      # Main setup guide
├── setup.sh                       # Automated setup script
├── build-instructions.md          # How to build ARM versions
├── performance-tuning.md          # Optimization guide
├── prismgb-kiosk-wayland.service # Wayland kiosk service
├── prismgb-kiosk-x11.service     # X11 kiosk service
├── xinitrc                        # X11 initialization
├── openbox-autostart              # Openbox autostart config
└── SUMMARY.md                     # This file
```

## Next Steps

1. **Test on actual Raspberry Pi hardware**
2. **Build ARM versions** (on Pi or via Docker)
3. **Upload ARM builds to GitHub releases**
4. **Update setup script** with correct download URLs
5. **Test kiosk mode** with real Chromatic device

## Hardware Recommendations

- **Minimum:** Raspberry Pi Zero 2 W (1GB RAM)
- **Recommended:** Raspberry Pi 4 (2GB+ RAM) or Pi 5
- **Best:** Raspberry Pi 5 (4GB+ RAM)

## Performance Expectations

- **Pi Zero 2 W:** Adequate, may have some lag
- **Pi 4 (2GB+):** Good performance
- **Pi 5:** Excellent performance

## Support

For issues or questions:
- Check `README.md` for troubleshooting
- Check `performance-tuning.md` for optimization tips
- Open an issue on GitHub