#!/usr/bin/env bash

DIR="."
namefile="tode_web.txt"

echo "🔍 Buscando archivos en $DIR (excluyendo node_modules)..."

# Limpiar el archivo
> "$namefile"

find "$DIR" \( -name "node_modules" -o -name "game" -o -name "decode.html" -o  -name "dist" -o -name "nginx" -o -name "grafana" -o -name "package-lock.json" -o -name "dist" \)  -prune -o \( \
  -name "*.html" -o \
  -name "*.ts" -o \
  -name "*.js" \
\) -type f -print | tee -a "$namefile"

echo "✅ Resultados guardados en: $namefile"
echo "📊 Total de archivos encontrados: $(wc -l < "$namefile")"
