#!/usr/bin/env bash
# ---------------------------------------------
# Filename: media_tools.sh
# Version: 1.0
# By: CSUBIRES <cjesuma@proton.me>
# Created: 2024/08/12 07:43:24 by CSUBIRES
# Updated: 2024/08/12 07:43:24 by CSUBIRES
# Description: Multi-functional script for \
# 	multimedia file handling.
# ---------------------------------------------

. utils/color.sh
. utils/menu.sh
. utils/utils.sh

# Variables globales
DIR="/mnt/hgfs/COMPRESS/"	# Carpeta media
[[ $# -eq 3 ]] && DIR="$3"
chk_path "$DIR"

# Generar string aleatorios
randpw() { < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-16};echo; }

# Ejecuta los distintos modos de compresión
function media_compress() {
	lg_prt "yw" "\n\t[▲] Estas en el directorio:" "$(pwd)"
	lg_prt "wtw" "\n" "COMPRIMIR $1" "\n"
	# Pedir confirmación
	read -p "¿Estas seguro? (S/N): " -n 1 -r
	[[ $REPLY =~ ^[Ss]$ ]] && lg_prt "w" " \n" || exit 0
	init_size=$(du -bsh | awk '{print $1}') # Tamaño inicial de la carpeta

    case "$1" in
        img)
            find . -type f -iregex ".*\.jpg\|.*\.jpeg\|.*\.png\|.*\.bmp" -exec mogrify -verbose -quality 70 {} + ;;
        mp4)
            find . -type f \( -iname \*.mp4 \) -print0|sed -e "s/.mp4//g"| while read -d $'\0' file; do
            	ffmpeg -y -i "$file.mp4" -strict -2 -c:a copy -c:v libx264 -preset fast -crf 28 -qphist -tune stillimage "$file.cmp.mp4" < /dev/null;
            done ;;
        avi)
            find . -type f \( -iname \*.avi \) -print0|sed -e "s/.avi//g"| while read -d $'\0' file; do
            	ffmpeg -y -i "$file.avi" -strict -2 -c:a copy -c:v libx264 -preset fast -crf 28 -qphist -tune stillimage "$file.cmp.avi" < /dev/null;
            done ;;
         mov)
			find . -type f \( -iname \*.mov \) -print0|sed -e "s/.mov//g"| while read -d $'\0' file; do
				ffmpeg -y -i "$file" -strict -2 -c:a copy -c:v libx264 -preset fast -crf 28 -qphist -tune stillimage "$file.cmp.mov" < /dev/null;
			done ;;
         mp3)
			lame --quiet -vbr-new -V 0 ./*.mp3 ;;
        *)
            lg_prt "ry" "[✖] Parametro no válido." "Usa --help" ;;
    esac

	# TODO ES posible que haya un error según el uppercase de la extension.. si es .MOV .. es necesario quitarlo del $file.mov

	end_size=$(du -bsh | awk '{print $1}') # Tamaño final de la carpeta
	lg_prt "wywy" "\n Tamaño Inicial:" "\t$init_size" "\n Tamaño Final:" "\t$end_size"
	lg_prt "g" "Archivos \"$1\" reducidos"
	return 0
}

# Convertir m4a a mp3 y comprimir
function mp4_to_mp3() {
	lg_prt "yw" "\n\t[▲] Estas en el directorio:" "$(pwd)"
	lg_prt "wtw" "\n" "CONVERTIR M4A A MP3" "\n"
	# Pedir confirmación
	read -p "¿Estas seguro? (S/N): " -n 1 -r
	[[ $REPLY =~ ^[Ss]$ ]] && lg_prt "w" " \n"  || exit 0

	find . -type f \( -iname \*.m4a \) -print0|sed -e "s/.m4a//g"| while read -d $'\0' file; do
		ffmpeg -i "$file.m4a" -c:v copy -c:a libmp3lame -b:a 96k "$file.mp3" < /dev/null;
	done
}

# Convertir tif a jpg
function tif_to_jpg(){
	lg_prt "yw" "\n\t[▲] Estas en el directorio:" "$(pwd)"
	lg_prt "wtw" "\n" "CONVERTIR TIF A JPG" "\n"
	# Pedir confirmación
	read -p "¿Estas seguro? (S/N): " -n 1 -r
	[[ $REPLY =~ ^[Ss]$ ]] && lg_prt "w" " \n"  || exit 0

	find . -type f \( -iname \*.TIF \) -exec mogrify -format jpg *.tif > /dev/null {} +
}

# Eliminar los datos EXIF de las imagenes jpg, jpeg, png, bmp
function remove_exif(){
	lg_prt "yw" "\n\t[▲] Estas en el directorio:" "$(pwd)"
	lg_prt "wtw" "\n" "BORRAR METADATOS EXIF DE IMAGENES" "\n"
	# Pedir confirmación
	read -p "¿Estas seguro? (S/N): " -n 1 -r
	[[ $REPLY =~ ^[Ss]$ ]] && lg_prt "w" " \n"  || exit 0

	find . -type f -iregex ".*\.jpg\|.*\.jpeg\|.*\.png\|.*\.bmp" -exec mogrify -verbose -strip {} +
}

# Redimensionar archivos jpg, jpeg, png, bmp masivamente con dimensiones de 400px
function resize_image(){
	lg_prt "yw" "\n\t[▲] Estas en el directorio:" "$(pwd)"
	lg_prt "wtw" "\n" "REDIMENSIONAR IMAGENES A x$1px" "\n"
	# Pedir confirmación
	read -p "¿Estas seguro? (S/N): " -n 1 -r
	[[ $REPLY =~ ^[Ss]$ ]] && lg_prt "w" " \n" || exit 0

	#find . -type f \( -iname \*.jpg -o -iname \*.jpeg -o -iname \*.png -o -iname \*.bmp \) -exec mogrify -verbose -resize 400x400 {} +

	if [[ $1 -eq 400 ]]; then
		find . -type f -iregex ".*\.jpg\|.*\.jpeg\|.*\.png\|.*\.bmp" -exec sh -c 'identify -format "%[fx:(h>400)]\n" "$0" | grep -q 1' {} \; -print0 | xargs -0 mogrify -verbose -resize 'x400'
	else
		find . -type f -iregex ".*\.jpg\|.*\.jpeg\|.*\.png\|.*\.bmp" -exec sh -c 'identify -format "%[fx:(h>1080)]\n" "$0" | grep -q 1' {} \; -print0 | xargs -0 mogrify -verbose -resize 'x1080'
	fi
}

# Dividir audios en trozos de 30 minutos
function split_mp3() {
	lg_prt "yw" "\n\t[▲] Estas en el directorio:" "$(pwd)"
	lg_prt "wtw" "\n" "DIVIDIR MP3s EN TROZOS DE 30 MINUTOS" "\n"
	# Pedir confirmación
	read -p "¿Estas seguro? (S/N): " -n 1 -r
	[[ $REPLY =~ ^[Ss]$ ]] && lg_prt "w" " \n"  || exit 0

    find . -type f -iregex ".*\.mp3" -print0|sed -e "s/.mp3//g"| while read -d $'\0' file; do
        lg_prt "wyw" "\n" "$file" "\n"
		new_dir="${file##*/}_split"
		mkdir "$new_dir"
	    # Dividir audio en segmentos de 30 minutos, reset_timestamps - Resetea el contador de 30 minutos
	    ffmpeg -i "$file.mp3" -hide_banner -loglevel error -stats -f segment -segment_times 1800,3600,5400,7200,9000,10800,12600,14400 -c copy -map 0 "$new_dir/$file-%02d.mp3" < /dev/null;
    done;
}

# Agrupar todos los videos en una sola carpeta
function group_videos(){
	lg_prt "yw" "\n\t[▲] Estas en el directorio:" "$(pwd)"
	lg_prt "wtw" "\n" "AGRUPAR ARCHIVOS DE VIDEO EN UNA CARPETA" "\n"
	mkdir "${DIR}all_videos" 2>/dev/null

	find . -type f -iregex ".*\.avi\|.*\.mp4\|.*\.mov\|.*\.wmv\|.*\.3gpp\|.*\.mpeg" -exec mv {} "${DIR}all_videos" \;

	lg_prt "g" "Archivos de video movidos a \"$DIR\all_videos\""
}

# Aplicar varias funciones consecutivamente
function auto_all(){
	lg_prt "yw" "\n\t[▲] Estas en el directorio:" "$(pwd)"
	remove_exif
	resize_image 1080
	media_compress img
	exit 0
}



unset HELP_META
unset HELP_OPTIONS
unset MENU_ROUTES

declare -A HELP_META=(
    [title]="MEDIA TOOLS"
    [script]="./media_tools.sh"
    [usage]="<opción> [archivo]"
    [footer]="Sin ROOT requerido. Los archivos de salida se generan en el mismo directorio."
)

HELP_OPTIONS=(
    "section|Transformación de video"
    "option|-r, --media_compress|Comprimir un archivo de media|[archivo]"
    "option|-g, --group|Agrupar múltiples vídeos en uno"
    "blank"
    "section|Conversión de audio"
    "option|-c, --m4a_to_mp3|Convertir archivos M4A a MP3"
    "option|-p, --split_mp3|Dividir MP3 en fragmentos"
    "blank"
    "section|Procesado de imágenes"
    "option|-j, --tif_to_jpg|Convertir imágenes TIFF a JPG"
    "option|-d, --rmexif|Eliminar metadatos EXIF de imágenes"
    "option|-s, --redi400|Redimensionar imágenes a 400px de ancho"
    "option|-t, --redi1080|Redimensionar imágenes a 1080px de ancho"
    "blank"
    "section|General"
    "option|-a, --auto|Procesar automáticamente todo el directorio"
    "option|-h, --help|Mostrar esta ayuda"
    "blank"
    "section|Ejemplos"
    "example|./media_tools.sh -r video.mp4|Reduce el archivo dado"
    "example|./media_tools.sh --tif_to_jpg|Convierte todos los .tif del directorio"
    "example|./media_tools.sh -s|Redimensiona todas las imágenes a 400px"
    "example|./media_tools.sh --auto|Procesado completo automático"
)

declare -A MENU_ROUTES=(
    [-r]="media_compress 1"		[--reduce]="media_compress 1"
    [-c]="mp4_to_mp3"			[--m4a_to_mp3]="mp4_to_mp3"
    [-p]="split_mp3"			[--split_mp3]="split_mp3"
    [-j]="tif_to_jpg"			[--tif_to_jpg]="tif_to_jpg"
    [-d]="remove_exif"			[--rmexif]="remove_exif"
    [-s]="resize_image 1"		[--redi400]="resize_image 1"
    [-t]="resize_image 1"		[--redi1080]="resize_image 1"
    [-a]="auto_all"				[--auto]="auto_all"
    [-h]="render_help"			[--help]="render_help"
    [-g]="group_videos"			[--group]="group_videos"
    [*]="render_help"
)

_resize400()  { resize_image 400;  }
_resize1080() { resize_image 1080; }

MENU_ROUTES[-s]="_resize400"
MENU_ROUTES[--redi400]="_resize400"
MENU_ROUTES[-t]="_resize1080"
MENU_ROUTES[--redi1080]="_resize1080"
MENU_REQUIRE_ROOT="false"
MENU_HELP_ON_EMPTY="true"
MENU_SHOW_DONE="true"
MENU_DEBUG="false"

render_menu "$@"
