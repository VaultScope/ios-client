# VaultScope Client (iOS)

[![Platform: iOS 17+](https://img.shields.io/badge/Platform-iOS%2017%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift: 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Build Tool: xtool](https://img.shields.io/badge/Toolchain-xtool-purple.svg)](https://xtool.org)
[![License: Noncommercial](https://img.shields.io/badge/License-PolyForm%20Noncommercial%201.0.0-green.svg)](LICENSE)

A native, high-performance iOS application engineered for **VaultScope Cloud Customers**, built with **Swift 6**, **SwiftUI**, and [xtool](https://xtool.org). 

Manage high-performance cloud servers, bare-metal nodes, invoices, and support tickets with hardware-grade security directly from your iPhone or iPad.

---

## Highlights & Features

### 1. Obsidian Liquid Glass Aesthetic
- **True Obsidian Backdrop (`#030304`)**: Tailored for OLED Super Retina displays with deep blacks and ultra-low battery consumption.
- **Specular Glass Surfaces**: Translucent `.ultraThinMaterial` card surfaces with subtle rim gradients and glow highlights.
- **Official Brand Design System**: High-DPI icon crest branding (`logo-image.png`) with clean typography hierarchy.

### 2. Built-in Interactive SFTP Client
- **Direct Remote Server Access**: Connects to running cloud instances via SFTP credentials.
- **Path Navigation**: Breadcrumb directory navigation with instant search and filtering.
- **File Management**: Create files, create directories, view permissions, and delete remote files.
- **Integrated Code & Text Editor**: In-app full-screen monospace editor with "Save to Server" synchronization.
- **iOS Share Sheet Export**: AirDrop, share, or download remote server files directly to your device.

### 3. Hardware-Enforced Security & Biometrics
- **Apple Secure Enclave Storage**: Authentication JWT tokens and session secrets stored in hardware Keychain with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
- **Biometric Locking**: Face ID, Touch ID, and Optic ID biometric gates on app launch and resumption.
- **Automatic Passcode Fallback**: Seamless fallback to system device passcode on biometric lockout or user request.
- **Privacy Shield**: Immediate obsidian masking in the iOS App Switcher to prevent sensitive infrastructure telemetry exposure.

### 4. Cloud Infrastructure Management
- **Lifecycle Control**: Graceful ACPI reboot, hard reset, startup, graceful shutdown, and server termination safeguards.
- **Live Metrics**: Real-time CPU and RAM sparklines with 1-tap SSH connection string copying.
- **Instant Deployment**: Browse VPS, Dedicated Bare-Metal, and ODP edge containers with interactive datacenter selection and OS image provisioning.

### 5. Billing & Support
- **Itemized Invoices**: Track pending balances, paid invoices, and VAT breakdown.
- **Direct Engineer Support**: Multi-state ticket threads with live status tracking and reply composer.

---

## Project Structure

```text
User-App/
├── Package.swift               # Swift 6 package manifest (iOS 17+)
├── xtool.yml                   # xtool configuration, bundleID, iconPath, and infoPath
├── Info.plist                  # Privacy permissions & Face ID usage description
├── xtool.sh                    # Automated build, sign, and device deployment script
├── AppIcon.png                 # 1024x1024 master application icon
├── LICENSE                     # PolyForm Noncommercial License 1.0.0
├── Sources/
│   └── UserApp/
│       ├── UserAppApp.swift    # Application entry point
│       ├── RootView.swift      # TabView navigation & lock screen controller
│       ├── Theme/              # Obsidian Liquid Glass theme definitions
│       │   └── VaultTheme.swift
│       ├── Core/               # Core infrastructure, security & networking
│       │   ├── Security/       # Keychain, Biometrics, and PrivacyShield
│       │   └── Networking/     # Live VAMOS REST API client & session manager
│       ├── Models/             # Strongly-typed Sendable Swift models
│       ├── Repositories/       # Auth, Services, Billing, Tickets repositories
│       ├── Services/           # Reactive state container (AppState)
│       ├── Components/         # Reusable UI cards, pills, and sparklines
│       └── Views/              # Views (Dashboard, Services, SFTP, Invoices, Account)
└── Resources/                  # High-resolution logos and icons
```

---

## Installation & Deployment Guide

This repository includes [`xtool.sh`](xtool.sh), an automated command-line tool that orchestrates building, signing, and deploying directly to iOS hardware without needing macOS or Xcode.

### Prerequisites

1. **Linux / WSL2 or macOS**
2. **Swift 6 Toolchain**:
   ```bash
   curl -sSL https://download.swift.org/swiftly_installer.sh | bash
   swiftly install latest
   ```
3. **xtool**:
   Follow instructions at [xtool.org](https://xtool.org) to install the `xtool` binary.
4. **libimobiledevice & usbmuxd** (for USB device deployment):
   ```bash
   sudo apt-get update && sudo apt-get install -y usbmuxd libimobiledevice6 ideviceinstaller
   ```

---

### Using `xtool.sh`

The [`xtool.sh`](xtool.sh) helper streamlines the entire lifecycle:

#### 1. Validate Environment
Check that your toolchain, daemons, and connected devices are recognized:
```bash
./xtool.sh check
```

#### 2. Debug Build
Compile the Swift codebase:
```bash
./xtool.sh build
```

#### 3. Produce Signed IPA
Compile, embed entitlements, code-sign with your local provisioning profile, and generate `xtool/UserApp.ipa`:
```bash
./xtool.sh package
```

#### 4. Install onto Connected iPhone
Deploy the compiled and signed IPA to your device:
```bash
./xtool.sh install
# Or specify a target UDID:
./xtool.sh install 00008150-000269992144C01C
```

#### 5. One-Shot Build & Run Pipeline
Build, code-sign, and deploy in one automated step:
```bash
./xtool.sh run
```

---

### Deploying via WSL2 (Windows Host)

If you are developing inside Windows Subsystem for Linux (WSL2):

1. **Attach your iPhone from Windows PowerShell (Administrator)**:
   ```powershell
   usbipd list
   usbipd attach --wsl --busid <busid-of-iphone>
   ```
2. **In WSL2 terminal**:
   ```bash
   ./xtool.sh run
   ```
3. **First-time Trust**:
   On your iPhone, navigate to **Settings -> General -> VPN & Device Management**, tap your developer certificate, and select **Trust**.

---

## API Configuration

By default, the client communicates directly with the live VaultScope production gateway:
```text
https://api.vaultscope.de
```

To test against an internal development API or local staging server, navigate to the **Account** tab in the app, update the **API Endpoint URL**, and tap **Test Connection**.

---

## License

This project is licensed under the **PolyForm Noncommercial License 1.0.0**.

- **Permitted**: Personal use, server monitoring, academic research, education, security audits, and contributing back to VaultScope.
- **Prohibited**: Commercial exploitation, charging subscription fees, selling modified versions, or using as part of a commercial product without explicit written consent.

See the full [LICENSE](LICENSE) file for complete legal terms.
