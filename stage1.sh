#!/bin/bash -x

# Auto-instalador para Artix OpenRC (Parte 1)
# por aleister888 <pacoe1000@gmail.com>
# Licencia: GNU GPLv3

# Esta parte del script se encarga de formatear y particionar el disco duro e
# instalar los paquetes del sistema base. El esquema de particiones puede ser:
# - ext4  (con o sin encriptación LUKS)
# - btrfs (con o sin encriptación LUKS)
#   - un subvolumen para la partición /     (@)
#   - un subvolumen para la partición /home (@home)

REPO_URL="https://github.com/aleister888/artixRC-dotfiles"

whip_msg(){
	whiptail --backtitle "$REPO_URL" --title "$1" --msgbox "$2" 10 60
}

whip_yes(){
	whiptail --backtitle "$REPO_URL" --title "$1" --yesno "$2" 10 60
}

whip_menu(){
	local TITLE=$1
	local MENU=$2
	shift 2
	whiptail --backtitle "$REPO_URL" \
	--title "$TITLE" --menu "$MENU" 15 60 4 $@ 3>&1 1>&2 2>&3
}

echo_msg(){
	clear; echo "$1"; sleep 1
}

# Función que nos muestra como quedarían las particiones de nuestra instalación para
# confirmar los cambios. También prepara las variables para formatear los discos
scheme_show(){
	local scheme   # Variable con el esquema de particiones completo
	local roottype # Tipo de partición/ (LUKS o normal)
	bootmount=     # Punto de montaje con la partición de arranque
	bootpart=      # Partición de arranque
	rootpart=      # Partición con el sistema

	# Establecemos la partición de arranque en función del tipo de sistema
	if [ "$PART_TYPE" == "msdos" ]; then
		bootmount="/boot"
	else
		bootmount="/boot/efi"
	fi
	# Definimos el nombre de las particiones de nuestro disco principal
	# (Los NVME tienen un sistema de nombrado distinto)
	case "$ROOT_DISK" in
	*"nvme"*)
		bootpart="$ROOT_DISK"p1
		rootpart="$ROOT_DISK"p2 ;;
	*)
		bootpart="$ROOT_DISK"1
		rootpart="$ROOT_DISK"2 ;;
	esac
	# Mostrar si la partición esta encriptada
	if [ "$crypt_root" == "true" ]; then
		roottype="LUKS"
	else
		roottype="/"
	fi

	# Creamos el esquema que whiptail nos mostrará
	scheme="/dev/$ROOT_DISK    $(lsblk -dn -o size /dev/"$ROOT_DISK")
	/dev/$bootpart  $bootmount
	/dev/$rootpart  $roottype
	"
	if [ "$crypt_root" == "true" ]; then
	scheme+="/dev/mapper/root  /"
	fi

	# Mostramos el esquema para confirmar los cambios
	if ! whiptail --backtitle "$REPO_URL" --title "Confirmar particionado" --yesno "$scheme" 15 60; then
		whip_yes "Salir" "¿Desea cancelar la instalacion? En caso contrario, volvera a elegir su esquema de particiones" && \
		exit 1
	fi
}

# Función para elegir como se formatearán nuestros discos
scheme_setup(){
local scheme_confirm="false"

while [ "$scheme_confirm" == "false" ]; do
	while true; do
		ROOT_DISK=$(whip_menu "Discos disponibles" "Selecciona un disco para la instalacion:" \
		"$(lsblk -dn -o name,size | tr '\n' ' ')") && break
	done

	if whip_yes "LUKS" "¿Desea encriptar el disco duro?"; then
		crypt_root=true
	else
		crypt_root=false
	fi

	# Confirmamos los cambios
	if scheme_show; then
		scheme_confirm=true
	else
		whip_msg "ERROR" "Hubo un error al comprobar el esquema de particiones elegido, o el usuario cancelo la operación."
	fi
done
}

part_encrypt(){
	while true; do
		whip_msg "LUKS" "Se va a encriptar el disco $1. A continuacion se te pedira la contraseña del disco"
		cryptsetup luksFormat -q --verify-passphrase "/dev/$2" && break
		whip_msg "LUKS" "Hubo un error, debera introducir la contraseña otra vez"
	done

	while true; do
		whip_msg "LUKS" "Se te pedira la contraseña para poder desencriptar el disco temporalmente y comenzar la instalacion."
		cryptsetup open "/dev/$2" "$3" && break
		whip_msg "LUKS" "Hubo un error, debera introducir la contraseña otra vez"
	done
}

format_disks(){
	# Borramos todas las firmas de nuestros discos y elegimos los tipos de particiones
	ROOT_FILESYSTEM=$(whip_menu "Sistema de archivos" "Selecciona el sistema de archivos para /:" \
	"ext4" "Ext4" "btrfs" "Btrfs")
	wipefs --all "/dev/$ROOT_DISK"

	# Creamos nuestra tabla de particionado y partición de arranque
	if [ "$PART_TYPE" == "msdos" ]; then
		# BIOS -> MBR
		echo -e "label: dos\nstart=1MiB, size=512MiB, type=83\n" | \
		sfdisk --quiet -f "/dev/$ROOT_DISK"; mkfs.fat -F32 "/dev/$bootpart"
	else
		# UEFI -> GPT
		parted "/dev/$ROOT_DISK" --script mklabel gpt mkpart ESP fat32 1MiB 513MiB set 1 boot on
		mkfs.fat -F32 "/dev/$bootpart"
	fi

	# Creamos la partición root
	parted -s "/dev/$ROOT_DISK" mkpart primary 513MiB 100%

	# Si se eligió usar encriptación, es el momento de encriptar nuestra partición
	if [ "$crypt_root" == "true" ]; then
		part_encrypt "/" "$rootpart" "cryptroot" && \
		# Cambiamos el indicador del disco a la partición encriptada
		rootpart="mapper/cryptroot"
	fi

	# Formateamos nuestra partición "/"
	if [ "$ROOT_FILESYSTEM" == "ext4" ]; then
		mkfs.ext4 "/dev/$rootpart"
	elif [ "$ROOT_FILESYSTEM" == "btrfs" ]; then
		mkfs.btrfs -f "/dev/$rootpart"
		mount "/dev/$rootpart" /mnt
		btrfs subvolume create /mnt/@
		# Se crea el subvolumen @home si no hay un disco para "/home".
		btrfs subvolume create /mnt/@home
		umount /mnt
	fi
}

# Función para montar nuestras particiones
mount_partitions(){
	# Si elegimos usar btrfs tenemos que montar los dos subvolúmenes creados por separado,
	# montamos el subvolumen @ en /mnt y el subvolumen @home en /mnt/home
	if [ "$ROOT_FILESYSTEM" == "btrfs" ]; then
		mount -o noatime,compress=zstd,subvol=@     "/dev/$rootpart" /mnt
		mkdir -p /mnt/home
		mount -o noatime,compress=zstd,subvol=@home "/dev/$rootpart" /mnt/home
	else
		mount -o noatime "/dev/$rootpart" /mnt
	fi

	mkdir /mnt/boot

	# Montamos nuestra partición de arranque
	mount "/dev/$bootpart" /mnt/boot
	[ "$PART_TYPE" == "gpt" ] && mkdir /mnt/boot/efi
}

# Instalar paquetes con basestrap
# Ejecutamos basestrap en un bucle hasta que se ejecuta correctamente
# porque el comando no tiene la opción --disable-download-timeout.
# Lo que podría hacer que la operación falle con conexiones muy lentas.
basestrap_install(){
	local basestrap_packages

	basestrap_packages="base elogind-openrc openrc linux linux-firmware neovim"
	basestrap_packages+=" opendoas mkinitcpio wget libnewt btrfs-progs"

	# Vamos a instalar los paquetes del grupo base-devel manualmente para luego poder borrar sudo
	# (Si en su lugar instalamos el grupo, luego será más complicado desinstalar sudo)
	basestrap_packages+=" autoconf automake bison debugedit fakeroot flex gc gcc groff"
	basestrap_packages+=" guile libisl libmpc libtool m4 make patch pkgconf texinfo which"

	basestrap_packages+=" linux-headers linux-lts linux-lts-headers networkmanager networkmanager-openrc dosfstools"
	basestrap_packages+=" cronie cronie-openrc cups cups-openrc freetype2 libjpeg-turbo grub git wpa_supplicant"
	basestrap_packages+=" usbutils pciutils cryptsetup device-mapper-openrc cryptsetup-openrc acpid-openrc dialog"

	# Instalamos xkeyboard-config aquí para poder elegir el layout de teclado más adelante (s3)
	basestrap_packages+=" xkeyboard-config bc"

	# Instalamos pipewire aquí para evitar conflictos (p.e. se isntala jack2 y no pipewire-jack).
	# Los paquetes para 32 bits se instalarán una vez activados los repos. de Arch Linux (s3)
	basestrap_packages+=" pipewire-pulse wireplumber pipewire pipewire-alsa pipewire-audio pipewire-jack"

	# Instalamos go y sudo para poder instalar compilar yay más adelante (makepkg:s3)
	basestrap_packages+=" go sudo"

	# Añadimos a los paquetes del sistema base el microcódigo de CPU correspodiente
	local manufacturer
	manufacturer=$(grep vendor_id /proc/cpuinfo | awk '{print $1}' | head -1)
	if [ "$manufacturer" == "GenuineIntel" ]; then
		basestrap_packages+=" intel-ucode"
	elif [ "$manufacturer" == "AuthenticAMD" ]; then
		basestrap_packages+=" amd-ucode"
	fi

	# Si el sistema es UEFI, instalaremos también efibootmgr
	if [ -d /sys/firmware/efi ]; then
		basestrap_packages+=" efibootmgr"
	fi

	# Si el dispositivo tiene bluetooth, instalaremos blueman
	if echo "$(lspci;lsusb)" | grep -i bluetooth; then
		basestrap_packages+=" blueman"
	fi

	while true; do
		basestrap /mnt $basestrap_packages && break
	done
}

##########
# SCRIPT #
##########

# Configuramos el servidor de claves y actualizamos las claves
grep ubuntu /etc/pacman.d/gnupg/gpg.conf || \
	echo 'keyserver hkp://keyserver.ubuntu.com' | \
	tee -a /etc/pacman.d/gnupg/gpg.conf >/dev/null
pacman -Sc --noconfirm
pacman-key --populate && pacman-key --refresh-keys

# Instalamos whiptail para la interfaz TUI
# y parted para formatear nuestros discos
pacman -Sy --noconfirm --needed parted libnewt

# Detectamos si el sitema es UEFI o BIOS.
if [ ! -d /sys/firmware/efi ]; then
	PART_TYPE="msdos" # MBR para BIOS
else
	PART_TYPE="gpt" # GPT para UEFI
fi

# Elegimos como se formatearán nuestros discos
scheme_setup
# Formateamos los discos
format_disks
# Montamos nuestras particiones
mount_partitions
# Instalamos paquetes en la nueva instalación
basestrap_install

mkdir -p /mnt/etc

# Creamos el fstab
fstabgen -U /mnt >> /mnt/etc/fstab

# Montar directorios importantes para el chroot
for dir in dev proc sys run; do
	mount --rbind /$dir /mnt/$dir; mount --make-rslave /mnt/$dir
done

# Hacer chroot y ejecutar la 2a parte del script
nexturl="https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/main/stage2.sh"
next="/tmp/stage2.sh"
artix-chroot /mnt bash -c "wget -O \"$next\" \"$nexturl\"; chmod +x \"$next\"; \"$next\""
