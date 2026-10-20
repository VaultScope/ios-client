#!/usr/bin/env bash
# ==============================================================================
# VaultScope Client iOS - Build & Deployment Utility (xtool.sh)
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="VaultScope Client"
IPA_PATH="$SCRIPT_DIR/xtool/UserApp.ipa"

print_header() {
    echo "========================================================"
    echo "  $APP_NAME - Build & Deployment Manager"
    echo "========================================================"
}

check_prereqs() {
    local missing=0
    if ! command -v xtool &>/dev/null; then
        echo "[ERROR] 'xtool' is not found in PATH. Please install xtool."
        missing=1
    fi
    if ! command -v swift &>/dev/null; then
        echo "[ERROR] 'swift' toolchain is not found in PATH."
        missing=1
    fi
    if ! command -v ideviceinstaller &>/dev/null; then
        echo "[WARNING] 'ideviceinstaller' is not installed. Required for device deployments."
    fi
    if [ "$missing" -ne 0 ]; then
        exit 1
    fi
}

start_usbmuxd() {
    echo "[INFO] Ensuring usbmuxd daemon is active..."
    if command -v systemctl &>/dev/null && systemctl is-active --quiet usbmuxd 2>/dev/null; then
        echo "[INFO] usbmuxd service is active."
    else
        systemctl start usbmuxd 2>/dev/null || usbmuxd -D 2>/dev/null || true
    fi
}

cmd_build() {
    print_header
    check_prereqs
    echo "[INFO] Compiling $APP_NAME for iOS..."
    xtool dev build
    echo "[SUCCESS] Build finished successfully."
}

cmd_package() {
    print_header
    check_prereqs
    echo "[INFO] Building and signing $APP_NAME (.ipa)..."
    xtool dev build --sign --ipa
    echo "[SUCCESS] Packaged: $IPA_PATH"
}

cmd_install() {
    print_header
    check_prereqs
    start_usbmuxd

    if [ ! -f "$IPA_PATH" ]; then
        echo "[INFO] IPA not found. Building signed package first..."
        cmd_package
    fi

    local target_udid="$1"
    if [ -n "$target_udid" ]; then
        echo "[INFO] Deploying to target UDID: $target_udid..."
        xtool install --udid "$target_udid" "$IPA_PATH"
    else
        echo "[INFO] Deploying to connected iOS device..."
        xtool install "$IPA_PATH"
    fi
    echo "[SUCCESS] $APP_NAME successfully installed on device!"
}

cmd_run() {
    print_header
    check_prereqs
    start_usbmuxd
    echo "[INFO] Running full build, sign, and install pipeline..."
    xtool dev build --sign --ipa
    if [ -n "$1" ]; then
        xtool install --udid "$1" "$IPA_PATH"
    else
        xtool install "$IPA_PATH"
    fi
    echo "[SUCCESS] $APP_NAME deployed to device."
}

cmd_check() {
    print_header
    echo "Checking build and deployment environment:"
    echo " - xtool:             $(command -v xtool 2>/dev/null || echo 'NOT FOUND')"
    echo " - swift:             $(command -v swift 2>/dev/null || echo 'NOT FOUND')"
    echo " - ideviceinstaller:  $(command -v ideviceinstaller 2>/dev/null || echo 'NOT FOUND')"
    echo " - idevice_id:        $(command -v idevice_id 2>/dev/null || echo 'NOT FOUND')"
    echo " - usbmuxd:           $(command -v usbmuxd 2>/dev/null || echo 'NOT FOUND')"
    echo ""
    echo "Connected Devices:"
    if command -v idevice_id &>/dev/null; then
        idevice_id -l || echo "No device detected via usbmuxd."
    fi
}

cmd_help() {
    print_header
    echo "Usage: ./xtool.sh <command> [arguments]"
    echo ""
    echo "Commands:"
    echo "  build               Compile the Swift package for debugging"
    echo "  package             Compile, code-sign, and produce UserApp.ipa"
    echo "  install [udid]      Install the existing IPA onto connected device"
    echo "  run [udid]          Complete pipeline: build, sign, and deploy"
    echo "  check               Validate toolchain prerequisites and list devices"
    echo "  help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./xtool.sh run"
    echo "  ./xtool.sh install 00008150-000269992144C01C"
}

case "${1:-run}" in
    build)
        cmd_build
        ;;
    package)
        cmd_package
        ;;
    install)
        cmd_install "$2"
        ;;
    run)
        cmd_run "$2"
        ;;
    check)
        cmd_check
        ;;
    help|--help|-h)
        cmd_help
        ;;
    *)
        echo "[ERROR] Unknown command '$1'"
        cmd_help
        exit 1
        ;;
esac
