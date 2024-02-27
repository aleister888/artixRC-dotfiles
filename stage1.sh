#!/bin/bash

# Listar los discos disponibles
echo "Discos disponibles:"
lsblk -d -o name,size,type | grep "disk"

# Pedir al usuario que seleccione un disco para formatear
read -p "Introduce el nombre del disco que quieres formatear (ejemplo: sda): " disk

# Confirmar los cambios
read -p "Estás seguro de que quieres formatear $disk? (s/n): " confirm
if [ "$confirm" != "s" ]; then
    echo "Operación cancelada."
    exit 1
fi

# Formatear el disco seleccionado
echo "Formateando disco $disk..."

if [ ! -d /sys/firmware/efi ]; then
	part_type='dos' # MBR para BIOS
else
	part_type='gpt' # GPT para UEFI
fi

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
if [ "$part_type" == "dos" ]; then
	# BIOS -> MBR
	parted -s "/dev/$disk" mklabel $part_type mkpart primary ext4 1MiB 513MiB set 1 boot on
	mkfs.ext4 "/dev/$part1"
else
	# EUFI -> GPT
	parted -s "/dev/$disk" mklabel $part_type mkpart primary fat32 1MiB 513MiB set 1 boot on
	mkfs.fat -F32 "/dev/$part1"
fi

# Crear partición swap de 4GB
parted -s "/dev/$part2" mkpart primary linux-swap 513MiB 4.5GB

# Partición primaria / BTRFS
parted -s "/dev/$part3" mkpart primary btrfs 4.5GB 100%
mkfs.btrfs "/dev/$part3"

# Crear subvolúmenes para / y /home
mount "/dev/$part3" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt

# Montar subvolúmenes
mount -o noatime,compress=zstd,subvol=@ "/dev/$part3" /mnt
mkdir -p /mnt/home
mount -o noatime,compress=zstd,subvol=@home "/dev/$part3" /mnt/home

echo "Formateo completado."

# Instalar paquetes con basestrap (fstab se genera automaticamente)
echo "Instalando paquetes con basestrap..."
basestrap /mnt base base-devel elogind-openrc openrc linux linux-firmware neovim opendoas mkinitcpio

echo "Configurando Opendoas..."
echo "permit persist keepenv setenv { XAUTHORITY LANG LC_ALL } :wheel" > /mnt/etc/doas.conf

echo "$disk" > /mnt/tmp/diskid

echo -e "\n\n\nVamos a acceder a nuestra instalación, sigue ahora los pasos para Stage 2"
artix-chroot /mnt bash
