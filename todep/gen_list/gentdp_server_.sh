#!/usr/bin/env bash

DIR="."
namefile="tode_server.txt"

echo "🔍 Buscando archivos en $DIR (excluyendo node_modules)..."

# Limpiar el archivo
> "$namefile"

find "$DIR" \( -name "node_modules" -o -name "backend" -o -name "package.json" -o -name "package-lock.json" -o -name "dist" \)  -prune -o \( \
  -name "*.json" -o \
  -name "*.yml" -o \
  -name "Dockerfile" -o \
  -name "*.hcl" -o \
  -name "*.sh" -o \
  -name "*.conf" -o \
  -name "*.rules" -o \
  -name ".env" -o \
  -name ".rules" -o \
  -name ".env.*" -o \
  -name "*.env"-o \
  -name "*.conf" \
\) -type f -print | tee -a "$namefile"

echo "✅ Resultados guardados en: $namefile"
echo "📊 Total de archivos encontrados: $(wc -l < "$namefile")"
