# PrismGB Raspberry Pi Performance Tuning

## Raspberry Pi Zero 2 W Optimizations

The Pi Zero 2 W has limited resources (1GB RAM, 1GHz quad-core). Here are optimizations:

### 1. Boot Configuration (`/boot/firmware/config.txt`)

```ini
# GPU Memory Split (balance between system and GPU)
gpu_mem=128

# CPU Governor (performance vs power saving)
# Uncomment for maximum performance (more heat/power)
# arm_freq=1000
# over_voltage=2

# HDMI Settings (force output, reduce blanking)
hdmi_force_hotplug=1
hdmi_drive=2
disable_overscan=1

# Disable unused interfaces to save memory
dtparam=audio=off
dtoverlay=disable-bt
dtoverlay=disable-wifi  # Only if using ethernet

# Enable hardware video decode (helps with video processing)
gpu_mem_256=128
gpu_mem_512=128
gpu_mem_1024=128
```

### 2. System Optimizations

```bash
# Disable swap (SD card wear, performance)
sudo dphys-swapfile swapoff
sudo dphys-swapfile uninstall
sudo systemctl disable dphys-swapfile

# Reduce journald logging
sudo mkdir -p /etc/systemd/journald.conf.d
echo -e "[Journal]\nStorage=volatile\nRuntimeMaxUse=32M" | sudo tee /etc/systemd/journald.conf.d/99-volatile.conf

# Disable unnecessary services
sudo systemctl disable bluetooth.service
sudo systemctl disable hciuart.service
sudo systemctl disable wifi-powersave@wlan0.service
sudo systemctl disable ModemManager.service
sudo systemctl disable wpa_supplicant.service  # Only if using ethernet

# Set CPU governor to performance
echo 'GOVERNOR="performance"' | sudo tee /etc/default/cpufrequtils
```

### 3. PrismGB-Specific Optimizations

Add these environment variables to the systemd service:

```ini
# Disable GPU acceleration if causing issues
Environment=PRISMGB_DISABLE_GPU=1

# Reduce Electron memory usage
Environment=ELECTRON_DISABLE_SANDBOX=1
Environment=ELECTRON_NO_ASAR=1

# Chromium flags for low-memory systems
Environment=ELECTRON_EXTRA_ARGS=--disable-dev-shm-usage --disable-gpu-sandbox --no-sandbox --disable-software-rasterizer --disable-background-timer-throttling --disable-backgrounding-occluded-windows --disable-renderer-backgrounding --disable-features=TranslateUI --disable-ipc-flooding-protection
```

### 4. Network Optimizations (if using Wi-Fi)

```bash
# Reduce Wi-Fi power management
echo 'options 8192cu rtw_power_mgnt=0 rtw_enusbss=1 rtw_ips_mode=1' | sudo tee /etc/modprobe.d/8192cu.conf

# Or disable Wi-Fi power saving entirely
sudo iw wlan0 set power_save off
```

### 5. Storage Optimizations

```bash
# Mount tmpfs for temporary files
echo 'tmpfs /tmp tmpfs defaults,noatime,nosuid,size=100m 0 0' | sudo tee -a /etc/fstab
echo 'tmpfs /var/tmp tmpfs defaults,noatime,nosuid,size=30m 0 0' | sudo tee -a /etc/fstab

# Reduce SD card writes
echo 'vm.dirty_background_ratio = 20' | sudo tee -a /etc/sysctl.conf
echo 'vm.dirty_ratio = 40' | sudo tee -a /etc/sysctl.conf
echo 'vm.dirty_writeback_centisecs = 500' | sudo tee -a /etc/sysctl.conf
echo 'vm.dirty_expire_centisecs = 600' | sudo tee -a /etc/sysctl.conf
```

### 6. Troubleshooting Performance Issues

**If PrismGB is slow or crashes:**

1. **Check memory usage:**
   ```bash
   free -h
   htop
   ```

2. **Monitor CPU temperature:**
   ```bash
   vcgencmd measure_temp
   ```

3. **Try software rendering:**
   ```bash
   # Add to service environment
   Environment=PRISMGB_DISABLE_GPU=1
   Environment=LIBGL_ALWAYS_SOFTWARE=1
   ```

4. **Reduce video quality/resolution:**
   - Use lower HDMI resolution in `config.txt`
   - Consider 720p instead of 1080p

5. **Check for thermal throttling:**
   ```bash
   vcgencmd get_throttled
   # 0x0 = no throttling
   # Non-zero = throttling occurred
   ```

### 7. Alternative: Use Raspberry Pi 4/5

For better performance, consider upgrading to:
- **Raspberry Pi 4** (2GB+ RAM recommended)
- **Raspberry Pi 5** (4GB+ RAM recommended)

These have significantly more processing power and memory for smoother PrismGB operation.

### 8. Monitoring Performance

Create a simple monitoring script:

```bash
#!/bin/bash
# Save as /home/pi/monitor.sh

while true; do
    echo "$(date): Temp=$(vcgencmd measure_temp | cut -d= -f2) CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d% -f1) Mem=$(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}')"
    sleep 30
done
```

Run with: `bash /home/pi/monitor.sh`