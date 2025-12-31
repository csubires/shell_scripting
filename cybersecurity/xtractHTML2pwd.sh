#!/bin/bash

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

# Se ejecuta al pulsar Ctrl+C
trap ctrl_c INT

function ctrl_c(){
	echo -e "\n${redColour}[!]Saliendo con interrupción${endColour}"
	exit 1
}

#find . -name "*.html" -exec html2text {} + | sed -n '/CONTRASEÑA/,/BIOS/p' | awk 'NF == 3' >> password.txt
#find . -name "*.html" -exec html2text {} + | sed -n '/CONTRASEÑA/,/BIOS/p' | awk 'NF >= 2' >> password.txt

ls "/home/user/Documentos/box/MyScripts/host" > htmlist.txt

while read line; do
	echo "/home/user/Documentos/box/MyScripts/host/html/$line"
	html2text "/home/user/Documentos/box/MyScripts/host/html/$line" | sed -n '/CONTRASEÑA/,/BIOS/p' | awk 'NF == 3' >> password.txt
done < "/home/user/Documentos/box/MyScripts/host/html/htmlist.txt"

cat password.txt | awk 'NF==3' | awk '{print $2 "\t\t\t" $3}' | sort | uniq > credentials.txt
cat -b credentials.txt 