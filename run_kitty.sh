#!/usr/bin/env bash

#kitty @ launch --type=tab --tab-title GIT --cwd /home/user/Documents/Projects/media/filmoteca
#kitty @ launch --type=tab --tab-title MAKE --cwd /home/user/Documents/Projects/media/filmoteca
#kitty @ launch --type=tab --tab-title IFCT --cwd ~/Documents/IFCT0109
#kitty @ launch --type=tab --tab-title TMUX --hold tmux
#kitty @ launch --type=tab --tab-title PROOF
#kitty @ launch --type=tab --tab-title OTHERS



kitty @ launch --type=tab --tab-title MAKE --cwd /home/user/Documents/Projects/media/filmoteca bash -c "make web-gateway; exec bash"
kitty @ launch --location=vsplit --cwd /home/user/Documents/Projects/media/filmoteca bash -c "make web-database; exec bash"
kitty @ launch --location=vsplit --cwd /home/user/Documents/Projects/media/filmoteca bash -c "make web-auth; exec bash"
kitty @ launch --location=hsplit --cwd /home/user/Documents/Projects/media/filmoteca bash -c "make web-i18n; exec bash"

echo "¿Deseas ejecutar los transpiladores? (s/n)"
read -r respuesta

if [[ "$respuesta" =~ ^[Ss]$ ]]; then
 @ launch --type=tab --tab-title MAKE2 --cwd /home/user/Documents/Projects/media/filmoteca bash -c "make sass; exec bash"
kitty @ launch --location=hsplit --cwd /home/user/Documents/Projects/media/filmoteca bash -c "make tsc; exec bash"
else
    echo "Bloque omitido."
fi
kitty