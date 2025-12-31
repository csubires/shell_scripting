#!/bin/bash --
# ---------------------------------------------
# Filename: orderFiles.sh
# Version: 1.0
# By: CSUBIRES <j3xuz_cobmetal88@hotmail.com>
# Created: 2024/08/12 07:43:24 by CSUBIRES
# Updated: 2024/08/12 07:43:24 by CSUBIRES
# Description: Multi-functional script for \
# 	multimedia file handling.
# sudo apt install fdupes
# ---------------------------------------------

source utils.sh

# Variables globales
DIR="/mnt/hgfs/COMPRESS/"	# Carpeta media
[[ $# -eq 3 ]] && DIR="$3"

# Generar string aleatorios
randpw() { < /dev/urandom tr -dc a-z-0-9 | head -c${1:-16};echo; }

# Panel de ayuda
function helpPanel() {
	clear
	lg_prt "wy" "Path:" "$DIR"
	lg_prt "wtw" "\n" "ORDER FILES" "\n"
	lg_prt "wobv" "Uso:" "./orderFiles.sh" "<Opción>" "<Modo>"
	lg_prt "y" "\nRENOMBRADO"
	lg_prt "bw" "\t-r, --renaming" "\tRenombrar archivos masivamente"
	lg_prt "vw" "\t\trnd_num" "\tRenombrar con números aleatorios"
	lg_prt "vw" "\t\tupper" "\t\tRenombrar pasando a mayúsculas"
	lg_prt "vw" "\t\trnd_str" "\tRenombrar con cadenas aleatorias"
	lg_prt "vw" "\t\tcapi" "\t\tRenombrar pasando a capitalize"
	lg_prt "vw" "\t\talfa" "\t\tEliminar caracteres no alfanumericos"
	lg_prt "byw" "\t-z, --rmstring" "string" "Eliminar \"string\" del nombre de los archivos"
	lg_prt "y" "\nEXTRA"
	lg_prt "bw" "\t-f, --findu" "\tBuscar archivos duplicados"
	lg_prt "bw" "\t-s, --sort" "\tAgrupar archivos en carpetas ordenadas alfabéticamente"
	lg_prt "wc" "\n Ejemplos:\n" "\t./orderFiles.sh -r rnd"
	lg_prt "c" "\t./orderFiles.sh -s"
	exit 0
}

# Clasificar archivos en carpetas por orden alfabético
function sortAlphaFolder() {
	clear
	lg_prt "yw" "\n\t[▲] Estas en el directorio:" "$(pwd)"
	lg_prt "wtw" "\n" "CREANDO CARPETAS DE ORDENACIÓN ALFABÉTICA" "\n"
	shopt -s nullglob

	for name in *; do
		[[ -d $name ]] && [[ $name == ? ]] && continue
		first=${name:0:1}
		destdir=${first^}
		lg_prt "y" "\n\t[+] Creando carpeta \"$destdir\"\n"
		mkdir -p -- "$destdir" &&
		mv -v -- "$name" "$destdir"
	done
}

# Renombrar archivos masivamente con nombres aleatorios
function renameFiles() {
	clear
	lg_prt "yw" "\n\t[▲] Estas en el directorio:" "$(pwd)"
	lg_prt "wtw" "\n" "RENOMBRAR ARCHIVOS ($1))" "\n"
	[[ $1 ]] && return 1
	# Pedir confirmación
	read -p "¿Estas seguro? (S/N): " -n 1 -r
	[[ $REPLY =~ ^[Ss]$ ]] && lg_prt "w" " \n" || return 0

	for file in $(find . -type f); do
								# /.git/hooks/pre-applypatch.sample
		folder="${file%/*}"		# /.git/hooks
		full="${file##*/}"		# pre-applypatch.sample
		full=$($full | tr '[:upper:]' '[:lower:]')
		ext="${full##*.}"		# .sample
		name="${full%.*}"		# pre-applypatch

		case "$1" in
			rnd_num)
				new_name="$(shuf -i 1-100000 -n 1)_$(shuf -i 1-100000 -n 1)" ;;
			upper)
				new_name=$($name | tr '[:lower:]' '[:upper:]') ;;
			rnd_str)
				new_name="$(randpw)" ;;
			capi)
				# Capitalize
				new_name=$($new_name | awk '{if (NF) $1=toupper(substr($1,1,1)) tolower(substr($1,2));}1') ;;
			alfa)
				new_name=$($name | tr -cd '[:alnum:] _')	# Eliminar no alfanumerico
				# $new_name=$($new_name | sed 's/_/ /g')	# Eliminar guión bajo _
				new_name=$($new_name | tr ' ' '_')			# Cambiar espacios por guiones bajos _
				;;
			*)
				lg_prt "ry" "[✖] Parametro no válido." "Usa --help" ;;
		esac

		lg_prt "oyg" "\n\t$name" " > " "$new_name"
		mv -- "$file" "$new_base.$ext"
	done
}

# Encontrar archivos duplicados
function findDuple(){
	clear
	lg_prt "yw" "\n\t[▲] Estas en el directorio:" "$(pwd)"
	lg_prt "wtw" "\n" "BUSCAR ARCHIVOS DUPLICADOS" "\n"
	fdupes -S -r .

	read -p "¿Quieres eliminar los archivos duplicados? (S/N): " -n 1 -r
	[[ $REPLY =~ ^[Ss]$ ]] && lg_prt "w" " \n"  || return 0
	fdupes -S -drN .
}

# Eliminar subcadena del nombre de los archivos
function removeString() {
	clear
	lg_prt "yw" "\n\t[▲] Estas en el directorio:" "$(pwd)"
	lg_prt "w" "Escribe el string a eliminar:"
	read varname
	lg_prt "wtw" "\n" "ELIMINAR \"SUBSTRING ($varname)\" DEL NOMBRE DE LOS ARCHIVOS" "\n"
	# Pedir confirmación
	read -p "¿Estas seguro? (S/N): " -n 1 -r
	[[ $REPLY =~ ^[Ss]$ ]] && lg_prt "w" " \n"  || return 0

	find . -name "*$varname*" | sed -e "p;s/$varname//" | xargs -n2 mv
}

# Ir a la carpeta
if [ -d "$DIR" ]; then
	cd "$DIR"
else
	lg_prt "ryr" "[▲] Carpeta de archivos media \"" $DIR "\"no disponible"
	exit 1
fi

# Control o MENU
if [[ $1 ]]; then
	lg_prt "gy" "Ruta: $DIR, Opción: $1"
	case "$1" in
		-r|--renaming) 	[[ $2 ]] && renameFiles $2;;
		-f|--findu) 	findDuple;;
		-s|--sort)	 	sortAlphaFolder;;
		-z|--rmstring) 	[[ $2 ]] && removeString $2;;
        -h|--help|*) 	helpPanel;;
	esac
	lg_prt "g" "\n[✔] Tarea finalizada"
	exit 0
else
	helpPanel
fi
