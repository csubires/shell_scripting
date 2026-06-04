#!/usr/bin/env bash

DIR="."
namefile="tode_css.txt"

echo "🔍 Buscando archivos en $DIR (excluyendo node_modules)..."

# Limpiar el archivo
> "$namefile"

find "$DIR" \( -name "node_modules" -o -name "package.json" -o -name "nginx" -o -name "grafana" -o -name "package-lock.json" -o -name "dist" \)  -prune -o \( \
  -name "*.html" -o \
  -name "*.css" -o \
  -name "*.json" -o \
  -name "*.conf" \
\) -type f -print | tee -a "$namefile"

echo "✅ Resultados guardados en: $namefile"
echo "📊 Total de archivos encontrados: $(wc -l < "$namefile")"
