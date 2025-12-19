#!/bin/bash

# ConnectCheck OLED Display Installer for Raspberry Pi (GitHub-ready, SSD1306)
# Run with: sudo bash install_connectcheck_oled.sh
# Supports SSD1306, auto I2C, clean init (no vertical line)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SERVICE_NAME="connectcheck-oled"
SCRIPT_DIR="/opt/connectcheck-oled"
SCRIPT_PATH="$SCRIPT_DIR/display.py"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}.service"

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Root check
if [[ $EUID -ne 0 ]]; then
    print_error "Please run as root (sudo)"
    exit 1
fi

# Raspberry Pi check
if ! grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
    print_warning "Not detected as Raspberry Pi. Continuing anyway..."
fi

print_status "Starting installation..."

# Update & install dependencies
apt update -y
apt install -y python3 python3-pip python3-venv i2c-tools python3-smbus python3-pil python3-psutil git

# Enable I2C automatically
print_status "Checking I2C interface..."
if ! grep -q "^dtparam=i2c_arm=on" /boot/config.txt; then
    echo "dtparam=i2c_arm=on" >> /boot/config.txt
    print_status "I2C enabled in /boot/config.txt. A reboot is required for I2C to be fully active."
else
    print_status "I2C already enabled in /boot/config.txt."
fi

# Load modules immediately
modprobe i2c-dev 2>/dev/null || true
modprobe i2c-bcm2835 2>/dev/null || true

# Check I2C bus
if ! i2cdetect -y 1 >/dev/null 2>&1; then
    print_warning "I2C bus not detected yet. Please reboot your Raspberry Pi to activate I2C."
else
    print_status "I2C bus detected."
fi

# Create virtual environment
print_status "Creating virtual environment..."
python3 -m venv /opt/oled_venv
source /opt/oled_venv/bin/activate
pip install --upgrade pip
pip install luma.oled pillow psutil

# Create script directory
mkdir -p "$SCRIPT_DIR"

# Create OLED Python script (SSD1306, clean init)
print_status "Creating display script..."
cat > "$SCRIPT_PATH" << 'EOF'
#!/usr/bin/env python3
import time, psutil, socket
from pathlib import Path
from luma.core.interface.serial import i2c
from luma.core.render import canvas
from luma.oled.device import ssd1306
from PIL import ImageFont

class OLEDDisplay:
    def __init__(self):
        try:
            self.serial = i2c(port=1, address=0x3C)
            self.device = ssd1306(self.serial)
            time.sleep(0.05)
            self.device.clear()
            time.sleep(0.05)
            self.device.clear()
            self.width = self.device.width
            self.height = self.device.height
        except Exception as e:
            print(f"Failed to init OLED: {e}")
            exit(1)

        self.font_small = ImageFont.load_default()
        self.font_large = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 12) \
            if Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf").exists() else ImageFont.load_default()

        self.scroll_text = "ConnectCheck Companion Streamdeck V3"
        self.scroll_pos = self.width
        self.scroll_speed = 1

    def get_ip_address(self):
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.settimeout(0.1)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except:
            return "No Network"

    def get_cpu_temp(self):
        try:
            with open('/sys/class/thermal/thermal_zone0/temp', 'r') as f:
                return int(f.read().strip()) / 1000.0
        except:
            return 0

    def draw_status_bar(self, draw, y, percentage, width=100):
        draw.rectangle([0, y, width, y+6], outline=255, fill=0)
        fill_width = int((percentage / 100.0) * width)
        if fill_width > 0:
            draw.rectangle([0, y, fill_width, y+6], outline=255, fill=255)

    def display_frame(self):
        with canvas(self.device) as draw:
            draw.rectangle([0,0,self.width,self.height], outline=0, fill=0)  # first frame full black

            ip = self.get_ip_address()
            cpu_temp = self.get_cpu_temp()
            cpu_percent = psutil.cpu_percent(interval=0.1)
            disk = psutil.disk_usage('/')
            disk_used_gb = disk.used / (1024**3)
            disk_total_gb = disk.total / (1024**3)

            draw.text((0, 0), f"IP: {ip}:8000", font=self.font_small, fill=255)
            draw.text((0, 10), f"CPU: {cpu_temp:.1f}°C {cpu_percent:.0f}%", font=self.font_small, fill=255)
            self.draw_status_bar(draw, 22, cpu_percent, self.width)
            draw.text((0, 32), f"Disk: {disk_used_gb:.1f}/{disk_total_gb:.1f}GB", font=self.font_small, fill=255)

            text_width = draw.textlength(self.scroll_text, font=self.font_small)
            if text_width > self.width:
                draw.text((self.scroll_pos, 44), self.scroll_text, font=self.font_small, fill=255)
                self.scroll_pos -= self.scroll_speed
                if self.scroll_pos < -text_width:
                    self.scroll_pos = self.width
            else:
                x = (self.width - text_width) // 2
                draw.text((x, 44), self.scroll_text, font=self.font_small, fill=255)

    def run(self):
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
ExecStart=/opt/oled_venv/bin/python3 $SCRIPT_PATH
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl start "$SERVICE_NAME"

print_status "Installation complete!"
i2cdetect -y 1 || print_warning "I2C detection failed. Display may not be connected."
systemctl status "$SERVICE_NAME" --no-pager -l || true

echo -e "${GREEN}=== Next Steps ===${NC}"
echo "1. Reboot your Raspberry Pi: sudo reboot"
echo "2. Check service status: sudo systemctl status $SERVICE_NAME"
echo "3. View logs: sudo journalctl -u $SERVICE_NAME -f"
