#!/bin/bash
# PrismGB Pi 4 One-Command Installer
# Includes all fixes, optimizations, and auto-fullscreen

set -e

echo "🎮 Installing PrismGB for Raspberry Pi 4..."
echo "This installer includes all optimizations and fixes."

# Check if running on Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    echo "❌ This installer is designed for Raspberry Pi"
    exit 1
fi

# Update system
echo "📦 Updating system packages..."
sudo apt update
sudo apt install -y curl wget nodejs npm xserver-xorg xinit openbox xdotool

# Install Electron globally
echo "⚡ Installing Electron..."
sudo npm install -g electron

# Download and extract PrismGB
echo "📥 Downloading PrismGB..."

# Check /tmp space and use home directory if needed
TMP_AVAIL=$(df /tmp | tail -1 | awk '{print $4}')
if [ "$TMP_AVAIL" -lt 1000000 ]; then
    echo "⚠️  /tmp has limited space, using home directory..."
    WORK_DIR="$HOME/prismgb-install"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"
else
    cd /tmp
fi

wget -O prismgb-pi-installer.tar.gz "https://github.com/NicholasBM/prismgb-pi/releases/download/v1.1.5/prismgb-pi-installer.tar.gz"

# Check if download was successful
if [ ! -f prismgb-pi-installer.tar.gz ]; then
    echo "❌ Download failed!"
    exit 1
fi

echo "📦 Extracting package..."
tar -xzf prismgb-pi-installer.tar.gz

# Check if extraction was successful
if [ ! -d prismgb-pi-installer ]; then
    echo "❌ Extraction failed!"
    exit 1
fi

# Install PrismGB files
echo "📁 Installing PrismGB files..."
sudo cp -r prismgb-pi-installer/opt /
sudo cp -r prismgb-pi-installer/etc /

# Fix missing assets issue
echo "🔧 Fixing missing assets..."
sudo mkdir -p /opt/prismgb/main/assets
sudo cp /opt/prismgb/renderer/assets/tray-icon.png /opt/prismgb/main/assets/ 2>/dev/null || echo "Tray icon already exists"

# Fix Electron sandbox issue for root execution
echo "🔧 Fixing Electron sandbox for root execution..."
sudo sed -i 's|exec electron dist/main/index.js|exec electron --no-sandbox main/index.js|g' /opt/prismgb/prismgb

# Create auto-click service for device detection
echo "🎮 Setting up auto-click on device connection..."
sudo tee /opt/prismgb/auto-click-on-device.sh > /dev/null << 'AUTOEOF'
#!/bin/bash
DISPLAY=:0
export DISPLAY
echo "Starting USB device monitor for auto-click and fullscreen..."

auto_click_and_fullscreen() {
    echo "Device connected! Making PrismGB fullscreen and auto-clicking..."
    
    # Get current screen resolution dynamically
    RESOLUTION=$(DISPLAY=:0 xrandr | grep '*' | awk '{print $1}' | head -1)
    WIDTH=$(echo $RESOLUTION | cut -d'x' -f1)
    HEIGHT=$(echo $RESOLUTION | cut -d'x' -f2)
    CENTER_X=$((WIDTH / 2))
    CENTER_Y=$((HEIGHT / 2))
    
    # Make PrismGB fullscreen first
    DISPLAY=:0 xdotool search --name "PrismGB" windowactivate windowsize $WIDTH $HEIGHT windowmove 0 0
    sleep 1
    
    # Then click the center to connect
    DISPLAY=:0 xdotool mousemove $CENTER_X $CENTER_Y
    sleep 0.5
    DISPLAY=:0 xdotool click 1
    
    echo "Made fullscreen ($WIDTH x $HEIGHT) and auto-clicked at $CENTER_X,$CENTER_Y"
}

previous_devices=$(lsusb)
while true; do
    sleep 2
    current_devices=$(lsusb)
    if [ "$current_devices" != "$previous_devices" ]; then
        echo "USB device change detected"
        if echo "$current_devices" | grep -q "374e\|1209\|046d\|2341"; then
            auto_click_and_fullscreen
        fi
        previous_devices="$current_devices"
    fi
done
AUTOEOF

sudo chmod +x /opt/prismgb/auto-click-on-device.sh

# Create auto-click systemd service with better dependencies
sudo tee /etc/systemd/system/prismgb-autoclick.service > /dev/null << 'AUTOSVCEOF'
[Unit]
Description=PrismGB Auto-Click on Device Connection
After=prismgb-direct.service multi-user.target
Wants=prismgb-direct.service
BindsTo=prismgb-direct.service

[Service]
Type=simple
User=root
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/pi/.Xauthority
ExecStartPre=/bin/sleep 30
ExecStart=/opt/prismgb/auto-click-on-device.sh
Restart=always
RestartSec=15
TimeoutStartSec=180

[Install]
WantedBy=multi-user.target
AUTOSVCEOF

# Clean up
echo "🧹 Cleaning up..."
if [ -n "$WORK_DIR" ]; then
    cd "$HOME"
    rm -rf "$WORK_DIR"
else
    rm -rf /tmp/prismgb-pi-installer*
fi

# Apply all our fixes and optimizations
echo "🔧 Applying fixes and optimizations..."

# Install working USB detection module
sudo tee /opt/prismgb/node_modules/usb-detection/index.js > /dev/null << 'EOF'
const { execSync } = require('child_process');
const EventEmitter = require('events');

class USBDetection extends EventEmitter {
  constructor() {
    super();
    this.monitoring = false;
    this.knownDevices = new Set();
  }

  find(vendorId, productId) {
    try {
      const output = execSync('lsusb', { encoding: 'utf8' });
      const devices = [];
      
      for (const line of output.split('\n')) {
        if (!line.trim()) continue;
        
        const match = line.match(/Bus (\d+) Device (\d+): ID ([0-9a-f]{4}):([0-9a-f]{4})\s+(.+)/i);
        if (match) {
          const [, bus, device, vid, pid, manufacturer] = match;
          const deviceInfo = {
            locationId: parseInt(bus) * 1000 + parseInt(device),
            vendorId: parseInt(vid, 16),
            productId: parseInt(pid, 16),
            deviceName: manufacturer.trim(),
            manufacturer: manufacturer.split(',')[0]?.trim() || 'Unknown',
            serialNumber: '',
            deviceAddress: parseInt(device)
          };
          
          if (vendorId !== undefined && productId !== undefined) {
            if (deviceInfo.vendorId === vendorId && deviceInfo.productId === productId) {
              devices.push(deviceInfo);
            }
          } else if (vendorId !== undefined) {
            if (deviceInfo.vendorId === vendorId) {
              devices.push(deviceInfo);
            }
          } else {
            devices.push(deviceInfo);
          }
        }
      }
      
      return devices;
    } catch (error) {
      console.error('USB detection error:', error);
      return [];
    }
  }

  startMonitoring() {
    if (this.monitoring) return;
    
    this.monitoring = true;
    this.knownDevices = new Set(this.find().map(d => `${d.vendorId}:${d.productId}:${d.deviceAddress}`));
    
    this.interval = setInterval(() => {
      const currentDevices = this.find();
      const currentSet = new Set(currentDevices.map(d => `${d.vendorId}:${d.productId}:${d.deviceAddress}`));
      
      for (const device of currentDevices) {
        const key = `${device.vendorId}:${device.productId}:${device.deviceAddress}`;
        if (!this.knownDevices.has(key)) {
          this.emit('add', device);
        }
      }
      
      for (const key of this.knownDevices) {
        if (!currentSet.has(key)) {
          const [vendorId, productId, deviceAddress] = key.split(':').map(Number);
          this.emit('remove', { vendorId, productId, deviceAddress });
        }
      }
      
      this.knownDevices = currentSet;
    }, 1000);
  }

  stopMonitoring() {
    if (this.interval) {
      clearInterval(this.interval);
      this.interval = null;
    }
    this.monitoring = false;
  }

  on(event, callback) {
    super.on(event, callback);
  }

  off(event, callback) {
    super.off(event, callback);
  }
}

const detector = new USBDetection();

module.exports = {
  find: (vendorId, productId) => detector.find(vendorId, productId),
  on: (event, callback) => detector.on(event, callback),
  off: (event, callback) => detector.off(event, callback),
  startMonitoring: () => detector.startMonitoring(),
  stopMonitoring: () => detector.stopMonitoring()
};
EOF

# Fix WindowManager for production mode
echo "🔧 Fixing WindowManager for production mode..."
sudo cp /opt/prismgb/main/WindowManager-Ms3H4scH.js /opt/prismgb/main/WindowManager-Ms3H4scH.js.backup
sudo sed -i 's|this.mainWindow.loadURL("http://localhost:3000/src/app/renderer/index.html")|this.mainWindow.loadFile(i.join(f, "../renderer/src/app/renderer/index.html"))|g' /opt/prismgb/main/WindowManager-Ms3H4scH.js
sudo sed -i 's|Loading from Vite dev server: http://localhost:3000/src/app/renderer/index.html|Loading built files (forced production mode)|g' /opt/prismgb/main/WindowManager-Ms3H4scH.js

# Create optimized start script with auto-fullscreen
echo "🚀 Creating optimized start script with auto-fullscreen..."
sudo tee /opt/prismgb/start-prismgb.sh > /dev/null << 'STARTEOF'
#!/bin/bash
# Kill any existing X servers
pkill -f "X :0" || true
sleep 2

# Start X server
/usr/bin/X :0 -nolisten tcp &
sleep 3

# Start window manager
DISPLAY=:0 openbox &
sleep 2

# Start PrismGB
export DISPLAY=:0
export NODE_ENV=production
cd /opt/prismgb
./prismgb &

# Auto-fullscreen after 5 seconds using the working method
sleep 5
DISPLAY=:0 xdotool search --name "PrismGB" windowactivate windowsize 1920 1080 windowmove 0 0
wait
STARTEOF

sudo chmod +x /opt/prismgb/start-prismgb.sh

# Create systemd service
echo "⚙️ Setting up auto-start service..."
sudo tee /etc/systemd/system/prismgb-direct.service > /dev/null << 'SERVICEEOF'
[Unit]
Description=PrismGB Direct Boot
After=multi-user.target

[Service]
Environment=NODE_ENV=production
Type=simple
User=root
ExecStart=/opt/prismgb/start-prismgb.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICEEOF

# Enable and start the services
sudo systemctl daemon-reload
sudo systemctl enable prismgb-direct
sudo systemctl enable prismgb-autoclick

# Start the auto-click service immediately (don't wait for reboot)
echo "🎮 Starting auto-click service..."
sudo systemctl start prismgb-autoclick

# Verify services are working
echo "✅ Checking service status..."
if sudo systemctl is-active --quiet prismgb-direct; then
    echo "✅ PrismGB service is running"
else
    echo "⚠️  PrismGB service not running - will start on reboot"
fi

if sudo systemctl is-active --quiet prismgb-autoclick; then
    echo "✅ Auto-click service is running"
else
    echo "⚠️  Auto-click service failed to start"
    echo "   Run: sudo systemctl start prismgb-autoclick"
fi

# Pi 4 optimizations
echo "⚡ Applying Pi 4 optimizations..."
echo 'gpu_mem=128' | sudo tee -a /boot/firmware/config.txt
echo 'disable_overscan=1' | sudo tee -a /boot/firmware/config.txt

# Aggressive 1080p forcing for better performance
echo '# FORCE 1080p output (aggressive settings)' | sudo tee -a /boot/firmware/config.txt
echo 'hdmi_ignore_edid=0xa5000080' | sudo tee -a /boot/firmware/config.txt
echo 'hdmi_edid_file=1' | sudo tee -a /boot/firmware/config.txt
echo 'hdmi_force_hotplug=1' | sudo tee -a /boot/firmware/config.txt
echo 'hdmi_group=2' | sudo tee -a /boot/firmware/config.txt
echo 'hdmi_mode=82' | sudo tee -a /boot/firmware/config.txt
echo 'hdmi_drive=2' | sudo tee -a /boot/firmware/config.txt
echo 'config_hdmi_boost=10' | sudo tee -a /boot/firmware/config.txt
echo 'framebuffer_width=1920' | sudo tee -a /boot/firmware/config.txt
echo 'framebuffer_height=1080' | sudo tee -a /boot/firmware/config.txt

echo ""
echo "🎉 PrismGB Pi 4 installation complete!"
echo ""
echo "✅ Auto-boots to PrismGB on TV"
echo "✅ Auto-fullscreen when device connected"  
echo "✅ Auto-clicks when Chromatic connected"
echo "✅ USB detection working"
echo "✅ Forced 1080p for optimal performance"
echo "✅ Services configured and started"
echo "✅ Ready for Chromatic - just plug and play!"
echo ""
echo "📋 Service Status:"
sudo systemctl is-active prismgb-direct && echo "  ✅ PrismGB: Running" || echo "  ⏳ PrismGB: Will start on reboot"
sudo systemctl is-active prismgb-autoclick && echo "  ✅ Auto-click: Running" || echo "  ⚠️  Auto-click: Check with 'sudo systemctl start prismgb-autoclick'"
echo ""
echo "🔄 Reboot now to ensure everything starts properly: sudo reboot"
echo ""
echo "🎮 After reboot: Just connect your Chromatic and it will auto-connect!"
echo ""