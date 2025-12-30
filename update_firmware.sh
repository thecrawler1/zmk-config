#!/bin/bash

# Script to update firmware for totem keyboard parts (left, right, dongle) using Seeeduino XIAO UF2 flashing
# Usage: sudo ./update_firmware.sh left|right|dongle

set -e  # Exit on error

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run with sudo to access device files."
    echo "Usage: sudo $0 left|right|dongle"
    exit 1
fi

# Validate argument
if [ $# -ne 1 ] || ! [[ "$1" =~ ^(left|right|dongle)$ ]]; then
    echo "Usage: $0 left|right|dongle"
    exit 1
fi

PART="$1"
UF2_FILE="firmware/totem_${PART}-xiao_ble-zmk.uf2"

# Move firmware.zip from Downloads if exists (always overwrite)
if [ -f ~/Downloads/firmware.zip ]; then
    echo "Moving firmware.zip from Downloads..."
    mv ~/Downloads/firmware.zip ./
fi

# Unzip firmware.zip if exists (auto-confirm overwrite)
if [ -f firmware.zip ]; then
    echo "Unzipping firmware.zip..."
    unzip -o -q firmware.zip -d firmware/
fi

# Check if UF2 file exists
if [ ! -f "$UF2_FILE" ]; then
    echo "Error: UF2 file not found: $UF2_FILE"
    echo "Ensure firmware.zip is in the root and contains the correct UF2 files."
    exit 1
fi

# Prompt user to connect and enter bootloader
echo "Connect the $PART part via USB and double-click reset to enter bootloader."
echo "The device should appear as a USB drive (usually /dev/sda or /dev/sdb)."
echo "Press Enter when ready."
read

# Wait for device (timeout after 60 attempts = 60 seconds)
echo "Waiting for Seeeduino XIAO to appear as USB drive..."
ATTEMPTS=0
DEVICE=""
while [ $ATTEMPTS -lt 60 ]; do
    # Check for common USB drive device names
    for dev in /dev/sd[a-z] /dev/mmcblk[0-9]; do
        if sudo fdisk -l "$dev" 2>/dev/null | grep -q "Disk $dev"; then
            DEVICE="$dev"
            break 2
        fi
    done
    sleep 1
    ATTEMPTS=$((ATTEMPTS + 1))
    if [ $((ATTEMPTS % 10)) -eq 0 ]; then
        echo "Still waiting... ($ATTEMPTS seconds)"
    fi
done

if [ -z "$DEVICE" ]; then
    echo "Error: No USB drive detected within 60 seconds."
    echo "Make sure to:"
    echo "1. Connect the $PART part via USB"
    echo "2. Double-click the reset button to enter bootloader mode"
    echo "3. The device should appear as a USB drive in your file manager"
    echo ""
    echo "Available block devices:"
    lsblk | grep -E "^(sd|mmc|nvme)" | head -10
    exit 1
fi

echo "Device detected: $DEVICE"

# Create mount point
mkdir -p /mnt/xiao

# Mount
echo "Mounting $DEVICE..."
sudo mount "$DEVICE" /mnt/xiao

# Copy UF2
echo "Flashing $UF2_FILE..."
sudo cp "$UF2_FILE" /mnt/xiao/

# Sync to ensure write completes
sync

# Umount
echo "Unmounting..."
sudo umount /mnt/xiao

echo "Flashing complete! Remove USB and wait for the $PART part to reboot."
