#!/usr/bin/env bash

# Instalar whiptail y parted
pacman -Sy --noconfirm --needed parted libnewt >/dev/null

# Detectar si el sitema es UEFI o BIOS.
if [ ! -d /sys/firmware/efi ]; then
	PART_TYPE='msdos' # MBR para BIOS
else
	PART_TYPE='gpt' # GPT para UEFI
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

home_setup(){
# Elegimos el disco para "/home" (Excluimos de la lista el disco ya elegido para "/").
HOME_DISK=$(whip_menu "Discos disponibles" "Seleccione un disco para su partición /home:" \
"$(lsblk -d -o name,size,type | grep "disk" | awk '{print $1 " " $2}' | grep -v $INSTALL_DISK | tr '\n' ' ')")

# Comprobamos que este disco tenga almenos una partición creada.
case "$HOME_DISK" in
*"nvme"*)
	HOME_DISK_STRUCT=$(lsblk -o NAME -n -l /dev/$HOME_DISK* | grep -o 'nvme.n.p[0-9]*')
	HOME_DISK_COUNT=$(lsblk -o NAME -n -l /dev/$HOME_DISK* | grep -oc 'nvme.n.p[0-9]*')
	;;
*)
	HOME_DISK_STRUCT=$(lsblk -o NAME -n -l /dev/$HOME_DISK* | grep '[0-9]')
	HOME_DISK_COUNT=$(lsblk -o NAME -n -l /dev/$HOME_DISK* | grep -c '[0-9]')
	;;
esac

case "$HOME_DISK" in
	*"nvme"*)
		HOME_SELECTED_PARTITION="$HOME_DISK"p1 ;;
	*)
		HOME_SELECTED_PARTITION="$HOME_DISK"1 ;;
esac

# Si no hay niguna partición ya creada preguntamos al usuario que tipo de partición quiere y la creamos.
if [ $HOME_DISK_COUNT -lt 1 ]; then
	home_partition
# Si ya hay más de una partición presente, se pide al usuario que escoga que partición usar.
elif [ $HOME_DISK_COUNT -gt 1 ]; then
	HOME_PARTITIONS=$(echo $HOME_DISK_STRUCT | tr '\n' ' ')
	HOME_PARTITIONS_ARRAY=()
	for HOME_PARTITION in $HOME_PARTITIONS; do
		HOME_PARTITIONS_ARRAY+=("$HOME_PARTITION" "$HOME_PARTITION")
	done
	HOME_SELECTED_PARTITION=$(whip_menu "Elegir Partición" \
	"Eliga cual partición de $HOME_DISK desea usar para /home:" ${HOME_PARTITIONS_ARRAY[@]})
# Si hay una sola partición ya creada en el disco duro se utilizara esta.
fi
}

home_partition(){
HOME_FILESYSTEM=$(whip_menu "Sistema de archivos" "Selecciona el sistema de archivos para /home:" \
	"ext4" "Ext4" "btrfs" "Btrfs" "xfs" "XFS")
if [ "$PART_TYPE" == "msdos" ]; then
	# BIOS -> MBR
	echo -e "label: dos\nstart=1MiB, size=512MiB, type=83\n" | sfdisk /dev/$HOME_DISK
else
	# EUFI -> GPT
	echo -e "label: gpt\nstart=1MiB, size=512MiB, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B\n" | sfdisk /dev/$HOME_DISK
fi
if   [ "$HOME_FILESYSTEM" = "ext4" ]; then
	mkfs.ext4 "/dev/$HOME_SELECTED_PARTITION"
elif [ "$HOME_FILESYSTEM" = "btrfs" ]; then
	mkfs.btrfs -f "/dev/$HOME_SELECTED_PARTITION"
elif [ "$HOME_FILESYSTEM" = "xfs" ]; then
	pacman -Sy --noconfirm --needed xfsprogs
	mkfs.xfs "/dev/$HOME_SELECTED_PARTITION"
fi
}

disk_setup(){
# Elegir el tipo de partición para "/".
INSTALL_FILESYSTEM=$(whip_menu "Sistema de archivos" "Selecciona el sistema de archivos para la instalación:" \
	"ext4" "Ext4" "btrfs" "Btrfs" "xfs" "XFS")

# Elegir el disco duro para la instalación.
INSTALL_DISK=$(whip_menu "Discos disponibles" "Selecciona un disco para la instalación:" \
	"$(lsblk -d -o name,size,type | grep "disk" | awk '{print $1 " " $2}' | tr '\n' ' ')" )

# Confirmar los cambios.
if [ -z $INSTALL_DISK ] || [ -z $INSTALL_FILESYSTEM ] || \
! whip_yes "Confirmación" "¿Estás seguro? Se borrarán todos los datos en $INSTALL_DISK."; then
	whip_msg "Operación Cancelada" "La instalación ha sido cancelada."
	exit 1
fi

if whip_yes "Partición /home" "¿Tiene un disco dedicado para su partición /home?"; then
	home_setup
fi
}

disk_partition(){
# Definimos las particiones que usara el auto-particionador.
case "$INSTALL_DISK" in
*"nvme"*)
	PART1="$INSTALL_DISK"p1
	PART2="$INSTALL_DISK"p2
	PART3="$INSTALL_DISK"p3
	;;
*)
	PART1="$INSTALL_DISK"1
	PART2="$INSTALL_DISK"2
	PART3="$INSTALL_DISK"3
	;;
esac

# Creamos nuestras tablas de particiones y formateamos acordemente nuestra partición de arranque.
if [ "$PART_TYPE" == "msdos" ]; then
	# BIOS -> MBR
	echo -e "label: dos\nstart=1MiB, size=512MiB, type=83\n" | sfdisk /dev/$INSTALL_DISK
	mkfs.ext4 "/dev/$PART1"
else
	# EUFI -> GPT
	echo -e "label: gpt\nstart=1MiB, size=512MiB, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B\n" | sfdisk /dev/$INSTALL_DISK
	mkfs.fat -F32 "/dev/$PART1"
fi

# Creamos nuestra partición SWAP.
parted -s "/dev/$INSTALL_DISK" mkpart primary linux-swap 513MiB 4.5GB
mkswap "/dev/$PART2"
swapon "/dev/$PART2"

# Creamos nuestra partición "/" y "/home".
if [ "$INSTALL_FILESYSTEM" = "ext4" ]; then
	parted -s "/dev/$INSTALL_DISK" mkpart primary ext4 4.5GB 100%
	mkfs.ext4 "/dev/$PART3"
elif [ "$INSTALL_FILESYSTEM" = "btrfs" ]; then
	parted -s "/dev/$INSTALL_DISK" mkpart primary btrfs 4.5GB 100%
	mkfs.btrfs -f "/dev/$PART3"
	mount "/dev/$PART3" /mnt
	btrfs subvolume create /mnt/@
	# Se crea el subvolumen @home si no hay un disco para "/home".
	[ -n "$HOME_SELECTED_PARTITION" ] && btrfs subvolume create /mnt/@home
	umount /mnt
elif [ "$INSTALL_FILESYSTEM" = "xfs" ]; then
	pacman -Sy --noconfirm --needed xfsprogs
	parted -s "/dev/$INSTALL_DISK" mkpart primary xfs 4.5GB 100%
	mkfs.xfs "/dev/$PART3"
fi
}

partition_mount(){
# Creamos nuestra carpeta para la partición de arranque y la montamos.
if [ "$PART_TYPE" == "msdos" ]; then
	BOOT_PART="/mnt/boot"
else
	BOOT_PART="/mnt/boot/efi"
fi
mkdir -p "$BOOT_PART"
mount "/dev/$PART1" "$BOOT_PART"
# Montamos nuestras particiones "/" y "/home".
if [ "$INSTALL_FILESYSTEM" = "btrfs" ]; then
	mount -o noatime,compress=zstd,subvol=@ "/dev/$PART3" /mnt
	if [ -n "$HOME_SELECTED_PARTITION" ]; then
		mkdir -p /mnt/home
		mount -o noatime /dev/"$HOME_SELECTED_PARTITION" /mnt/home
	else
		mount -o noatime,compress=zstd,subvol=@home "/dev/$PART3" /mnt/home
	fi
else
	mount -o noatime "/dev/$PART3" /mnt
	if [ -n "$HOME_SELECTED_PARTITION" ]; then
		mkdir -p /mnt/home
		mount -o noatime /dev/"$HOME_SELECTED_PARTITION" /mnt/home
	fi
fi
}

disk_setup

disk_partition

partition_mount

lsblk -f
