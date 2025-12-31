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

# Variables globales
DICTIONARY="/media/user/EXTBOOT/dic/text/name_wifis.txt"
HANDSHAKE_FOLDER="/media/user/EXTBOOT/wifi/handshake"
counter=0
total_handshakes=0

trap ctrl_c INT

function ctrl_c(){
	echo -e "\n${redColour}[!] Saliendo con interrupción${endColour}"
	exit 1
}

clear

if test -f "$DICTIONARY"; then
	if [ -d "$HANDSHAKE_FOLDER" ]; then
    	find "$HANDSHAKE_FOLDER" -name "*.cap" > handshakes_list.txt    	
    	total_handshakes="$(cat handshakes_list.txt | wc -l)"
    	total_dictionary="$(cat "$DICTIONARY" | wc -l)"
    	
    	echo -ne "\n\t${yellowColour}Diccionario: ${endColour}${grayColour}$DICTIONARY${endColour}"
    	echo -ne "\n\t${yellowColour}Directorio handshakes: ${endColour}${grayColour}$HANDSHAKE_FOLDER${endColour}"
    	echo -ne "\n\t${yellowColour}Número de handshakes: ${endColour}${grayColour}$total_handshakes${endColour}"
    	echo -ne "\n\t${yellowColour}Elementos del diccionario: ${endColour}${grayColour}$total_dictionary${endColour}\n"
    	
    	while read -r line; do
    		let counter+=1
			echo -ne "\n${blueColour} [$counter/$total_handshakes]${endColour} "
			echo -ne "\t${yellowColour}aircrack-ng ${endColour}${purpleColour}-w $DICTIONARY${endColour} ${blueColour}$line${endColour}\n"
			aircrack-ng -w $DICTIONARY $line
			
		done < 'handshakes_list.txt'
		
		echo -ne "\n\n\t${greenColour}Tarea finalizada${endColour}"
		echo -ne "\n\n\t${greenColour}TODO: Mostrar contraseñas encontradas${endColour}\n\n"
		exit 0
    else
    	echo -ne "\n\n\t${redColour}[!] El directorio de handshakes \"$HANDSHAKE_FOLDER\" no existe${endColour}\n\n"
    	exit 1
    fi
else
	echo -ne "\n\n\t${redColour}[!] El diccionario \"$DICTIONARY\" no existe${endColour}\n\n"
    exit 1
fi
