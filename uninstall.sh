#!/bin/bash
# Uninstaller for the CPU Boost Toggle Plasma applet.
# Run as your normal user (NOT with sudo) — it escalates only for the
# specific steps that need root.

GROUP_NAME="cpufreq"
UDEV_RULE_DST="/etc/udev/rules.d/99-cpufreq-scaling.rules"
BIN_DST="/usr/local/bin/turbo-boost"
PLASMOID_ID="org.manuromero411.turboboost"

if [ "$(id -u)" -eq 0 ]; then
    echo "[ERROR] Do not run this script as root or with sudo."
    echo "        It will call sudo itself for the steps that need it."
    exit 1
fi

echo "==> Removing the Plasma applet"
if command -v kpackagetool6 &> /dev/null; then
    kpackagetool6 -t Plasma/Applet -r "$PLASMOID_ID" || echo "    (already removed or not found)"
elif command -v kpackagetool5 &> /dev/null; then
    kpackagetool5 -t Plasma/Applet -r "$PLASMOID_ID" || echo "    (already removed or not found)"
fi

echo "==> Removing udev rule"
sudo rm -f "$UDEV_RULE_DST"
sudo udevadm control --reload

echo "==> Removing $BIN_DST"
sudo rm -f "$BIN_DST"

read -p "Remove the '$GROUP_NAME' group too? [y/N] " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    sudo groupdel "$GROUP_NAME" || echo "[WARN] Could not remove the group (it may still be a user's primary group)."
fi

echo
echo "==> Uninstall complete."
echo "Note: scaling_max_freq permissions revert to root-only after your next reboot,"
echo "now that the udev rule is gone."
