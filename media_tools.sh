#!/usr/bin/env bash
# sudo apt install imagemagick libheif1 libheif-dev sudo apt install libheif-examples


. utils/color.sh
. utils/menu.sh
. utils/utils.sh
. utils/progressbar.sh

DIR="/mnt/hgfs/VMShared/COMPRESS/"
[[ $# -eq 3 ]] && DIR="$3"
chk_path "$DIR"
cd $DIR

# ============================
# METADATA (VIDEO)
# ============================

function is_processed_video() {
    ffprobe -v quiet -show_entries format_tags=processed -of default=nw=1:nk=1 "$1" 2>/dev/null | grep -q "yes"
}

function mark_processed_video() {
    ffmpeg -y -i "$1" -metadata processed=yes -c copy "$2" < /dev/null
}

function is_processed_file() {
    [[ "$1" == *.cmp.* ]]
}

# ============================
# VIDEO PROCESS
# ============================

function process_video() {
    local ext="$1"

    mapfile -d '' files < <(find . -type f -iname "*.${ext}" ! -iname "*.cmp.*" -print0)
    local total=${#files[@]}

    pb_start "$total" "Procesando .$ext"

    local i=0
    for file in "${files[@]}"; do
        ((i++))

        if is_processed_video "$file"; then
            pb_update "$i" "skip meta"
            continue
        fi

        out="${file%.*}.cmp.${ext}"
		tmp="${file%.*}.tmp.${ext}"
        [[ -f "$out" ]] && { pb_update "$i" "ya existe"; continue; }

       ffmpeg -y -i "$file" \
    -c:a copy \
    -c:v libx264 -preset fast -crf 28 -tune stillimage \
    "$tmp" < /dev/null

        mark_processed_video "$tmp" "$out"
        rm -f "$tmp"

        pb_update "$i" "$(basename "$file")"
    done

    pb_done "Vídeos .$ext procesados"
}

# ============================
# MEDIA COMPRESS
# ============================

function media_compress() {
    lg_prt "yw" "\n\t[▲] Directorio:" "$(pwd)"
    read -p "¿Estas seguro? (S/N): " -n 1 -r
    [[ $REPLY =~ ^[Ss]$ ]] || exit 0

    case "$1" in
        img)
            mapfile -d '' files < <(find . -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" \) ! -iname "*.cmp.*" -print0)
            pb_start "${#files[@]}" "Comprimiendo imágenes"

            i=0
            for f in "${files[@]}"; do
                ((i++))
                mogrify -quality 70 "$f"
                pb_update "$i" "$(basename "$f")"
            done

            pb_done "Imágenes comprimidas"
        ;;

        mp4|avi|mov)
            process_video "$1"
        ;;

        mp3)
            mapfile -d '' files < <(find . -type f -iname "*.mp3" -print0)
            pb_start "${#files[@]}" "Recomprimiendo MP3"

            i=0
            for f in "${files[@]}"; do
                ((i++))
                lame --quiet -vbr-new -V 0 "$f"
                pb_update "$i" "$(basename "$f")"
            done

            pb_done "MP3 procesados"
        ;;

        *)
            lg_prt "ry" "[✖] Parámetro no válido"
        ;;
    esac
}

# ============================
# M4A → MP3
# ============================

function mp4_to_mp3() {
    mapfile -d '' files < <(find . -type f -iname "*.m4a" -print0)
    pb_start "${#files[@]}" "M4A → MP3"

    i=0
    for f in "${files[@]}"; do
        ((i++))
        out="${f%.*}.mp3"
        [[ -f "$out" ]] && { pb_update "$i" "skip"; continue; }

        ffmpeg -i "$f" -c:a libmp3lame -b:a 96k "$out" < /dev/null
        pb_update "$i" "$(basename "$f")"
    done

    pb_done "Conversión completada"
}

# ============================
# TIF → JPG (FIXED)
# ============================

function tif_to_jpg() {
    mapfile -d '' files < <(find . -type f -iname "*.tif" -print0)
    pb_start "${#files[@]}" "TIF → JPG"

    i=0
    for f in "${files[@]}"; do
        ((i++))
        mogrify -format jpg "$f"
        pb_update "$i" "$(basename "$f")"
    done

    pb_done "Conversión completada"
}

# ============================
#HEIC → JPG (FIXED)
# ============================

function heic_to_jpg() {
    mapfile -d '' files < <(find . -type f -iname "*.heic" -print0)
    pb_start "${#files[@]}" "HEIC → JPG"

    i=0
    for f in "${files[@]}"; do
        ((i++))
        mogrify -format jpg -auto-orient "$f"
        pb_update "$i" "$(basename "$f")"
    done

    pb_done "Conversión completada"
}



# ============================
# REMOVE EXIF
# ============================

function remove_exif() {
    mapfile -d '' files < <(find . -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" \) -print0)
    pb_start "${#files[@]}" "Eliminando EXIF"

    i=0
    for f in "${files[@]}"; do
        ((i++))
        mogrify -strip "$f"
        pb_update "$i" "$(basename "$f")"
    done

    pb_done "EXIF eliminado"
}

# ============================
# RESIZE
# ============================

function resize_image() {
    local size="$1"

    mapfile -d '' files < <(find . -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" \) -print0)
    pb_start "${#files[@]}" "Resize → ${size}px"

    i=0
    for f in "${files[@]}"; do
        ((i++))
        mogrify -resize "x${size}" "$f"
        pb_update "$i" "$(basename "$f")"
    done

    pb_done "Resize completado"
}

# ============================
# AUTO
# ============================

function auto_all() {
    remove_exif
    resize_image 1080
    media_compress img
}

# ============================
# MENU (igual que el tuyo)
# ============================

unset HELP_META HELP_OPTIONS MENU_ROUTES

declare -A HELP_META=(
    [title]="MEDIA TOOLS"
    [script]="./media_tools.sh"
    [usage]="<opción> [archivo]"
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
    "option|-i, --heic_to_jpg|Convertir imágenes HEIC a JPG"
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
    [-r]="media_compress 1" [--reduce]="media_compress 1"
    [-c]="mp4_to_mp3" [--m4a_to_mp3]="mp4_to_mp3"
    [-j]="tif_to_jpg" [--tif_to_jpg]="tif_to_jpg"
    [-i]="heic_to_jpg" [--heic_to_jpg]="heic_to_jpg"
    [-d]="remove_exif" [--rmexif]="remove_exif"
    [-s]="resize_image 1" [--redi400]="resize_image 1"
    [-t]="resize_image 1" [--redi1080]="resize_image 1"
    [-a]="auto_all" [--auto]="auto_all"
    [-h]="render_help" [--help]="render_help"
    [*]="render_help"
)

_resize400(){ resize_image 400; }
_resize1080(){ resize_image 1080; }

MENU_ROUTES[-s]="_resize400"
MENU_ROUTES[--redi400]="_resize400"
MENU_ROUTES[-t]="_resize1080"
MENU_ROUTES[--redi1080]="_resize1080"

render_menu "$@"
