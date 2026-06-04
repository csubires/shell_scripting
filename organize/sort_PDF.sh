#!/usr/bin/env bash

# Crear la carpeta "output" si no existe
output_dir="output"
mkdir -p "$output_dir"

# Crear subdirectorios A-Z y 0-9 dentro de "output"
for char in {A..Z} {0..9}; do
  mkdir -p "$output_dir/$char"
done

# Buscar todos los archivos PDF en el directorio actual y subdirectorios, excluyendo "output"
find . -type f -iname "*.pdf" ! -path "./$output_dir/*" | while read -r pdf_file; do
  # Obtener el nombre del archivo sin la ruta
  pdf_name=$(basename "$pdf_file")

  # Extraer el primer carácter del nombre del archivo y convertirlo en mayúsculas
  first_char=$(echo "${pdf_name:0:1}" | tr 'a-z' 'A-Z')

  # Validar si el primer carácter es una letra o un número
  if [[ "$first_char" =~ [A-Z0-9] ]]; then
    target_dir="$output_dir/$first_char"
  else
    # En caso de que no sea ni letra ni número, usar carpeta "Other"
    target_dir="$output_dir/Other"
    mkdir -p "$target_dir"
  fi

  # Ruta completa del archivo destino
  target_file="$target_dir/$pdf_name"

  # Si el archivo ya existe en el destino
  if [[ -e "$target_file" ]]; then
    if cmp -s "$pdf_file" "$target_file"; then
      # Si los archivos son idénticos, borrar el original
      rm "$pdf_file"
    else
      # Si son diferentes, copiar con un nombre nuevo
      new_name="${pdf_name%.pdf}_repeat.pdf"
      cp "$pdf_file" "$target_dir/$new_name"
    fi
  else
    # Mover el archivo al subdirectorio correspondiente
    mv "$pdf_file" "$target_file"
  fi
done

echo "Archivos PDF organizados correctamente en la carpeta '$output_dir'."
