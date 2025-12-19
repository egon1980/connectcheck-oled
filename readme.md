# ConnectCheck OLED Display 🖥️

![License](https://img.shields.io/badge/license-MIT-green)
![Python](https://img.shields.io/badge/python-3.7+-blue)
![Platform](https://img.shields.io/badge/platform-Raspberry%20Pi%205-orange)
![Status](https://img.shields.io/badge/status-stable-brightgreen)

> Real-time network connectivity monitoring on a crisp OLED display for your Raspberry Pi 5

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Hardware Requirements](#hardware-requirements)
- [Quick Start](#quick-start)
- [Installation](#installation)
  - [One-Command Installer](#one-command-installer)
  - [Manual Installation](#manual-installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Screenshots](#screenshots)
- [Contributing](#contributing)
- [License](#license)
- [Support](#support)

---

## 🔍 Overview

ConnectCheck OLED Display is a lightweight Python application that provides real-time network connectivity monitoring on an OLED display connected to your Raspberry Pi 5. Monitor your network status, IP addresses, and connection quality at a glance.

## ✨ Features

| Feature | Description |
|---------|-------------|
| **Real-time Monitoring** | Live updates every 5 seconds |
| **Multi-interface Support** | Monitor Ethernet, WiFi, and VPN connections |
| **Visual Indicators** | Color-coded status indicators and icons |
| **Auto-start** | Starts automatically on boot |
| **Low Resource** | Minimal CPU and memory usage |
| **Customizable** | Easy configuration via JSON file |

## 🔧 Hardware Requirements

| Component | Specification | Notes |
|-----------|---------------|-------|
| **Raspberry Pi** | **Model 5** | Required for optimal performance |
| **OLED Display** | **0.96" I2C SSD1306** | 128x64 pixels |
| **Connections** | **4 female-female jumper wires** | For I2C interface |

### Wiring Diagram

| OLED Pin | Raspberry Pi Pin | Description |
|----------|------------------|-------------|
| **VCC** | **Pin 1 (3.3V)** | Power supply |
| **GND** | **Pin 6 (GND)** | Ground |
| **SCL** | **Pin 5 (GPIO3)** | I2C clock |
| **SDA** | **Pin 3 (GPIO2)** | I2C data |

---

## 🚀 Quick Start

Get ConnectCheck running in under 2 minutes:

```bash
curl -sSL https://raw.githubusercontent.com/egon1980/connectcheck-oled/main/install_connectcheck_oled.sh | bash
```

---

## 📦 Installation

### One-Command Installer

The fastest way to install ConnectCheck OLED Display:

```bash
# Download and run the installer
wget -O - https://raw.githubusercontent.com/egon1980/connectcheck-oled/main/install_connectcheck_oled.sh | sudo bash
```

The installer will:
- ✅ Update your system packages
- ✅ Install all Python dependencies
- ✅ Enable I2C interface
- ✅ Configure auto-start on boot
- ✅ Start the service immediately

### Manual Installation

Prefer to install manually? Follow these steps:

#### 1. Update System

```bash
sudo apt update && sudo apt upgrade -y
```

#### 2. Enable I2C Interface

```bash
sudo raspi-config
# Navigate to: Interface Options → I2C → Enable
```

#### 3. Install Dependencies

```bash
sudo apt install -y python3-pip python3-smbus i2c-tools
```

#### 4. Clone Repository

```bash
git clone https://github.com/egon1980/connectcheck-oled.git
cd connectcheck-oled
```

#### 5. Install Python Requirements

```bash
pip3 install -r requirements.txt
```

#### 6. Install Service

```bash
sudo cp connectcheck-oled.service /etc/systemd/system/
sudo systemctl enable connectcheck-oled.service
sudo systemctl start connectcheck-oled.service
```

---

## 📖 Usage

### Basic Usage

After installation, ConnectCheck starts automatically. The display shows:

| Screen | Information Displayed |
|--------|----------------------|
| **Main** | Current IP, connection status, data usage |
| **Network** | SSID, signal strength, connection type |
| **System** | CPU temp, load average, uptime |

### Manual Control

```bash
# Check service status
sudo systemctl status connectcheck-oled

# Restart service
sudo systemctl restart connectcheck-oled

# View logs
sudo journalctl -u connectcheck-oled -f

# Stop service
sudo systemctl stop connectcheck-oled
```

---

## ⚙️ Configuration

Edit `/etc/connectcheck-oled/config.json`:

```json
{
  "display": {
    "refresh_rate": 5,
    "brightness": 255,
    "rotation": 0
  },
  "network": {
    "interfaces": ["eth0", "wlan0"],
    "ping_targets": ["8.8.8.8", "1.1.1.1"],
    "timeout": 3
  },
  "appearance": {
    "show_ip": true,
    "show_hostname": true,
    "show_temp": true,
    "theme": "dark"
  }
}
```

### Configuration Options

| Option | Values | Description |
|--------|--------|-------------|
| **refresh_rate** | 1-60 | Update interval in seconds |
| **brightness** | 0-255 | Display brightness level |
| **rotation** | 0, 90, 180, 270 | Display rotation angle |
| **interfaces** | Array | Network interfaces to monitor |
| **theme** | "dark", "light" | Color theme |

---

## 🔧 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| **Display not working** | Check I2C connections, run `i2cdetect -y 1` |
| **Service won't start** | Check logs: `sudo journalctl -u connectcheck-oled` |
| **Wrong IP shown** | Verify interface name in config.json |
| **Display too dim** | Increase brightness in configuration |
| **High CPU usage** | Increase refresh_rate in configuration |

### Diagnostic Commands

```bash
# Test I2C connection
sudo i2cdetect -y 1
# Should show address 3C or 3D

# Check Python dependencies
python3 -c "import smbus, PIL, board"

# Test display manually
python3 test_display.py
```

---

## 📸 Screenshots

### Main Dashboard
![Main Dashboard](screenshots/main_screen.png)
*Real-time network status and IP information*

### Network Details
![Network Details](screenshots/network_screen.png)
*Connection type, signal strength, and data usage*

### System Info
![System Info](screenshots/system_screen.png)
*System temperature, load, and uptime*

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Quick Contribution Steps

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2024 ConnectCheck OLED Display

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

---

## 📞 Support

Need help? We've got you covered:

| Resource | Link |
|----------|------|
| **📖 Documentation** | [Wiki](https://github.com/yourusername/connectcheck-oled/wiki) |
| **🐛 Issues** | [GitHub Issues](https://github.com/yourusername/connectcheck-oled/issues) |
| **💬 Discussions** | [GitHub Discussions](https://github.com/yourusername/connectcheck-oled/discussions) |
| **📧 Email** | support@connectcheck-oled.com |

### Community

- **Discord**: [Join our server](https://discord.gg/connectcheck)
- **Reddit**: [r/ConnectCheck](https://reddit.com/r/ConnectCheck)
- **Twitter**: [@ConnectCheck](https://twitter.com/ConnectCheck)

---

## ⭐ Show Your Support

If this project helped you, please give it a star on GitHub!

[![Star History Chart](https://api.star-history.com/svg?repos=yourusername/connectcheck-oled&type=Date)](https://star-history.com/#yourusername/connectcheck-oled&Date)

---

**Made with ❤️ by the ConnectCheck Team**
