#!/bin/bash
# ---------------------------------------------
# Filename: run.sh
# Version: 1.0
# By: CSUBIRES <j3xuz_cobmetal88@hotmail.com>
# Created: 2024/08/12 08:36:01 by CSUBIRES
# Updated: 2025/02/12 08:36:01 by CSUBIRES
# Description: Script for configuration \
#	collection and backup compression.
# ---------------------------------------------

source utils.sh

#Variables globales
NAME_BACKUP="DEVELOPER"
USER_NAME="user"
EXPLORER="nemo"
DATESTR="$(date +%Y%m%dT%H%M%S)"

#Paths
FOLDER_TMP="/tmp/backup_logs" # "$(mktemp -d)"
FOLDER_OUT="/mnt/hgfs/DEVELOPER"
FOLDERS_LIST="$(pwd)/config/folders.list"
COMMAND_LIST="$(pwd)/config/command.list"
IGNORED_LIST="$(pwd)/config/ignore.list"
SECRET="/home/$USER_NAME/.local/share/.secret"

# Panel de ayuda
function helpPanel() {
	clear
	lg_prt "wtw" "\n" "BACKUP LINUX AUTO" "\n"
	lg_prt "wob" "Uso:" "./run.sh" "<Opción>"
	lg_prt "bwr" "\t-r, --collector" "Recopilación de configuraciones y comandos" "ROOT"
	lg_prt "bwr" "\t-c, --compress" "\tCompresión y Cifrado del backup" "ROOT"
	lg_prt "bwr" "\t-a, --all" "\tModo Auto" "ROOT"
	lg_prt "bw" "\t-h, --help" "\tMostrar ayuda"
	lg_prt "wc" "\n Ejemplos:\n" "\t./run.sh -r"
	lg_prt "c" "\t./run.sh --compress\n"
	exit 0
}

# Leer el listado de comandos, ejecutarlos y volcar la salida a archivos
function collector() {
	clear
	mkdir -p "$FOLDER_TMP"
	lg_prt "wtw" "\n" "RECOPILACIÓN DE CONFIGURACIONES Y COMANDOS" "\n\n"
	lg_prt "yw" "\n\n\t[▲] Recopilando información" "Espere..."
	counter=0
	while IFS= read -r cmd; do
		let counter++
		lg_prt "yw" " $counter" "\t$cmd"
		bash -c "$cmd" > "$FOLDER_TMP/$(echo "$cmd" | tr -cd '[:alnum:]._-').log" 2>&1
	done < "$COMMAND_LIST"
	lg_prt "gy" "\t[✔] Archivos de configuración guardados en " $FOLDER_TMP
}

# Comprimir y cifrar la colección
function compress() {
	clear
	chk_path "$FOLDER_TMP"
	[[ $? == 0 ]] && echo "TODO"
	lg_prt "wtw" "\n" "COMPRESIÓN Y CIFRADO DEL BACKUP" "\n\n"
	PHRASE="$(head $SECRET -n 3 | tail -1)"
	KEY="$(echo $PHRASE | base64 -d | sha256sum | head -c 32 | base64)"
	lg_prt "yw" " Fecha:" "\t$DATESTR"
	lg_prt "yw" " User:" "\t\t$USER_NAME"
	lg_prt "yw" " Backup for:" "\t$NAME_BACKUP"
	lg_prt "yw" " Folders list:" "\t$FOLDERS_LIST"
	lg_prt "yw" " Command list:" "\t$COMMAND_LIST"
	lg_prt "yw" " Ignored list:" "\t$IGNORED_LIST"
	lg_prt "yw" "\n\t[▲] Comprimiento." "Espere..."

	7z a -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on -mhe=on -xr!.git -xr@"${IGNORED_LIST}" -p"${KEY}" -t7z "${FOLDER_OUT}/${DATESTR}_${NAME_BACKUP}.bak" "$FOLDER_TMP" @"${FOLDERS_LIST}"

	# Cambiar propietario y grupo para poder borrar carpeta
	# chown "$USER_NAME:$USER_NAME" -R "$FOLDER_TMP"
	# chmod 666 "/mnt/hgfs/DEVELOPER/${DATESTR}_${NAME_BACKUP}.bak"
	sleep 2
	rm -rf "$FOLDER_TMP"
	lg_prt "g" "\t[✔] Archivo backup comprimido en \""${FOLDER_OUT}/${DATESTR}_${NAME_BACKUP}.bak"\""
	lg_prt "g" "\t[i] Check with: \"${KEY}\""
	# eval "$EXPLORER /tmp"
	exit 0
}

# Comprobar que se es usuario root y existen los listados
[[ "$(id -u)" != "0" ]] && lg_prt "r" "[✖] Es necesario tener permisos ROOT" && exit 1
chk_path $FOLDERS_LIST
[[ $? == 0 ]] && echo "TODO"
chk_path $COMMAND_LIST
[[ $? == 0 ]] && echo "TODO"

# Control o MENU
if [[ $1 ]]; then
	lg_prt "yw" "\n\t[▲] Estas en el directorio:" "$(pwd)"
	case "$1" in
		-r|--collector)	collector;;
		-c|--compress)	compress;;
		-a|--all)		collector && sleep 5 && compress;;
        -h|--help|*) 	helpPanel;;
	esac
	exit 0
else
	lg_prt "ryr" "[✖] Parametros insuficientes." "Usa --help"
fi

# a:			Modo "añadir" (add)
# -m0=lzma2:	Especifica el método de compresión.
# -mx=9:        Define el nivel de compresión. El valor 9 es el nivel máximo.
# -mfb=64:      Establece el tamaño del "fast bytes" para el algoritmo LZMA2.
# -md=32m:      Define el tamaño del diccionario de compresión.
# -ms=on:       Habilita la compresión sólida (solid).
# -mhe=on:      Habilita el cifrado de los encabezados del archivo.
# -xr!.git:     Excluye archivos o carpetas específicos.
# -p"${KEY}":   Especifica la contraseña (password) para cifrar el archivo comprimido.
# -t7z:        	Especifica el tipo de archivo comprimido.
