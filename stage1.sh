#!/bin/bash

# Instalr whiptail y parted
pacman -Sy --noconfirm --needed parted newt >/dev/null 2>&1

# Listar los discos disponibles
disk=$(whiptail --title "Selecciona un disco para formatear" --menu "Discos disponibles:" 15 60 4 $(lsblk -d -o name,size,type | grep "disk" | awk '{print $1 " " $2}' | tr '\n' ' ') 3>&1 1>&2 2>&3)

# Confirmar los cambios
if [ $? -ne 0 ]; then
	whiptail --title "Operación cancelada" --msgbox "No se ha seleccionado ningún disco. La operación ha sido cancelada." 10 60
	exit 1
fi

# Confirmar con Whiptail los cambios
if ! whiptail --title "Confirmar formateo" --yesno "Estás seguro de que quieres formatear $disk?" 10 60; then
	whiptail --title "Operación cancelada" --msgbox "El formateo ha sido cancelado." 10 60
	exit 1
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

# Partición primaria / BTRFS
parted -s "/dev/$disk" mkpart primary btrfs 4.5GB 100%
mkfs.btrfs -f "/dev/$part3"

# Crear subvolúmenes para / y /home
mount "/dev/$part3" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt

# Montar subvolúmenes
mount -o noatime,compress=zstd,subvol=@ "/dev/$part3" /mnt
mkdir -p /mnt/home
mount -o noatime,compress=zstd,subvol=@home "/dev/$part3" /mnt/home
if [ "$part_type" == "msdos" ]; then
	boot_part="/mnt/boot"
else
	boot_part="/mnt/boot/efi"
fi
mkdir -p "$boot_part"
mount "/dev/$part1" "$boot_part"
genfstab -U /mnt >> /mnt/etc/fstab

echo "Formateo completado."

# Instalar paquetes con basestrap (fstab se genera automaticamente)
echo "Instalando paquetes con basestrap..."
basestrap /mnt base elogind-openrc openrc linux linux-firmware neovim opendoas mkinitcpio

echo "Configurando Opendoas..."
echo "permit persist keepenv setenv { XAUTHORITY LANG LC_ALL } :wheel" > /mnt/etc/doas.conf

echo -e "\n\n\nVamos a acceder a nuestra instalación, sigue ahora los pasos para Stage 2"
artix-chroot /mnt bash -c "pacman -Sy --noconfirm wget && wget https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/main/stage2.sh && chmod 700 stage2.sh && ./stage2.sh"
