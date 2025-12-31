#!/bin/bash

sudo ip link set dev wlxe894f61520d0 down
sudo ip link set dev wlxe894f61520d0 name wlan0
sudo ip link set dev wlan0 up
sudo iwlist wlan0 scan | grep 'WLAN_BA'
sudo iwconfig wlan0 essid 'WLAN_BA'
sudo wpa_supplicant -iwlan0 -c/etc/wpa_supplicant/ssid.conf
sudo dhclient wlan0
# sudo wpa_passphrase WLAN_BA router5361Blanco
