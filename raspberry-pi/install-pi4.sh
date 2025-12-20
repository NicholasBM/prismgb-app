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
cd /tmp
wget -O prismgb-pi-installer.tar.gz "https://github.com/NicholasBM/prismgb-app/releases/download/v1.1.5/prismgb-pi-installer.tar.gz"
tar -xzf prismgb-pi-installer.tar.gz

# Install PrismGB files
echo "📁 Installing PrismGB files..."
sudo cp -r prismgb-pi-installer/opt /
sudo cp -r prismgb-pi-installer/etc /

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
EOF# Fi
x WindowManager for production mode
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

# Auto-fullscreen after 5 seconds
sleep 5
DISPLAY=:0 xdotool search --name "PrismGB" windowactivate
sleep 1
DISPLAY=:0 xdotool key F11
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

# Enable the service
sudo systemctl daemon-reload
sudo systemctl enable prismgb-direct

# Pi 4 optimizations
echo "⚡ Applying Pi 4 optimizations..."
echo 'gpu_mem=128' | sudo tee -a /boot/firmware/config.txt
echo 'disable_overscan=1' | sudo tee -a /boot/firmware/config.txt
echo 'hdmi_force_hotplug=1' | sudo tee -a /boot/firmware/config.txt

echo ""
echo "🎉 PrismGB Pi 4 installation complete!"
echo ""
echo "✅ Auto-boots to PrismGB on TV"
echo "✅ Auto-fullscreen in 5 seconds"  
echo "✅ USB detection working"
echo "✅ Optimized for Pi 4"
echo "✅ Ready for Chromatic"
echo ""
echo "🔄 Reboot now to start PrismGB: sudo reboot"
echo ""