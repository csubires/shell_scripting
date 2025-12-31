#!/bin/bash

namewifi=$1
datawifi=$2

dict1=/media/user/EXTBOOT/WIFI/dics/wpa-probable.txt
dict2=/media/user/EXTBOOT/WIFI/dics/español.txt
dict3=/media/user/EXTBOOT/WIFI/dics/mydic.txt
pathWPAraw=/media/user/EXTBOOT/WIFI/handshake/john/${namewifi}.txt
#pathWPAir=/media/user/EXTBOOT/WIFI/handshake/WLN_PELUSA-00-1A-2B-05-01-9C.cap

echo
echo WPA File Path: ${pathWPAraw}
echo
#aircrack-ng -a 2 -e ASDF $pathWPAir -w $dict1

echo Dictionary ${dict1}
john --wordlist=$dict1 $pathWPAraw
echo
echo Dictionary ${dict2}
john --wordlist=$dict2 $pathWPAraw
echo
#echo Dictionary ${dict3}
#john --wordlist=$dict3 $pathWPAraw
