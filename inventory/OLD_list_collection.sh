#!/bin/bash
source ./../utils.sh

#Variables globales
DIR="/home/user/Documentos/box/"
DIRSLA="${DIR//[^'/']}"
DIRNUM="${#DIRSLA}"
DATESTR="$(date +%Y%m%d)"
REPORTDIR="index.html"

# Rutas donde estan las colecciones
declare -A folder_collection
folder_collection[films]="/mnt/hgfs/movies/"
folder_collection[filmsext]="/mnt/hgfs/ext_movies/"
folder_collection[series]="/mnt/hgfs/series/"
folder_collection[seriesext]="/mnt/hgfs/ext_series/"
folder_collection[music]="/mnt/hgfs/music/"
folder_collection[misce]="/mnt/hgfs/miscellaneous/"
folder_collection[books]="/mnt/hgfs/books/"

# Rutas donde estan las colecciones
declare -A name_report
name_report[films]="Listado Películas"
name_report[filmsext]="Listado Películas EXTRA"
name_report[series]="Listado Series"
name_report[seriesext]="Listado Series EXTRA"
name_report[music]="Listado Música"
name_report[misce]="Listado Miscellaneous"
name_report[books]="Listado Libros"


# Se ejecuta al pulsar Ctrl+C
trap ctrl_c INT

function ctrl_c() {
    lg_prt "y" "\n[▲] Saliendo con interrupción"
	exit 1
}



# Panel de ayuda
function help_panel() {
	clear

	lg_prt "wtw" "\n" "LISTAR COLECCIONES MEDIA" "\n"
	lg_prt "wob" "Uso:" "./report_collections.sh" "<Opción>"

	lg_prt "bw" "\t-f, --films" "\t\tListar Películas"
	lg_prt "bwo" "\t-fe, --filmsext" "\tListar Películas EXTRA" "(HDD Externo)"
	lg_prt "bw" "\t-s, --series" "\t\tListar Series"
	lg_prt "bwo" "\t-se, --seriesext" "\tListar Series EXTRA" "(HDD Externo)"
	lg_prt "bw" "\t-m, --music" "\t\tListar Música"
	lg_prt "bwo" "\t-x, --misce" "\t\tListar Miscellaneous" "(Canciones sueltas)"
	lg_prt "bw" "\t-b, --books" "\t\tListar libros"

	lg_prt "bw" "\t-h, --help" "\t\tMostrar ayuda"

	lg_prt "wc" "\n Ejemplos:\n" "\t./report_collections.sh -f"
	lg_prt "c" "\t./report_collections.sh --books\n"
	exit 0
}



# Lista las carpetas del nivel superior
function categories() {
	counter=0

	find "$1" -type d | while read -r d; do 	# Leer solo directorios
		folder_name="${d/#$DIR/\ }"			# Eliminar el path base
		let counter++

		if [[ "$folder_name" != *"/"* && $folder_name != " " ]]; then # Si no es subdirectorio ni está en blanco
			lg_prt "yw" "[$counter]" "$folder_name"
			echo "<p><a href=\"#${folder_name// /}\">${folder_name}</a></p>" >> "$REPORTDIR"
		fi
	done

	echo "<p><a style=\"background-color: var(--oran-1);\" href=\"#sub\">Sub Categorías</a></p>" >> "$REPORTDIR"
	return 0
}


# Lista los archivos dentro de cada carpeta y subcarpeta
function recusiveFiles() {

	 find "$1" -maxdepth 1 -type d | while read -r folder; do 	# Listar carpetas en nivel 1
		folder_name="${folder/#$DIR/\ }"						# Eliminar el path base

		# Evitar doble iteración && no es un archivo && y tampoco está en blanco
		if [[ "$folder" != "$1" && $folder_name != *"."* && $folder_name != " " ]]; then

			base_name="${folder##*/}"							# Estraer el basename

			# Saber si es un subdirectorio
			res="${folder//[^'/']}"				# Contar el número de slash
			level="$(expr ${#res} - $DIRNUM)" 	# Comparar con el directorio padre
			[[ $level -gt 0 ]] && is_sub=" class=\"sub_genre\" id=\"sub\"" || is_sub=""

			lg_prt "y" "\n$base_name"
			echo "</section><h5 id=\"${base_name// /}\"><p> $base_name </p><a href=\"#up\">↑ UP</a></h5> <section${is_sub}>" >> "$REPORTDIR"

			counter=0
			auxcharacter=" "

			find "$folder" -maxdepth 1 -type f | sort | while read -r unfile; do
				# extension=${unfile##*.}
				base_name="${unfile##*/}" 		# Estraer el basename
				let counter++

				character="${base_name:0:1}"
				if [[ "$character" == "$auxcharacter" ]]; then
					echo " $base_name <br>" >> "$REPORTDIR"
				else
					auxcharacter="$character"
					echo "<p><b> ${character^^} </b> $base_name <br>" >> "$REPORTDIR"
				fi

				lg_prt "yb" "\t[$counter]" "$base_name"

			done
			echo "</p>" >> "$REPORTDIR"

			# echo "$folder == $1"
			# Si no es el mismo directorio buscar en el subdirectorio
			[[ "$folder" == "$1" ]] || recusiveFiles "$folder"
		fi

	done
	return 0
}



# Lista los archivos dentro de cada carpeta y subcarpeta
function recusiveFolder2Level() {

	 find "$1" -maxdepth 1 -type d | while read -r folder; do 	# Listar carpetas en nivel 1
		folder_name="${folder/#$DIR/\ }"						# Eliminar el path base

		# Evitar doble iteración && no es un archivo && y tampoco está en blanco
		if [[ "$folder" != "$1" && $folder_name != *"."* && $folder_name != " " ]]; then

			base_name="${folder##*/}"							# Estraer el basename

			lg_prt "y" "\n$base_name"
			echo "</section><h5 id=\"${base_name// /}\"><p> $base_name </p><a href=\"#up\">↑ UP</a></h5> <section>" >> "$REPORTDIR"

			counter=0
			find "$folder" -maxdepth 1 -type d | sort | while read -r unfile; do
				# extension=${unfile##*.}
				base_name2="${unfile##*/}" 		# Estraer el basename
				let counter++

				if [[ "$base_name" != "$base_name2" ]]; then
					echo "<p><b> ${base_name2^^} </b>" >> "$REPORTDIR"
					lg_prt "yb" "\t[$counter]" "$base_name2"

					find "$unfile" -maxdepth 1 -type d | sort | while read -r unfile2; do
						base_name3="${unfile2##*/}" 		# Estraer el basename
						lg_prt "v" "\t\t\t${base_name3}"
						[[ "$base_name3" != "$base_name2" ]] && echo " $base_name3 <br>" >> "$REPORTDIR"
					done
				fi

			done
			echo "</p>" >> "$REPORTDIR"
		fi

	done
	return 0
}


# Lista los archivos dentro de cada carpeta y subcarpeta
function recusiveFolder1Level() {

	 find "$1" -maxdepth 1 -type d | while read -r folder; do 	# Listar carpetas en nivel 1
		folder_name="${folder/#$DIR/\ }"						# Eliminar el path base

		# Evitar doble iteración && no es un archivo && y tampoco está en blanco
		if [[ "$folder" != "$1" && $folder_name != *"."* && $folder_name != " " ]]; then

			base_name="${folder##*/}"							# Estraer el basename

			lg_prt "y" "\n$base_name"
			echo "</section><h5 id=\"${base_name// /}\"><p> $base_name </p><a href=\"#up\">↑ UP</a></h5> <section>" >> "$REPORTDIR"

			counter=-1
			find "$folder" -maxdepth 1 -type d | sort | while read -r unfile; do
				# extension=${unfile##*.}
				base_name2="${unfile##*/}" 		# Estraer el basename
				let counter++
				modu="$(expr $counter % 10)"

				[[  $modu -eq 0 ]] && echo "<p>" >> "$REPORTDIR"
				[[ "$base_name" != "$base_name2" ]] && echo " ${base_name2} <br>" >> "$REPORTDIR"
				lg_prt "yb" "\t[$counter]" "$base_name2"

			done
			echo "</p>" >> "$REPORTDIR"
		fi

	done
	return 0
}


# Listar archivos dentro de múltiples carpetas
function renderHTML() {
	clear
	lg_prt "wtw" "\n" "LISTAR ARCHIVOS $1" "\n"
	lg_prt "yw" "\tDirectorio:" "\t${folder_collection[$1]}"
	lg_prt "yw" "\tNombre:" "\t${name_report[$1]}"

	# Comprobar la existencia del directorio media
	if ! [[ -d "${folder_collection[$1]}" ]]; then
		lg_prt "ryr" "\n [▲] Carpeta de archivos media" "\"${folder_collection[$1]}\"" "no disponible\n"
		exit 1
	fi

	# Pedir confirmación
	read -p "¿Estas seguro? (S/N): " -n 1 -r
	[[ $REPLY =~ ^[Ss]$ ]] && lg_prt "w" " \n"  || exit 0

	DIR="${folder_collection[$1]}" # DIR="/home/user/Documentos/box/pelis/"
	DIRSLA="${DIR//[^'/']}"
	DIRNUM="${#DIRSLA}"
	REPORTDIR="reportes/${DATESTR}_${name_report[$1]}.html"

	tamanio_carpeta=$(du -hs "${DIR}" | awk '{print $1}')
	numero_archivos=$(find "${DIR}" -type f | wc -l)
	numero_carpetas=$(find "${DIR}" -mindepth 1 -type d | wc -l)


cat << EOF > "$REPORTDIR"
<!DOCTYPE html>
<html>
	<head>
		<title>${name_report[$1]}</title>
		<style type="text/css">

:root {
	--mint: #f1faeeff;
	--oran-1: #ff895d;
	--blue-1: #d5eeff;
	--blue-2: #007cb9;
	--blue-3: #085f63;
}

html { font-size: 4vh; }

body {
	padding: 0;
	margin: 0;
	height: 100vh;
	font-family: Helvetica;
	font-style: normal;
	font-weight: normal;
	overflow: scroll;
}

header {
	border-bottom: solid 2px var(--mint);
	height: 10%;
	display: grid;
	grid-template-columns: repeat(3, auto);
	justify-items: center;
	align-items: center;
	padding: 10px;
}

header > p > b {
	background-color: transparent;
	color: var(--blue-3);
}

h3, h5 {
	background-color: var(--blue-3);
	color: var(--mint);
	text-align: center;
	text-transform:uppercase;
}

section {
	display: grid;
  	grid-template-columns: repeat(3, auto);
	grid-gap: 10px ;
	padding: 5px ;
	margin: 0.5em;
	font-size: 5vh;
	background-color: var(--blue-2);
	justify-items:center;
}

section > p {
	background-color: var(--blue-1);
	min-width: -moz-available;
	display: grid;
	padding: 5px;
	border: 1px solid black;
	border-radius: 3px;
	font-family: Times, Times New Roman, serif;
}

br { margin-bottom: 2vh !important; }
h3 { padding: 15px 0px 10px; }
h5 { display:block ruby; }
.sub_genre { background-color: var(--oran-1); }

a {
	text-decoration: none;
	text-transform:uppercase;
	letter-spacing: 0.1em;
	text-align: center;
	padding: 15px 0px 10px;
	font-weight: bold;
	background-color: var(--blue-1);
	color: var(--blue-3);
}

a:hover {
	background-color: var(--blue-3);
	color: var(--mint);
}

h5 > a {
	text-decoration: none;
	background-color: var(--oran-1);
	border-radius: 4px;
	color: var(--mint);
	cursor: pointer;
	font-size: 1em;
	font-weight: 700;
	padding: 0.7em;
	text-transform: uppercase;
	margin: 1vh;
	float:right;
}

h5 > a:hover {
	background-color: var(--blue-2);
	border: 1px solid white;
}

b {
	text-align: center;
	background-color: var(--blue-3);
	color: var(--mint);
	margin-bottom: 4px;
	max-height: 1em;
	padding: 5px;
	font-size: 4vh;
}

		</style>
	</head>
	<body>

		<h3>${name_report[$1]}</h3>
		<header>
			<p><b>Tamaño:</b> ${tamanio_carpeta}</p>
			<p>${numero_archivos} <b>archivos</b></p>
			<p>${numero_carpetas} <b>carpetas</b></p>
		</header>

		<h3 id="up">Categorías</h3>
		<section>
EOF

categories "$DIR"
# Si viene con un segundo parametro elegir otro

case "$2" in
	recusiveFolder1Level)	recusiveFolder1Level "$DIR";;
	recusiveFolder2Level) 	recusiveFolder2Level "$DIR";;
    *) 						recusiveFiles "$DIR";;
esac

cat << _EOF_ >> "$REPORTDIR"
		</section>
	</body>
</html>
_EOF_

	lg_prt "gw" "\n[✔] Reporte guardado en" "$REPORTDIR"
	exit 0
}


# Control o MENU
if [[ $1 ]]; then

	# MENU
	case "$1" in
		-f|--films)			renderHTML "films" "None";;
		-fe|--filmsext) 	renderHTML "filmsext" "None";;
        -s|--series) 		renderHTML "series" "recusiveFolder2Level";;
		-se|--seriesext)	renderHTML "seriesext" "recusiveFolder2Level";;
		-m|--music) 		renderHTML "music" "recusiveFolder1Level";;
        -x|--misce) 		renderHTML "misce" "None";;
		-b|--books) 		renderHTML "books" "None";;
		-h|--help|*) 		help_panel;;
	esac

	exit 0
else
	lg_prt "ry" "\n[✖] Parametros no válidos o insuficientes." "Usa --help"
fi


# TODO Mejorar quitar find multiple dejar uno con maxdepth 3 y controlar con número de slash
