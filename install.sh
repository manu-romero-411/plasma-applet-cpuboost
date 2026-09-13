#!/bin/bash
# Installer for the CPU Boost Toggle Plasma applet.
# Run as your normal user (NOT with sudo) — it escalates only for the
# specific steps that need root.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GROUP_NAME="cpufreq"
UDEV_RULE_SRC="$SCRIPT_DIR/99-cpufreq-scaling.rules"
UDEV_RULE_DST="/etc/udev/rules.d/99-cpufreq-scaling.rules"
BIN_SRC="$SCRIPT_DIR/turbo-boost"
BIN_DST="/usr/local/bin/turbo-boost"
PLASMOID_ID="org.manuromero411.turboboost"

if [ "$(id -u)" -eq 0 ]; then
    echo "[ERROR] Do not run this script as root or with sudo."
    echo "        It will call sudo itself for the steps that need it."
    exit 1
fi

if [ ! -f "$BIN_SRC" ]; then
    echo "[ERROR] Cannot find $BIN_SRC. Run this script from inside the project directory."
    exit 1
fi

echo "==> Installing turbo-boost script to $BIN_DST"
sudo install -m 755 "$BIN_SRC" "$BIN_DST"

echo "==> Creating group '$GROUP_NAME' (if it doesn't exist yet)"
if ! getent group "$GROUP_NAME" > /dev/null; then
    sudo groupadd "$GROUP_NAME"
else
    echo "    Group '$GROUP_NAME' already exists, skipping."
fi

echo "==> Adding user '$USER' to group '$GROUP_NAME'"
sudo usermod -aG "$GROUP_NAME" "$USER"

echo "==> Installing udev rule to $UDEV_RULE_DST"
sudo install -m 644 "$UDEV_RULE_SRC" "$UDEV_RULE_DST"

echo "==> Reloading udev rules"
sudo udevadm control --reload
sudo udevadm trigger --subsystem-match=cpu --action=add

echo "==> Installing the Plasma applet"
if command -v kpackagetool6 &> /dev/null; then
    KPKG=kpackagetool6
elif command -v kpackagetool5 &> /dev/null; then
    KPKG=kpackagetool5
else
    echo "[ERROR] Neither kpackagetool6 nor kpackagetool5 was found. Cannot install the applet."
    exit 1
fi

if "$KPKG" -t Plasma/Applet -s "$PLASMOID_ID" &> /dev/null; then
    echo "    Applet already installed, upgrading."
    "$KPKG" -t Plasma/Applet -u "$SCRIPT_DIR"
else
    "$KPKG" -t Plasma/Applet -i "$SCRIPT_DIR"
fi

echo
echo "==> Install complete."
echo "IMPORTANT: log out and back in for the '$GROUP_NAME' group membership to take effect"
echo "(sysfs permissions are already correct, but your current login session isn't in the group yet)."
echo "Then add 'CPU Boost Toggle' to your panel via 'Add Widgets'."
