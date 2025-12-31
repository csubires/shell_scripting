# ---------------------------------------------
# Filename: miscellaneous.sh
# Version: 1.0
# By: CSUBIRES <j3xuz_cobmetal88@hotmail.com>
# Created: 2024/08/12 08:03:04 by CSUBIRES
# Updated: 2024/08/12 08:03:04 by CSUBIRES
# Description: .
# ---------------------------------------------

# Descargar desde el SERVER al destino
scp user@192.168.65.22:/tmp/tmp.WrhGxIXlIw/20231227_backup_server_6232.cmp /home/user/Documentos/box
scp user@192.168.65.22:/home/user/docker-app/firefox/config/Descargas/bookmarks.html /home/user/Documents/box

# Reducir tamaño de imagenes jpg recursivamente (cuidado casesensitive)
find . -name "*.jpg" -exec mogrify -verbose -quality 70 {} +

# Redimensiona tamaño de imagenes jpg recursivamente (cuidado casesensitive)
find . -name "*.jpg" -exec mogrify -verbose -resize 400x400 {} +

# Encontrar duplicados de archivos
fdupes -S -r .

# Rotar video 90º
ffmpeg -i "20190726_162606.cmp.mp4" -metadata:s:v rotate="90" -codec copy "20190726_162606.cmp666.mp4"

# Reducir mp3 (cuidado casesensitive)
lame --quiet -vbr-new -V 0 ./11.mp3

# Reducir tamaño de un video (cuidado casesensitive)
ffmpeg -i "./willy.mp4" -strict -2 -c:a copy -c:v libx264 -preset fast -crf 28 -qphist -tune stillimage "./willy.cmp.mp4"
ffmpeg -i "./101852.avi" -strict -2 -c:a copy -c:v libx264 -preset fast -crf 28 -qphist -tune stillimage "./101852.cmp.avi"

# Reducir tamaño de una carpeta de videos (cuidado casesensitive)
find . -name "*.mp4" -print0|sed -e "s/.mp4//g"| while read -d $'\0' file; do ffmpeg -y -i "$file.mp4" -strict -2 -c:a copy -c:v libx264 -preset fast -crf 28 -qphist -tune stillimage "$file.cmp.mp4" < /dev/null; done
find . -name "*.avi" -print0|sed -e "s/.avi//g"| while read -d $'\0' file; do ffmpeg -y -i "$file.avi" -strict -2 -c:a copy -c:v libx264 -preset fast -crf 28 -qphist -tune stillimage "$file.cmp.avi" < /dev/null; done

# Renombrar archivos de una carpeta y subcarpetas con un nombre aleatorio
find -name '*.jpg' -execdir bash -c 'mv -i "{}" "$RANDOM_$RANDOM.jpg"' \;
find . -type f -iregex ".*\.jpg\|.*\.jpeg\|.*\.png\|.*\.bmp" -execdir bash -c 'mv -i "{}" "$(shuf -i 1-100000 -n 1)_$(shuf -i 1-100000 -n 1).jpg"' \;

# Carpetas compartidas de vmware no funcionan
sudo vmhgfs-fuse .host:/ /mnt/hgfs -o allow_other
sudo vmhgfs-fuse .host:/ /mnt/hgfs -o subtype=vmhgfs-fuse,allow_other
cd /mnt/hgfs/COMPRESS

# Renombrar masivamente archivos quitando una parte del nombre
find . -depth -name "*.m4a" -exec sh -c 'mv "$1" "${1% (128kbit_AAC).m4a}.m4a"' _ {} \;

# Dividir audios
ffmpeg -i "Cambia la vida.mp3" -f segment -segment_times 30,60,90,120,150,180 -c copy -map 0 "Cambia la vida%02d.mp3"

# Dividir especificando tiempos
ffmpeg -ss 00:00:00 -t 00:30:00 -i "Marco Aurelio - Meditaciones.mp3" -vn -acodec copy "1 - Marco Aurelio - Meditaciones.mp3"
ffmpeg -ss 00:30:00 -t 00:30:00 -i "Marco Aurelio - Meditaciones.mp3" -vn -acodec copy "2 - Marco Aurelio - Meditaciones.mp3"
ffmpeg -ss 01:00:00 -t 00:30:00 -i "Marco Aurelio - Meditaciones.mp3" -vn -acodec copy "3 - Marco Aurelio - Meditaciones.mp3"

# Buscar espacios sobrantes en nombres de archivos
find . -type f \( \
  -regextype posix-extended -regex '.*/[[:space:]]+[^/]+(\.[^/.]+)?$|.*/[^/]+[[:space:]]+(\.[^/.]+)?$' \
  -o -name '*  *' \
\)