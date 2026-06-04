#!/usr/bin/env bash

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

# Variables globales
counter=0
total_url=0
regex='^(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]\.[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]$'

trap ctrl_c INT

function ctrl_c(){
	echo -e "\n${redColour}[!] Saliendo con interrupción${endColour}"
	exit 1
}

clear

if test -f "bookmarks.html"; then
	grep -Eoi '<A [^>]+>' bookmarks.html | grep -Eo 'HREF="[^\"]+"' | grep -Eo '(http|https)://[^/"]+' | sed -r 's/tp:+/tps:/g' > bookmarks_urls.txt
	echo -ne "\n\t${yellowColour}[!] Iniciando busqueda de enlaces que no soportan HTTPS o estan caidos${endColour}\n\n"
	total_url="$(cat bookmarks_urls.txt | wc -l)"
	touch bookmarks_fail_urls.txt

	while read -r line; do

		let res=0
		curl "$line" -s -f -o /dev/null || let res=1
		let counter+=1
		echo -ne "${blueColour} [$counter/$total_url]${endColour} "

		if [[ $line =~ $regex ]]; then
			if [  "$(echo $res)" != "0"  ]; then
				echo -ne "${yellowColour}$?${endColour}\t${redColour}${line:0:70}${endColour}\n"
				echo "$line" >> bookmarks_fail_urls.txt
			else
				echo -ne "${yellowColour}$?${endColour}\t${greenColour}${line:0:70}${endColour}\n"
			fi
		else
			echo -ne "${yellowColour}n/a${endColour}\t${redColour}$line no es una url valida${endColour}\n"
		fi

	done < 'bookmarks_urls.txt'

	fail_urls="$(cat bookmarks_fail_urls.txt | wc -l)"
	echo -ne "\n\n\t${greenColour}Tarea finalizada${endColour}"
	echo -ne "\n\n\t${redColour}[!] Número de URLs fallidas ${fail_urls}${endColour}"
	echo -ne "\n\t${yellowColour}[!] URLs fallidas guardadas en bookmarks_fail_urls.txt${endColour}\n\n"
	exit 0
else
	echo -ne "\n\n\t${redColour}[!] El archivo \"bookmarks.html\" no existe en el actual directorio $(pwd)${endColour}\n\n"
	exit 1
fi
