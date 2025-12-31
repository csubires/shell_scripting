#!/bin/bash
# ---------------------------------------------
# Filename: mirrowFolder.sh
# Version: 1.0
# By: CSUBIRES <j3xuz_cobmetal88@hotmail.com>
# Created: 2024/08/12 07:38:31 by CSUBIRES
# Updated: 2024/10/29 09:24:34 by CSUBIRES
# Description: Script to synchronize folders.
# ---------------------------------------------

source utils.sh

# Variables globales IMPORTANTE el /
DIR_ORIG="/home/user/Documents/box/upload/"
DIR_DEST="/home/user/Documents/box/dest/"

lg_prt "yw" "\n\t[▲] Sincronizando carpetas\n"
rsync -a --progress --delete "${DIR_ORIG}" "${DIR_DEST}"

lg_prt "yw" "\n\t[▲] Comprobando las diferencias\n"
diff -r "${DIR_ORIG}" "${DIR_DEST}"
