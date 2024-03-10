#!/bin/bash

whip_msg(){
	whiptail --title "$1" --msgbox "$2" 10 60
}

whip_yes(){
	whiptail --title "$1" --yesno "$2" 10 60
}

# Instalr whiptail y parted
pacman -Sy --noconfirm --needed parted libnewt >/dev/null 2>&1

# Elegir el tipo de partición
fs_type=$(whiptail --title "Selecciona el sistema de archivos" \
	--menu "Selecciona el sistema de archivos para formatear los discos:" 15 60 2 \
	"ext4" "Ext4" "btrfs" "Btrfs" 3>&1 1>&2 2>&3)

# Listar los discos disponibles
disk=$(whiptail --title "Selecciona un disco para formatear" \
	--menu "Discos disponibles:" 15 60 4 \
	$(lsblk -d -o name,size,type | grep "disk" | awk '{print $1 " " $2}' | tr '\n' ' ') 3>&1 1>&2 2>&3)

# Confirmar los cambios
if [ $? -ne 0 ]; then
	whip_msg "Operación cancelada" "No se ha seleccionado ningún disco. La operación ha sido cancelada."
	exit 1
fi

# Confirmar con Whiptail los cambios
if ! whip_yes "Confirmar formateo" "Estás seguro de que quieres formatear $disk?"; then
	whip_msg "Operación cancelada" "El formateo ha sido cancelado."
	exit 1
fi

# Preguntamos al usuario si ya tiene un disco para su partición /home
if whip_yes "Partición /home" "¿Tiene un disco dedicado para su partición /home?"; then
	# Preguntamos cúal es ese disco
	home_disk=$(whiptail --title "Selecciona un disco para /home" \
		--menu "Discos disponibles:" 15 60 4 \
		$(lsblk -d -o name,size,type | grep "disk" | awk '{print $1 " " $2}' | tr '\n' ' ') \
		3>&1 1>&2 2>&3)
	# Preguntamos si queremos formatear el disco /home o solo montarlo tal como está
	if whip_yes "Partición /home" "¿Desea re-formatear el disco dedicado para su partición /home? (Seleccionar 'No' montará el disco tal y como está en /mnt/home)"; then
		if whip_yes "Partición /home" "¿Está seguro, esto borrara toda la información en $home_disk?"; then
			home_format=true
		fi
	fi
fi

# Formatear el disco seleccionado
whiptail --title "Formateando disco" --infobox "Formateando disco $disk..." 10 60

if [ ! -d /sys/firmware/efi ]; then
	part_type='msdos' # MBR para BIOS
else
	part_type='gpt' # GPT para UEFI
fi

# The idea for defining partitions like this was taken from:
# https://github.com/Zaechus/artix-installer/blob/main/install.sh

# Definimos nuestras particiones
case "$disk" in
*"nvme"*)
	part1="$disk"p1
	part2="$disk"p2
	part3="$disk"p3
	;;
*)
	part1="$disk"1
	part2="$disk"2
	part3="$disk"3
	;;
esac

# Creamos una partición /boot o /boot/efi dependiendo
# de si estamos en un sistema UEFI o no
if [ "$part_type" == "msdos" ]; then
	# BIOS -> MBR
	echo -e "label: dos\nstart=1MiB, size=512MiB, type=83\n" | sfdisk /dev/$disk
	mkfs.ext4 "/dev/$part1"
else
	# EUFI -> GPT
	echo -e "label: gpt\nstart=1MiB, size=512MiB, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B\n" | sfdisk /dev/$disk
	mkfs.fat -F32 "/dev/$part1"
fi

# Crear partición swap de 4GB
parted -s "/dev/$disk" mkpart primary linux-swap 513MiB 4.5GB
mkswap "/dev/$part2"
swapon "/dev/$part2"

# Crear partición / y /home
if [ "$fs_type" = "ext4" ]; then
	parted -s "/dev/$disk" mkpart primary ext4 4.5GB 100%
	mkfs.ext4 "/dev/$part3"
elif [ "$fs_type" = "btrfs" ]; then
	# Partición primaria / BTRFS
	parted -s "/dev/$disk" mkpart primary btrfs 4.5GB 100%
	mkfs.btrfs -f "/dev/$part3"
	
	# Crear subvolúmenes para / y /home
	mount "/dev/$part3" /mnt
	btrfs subvolume create /mnt/@
	# Creamos el subvolúmen @home si no se eleigio un disco para /home
	[ -z "$home_disk" ] && btrfs subvolume create /mnt/@home
	umount /mnt
	
fi

# Montar particiones
# Si no se eleigió un disco para /home, montar las particiones normalmente
if [ -z $home_disk ]; then
	if [ "$fs_type" = "ext4" ]; then
		mount -o noatime "/dev/$part3" /mnt
	elif [ "$fs_type" = "btrfs" ]; then
		# Montar subvolúmenes
		mount -o noatime,compress=zstd,subvol=@ "/dev/$part3" /mnt
		mkdir -p /mnt/home
		mount -o noatime,compress=zstd,subvol=@home "/dev/$part3" /mnt/home
	fi
else
# Si se eleigió un disco para /home:
#  - Montarlo en /mnt/home, si no se requiere formatearlo
	if [ -z $home_format ]; then
		if [ "$fs_type" = "ext4" ]; then
			mount -o noatime "/dev/$part3" /mnt
		elif [ "$fs_type" = "btrfs" ]; then
			mount -o noatime,compress=zstd,subvol=@ "/dev/$part3" /mnt
		fi
		mkdir -p /mnt/home
		mount $home_disk /mnt/disk
#  - Formatearlo y montarlo en /mnt/home si se eligió así
	else
		if [ "$fs_type" = "ext4" ]; then
			# Formatear disco /home
			# PLACEHOLDER
			mount -o noatime "/dev/$part3" /mnt
			mkdir -p /mnt/home
			mount -o noatime "/dev/$home_disk" /mnt/home
		elif [ "$fs_type" = "btrfs" ]; then
			# Formatear disco /home
			# PLACEHOLDER
			mount -o noatime,compress=zstd,subvol=@ "/dev/$part3" /mnt
			mkdir -p /mnt/home
			mount -o noatime,compress=zstd "/dev/$home_disk" /mnt/home
		fi
	fi
fi


if [ "$part_type" == "msdos" ]; then
	boot_part="/mnt/boot"
else
	boot_part="/mnt/boot/efi"
fi
mkdir -p "$boot_part"
mount "/dev/$part1" "$boot_part"

whiptail --title "Formateo completado" --msgbox "El formateo ha sido completado." 10 60

# Instalar paquetes con basestrap (fstab se genera automaticamente)
basestrap /mnt base elogind-openrc openrc linux linux-firmware neovim opendoas mkinitcpio

# Configurar Opendoas
echo "permit nopass keepenv setenv { XAUTHORITY LANG LC_ALL } :wheel" > /mnt/etc/doas.conf

fstabgen -U /mnt >> /mnt/etc/fstab

# Montar directorios importantes para el chroot
mount -t proc proc /mnt/proc
mount --bind /sys /mnt/sys
mount --bind /dev /mnt/dev
mount --bind /dev/pts /mnt/dev/pts
mount --bind /dev/shm /mnt/dev/shm
mount --bind /run /mnt/run

chroot /mnt bash -c "curl -s https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/main/stage2.sh | bash"
