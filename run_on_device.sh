#!/usr/bin/env bash
set -e

# Ensure usbmuxd is running
systemctl start usbmuxd 2>/dev/null || usbmuxd -D 2>/dev/null || true

# Deploy to connected device
cd "$(dirname "$0")"
echo "Building VaultScope Client app..."
xtool dev build --sign --ipa "$@"

echo "Installing to connected iPhone..."
ideviceinstaller install xtool/UserApp.ipa
echo "VaultScope successfully installed on Tony's iPhone!"
echo "If this is the first install, open Settings -> General -> VPN & Device Management to trust the developer certificate, then tap VaultScope on your Home Screen."
