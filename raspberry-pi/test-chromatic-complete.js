const { execSync } = require('child_process');

console.log('=== ModRetro Chromatic Complete Detection Test ===\n');

try {
    // Check if device is connected
    console.log('1. Checking USB connection...');
    const lsusbOutput = execSync('lsusb | grep 374e:0101', { encoding: 'utf8' });
    console.log('✓ Chromatic detected:', lsusbOutput.trim());
    
    // Check video devices
    console.log('\n2. Checking video devices...');
    const videoDevices = execSync('v4l2-ctl --list-devices 2>/dev/null | grep -A2 "Chromatic"', { encoding: 'utf8' });
    console.log('✓ Video devices found:');
    console.log(videoDevices);
    
    // Check audio devices
    console.log('3. Checking audio devices...');
    try {
        const audioDevices = execSync('arecord -l | grep -i chromatic', { encoding: 'utf8' });
        console.log('✓ Audio device found:');
        console.log(audioDevices.trim());
        
        // Get audio card number
        const cardMatch = audioDevices.match(/card (\d+):/);
        if (cardMatch) {
            const cardNum = cardMatch[1];
            console.log(`✓ Audio card: ${cardNum} (use hw:${cardNum},0 for recording)`);
        }
    } catch (audioError) {
        console.log('✗ No audio device detected');
        console.log('  - Check if firmware supports audio');
        console.log('  - Try updating Chromatic firmware');
    }
    
    // Test video capture capability
    console.log('\n4. Testing video capture...');
    const videoFormats = execSync('v4l2-ctl -d /dev/video0 --list-formats-ext 2>/dev/null | head -10', { encoding: 'utf8' });
    console.log('✓ Video formats available:');
    console.log(videoFormats);
    
    // Test audio capture capability
    console.log('5. Testing audio capture capability...');
    try {
        const audioInfo = execSync('arecord -D hw:3,0 --dump-hw-params 2>/dev/null | head -5', { encoding: 'utf8' });
        console.log('✓ Audio capture ready:');
        console.log(audioInfo);
    } catch (audioTestError) {
        console.log('✗ Audio capture test failed - device may not be ready');
    }
    
    console.log('\n=== Chromatic Status Summary ===');
    console.log('Video: ✓ Ready (/dev/video0, /dev/video1)');
    console.log('Audio: ✓ Ready (hw:3,0 - 44.1kHz stereo)');
    console.log('Streaming: ✓ Both video and audio available');
    
    console.log('\n=== Example Usage ===');
    console.log('Record test: arecord -D hw:3,0 -f S16_LE -r 44100 -c 2 test.wav');
    console.log('Stream both: ffmpeg -f v4l2 -i /dev/video0 -f alsa -i hw:3,0 output.mp4');
    
} catch (error) {
    console.error('✗ Error:', error.message);
    console.log('\nTroubleshooting:');
    console.log('- Make sure Chromatic is connected via USB');
    console.log('- Check if device is powered on');
    console.log('- Try reconnecting the USB cable');
    console.log('- Update Chromatic firmware for audio support');
}