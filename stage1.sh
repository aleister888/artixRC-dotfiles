#!/bin/sh

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

# Creamos una partición /boot o /boot/efi dependiendo
# de si estamos en un sistema UEFI o no
if [ ! -d /sys/firmware/efi ]; then
	parted /dev/$disk mklabel gpt mkpart primary ext4 1MiB 513MiB set 1 boot on
	mkfs.ext4 /dev/${disk}1
	boot_partition="/dev/${disk}1"
else
	parted /dev/$disk mklabel gpt mkpart primary fat32 1MiB 513MiB set 1 boot on
	mkfs.fat -F32 /dev/${disk}1
	boot_partition="/dev/${disk}1"
fi

# Partición primaria / BTRFS
parted /dev/$disk mkpart primary btrfs 513MiB 100%
mkfs.btrfs /dev/${disk}2

# Crear subvolúmenes para / y /home
mount /dev/${disk}2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt

# Montar subvolúmenes
mount -o noatime,compress=zstd,subvol=@ /dev/${disk}2 /mnt
mkdir -p /mnt/home
mount -o noatime,compress=zstd,subvol=@home /dev/${disk}2 /mnt/home

# Desmontar el sistema de archivos
umount /mnt

# Montar subvolúmenes y activar la partición de intercambio (swap)
mount -o noatime,compress=zstd,subvol=@ /dev/${disk}2 /mnt
mkdir -p /mnt/home
mount -o noatime,compress=zstd,subvol=@home /dev/${disk}2 /mnt/home

echo "Formateo completado."

# Instalar paquetes con basestrap (fstab se genera automaticamente)
echo "Instalando paquetes con basestrap..."
basestrap /mnt base base-devel elogind-openrc openrc linux linux-firmware neovim opendoas mkinitcpio

echo "Configurando Opendoas..."
echo "permit persist keepenv setenv { XAUTHORITY LANG LC_ALL } :wheel" > /mnt/etc/doas.conf

echo -e "\n\n\n Vamos a acceder a nuestra instalación, sigue ahora los pasos para Stage 2"
artix-chroot /mnt bash
