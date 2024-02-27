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

if [ ! -d /sys/firmware/efi ]; then
	part_type='dos' # MBR para BIOS
else
	part_type='gpt' # GPT para UEFI
fi

# Creamos una partición /boot o /boot/efi dependiendo
# de si estamos en un sistema UEFI o no
if [ "$part_type" == "dos" ]; then
	# BIOS -> MBR
	parted -s /dev/$disk mklabel $part_type mkpart primary ext4 1MiB 513MiB set 1 boot on
	[ "$disk" == "nvme*" ] && disk = "$disk"p
	fi
	mkfs.ext4 /dev/${disk}1
	boot_partition="/dev/${disk}1"
else
	# EUFI -> GPT
	parted -s /dev/$disk mklabel $part_type mkpart primary fat32 1MiB 513MiB set 1 boot on
	[ "$disk" == "nvme*" ] && disk = "$disk"p
	mkfs.fat -F32 /dev/${disk}1
	boot_partition="/dev/${disk}1"
fi

# Crear partición swap de 4GB
parted -s /dev/$disk mkpart primary linux-swap 513MiB 4.5GB

# Partición primaria / BTRFS
parted -s /dev/$disk mkpart primary btrfs 4.5GB 100%
mkfs.btrfs /dev/${disk}3

# Crear subvolúmenes para / y /home
mount /dev/${disk}3 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt

# Montar subvolúmenes
mount -o noatime,compress=zstd,subvol=@ /dev/${disk}3 /mnt
mkdir -p /mnt/home
mount -o noatime,compress=zstd,subvol=@home /dev/${disk}3 /mnt/home

echo "Formateo completado."

# Instalar paquetes con basestrap (fstab se genera automaticamente)
echo "Instalando paquetes con basestrap..."
basestrap /mnt base base-devel elogind-openrc openrc linux linux-firmware neovim opendoas mkinitcpio

echo "Configurando Opendoas..."
echo "permit persist keepenv setenv { XAUTHORITY LANG LC_ALL } :wheel" > /mnt/etc/doas.conf

echo "$disk" > /mnt/tmp/diskid

echo -e "\n\n\nVamos a acceder a nuestra instalación, sigue ahora los pasos para Stage 2"
artix-chroot /mnt bash
