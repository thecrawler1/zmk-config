#!/bin/bash

set -e

if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run with sudo to access device files."
    echo "Usage: sudo $0 left|right|dongle"
    exit 1
fi

if [ $# -ne 1 ] || ! [[ "$1" =~ ^(left|right|dongle)$ ]]; then
    echo "Usage: $0 left|right|dongle"
    exit 1
fi

PART="$1"
UF2_FILE="firmware/totem_${PART}-xiao_ble-zmk.uf2"

if [ -f ~/Downloads/firmware.zip ]; then
    echo "Moving firmware.zip from Downloads..."
    mv ~/Downloads/firmware.zip ./
fi

if [ -f firmware.zip ]; then
    echo "Unzipping firmware.zip..."
    unzip -o -q firmware.zip -d firmware/
fi

if [ ! -f "$UF2_FILE" ]; then
    if command -v gh &> /dev/null; then
        echo "Attempting to download latest firmware from GitHub..."
        
        GH_EXEC="gh"
        if [ -n "$SUDO_USER" ]; then
            GH_EXEC="sudo -u $SUDO_USER gh"
        fi
        
        echo "Fetching latest successful build..."
        REPO="thecrawler1/zmk-config"
        RUN_ID=$($GH_EXEC run list --repo "$REPO" --workflow "build.yml" --status success --limit 1 --json databaseId --jq '.[0].databaseId')
        
        if [ -n "$RUN_ID" ]; then
            echo "Downloading firmware from run ID: $RUN_ID..."
            $GH_EXEC run download "$RUN_ID" --repo "$REPO" -n firmware --dir firmware
        else
            echo "Warning: No successful build found on GitHub."
        fi
    fi
fi

if [ ! -f "$UF2_FILE" ]; then
    echo "Error: UF2 file not found: $UF2_FILE"
    echo "Ensure firmware.zip is in the root and contains the correct UF2 files."
    exit 1
fi

echo "Connect the $PART part via USB and double-click reset to enter bootloader."
echo "The device should appear as a USB drive (usually /dev/sda or /dev/sdb)."
echo "Press Enter when ready."
read

echo "Waiting for Seeeduino XIAO to appear as USB drive..."
ATTEMPTS=0
DEVICE=""
while [ $ATTEMPTS -lt 60 ]; do
    # Safer detection using lsblk (avoids blocking fdisk calls on bad devices)
    # Looks for a USB disk that is NOT the boot drive
    NEW_DEVICE=$(lsblk -d -n -o NAME,TRAN,RM | grep "usb" | awk '{print "/dev/" $1}' | head -n 1)
    
    if [ -n "$NEW_DEVICE" ]; then
        DEVICE="$NEW_DEVICE"
        break
    fi
    
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

mkdir -p /mnt/xiao

echo "Mounting $DEVICE..."
# Use -o flush to write data immediately (safer for removable media)
# Use -o uid=$UID if possible, but sudo mount usually makes it root owned.
sudo mount -o flush "$DEVICE" /mnt/xiao

echo "Flashing $UF2_FILE..."
# cp may return error if device reboots immediately (which is expected for UF2)
if sudo cp "$UF2_FILE" /mnt/xiao/; then
    echo "Firmware copied successfully."
else
    echo "Warning: Copy command returned error (likely device rebooted early). This is normal for UF2."
fi

# SKIP SYNC: The device reboots immediately after receiving the file.
# Syncing causes the kernel to hang waiting for a device that is gone.
# sync

echo "Unmounting..."
# Use lazy unmount (-l) because the device is likely already physically disconnected/rebooting
sudo umount -l /mnt/xiao 2>/dev/null || true

echo "Flashing complete! The $PART part should be rebooting now."
