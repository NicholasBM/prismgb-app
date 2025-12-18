# PrismGB Raspberry Pi Release Checklist

## Step-by-Step Release Process

### 1. Configure for Your GitHub Repo

```bash
# Replace 'YOUR_USERNAME' with your actual GitHub username
cd raspberry-pi
./configure-repo.sh YOUR_USERNAME
```

This updates all URLs to point to your GitHub repo.

### 2. Commit to Your GitHub Repo

```bash
# Add all the raspberry-pi files
git add raspberry-pi/
git commit -m "Add Raspberry Pi kiosk setup and source package system"
git push origin main
```

### 3. Create the Source Package

```bash
# Create the deployable source package
npm run package:rpi-source
```

This creates: `raspberry-pi/prismgb-source-1.1.0.tar.gz` (about 1.3MB)

### 4. Create GitHub Release

1. **Go to your GitHub repo** → Releases → "Create a new release"

2. **Tag version:** `v1.1.0`

3. **Release title:** `PrismGB v1.1.0 - Raspberry Pi Support`

4. **Description:**
   ```markdown
   # PrismGB v1.1.0 - Raspberry Pi Support
   
   This release adds complete Raspberry Pi Zero 2 W support with kiosk mode.
   
   ## 🍓 Raspberry Pi Setup
   
   **One-command setup:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/prismgb-app/main/raspberry-pi/setup.sh | bash
   ```
   
   **Manual setup:**
   1. Download `prismgb-source-1.1.0.tar.gz`
   2. Copy to your Pi and extract
   3. Run `./build-on-pi.sh` (takes 20-30 minutes)
   4. Run `./raspberry-pi/setup.sh` for kiosk mode
   
   ## Features
   - ✅ Boots straight into PrismGB
   - ✅ Auto-restarts on crash
   - ✅ Optimized for Pi Zero 2 W
   - ✅ Wayland or X11 kiosk modes
   - ✅ USB Chromatic support
   
   ## Requirements
   - Raspberry Pi Zero 2 W (or Pi 4/5)
   - Raspberry Pi OS Lite (64-bit Bookworm)
   - 2GB free space for build
   - Internet connection
   
   Build time: 20-30 minutes on Pi Zero 2 W
   ```

5. **Upload the source package:**
   - Drag and drop `raspberry-pi/prismgb-source-1.1.0.tar.gz`

6. **Publish release**

### 5. Test the Magic Command

After the release is published, test on a fresh Raspberry Pi:

```bash
# This should now work!
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/prismgb-app/main/raspberry-pi/setup.sh | bash
```

## What Each File Does

```
raspberry-pi/
├── setup.sh                       # Smart setup (tries source package)
├── setup-manual.sh                # Manual setup (local files only)
├── prismgb-source-1.1.0.tar.gz   # Source package (upload to release)
├── create-source-package.sh       # Creates the source package
├── configure-repo.sh               # Updates URLs for your repo
├── build-on-pi.sh                 # Build script (inside source package)
├── prismgb-kiosk-wayland.service  # Wayland kiosk service
├── prismgb-kiosk-x11.service      # X11 kiosk service
├── README.md                       # User documentation
├── DEPLOYMENT.md                   # Deployment guide
├── performance-tuning.md           # Pi optimization tips
└── RELEASE-CHECKLIST.md           # This file
```

## Testing Checklist

### Before Release
- [ ] Source package builds successfully
- [ ] All URLs point to your repo
- [ ] Documentation is accurate

### After Release
- [ ] One-command setup works
- [ ] Source package downloads correctly
- [ ] Build completes on Pi
- [ ] Kiosk mode starts properly
- [ ] PrismGB detects Chromatic
- [ ] Auto-restart works after crash

## Troubleshooting

### If the one-command setup fails:
1. Check the GitHub release exists
2. Verify the source package was uploaded
3. Test the URLs manually with `wget`

### If build fails on Pi:
1. Check available disk space (`df -h`)
2. Check memory usage (`free -h`)
3. Try the manual setup script instead

### If kiosk doesn't start:
1. Check service status: `sudo systemctl status prismgb-kiosk.service`
2. Check logs: `journalctl -u prismgb-kiosk.service -f`
3. Try X11 mode instead of Wayland

## Success Criteria

✅ **Complete success when:**
- Pi boots straight into PrismGB
- Chromatic is detected when plugged in
- Video streams smoothly
- App restarts automatically if it crashes
- No desktop environment visible

This creates a true "appliance" experience! 🎮