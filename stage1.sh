#!/bin/bash

# Instalar whiptail y parted
pacman -Sy --noconfirm --needed parted libnewt
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

echo_msg(){
	clear; echo $1; sleep 1
}

home_setup(){
# Elegimos el disco para "/home" (Excluimos de la lista el disco ya elegido para "/").
HOME_DISK=$(whip_menu "Discos disponibles" "Seleccione un disco para su partición /home:" \
"$(lsblk -d -o name,size,type | grep "disk" | awk '{print $1 " " $2}' | grep -v "$INSTALL_DISK" | tr '\n' ' ')")

# Comprobamos que este disco tenga almenos una partición creada.
case "$HOME_DISK" in
*"nvme"*)
	HOME_DISK_STRUCT=$(lsblk -o NAME -n -l /dev/"$HOME_DISK"* | grep -o 'nvme.n.p[0-9]*')
	HOME_DISK_COUNT=$(lsblk -o NAME -n -l /dev/"$HOME_DISK"* | grep -oc 'nvme.n.p[0-9]*')
	HOME_SELECTED_PARTITION="$HOME_DISK"p1 ;;
*)
	HOME_DISK_STRUCT=$(lsblk -o NAME -n -l /dev/"$HOME_DISK"* | grep '[0-9]')
	HOME_DISK_COUNT=$(lsblk -o NAME -n -l /dev/"$HOME_DISK"* | grep -c '[0-9]')
	HOME_SELECTED_PARTITION="$HOME_DISK"1 ;;
esac

# Si no hay niguna partición ya creada preguntamos al usuario que tipo de partición quiere y la creamos.
if [ "$HOME_DISK_COUNT" -lt 1 ]; then
	home_partition
# Si hay una sola partición ya existente, se pregunta al usuario si quiere utilizarla como /home
# o si quiere borrarla y crear una nueva
elif [ "$HOME_DISK_COUNT" -eq 1 ]; then
	if ! whip_yes "Partición detectada" "¿Desea usar $HOME_SELECTED_PARTITION como /home? En caso contrario, se formateará el disco."; then
		if whip_yes "Confirmación" "¿Estás seguro? Esto borrara toda la información en $HOME_SELECTED_PARTITION"; then
			home_partition
		fi
	fi
# Si ya hay más de una partición presente, se pide al usuario que escoga que partición usar.
elif [ "$HOME_DISK_COUNT" -gt 1 ]; then
		HOME_PARTITIONS=$(echo "$HOME_DISK_STRUCT" | tr '\n' ' ')
		declare -a HOME_PARTITIONS_ARRAY=()
		for HOME_PARTITION in $HOME_PARTITIONS; do
			SIZE=$(lsblk -o size /dev/"$HOME_PARTITION" | tail -n 1)
			HOME_PARTITIONS_ARRAY+=("$HOME_PARTITION" "$SIZE")
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
	echo -e "label: dos\n,,\n" | sfdisk -f /dev/"$HOME_DISK" >/dev/null # BIOS -> MBR
else
	echo -e "label: gpt\n,,\n" | sfdisk -f /dev/"$HOME_DISK" >/dev/null # EUFI -> GPT
fi

if   [ "$HOME_FILESYSTEM" = "ext4" ]; then
	mkfs.ext4 "/dev/$HOME_SELECTED_PARTITION"
elif [ "$HOME_FILESYSTEM" = "btrfs" ]; then
	mkfs.btrfs -f "/dev/$HOME_SELECTED_PARTITION"
elif [ "$HOME_FILESYSTEM" = "xfs" ]; then
	pacman -Sy --noconfirm --needed xfsprogs
	mkfs.xfs -f "/dev/$HOME_SELECTED_PARTITION"
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
if [ -z "$INSTALL_DISK" ] || [ -z "$INSTALL_FILESYSTEM" ] || \
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
	echo -e "label: dos\nstart=1MiB, size=512MiB, type=83\n" | sfdisk -f /dev/"$INSTALL_DISK" >/dev/null
	mkfs.ext4 "/dev/$PART1"
else
	# EUFI -> GPT
	echo -e "label: gpt\nstart=1MiB, size=512MiB, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B\n" | sfdisk -f /dev/"$INSTALL_DISK" >/dev/null
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
	if [ -n "$HOME_SELECTED_PARTITION" ]; then
		umount /mnt
	else
		btrfs subvolume create /mnt/@home
		umount /mnt
	fi
elif [ "$INSTALL_FILESYSTEM" = "xfs" ]; then
	pacman -Sy --noconfirm --needed xfsprogs
	parted -s "/dev/$INSTALL_DISK" mkpart primary xfs 4.5GB 100%
	mkfs.xfs -f "/dev/$PART3"
fi
}

partition_mount(){
# Montamos nuestras particiones "/" y "/home".
if [ "$INSTALL_FILESYSTEM" = "btrfs" ]; then
	mount -o noatime,compress=zstd,subvol=@ "/dev/$PART3" /mnt
	mkdir -p /mnt/home
	if [ -n "$HOME_SELECTED_PARTITION" ]; then
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

# Creamos nuestro directorio de arranque.
if [ "$PART_TYPE" == "msdos" ]; then
	mkdir -p /mnt/boot
	mount "/dev/$PART1" /mnt/boot
else
	mkdir -p /mnt/boot/efi
	mount "/dev/$PART1" /mnt/boot/efi
fi
}

# Formateamos los discos duros
if disk_setup && disk_partition && partition_mount; then
	echo_msg "El formateo ha sido completado."
fi

# Instalar paquetes con basestrap
basestrap_pkgs="base elogind-openrc openrc linux linux-firmware neovim opendoas mkinitcpio wget libnewt"
if [ "$INSTALL_FILESYSTEM" = "xfs" ] || [ "$HOME_FILESYSTEM" = "xfs" ]; then
	basestrap_pkgs="$basestrap_pkgs xfsprogs"
fi
basestrap /mnt $basestrap_pkgs

mkdir -p /mnt/etc
echo "permit nopass keepenv setenv { XAUTHORITY LANG LC_ALL } :wheel" > /mnt/etc/doas.conf

fstabgen -U /mnt >> /mnt/etc/fstab

# Montar directorios importantes para el chroot
for dir in dev proc sys run; do mount --rbind /$dir /mnt/$dir; mount --make-rslave /mnt/$dir; done
#mount -t proc proc /mnt/proc
#mount --bind /sys /mnt/sys
#mount --bind /dev /mnt/dev
#mount --bind /dev/pts /mnt/dev/pts
#mount --bind /dev/shm /mnt/dev/shm
#mount --bind /run /mnt/run

# Hacer chroot y ejecutar la 2a parte del script

chroot /mnt bash -c "cd /tmp &&
wget https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/main/stage2.sh &&
chmod 700 stage2.sh &&
./stage2.sh"
