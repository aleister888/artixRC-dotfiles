#!/bin/sh
doas rm -rf /swap
doas btrfs subvolume create /swap
doas btrfs filesystem mkswapfile --size 4g --uuid clear /swap/swapfile
doas swapon /swap/swapfile
