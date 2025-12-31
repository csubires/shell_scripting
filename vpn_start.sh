#!/bin/bash
# ---------------------------------------------
# Filename: vpnStart.sh
# Version: 1.0
# By: CSUBIRES <j3xuz_cobmetal88@hotmail.com>
# Created: 2024/08/12 07:14:59 by CSUBIRES
# Updated: 2024/08/12 07:14:59 by CSUBIRES
# Description: Script used to create a VPN \
# 	connection with Openvpn and VPNBook.
# ---------------------------------------------

source utils.sh

# Variables globales
readonly USER="user"								# Usuario local
readonly FILE_PSSWRD="/etc/openvpn/.secret"		# Archivos de login de VPN

# Archivos de configuración VPN
declare -A file_ovpn=(
	[ca196]="/home/${USER}/Documents/VPN/ca196/vpnbook-ca196-tcp443.ovpn"
	[de20]="/home/${USER}/Documents/VPN/de20/vpnbook-de20-tcp443.ovpn"
	[de220]="/home/${USER}/Documents/VPN/de220/vpnbook-de220-tcp443.ovpn"
	[fr200]="/home/${USER}/Documents/VPN/fr200/vpnbook-fr200-tcp443.ovpn"
	[fr231]="/home/${USER}/Documents/VPN/fr231/vpnbook-fr231-tcp443.ovpn"
	[pl134]="/home/${USER}/Documents/VPN/pl134/vpnbook-pl134-tcp443.ovpn"
	[pl140]="/home/${USER}/Documents/VPN/pl140/vpnbook-pl140-tcp443.ovpn"
	[uk205]="/home/${USER}/Documents/VPN/uk205/vpnbook-uk205-tcp443.ovpn"
	[uk68]="/home/${USER}/Documents/VPN/uk68/vpnbook-uk68-tcp443.ovpn"
	[us1]="/home/${USER}/Documents/VPN/us1/vpnbook-us1-tcp443.ovpn"
	[us2]="/home/${USER}/Documents/VPN/us2/vpnbook-us2-tcp443.ovpn"
)

# Panel de ayuda
function helpPanel() {
	clear

	lg_prt "wtw" "\n" "OPEN VPN STARTER" "\n"
	lg_prt "wobv" "Uso:" "./vpnStart.sh" "<Opción>" "<Country>"

	lg_prt "bwr" "\t-c, --country" "\tIniciar conexión con una VPN" "Necesario ROOT"
	lg_prt "vyw" "\t\tca149" "\tCANADA" "+(p2p)"
	lg_prt "vyw" "\t\tca196" "\tCANADA" "(Solo web)"
	lg_prt "vyw" "\t\tde20" "\tGERMANY" "+(p2p)"
	lg_prt "vyw" "\t\tde220" "\tGERMANY" "(Solo web)"
	lg_prt "vyw" "\t\tfr200" "\tFRANCE" "+(p2p)"
	lg_prt "vyw" "\t\tfr231" "\tFRANCE" "(Solo web)"
	lg_prt "vyw" "\t\tpl134" "\tPOLAND" "+(p2p)"
	lg_prt "vyw" "\t\tpl140" "\tPOLAND" "(Solo web)"
	lg_prt "vyw" "\t\tuk205" "\tUK" "+(p2p)"
	lg_prt "vyw" "\t\tuk68" "\tUK" "(Solo web)"
	lg_prt "vyw" "\t\tus1" "\tUS" "(Solo web)"
	lg_prt "vyw" "\t\tus2" "\tUS" "(Solo web)"

	lg_prt "bwr" "\n\t-p, --passwrd" "\tCambiar la contraeña" "Necesario ROOT"
	lg_prt "bwr" "\t-r, --reset" "\tResetear la conexión" "Necesario ROOT"
	lg_prt "bw" "\t-h, --help" "\tMostrar ayuda"

	lg_prt "wc" "\n Ejemplos:\n" "\t./vpnStart.sh -c FR231"
	lg_prt "c" "\t./vpnStart.sh --reset\n"
	exit 0
}

# Activar la VPN
function startVPN() {
	clear

	# Comprobar si el cortafuegos está activo
	if sudo ufw status | grep -q inactivo$; then
		lg_prt "y" "\n[▲] El cortafuegos está deshabilitado\n"
		# Pedir confirmación
		read -p "¿Habilitar cortafuegos? (S/N): " -n 1 -r
		[[ $REPLY =~ ^[Ss]$ ]] && lg_prt "w" " \n"  || exit 1
	    ufw enable
	    sleep 3
	    clear
	fi

	if [[ "${file_ovpn[$1]}" ]]; then
		lg_prt "yw" "\n\tArchivo OVPN:" "${file_ovpn[$1]}"
		lg_prt "yw" "\tArchivo PASS:" "$FILE_PSSWRD\n"
		openvpn --auth-nocache --config ${file_ovpn[$1]} --auth-user-pass $FILE_PSSWRD
		exit 0
	else
		lg_prt "ryr" "\n[✖] El país" "\"$1\"" "no está disponible\n"
		exit 1
	fi
}

# Cambiar la contraseña del archivo de login del VPN
function changePsswd() {
	clear

	lg_prt "yw" "\n\tArchivo PASS:" "\t$FILE_PSSWRD"
	lg_prt "vw" "\n\tUser:" "\t\t$(head $FILE_PSSWRD -n 1)"
	lg_prt "vw" "\tOld Passwrd:" "\t$(tail $FILE_PSSWRD -n 1)"
	lg_prt "vg" "\tNew Passwrd:" "\t$1"
	sed -i "2s/.*/$1/" $FILE_PSSWRD
	lg_prt "g" "\n [✔] Contraseña modificada correctamente"
	exit 0
}

# Resetear conexión
function resetConnection() {
	clear

	lg_prt "yw" "[▲] Reseteando conexión" "Espere..."
	service network-manager restart
	sleep 3
	#clear
	lg_prt "g" "\n [✔] Conexión reseteada"
	exit 0
}

if [[ "$(id -u)" == "0" ]]; then

	# Control o MENU
	if [[ $1 ]]; then

		# MENU
		case "$1" in
			-c|--country) 	[[ $2 ]] && startVPN $2 || lg_prt "ry" "[✖] Parametros insuficientes" "Usa --help";;
			-p|--passwrd) 	[[ $2 ]] && changePsswd $2 || lg_prt "ry" "[✖] Parametros insuficientes" "Usa --help";;
			-r|--reset) 	resetConnection;;
	        -h|--help|*) 	helpPanel;;
		esac

		exit 0
	else
		lg_prt "ry" "[✖] Parametros no válidos o insuficientes." "Usa --help"

	fi

else
	 lg_prt "r" "[✖] Es necesario tener permisos ROOT"
	 exit 1
fi
