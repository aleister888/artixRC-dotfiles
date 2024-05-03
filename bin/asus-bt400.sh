#!/bin/sh

# Script para instalar los drivers de:
# https://www.asus.com/networking-iot-servers/adapters/all-series/usbbt400/

curl 'https://dlcdnets.asus.com/pub/ASUS/wireless/USB-BT400/DR_USB_BT400_1201710_Windows.zip' \
	-o /tmp/bt400-driver.zip

usbid=$(lsusb | grep BCM20702A0 | grep -oE '....:....')

atool /tmp/bt400-driver.zip -X /tmp/windows_driver
cd /tmp/windows_driver/Win10_USB-BT400_DRIVERS/Win10_USB-BT400_Driver_Package/64
doas mkdir -p /lib/firmware/brcm/
doas hex2hcd BCM20702A1_001.002.014.1443.1467.hex -o /lib/firmware/brcm/BCM20702A1-0b05-17cb.hcd
