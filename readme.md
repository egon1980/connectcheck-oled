# ConnectCheck OLED Display 🖥️

![License](https://img.shields.io/badge/license-MIT-green)
![Python](https://img.shields.io/badge/python-3.7+-blue)
![Platform](https://img.shields.io/badge/platform-Raspberry%20Pi%205-orange)
![Status](https://img.shields.io/badge/status-stable-brightgreen)
---

## 🔍 Overview

ConnectCheck OLED Display is a lightweight Python application that provides real-time network connectivity monitoring on an OLED display connected to your Raspberry Pi 5. Monitor your network status, IP addresses, and connection quality at a glance.

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

  Note: de installer only works when the user Connectcheck is enabled

After installation and there is nog display:

Enable I2C Interface

```bash
sudo raspi-config
# Navigate to: Interface Options → I2C → Enable
```

And reboot

```bash
sudo reboot
```

#

---

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




---

**Made with ❤️ by the ConnectCheck Team**
