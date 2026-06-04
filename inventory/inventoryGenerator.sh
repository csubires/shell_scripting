#!/bin/bash
./../utils.sh

# Variables globales
BASE_DIR=""
BASE_NUM=0
OUT_FILE=""

# Rutas donde estan las colecciones
declare -A folder_collection
folder_collection[films]="/mnt/hgfs/movies/"
folder_collection[filmsext]="/mnt/hgfs/ext_movies/"
folder_collection[series]="/mnt/hgfs/series/"
folder_collection[seriesext]="/mnt/hgfs/ext_series/"
folder_collection[music]="/mnt/hgfs/music/"
folder_collection[misce]="/mnt/hgfs/miscellaneous/"
folder_collection[books]="/mnt/hgfs/books/"

# Nombres del reporte
declare -A name_report
name_report[films]="Listado Películas"
name_report[filmsext]="Listado Películas EXTRA"
name_report[series]="Listado Series"
name_report[seriesext]="Listado Series EXTRA"
name_report[music]="Listado Música"
name_report[misce]="Listado Miscellaneous"
name_report[books]="Listado Libros"

# Archivos permitidos en el listado
declare -A allow_ext
allow_ext[films]=".*\.avi\|.*\.mkv\|.*\.mp4\|.*\.mpeg\|.*\.mpg\|.*\.wmv\|.*\.webm"
allow_ext[filmsext]=".*\.avi\|.*\.mkv\|.*\.mp4\|.*\.mpeg\|.*\.mpg\|.*\.wmv\|.*\.webm"
allow_ext[series]=".*\.avi\|.*\.mkv\|.*\.mp4\|.*\.mpeg\|.*\.mpg\|.*\.wmv\|.*\.webm"
allow_ext[seriesext]=".*\.avi\|.*\.mkv\|.*\.mp4\|.*\.mpeg\|.*\.mpg\|.*\.wmv\|.*\.webm"
allow_ext[music]=".*\.mp3\|.*\.m4a\|.*\.wma\|.*\.flac\|.*\.ogg"
allow_ext[misce]=".*\.mp3\|.*\.m4a\|.*\.wma\|.*\.flac\|.*\.ogg"
allow_ext[books]=".*\.pdf\|.*\.odt\|.*\.doc\|.*\.docx"

# Se ejecuta al pulsar Ctrl+C
trap ctrl_c INT

function ctrl_c() {
	lg_prt "y" "\n[▲] Saliendo con interrupción"
	exit 1
}

# Panel de ayuda
function help_panel() {
	clear

	lg_prt "wtw" "\n" "LISTAR COLECCIONES MULTIMEDIA" "\n"
	lg_prt "wob" "Uso:" "./list_collection.sh" "<Opción>"

	lg_prt "bw" "\t-f,  --films" "\t\tListar Películas"
	lg_prt "bwo" "\t-fe, --filmsext" "\tListar Películas EXTRA" "(HDD Externo)"
	lg_prt "bw" "\t-s,  --series" "\t\tListar Series"
	lg_prt "bwo" "\t-se, --seriesext" "\tListar Series EXTRA" "(HDD Externo)"
	lg_prt "bw" "\t-m,  --music" "\t\tListar Música"
	lg_prt "bwo" "\t-x,  --misce" "\t\tListar Miscellaneous" "(Canciones sueltas)"
	lg_prt "bw" "\t-b,  --books" "\t\tListar Libros"

	lg_prt "bw" "\t-h,  --help" "\t\tMostrar ayuda"

	lg_prt "wc" "\n Ejemplos:\n" "\t./list_collection.sh -f"
	lg_prt "c" "\t./list_collection.sh --books\n"
	exit 0
}

# Obtener todas distintas extensiones de los archivos de una carpeta
# find . -type f | awk -F. '!a[$NF]++{print $NF}'
# find . -type f | sed -e 's/.*\.//' | sed -e 's/.*\///' | sort | uniq -c | sort -rn
# find . -type f | sed -e 's/.*\.//' | sed -e 's/.*\///' | sort -u

# Lista las carpetas y los archivos según el tipo de reporte.
# Función para recorrer y listar directorios y archivos
# Args:
#	$1 (string): Directorio a listar. Ex: /mnt/hgfs/books/
#	$2 (number): Mínima profundidad de listado.
#	$3 (number): Máxima profundidad de listado.
#	$4 (bool): 	 0 - Listar sólo carpetas, 1 - Listar carpetas y archivos.
#	$5 (string): Cadena con ID del tipo de listado

function walk_folders_HTML() {
	counter=0		# Contador para dividir listados de más de 10 items

	lg_prt "yw" "\nArgs:" "\$1:${1} \$2:${2} \$3:${3} \$4:${4} \$5:${5}"
	lg_prt "ywb" "\nNivel" "Nombre Carpeta/Archivo", "Número de archivos"

	find "$1" -mindepth "$2" -maxdepth "$3" -type d | sort | while read -r item; do 	# Obtener listado carpetas y archivos
		item_name="${item/#$BASE_DIR/\ }"												# Eliminar el path base (BASE_DIR)
		base_name="${item_name##*/}"													# Estraer el basename



		# Si mindepth y maxdepth es 1, renderizar como menú (categorías)
		if [[ $2 -eq 1 && $3 -eq 1 ]]; then
			lg_prt "yw" "$base_name"
			echo "<a href=\"#${base_name// /}\">${base_name}</a>" >> "$OUT_FILE"

		else
			# Obtener el nivel de subdirectorios
			slash="${item_name//[^'/']}"												# Dejar solo los slash
			level="$(expr ${#slash} - $BASE_NUM)"										# Slash_TOTAL - Slash_BASE = Nivel de profundidad

			# Mostrar número de archivos en la carpeta según su extensión (tipo de archivo)
			num_files=$(find "$item" -maxdepth 1 -type f -iregex "${allow_ext[$5]}" | wc -l)
			[[ $num_files -gt 0 ]] && show_num="<i>${num_files}</i>" || show_num=""			# Mostrar sólo si es mayor que 0

			printf %${level}s |tr " " "\t"												# Añadir tabulaciones
			lg_prt "ywb" "$level" "$base_name" "$num_files"

			# MANEJO DE NIVELES SEGÚN TIPO DE REPORTE
			case "$5" in
				films | filmsext | misce | books)

					# Mostrar cabecera de categoría/género
					[[ $level -eq 0 ]]  && echo "</section><h3 id=\"${base_name// /}\">${base_name}</h3><section>" >> "$OUT_FILE"

					# Abrir etiqueta de listado <UL> o cerrarlo </UL> según el estado anterior
					if [[ $level -eq 1 ]]; then
						# Mostrar cabecera de subcategoría/subgénero
					 	echo "</ul><ul><li class=\"header\">${base_name}</li>" >> "$OUT_FILE"
					fi

					# Abrir etiqueta de listado <UL> o cerrarlo </UL> según el estado anterior
					if [[ $level -gt 1 ]]; then
						names=(`echo $item_name | tr '/' ' '`)
						# Mostrar cabecera de subcategoría/subgénero
					 	echo "</ul><ul><li class=\"sub\">${names[-2]} ${names[-1]}</li>" >> "$OUT_FILE"
					fi

				;;

				series | seriesext)

					# Mostrar cabecera de categoría/género
					[[ $level -eq 0 ]] && echo "</section><h3 id=\"${base_name// /}\">${base_name}${show_num}</h3><section>" >> "$OUT_FILE"

					# Abrir etiqueta de listado <UL> o cerrarlo </UL> según el estado anterior
					if [[ $level -eq 1 ]]; then
						# Mostrar cabecera de subcategoría/subgénero
					 	echo "</ul><ul><li class=\"header\">${base_name}</li>" >> "$OUT_FILE"
					fi

					# Abrir etiqueta de listado <UL> o cerrarlo </UL> según el estado anterior
					if [[ $level -gt 1 ]]; then
						# Mostrar cabecera de subcategoría/subgénero
					 	echo "<li>${base_name}${show_num}</li>" >> "$OUT_FILE"
					fi

				;;

				music)

					# Mostrar cabecera de categoría/género
					[[ $level -eq 0 ]] && echo -n "</ul></section><h3 id=\"${base_name// /}\">${base_name}${show_num}</h3><section><ul>" >> "$OUT_FILE"

					let counter++
					modu="$(expr $counter % 11)"

					# Abrir etiqueta de listado <UL> o cerrarlo </UL> según el estado anterior
					if [[ $level -gt 0 ]]; then
						[[  $modu -eq 0  && $num_files -gt 0 ]] && echo "</ul><ul>" >> "$OUT_FILE"

					 	# Mostrar carpeta cabecera como contenedora de CDs si dicha carpeta tiene 0 archivos
					 	[[ $num_files -eq 0 ]] && show_sub=" class=\"subi\"" || show_sub=""

						# Mostrar un album
					 	echo "<li${show_sub}>${base_name}${show_num}</li>" >> "$OUT_FILE"
					fi

				;;

				*)
					lg_prt "ryr" "Opción" "$5" "no válida"
					exit 1

				;;
			esac

			# Mostrar archivos también en el reporte
			if [[ $4 -eq 1 ]]; then
				[[ $level -eq 0 && $num_files -lt 10 ]] && echo "<ul>" >> "$OUT_FILE"		# Abrir listado para la categoría o género principal

				# Si el número de archivo es mayor a 10, dividir el listado en sublistados albeticamente
				if [[ $level -eq 0 && $num_files -gt 10 ]]; then
					auxcharacter=" "

					find "$item" -mindepth 1 -maxdepth 1 -type f -iregex "${allow_ext[$5]}" | sort | while read -r item; do
						base_name="${item##*/}" 											# Estraer el basename de archivo
						printf %${level}s |tr " " "\t"										# Añadir tabulaciones
						lg_prt "v" "$base_name"

						character="${base_name:0:1}"
						if [[ "$character" != "$auxcharacter" ]]; then
							auxcharacter="$character"
							echo "</ul><ul><li class=\"header\">${character^^}</li>" >> "$OUT_FILE"
						fi

						echo "<li>${base_name}</li>" >> "$OUT_FILE"
					done
					echo "</ul>" >> "$OUT_FILE"

				else
					find "$item" -mindepth 1 -maxdepth 1 -type f -iregex "${allow_ext[$5]}" | sort | while read -r item; do
						base_name="${item##*/}" 											# Estraer el basename de archivo
						printf %${level}s |tr " " "\t"										# Añadir tabulaciones
						lg_prt "v" "$base_name"
						echo "<li>${base_name}</li>" >> "$OUT_FILE"
					done
				fi

				[[ $level -eq 0  && $num_files -lt 10 ]] && echo "</ul>" >> "$OUT_FILE"		# Cerrar listado para la categoría o género principal

			fi

		fi

	done 	# END FIND

	return 0
}


# Renderizar el archivo HTML con el listado/inventario.
# Args:
#	$5 (string): Cadena con ID del tipo de listado

function render_HTML() {
	clear
	lg_prt "wtw" "\n" "LISTAR ARCHIVOS $1" "\n"
	lg_prt "yw" "\tDirectorio:" "\t${folder_collection[$1]}"
	lg_prt "yw" "\tNombre:" "\t${name_report[$1]}\n"

	# Comprobar la existencia del directorio media
	if ! [[ -d "${folder_collection[$1]}" ]]; then
		lg_prt "ryr" "\n [▲] Carpeta de archivos media" "\"${folder_collection[$1]}\"" "no disponible\n"
		exit 1
	fi

	# Pedir confirmación
	read -rep $'¿Estas seguro? (S/N):\n'
	[[ $REPLY =~ ^[Ss]$ ]] && lg_prt "w" "\n"  || exit 0


	BASE_DIR="${folder_collection[$1]}"										# Directorio base a listar. Ex: ./mock/películas/
	BASE_SLA="${BASE_DIR//[^'/']}"											# Dejar solo los slash. Ex: ///
	BASE_NUM="${#DIRSLA}"													# Contar número de slash (profundidad de carpeta). Ex: 3

	DATE_STR="$(date +%Y%m%d)"												# Fecha actual
	OUT_FILE="reportes/${DATE_STR}_${name_report[$1]}.html"					# Archivo donde volcar el reporte

	SIZE_BASE=$(du -hs "${BASE_DIR}" | awk '{print $1}')					# Tamaño del directorio base
	NUM_FILES=$(find "${BASE_DIR}" -type f | wc -l)							# Número total de archivos en el directorio base
	NUM_FOLDERS=$(find "${BASE_DIR}" -mindepth 1 -type d | wc -l)			# Número total de carpetas en el directorio base


cat << EOF > "$OUT_FILE"
<!DOCTYPE html>
<html>
	<head>
		<title>${name_report[$1]}</title>
		<style type="text/css">
			html{scroll-behavior:smooth;scrollbar-color:#65727e,#212529}body{background-color:#f8f9fa;color:#000;font-family:system-ui,-apple-system,"Segoe UI",Roboto,"Helvetica Neue","Noto Sans","Liberation Sans",Arial,sans-serif,"Apple Color Emoji","Segoe UI Emoji","Segoe UI Symbol","Noto Color Emoji";font-size:1rem;font-weight:400;line-height:1.5;margin:0;padding:0}body h3:first-child{margin-top:0}header{border-bottom:solid 2px #e9ecef;display:flex;justify-content:space-around;justify-items:center;align-items:center;padding:10px;color:#085f63}header b{color:#085f63;background-color:transparent;font-size:1.5rem}nav{display:flex;flex-wrap:wrap;justify-content:center;gap:1rem;padding:1rem;margin:.5rem;font-size:1.5rem;background-color:#ebedf0;border-radius:3px}a{background-color:#0d6efd;padding:.5rem 1rem;border-radius:5px;text-decoration:none;text-transform:uppercase;letter-spacing:.1em;text-align:center;font-weight:700;color:#fff}a:hover{background-color:#0257d5;border-color:#0262ef}a.up{position:sticky;top:5rem;padding:.8rem 1.2rem;border-radius:50%;margin-right:.5rem;background-color:#fd7e14;float:right}a.up:hover{background-color:#dc6502;border-color:#f57102}a.up .arrow-up{transform:scale(3);transform-origin:center}h3{background-color:#085f63;color:#f1faee;text-align:center;text-transform:uppercase;padding:1rem;margin-top:3rem}h3.sub{background-color:#fd7e14}section{display:flex;gap:1rem;justify-content:space-around;flex-wrap:wrap;background-color:#ebedf0;margin:.5rem;border-radius:5px}section ul{width:20rem;border:1px solid gray;border-radius:3px;list-style:none;padding:.5rem .7rem .5rem .5rem;display:flex;flex-direction:column;gap:.5rem;background-color:#fff;box-shadow:0 4px 8px 0 rgba(0,0,0,0.2),0 6px 20px 0 rgba(0,0,0,0.19)}section ul:empty{display:none}section ul li,section ul i{padding:0 .3rem}section ul li:hover,section ul i:hover{background-color:#545b62;color:#fff}section ul li.subi,section ul i.subi{background-color:#fd7e14}section ul i{color:#085f63;opacity:.7;float:right}section ul .header,section ul .sub{text-align:center;font-size:1.2rem;color:#f1faee;background-color:#495057;font-style:italic;font-weight:700;padding:.5rem;text-transform:uppercase}section ul .sub{background-color:#fd7e14}section ul .sub:hover{background-color:#dc6502;border-color:#f57102}
		</style>
	</head>
	<body>

		<h3>${name_report[$1]}</h3>
		<header>
			<p><b>${SIZE_BASE}</b> Ocupados</p>
			<p><b>${NUM_FILES}</b> Archivos</p>
			<p><b>${NUM_FOLDERS}</b> Carpetas</p>
		</header>

		<h3 id="up">Categorías</h3>
		<nav>
EOF

		# Renderizar categorías
		# Path base, mindepth, maxdepth, only_folders, id_listado
		walk_folders_HTML "$BASE_DIR" 1 1 0 ""

cat << _EOF_ >> "$OUT_FILE"
		</nav>

		<a class="up" href="#up">
			<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="arrow-up" viewBox="0 0 16 16">
		  		<path d="M16 8A8 8 0 1 0 0 8a8 8 0 0 0 16 0zm-7.5 3.5a.5.5 0 0 1-1 0V5.707L5.354 7.854a.5.5 0 1 1-.708-.708l3-3a.5.5 0 0 1 .708 0l3 3a.5.5 0 0 1-.708.708L8.5 5.707V11.5z"/>
			</svg>
		</a>

<section>
_EOF_

# Renderizar carpetas y archivos
# Path base, mindepth, maxdepth, only_folders,  id_listado
case "$1" in
	films | filmsext | misce | books) 	walk_folders_HTML "$BASE_DIR" 1 9 1 "$1";;
	series | seriesext) 				walk_folders_HTML "$BASE_DIR" 1 9 0 "$1";;
	music)								walk_folders_HTML "$BASE_DIR" 1 5 0 "$1";;
	*)
		lg_prt "ryr" "Opción" "$5" "no válida"
		exit 1
	;;
esac

cat << _EOF_ >> "$OUT_FILE"
	</body>
</html>
_EOF_

	lg_prt "gw" "\n[✔] Reporte guardado en" "$OUT_FILE \n"
	exit 0
} # END render_HTML


# Menú principal
function menu_selector() {
	if [[ $1 ]]; then

		# MENU
		case "$1" in
			-f|--films)			render_HTML "films";;
			-fe|--filmsext) 	render_HTML "filmsext";;
			-s|--series) 		render_HTML "series";;
			-se|--seriesext)	render_HTML "seriesext";;
			-m|--music) 		render_HTML "music";;
			-x|--misce) 		render_HTML "misce";;
			-b|--books) 		render_HTML "books";;
			-h|--help|*) 		help_panel;;
		esac

		# exit 0
	else
		lg_prt "ry" "\n[✖] Parametros no válidos o insuficientes." "Usa --help"
	fi
}


# Punto de inicio del programa
menu_selector $1
