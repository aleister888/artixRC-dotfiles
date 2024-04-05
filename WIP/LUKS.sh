#!/bin/bash

# Instalar whiptail y parted
pacman -Sy --noconfirm --needed parted libnewt
# Detectar si el sitema es UEFI o BIOS.
if [ ! -d /sys/firmware/efi ]; then
	PART_TYPE="msdos" # MBR para BIOS
else
	PART_TYPE="gpt" # GPT para UEFI
fi

whip_msg(){
	whiptail --title "$1" --msgbox "$2" 10 60
}

whip_yes(){
	whiptail --title "$1" --yesno "$2" 10 60
}

whip_menu(){
	local TITLE=$1
	local MENU=$2
	shift 2
	whiptail --title "$TITLE" --menu "$MENU" 15 60 4 $@ 3>&1 1>&2 2>&3
}

echo_msg(){
	clear; echo "$1"; sleep 1
}

scheme_show(){
	# Inicializamos nuestras variables
	local scheme # Variable con el esquema de particiones completo
	local bootmount # Punto de montaje con la partición de arranque
	local bootpart # Partición de arranque
	local rootpart # Partición con el sistema
	local roottype # Tipo de / ( Encriptado o sin encriptación)
	# Establecemos la partición de arranque en función del tipo de sistema
	if [ "$PART_TYPE" == "msdos" ]; then
		bootmount="/boot"
	else
		bootmount="/boot/efi"
	fi
	# Ajustamos / en función del tipo de disco
	case "$ROOT_DISK" in
	*"nvme"*)
		bootpart="$ROOT_DISK"p1
		rootpart="$ROOT_DISK"p2 ;;
	*)
		bootpart="$ROOT_DISK"1
		rootpart="$ROOT_DISK"2 ;;
	esac
	# Ajustamos / en función del tipo de disco
	if [ "$home_partition" == "true" ]; then
		local homepart
		case "$HOME_DISK" in
		*"nvme"*)
			homepart="$HOME_DISK"p2 ;;
		*)
			homepart="$HOME_DISK"2 ;;
		esac
	fi
	# Vemos si / estará encriptado o no
	if [ "$crypt_root" == "true" ]; then
		roottype=LUKS
	else
		roottype=/
	fi

	if [ "$home_partition" == "true" ]; then
	scheme="/dev/$ROOT_DISK
	$bootmount /dev/$bootpart
/dev/$HOME_DISK
	/home /dev/$homepart
$roottype /dev/$rootpart"
	else
	scheme="/dev/$ROOT_DISK
	$bootmount /dev/$bootpart
$roottype /dev/$rootpart"
	fi

	if [ "$crypt_root" == "true" ]; then
	scheme+="
	/ /dev/mapper/root"
	fi

	whiptail --title "Confirmar particionado" --yesno "$scheme" 12 40
}

scheme_setup(){
local scheme_confirm="false"
while [ "$scheme_confirm" == "false" ]; do
	# Elegimos el disco para /
	local root_selected="false"
	while [ "$root_selected" == "false" ]; do
	ROOT_DISK=$(whip_menu "Discos disponibles" "Selecciona un disco para la instalación:" \
	"$(lsblk -d -o name,size,type | grep "disk" | awk '{print $1 " " $2}' | tr '\n' ' ')" ) && \
	root_selected=true
	done

	# Preguntamos si queremos un disco dedicado para /home
	if whip_yes "Partición /home" "¿Tiene un disco dedicado para su partición /home?"; then
		home_partition=true
	else
		home_partition=false
	fi

	# Si queremos un disco para /home, elegimos cual
	local home_selected="false"
	[ "$home_partition" = true ] && \
	while [ "$home_selected" == "false" ]; do
	HOME_DISK=$(whip_menu "Discos disponibles" "Seleccione un disco para su partición /home:" \
	"$(lsblk -d -o name,size,type | grep "disk" | awk '{print $1 " " $2}' | grep -v "$ROOT_DISK" | tr '\n' ' ')") && \
	home_selected=true
	done

	# Elegimos si queremos encriptación en el disco /
	if whip_yes "LUKS" "¿Desea usar encriptación para la partición /?"; then
		crypt_root=true
	else
		crypt_root=false
	fi

	if scheme_show; then
		scheme_confirm=true
	else
		whip_msg "ERROR" "Hubo un error al comprobar el esquema de particiones elegido, o el usuario cancelo la operación."
	fi
done
}

scheme_format(){
	echo WIP
}

scheme_format(){
	echo WIP
}

scheme_setup
