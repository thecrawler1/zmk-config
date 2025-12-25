#!/bin/bash

# Script to update firmware for totem keyboard parts (left, right, dongle) using Seeeduino XIAO UF2 flashing
# Usage: sudo ./update_firmware.sh left|right|dongle

set -e  # Exit on error

# Validate argument
if [ $# -ne 1 ] || ! [[ "$1" =~ ^(left|right|dongle)$ ]]; then
    echo "Usage: $0 left|right|dongle"
    exit 1
fi

PART="$1"
UF2_FILE="firmware/totem_${PART}-xiao_ble-zmk.uf2"

# Unzip firmware.zip if exists
if [ -f firmware.zip ]; then
    echo "Unzipping firmware.zip..."
    unzip -q firmware.zip -d firmware/
fi

# Check if UF2 file exists
if [ ! -f "$UF2_FILE" ]; then
    echo "Error: UF2 file not found: $UF2_FILE"
    echo "Ensure firmware.zip is in the root and contains the correct UF2 files."
    exit 1
fi

# Prompt user to connect and enter bootloader
echo "Connect the $PART part via USB and double-click reset to enter bootloader."
echo "Press Enter when ready."
read

# Wait for device (timeout after 30 attempts)
echo "Waiting for Seeeduino XIAO (/dev/sda)..."
ATTEMPTS=0
while ! fdisk -l | grep -q "Disk /dev/sda"; do
    if [ $ATTEMPTS -ge 30 ]; then
        echo "Error: Device not detected within 30 seconds. Check USB connection and bootloader entry."
        exit 1
    fi
    sleep 1
    ATTEMPTS=$((ATTEMPTS + 1))
done

echo "Device detected: /dev/sda"

# Create mount point
mkdir -p /mnt/xiao

# Mount
echo "Mounting..."
mount /dev/sda /mnt/xiao

# Copy UF2
echo "Flashing $UF2_FILE..."
cp "$UF2_FILE" /mnt/xiao/

# Sync to ensure write completes
sync

# Umount
echo "Unmounting..."
umount /mnt/xiao

echo "Flashing complete! Remove USB and wait for the $PART part to reboot."
