#!/bin/bash

# Instalar whiptail y parted
pacman -Sy --noconfirm --needed parted libnewt xfsprogs

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

# Función para salirnos del script
script_exit(){
	whip_yes "Salir" "¿Desea cancelar la instalación? En caso contrario re-eligiera su esquema de particiones" &&
	exit 1
}

# Función que nos muestra como quedarían las particiones de nuestra instalación para
# confirmar los cambios. También prepara las variables para formatear los discos
scheme_show(){
	# Inicializamos nuestras variables
	local scheme # Variable con el esquema de particiones completo
	bootmount= # Punto de montaje con la partición de arranque
	bootpart= # Partición de arranque
	rootpart= # Partición con el sistema
	homepart= # Partición para /home (Si es que esta en otro disco)
	local roottype # Tipo de / ( Encriptado o sin encriptación)
	# Establecemos la partición de arranque en función del tipo de sistema
	if [ "$PART_TYPE" == "msdos" ]; then
		bootmount="/boot"
	else
		bootmount="/boot/efi"
	fi
	# Definimos el nombre de las particiones
	# de nuestro disco principal*
	case "$ROOT_DISK" in
	*"nvme"*)
		bootpart="$ROOT_DISK"p1
		rootpart="$ROOT_DISK"p2 ;;
	*) # *Los NVME tienen un esquema de ordenación diferente
		bootpart="$ROOT_DISK"1
		rootpart="$ROOT_DISK"2 ;;
	esac
	# Definimos el nombre de las particiones
	# de nuestro disco /home (Si lo hay)
	if [ "$home_partition" == "true" ]; then
		case "$HOME_DISK" in
		*"nvme"*)
			homepart="$HOME_DISK"p1 ;;
		*)
			homepart="$HOME_DISK"1 ;;
		esac
	fi
	# Mostraremos si el disco duro esta encriptado o no
	if [ "$crypt_root" == "true" ]; then
		roottype="LUKS"
	else
		roottype="/"
	fi
	# Creamos el esquema que whiptail nos mostrará
	scheme="/dev/$ROOT_DISK $(lsblk -dn -o size /dev/"$ROOT_DISK")
	$bootmount  /dev/$bootpart
	$roottype  /dev/$rootpart
	"
	if [ "$crypt_root" == "true" ]; then
	scheme+="   /  /dev/mapper/root"
	fi

	if [ "$home_partition" == "true" ]; then
	scheme+="
/dev/$HOME_DISK $(lsblk -dn -o size /dev/"$HOME_DISK")
	/home  /dev/$homepart"
	fi
	scheme+="
Aceptar los cambios borrará el contenido de todos los discos mostrados"
	# Mostramos el esquema para confirmar los cambios
	whiptail --title "Confirmar particionado" --yesno "$scheme" 14 60 ||
	script_exit
}

# Función para elegir como se formatearán nuestros discos
scheme_setup(){
local scheme_confirm="false"
while [ "$scheme_confirm" == "false" ]; do
	# Elegimos el disco para /
	local root_selected="false"
	while [ "$root_selected" == "false" ]; do
	ROOT_DISK=$(whip_menu "Discos disponibles" "Selecciona un disco para la instalación:" \
	"$(lsblk -dn -o name,size | tr '\n' ' ')" ) && \
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
	"$(lsblk -dn -o name,size | grep -v "$ROOT_DISK" | tr '\n' ' ')") && \
	home_selected=true
	done
	# Elegimos si queremos encriptación en el disco /
	if whip_yes "LUKS" "¿Desea usar encriptación para la partición /?"; then
		crypt_root=true
	else
		crypt_root=false
	fi
	# Confirmamos los cambios
	if scheme_show; then
		scheme_confirm=true
	else
		whip_msg "ERROR" "Hubo un error al comprobar el esquema de particiones elegido, o el usuario canceló la operación."
	fi
done
}

root_encrypt(){
while true; do
	whip_msg "LUKS" "Se va a encriptar el disco /. A continuación se te pedirá la contraseña del disco"
	cryptsetup luksFormat -q --verify-passphrase "/dev/$rootpart" && break
	whip_msg "LUKS" "Hubo un error, deberá introducir la contraseña otra vez"
done
	cryptsetup open "/dev/$rootpart" cryptroot
}

home_delete_confirm(){
whiptail --title "$HOME_DISK" --yesno \
"¿Desea borrar todos los datos de $HOME_DISK? Esto borrara toda la información que este contiene (Documentos, imágenes, videos, etc).\n
En caso contrario se utilizará el disco duro tal cual esta ahora (Si esque ya se uso en otra instalación como /home)" 13 60
}

format_disks(){
	# Borramos todas las firmas de nuestros discos
	wipefs --all "/dev/$ROOT_DISK"
	if [ "$home_partition" == "true" ] && home_delete_confirm; then
		home_fresh="true"
		wipefs --all /dev/$HOME_DISK
	else
		home_fresh="false"
	fi
	# Creamos nuestra tabla de particionado y partición de arranque
	if [ "$PART_TYPE" == "msdos" ]; then # BIOS -> MBR
		echo -e "label: dos\nstart=1MiB, size=512MiB, type=83\n" | \
		sfdisk -f "/dev/$ROOT_DISK"; mkfs.ext4 "/dev/$bootpart"
	else # UEFI -> GPT
		echo -e "label: gpt\nstart=1MiB, size=512MiB, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B\n" | \
		sfdisk -f "/dev/$ROOT_DISK"; mkfs.fat -F32 "/dev/$bootpart"
	fi

	# Creamos la partición root
	parted -s "/dev/$ROOT_DISK" mkpart primary 513MiB 100%
	[ "$crypt_root" == "true" ] && root_encrypt && rootpart="mapper/cryptroot"

	# Formateamos nuestra partición "/"
	if [ "$ROOT_FILESYSTEM" = "ext4" ]; then
		mkfs.ext4 "/dev/$rootpart"
	elif [ "$ROOT_FILESYSTEM" = "xfs" ]; then
		mkfs.xfs -f "/dev/$PART3"
	elif [ "$ROOT_FILESYSTEM" = "btrfs" ]; then
		mkfs.btrfs -f "/dev/$rootpart"
		mount "/dev/$rootpart" /mnt
		btrfs subvolume create /mnt/@
		# Se crea el subvolumen @home si no hay un disco para "/home".
		[ "$home_partition" != "true" ] && btrfs subvolume create /mnt/@home
		umount /mnt
	fi

	# Formateamos nuestra partición "/home" (Si es necesario)
	if [ "$home_partition" = true ]; then
		if [ "$PART_TYPE" == "msdos" ]; then # Creamos la tabla de particionado
			parted "/dev/$HOME_DISK" mklabel msdos
		else
			parted "/dev/$HOME_DISK" mklabel gpt
		fi
		parted -a optimal "/dev/$HOME_DISK" mkpart primary ext4 1MiB 100%
		if [ "$HOME_FILESYSTEM" = "ext4" ]; then
			mkfs.ext4 "/dev/$homepart"
		elif [ "$HOME_FILESYSTEM" = "xfs" ]; then
			mkfs.xfs -f "/dev/$homepart"
		elif [ "$HOME_FILESYSTEM" = "btrfs" ]; then
			mkfs.btrfs -f "/dev/$homepart" # Sin sub-volúmenes, pues raramente se usan para /home
		fi
	fi
}

# Función para montar nuestras particiones
mount_partitions(){
	if [ "$ROOT_FILESYSTEM" = "btrfs" ]; then
		mount -o noatime,compress=zstd,subvol=@ "/dev/$rootpart" /mnt && \
		mkdir -p /mnt/home
		if [ "$home_partition" == "true" ]; then
			mount -o noatime "/dev/$homepart" /mnt/home
		else
			mount -o noatime,compress=zstd,subvol=@home "/dev/$rootpart" /mnt/home
		fi
	else
		mount -o noatime "/dev/$rootpart" /mnt
		if [ "$home_partition" == "true" ]; then
			mkdir -p /mnt/home
			mount -o noatime "/dev/$homepart" /mnt/home
		fi
	fi

	if [ "$crypt_root" == "true" ] || [ "$PART_TYPE" == "msdos" ]; then
		mkdir /mnt/boot
		mount "/dev/$bootpart" /mnt/boot
	else
		mkdir -p /mnt/boot/efi
		mount "/dev/$bootpart" /mnt/boot/efi
	fi
}

make_fstab(){
	fstabgen -U /mnt >> /mnt/etc/fstab
}

##########
# SCRIPT #
##########

# Elegimos como se formatearán nuestros discos
scheme_setup
# Elegimos el formato que queremos para nuestros discos
ROOT_FILESYSTEM=$(whip_menu "Sistema de archivos" "Selecciona el sistema de archivos para /:" \
	"ext4" "Ext4" "btrfs" "Btrfs" "xfs" "XFS")
[ "$home_partition" = true ] && HOME_FILESYSTEM=$(whip_menu "Sistema de archivos" "Selecciona el sistema de archivos para /home:" \
	"ext4" "Ext4" "btrfs" "Btrfs" "xfs" "XFS")
# Formateamos los discos
format_disks
# Montamos nuestras particiones
mount_partitions
