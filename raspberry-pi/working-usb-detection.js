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
          
          // If specific vendor/product requested, filter
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
      
      // Check for new devices (added)
      for (const device of currentDevices) {
        const key = `${device.vendorId}:${device.productId}:${device.deviceAddress}`;
        if (!this.knownDevices.has(key)) {
          this.emit('add', device);
        }
      }
      
      // Check for removed devices
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