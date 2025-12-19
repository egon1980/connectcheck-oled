#!/bin/bash

# ConnectCheck OLED Display Installer for Raspberry Pi
# One-command installer for system monitoring OLED display
# Run with: curl -sSL https://raw.githubusercontent.com/yourusername/connectcheck-oled/main/install.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
SERVICE_NAME="connectcheck-oled"
SCRIPT_DIR="/opt/connectcheck-oled"
SCRIPT_PATH="$SCRIPT_DIR/display.py"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}.service"

# Function to print status
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
    print_warning "This script is designed for Raspberry Pi. Continuing anyway..."
fi

print_status "Starting ConnectCheck OLED Display installation..."

# Update package list
print_status "Updating package list..."
apt update -y

# Install dependencies
print_status "Installing required packages..."
apt install -y python3 python3-pip i2c-tools python3-smbus python3-pil python3-psutil

# Install luma.oled (needs pip as no apt package available)
print_status "Installing luma.oled Python package..."
pip3 install --break-system-packages luma.oled

# Enable I2C interface
print_status "Enabling I2C interface..."
if ! grep -q "^dtparam=i2c_arm=on" /boot/config.txt; then
    echo "dtparam=i2c_arm=on" >> /boot/config.txt
fi

# Load I2C modules
modprobe i2c-dev 2>/dev/null || true
modprobe i2c-bcm2835 2>/dev/null || true

# Create script directory
print_status "Creating script directory..."
mkdir -p "$SCRIPT_DIR"

# Create OLED display Python script
print_status "Creating OLED display script..."
cat > "$SCRIPT_PATH" << 'EOF'
#!/usr/bin/env python3

import time
import psutil
import socket
from pathlib import Path
from luma.core.interface.serial import i2c
from luma.core.render import canvas
from luma.oled.device import ssd1306
from PIL import ImageFont

class OLEDDisplay:
    def __init__(self):
        # Initialize OLED display
        try:
            self.serial = i2c(port=1, address=0x3C)
            self.device = ssd1306(self.serial)
            self.width = self.device.width
            self.height = self.device.height
        except Exception as e:
            print(f"Failed to initialize OLED display: {e}")
            exit(1)
        
        # Load fonts
        self.font_small = ImageFont.load_default()
        self.font_large = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 12) if Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf").exists() else ImageFont.load_default()
        
        # Scroll text settings
        self.scroll_text = "ConnectCheck Companion Streamdeck V3"
        self.scroll_pos = self.width
        self.scroll_speed = 2
    
    def get_ip_address(self):
        """Get primary IP address"""
        try:
            # Create a dummy socket to determine IP
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.settimeout(0.1)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except:
            return "No Network"
    
    def get_cpu_temp(self):
        """Get CPU temperature"""
        try:
            with open('/sys/class/thermal/thermal_zone0/temp', 'r') as f:
                temp = int(f.read().strip()) / 1000.0
            return temp
        except:
            return 0
    
    def draw_status_bar(self, draw, y, percentage, width=100):
        """Draw a status bar"""
        # Background
        draw.rectangle([0, y, width, y + 6], outline=255, fill=0)
        # Fill
        fill_width = int((percentage / 100.0) * width)
        if fill_width > 0:
            draw.rectangle([0, y, fill_width, y + 6], outline=255, fill=255)
    
    def display_frame(self):
        """Display current system info"""
        with canvas(self.device) as draw:
            # Get system info
            ip = self.get_ip_address()
            cpu_temp = self.get_cpu_temp()
            cpu_percent = psutil.cpu_percent(interval=0.1)
            disk = psutil.disk_usage('/')
            disk_used_gb = disk.used / (1024**3)
            disk_total_gb = disk.total / (1024**3)
            
            # Line 1: IP with port
            draw.text((0, 0), f"IP: {ip}:8000", font=self.font_small, fill=255)
            
            # Line 2: CPU temp and load
            draw.text((0, 10), f"CPU: {cpu_temp:.1f}°C {cpu_percent:.0f}%", font=self.font_small, fill=255)
            
            # Line 3: CPU load bar
            self.draw_status_bar(draw, 22, cpu_percent, self.width)
            
            # Line 4: Disk usage
            draw.text((0, 32), f"Disk: {disk_used_gb:.1f}/{disk_total_gb:.1f}GB", font=self.font_small, fill=255)
            
            # Line 5-6: Scrolling text
            text_width = draw.textlength(self.scroll_text, font=self.font_small)
            if text_width > self.width:
                # Scroll text
                draw.text((self.scroll_pos, 44), self.scroll_text, font=self.font_small, fill=255)
                self.scroll_pos -= self.scroll_speed
                if self.scroll_pos < -text_width:
                    self.scroll_pos = self.width
            else:
                # Center static text
                x = (self.width - text_width) // 2
                draw.text((x, 44), self.scroll_text, font=self.font_small, fill=255)
    
    def run(self):
        """Main loop"""
        print("OLED display started. Press Ctrl+C to stop.")
        try:
            while True:
                self.display_frame()
                time.sleep(0.1)
        except KeyboardInterrupt:
            print("\nShutting down...")
            self.device.clear()

if __name__ == "__main__":
    display = OLEDDisplay()
    display.run()
EOF

chmod +x "$SCRIPT_PATH"

# Create systemd service
print_status "Creating systemd service..."
cat > "$SERVICE_PATH" << EOF
[Unit]
Description=ConnectCheck OLED Display Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$SCRIPT_DIR
ExecStart=/usr/bin/python3 $SCRIPT_PATH
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
print_status "Enabling and starting service..."
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl start "$SERVICE_NAME"

# Verify I2C devices
print_status "Detecting I2C devices..."
i2cdetect -y 1 || print_warning "I2C detection failed. Display may not be connected."

# Final status
echo
print_status "Installation complete!"
echo
echo -e "${GREEN}=== ConnectCheck OLED Display Status ===${NC}"
systemctl status "$SERVICE_NAME" --no-pager -l || true
echo
echo -e "${GREEN}=== Next Steps ===${NC}"
echo "1. Reboot your Raspberry Pi to ensure I2C is properly enabled:"
echo "   sudo reboot"
echo
echo "2. After reboot, check service status:"
echo "   sudo systemctl status $SERVICE_NAME"
echo
echo "3. View logs if needed:"
echo "   sudo journalctl -u $SERVICE_NAME -f"
echo
echo "4. If display is not working:"
echo "   - Verify OLED is connected to I2C pins (SDA: GPIO2, SCL: GPIO3)"
echo "   - Check I2C address: sudo i2cdetect -y 1"
echo "   - Common addresses: 0x3C, 0x3D"
echo
print_status "ConnectCheck OLED Display installation finished successfully!"