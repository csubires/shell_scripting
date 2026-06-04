#!/bin/bash
# ---------------------------------------------
# Filename: syncServer.sh
# Version: 1.0
# By: CSUBIRES <cjesuma@proton.me>
# Created: 2024/08/12 07:32:33 by CSUBIRES
# Updated: 2024/08/12 07:32:33 by CSUBIRES
# Description: Script to synchronize remote folders.
# ---------------------------------------------

source utils.sh

# Variables globales
SERVER='user@192.168.65.22'
ORIG='/home/user/Documents/box/upload/'
DEST='/home/user/Documents/upload/'

mkdir -p "/home/user/Documents/box/upload"

lg_prt "vw" "\n SERVER:" $SERVER
lg_prt "vw" " ORIG:" $ORIG
lg_prt "vw" " DEST:" $DEST
lg_prt "y" "\n [▲] Sincronizando carpeta con el servidor\n"

read -p "¿SUBIR (U) o BAJAR (D)? (U/D): " -n 1 -r
if [[ $REPLY =~ ^[Uu]$ ]]; then
	rsync --progress -r $ORIG $SERVER:$DEST
else
	rsync --progress -r $SERVER:$DEST $ORIG
fi
lg_prt "g" "[✔] Operación finalizada\n"
