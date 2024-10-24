#!/bin/bash

# Auto-instalador para Artix OpenRC (Parte 2)
# por aleister888 <pacoe1000@gmail.com>
# Licencia: GNU GPLv3

REPO_URL="https://github.com/aleister888/artixRC-dotfiles"

# Funciones que invocaremos a menudo
whip_msg(){
	whiptail --backtitle "$REPO_URL" \
	--title "$1" --msgbox "$2" 10 60
}

pacinstall() {
	pacman -Sy --noconfirm --disable-download-timeout --needed "$@"
}

service_add(){
	rc-update add "$1" default
}

echo_msg(){
	clear; echo "$1 $(tput setaf 7)$(tput setab 2)OK$(tput sgr0)"; sleep 1
}

# Instalamos base-devel manualmente para usar doas en vez de sudo
devel_packages="autoconf automake bison debugedit fakeroot flex gc gcc groff guile libisl libmpc libtool m4 make patch pkgconf texinfo which"
packages="$devel_packages cronie cronie-openrc git linux-headers linux-lts linux-lts-headers grub networkmanager networkmanager-openrc wpa_supplicant dialog dosfstools cups cups-openrc freetype2 libjpeg-turbo usbutils pciutils cryptsetup device-mapper-openrc cryptsetup-openrc acpid-openrc openntpd-openrc sudo"

# Establecer zona horaria
timezoneset(){
	valid_timezone=false
	while [ "$valid_timezone" == "false" ]; do

		# Obtener la lista de regiones disponibles
		regions=$( find /usr/share/zoneinfo -mindepth 1 -type d -printf "%f\n" | sort -u )

		# Crear un array con las regiones
		regions_array=()
		for region in $regions; do
			regions_array+=("$region" "$region")
		done

		# Utilizar Whiptail para presentar las opciones de región al usuario
		region=$(whiptail --backtitle "$REPO_URL" --title "Selecciona una region" --menu "Por favor, elige una region:" 20 70 10 ${regions_array[@]} 3>&1 1>&2 2>&3)

		# Obtener la lista de zonas horarias disponibles para la región seleccionada
		timezones=$( find "/usr/share/zoneinfo/$region" -mindepth 1 -type f -printf "%f\n" | sort -u )
		timezones_array=()
		for timezone in $timezones; do
			timezones_array+=("$timezone" "$timezone")
		done

		# Utilizar Whiptail para presentar las opciones de zona horaria al usuario dentro de la región seleccionada
		timezone=$(whiptail --backtitle "$REPO_URL" --title "Selecciona una zona horaria en $region" --menu "Por favor, elige una zona horaria en $region:" 20 70 10 ${timezones_array[@]} 3>&1 1>&2 2>&3)

		# Verificar si la zona horaria seleccionada es válida
		if [ -f "/usr/share/zoneinfo/$region/$timezone" ]; then
			valid_timezone=true
		else
			whip_msg "Zona horaria no valida" "Zona horaria no valida. Asegurate de elegir una zona horaria valida."
		fi
	done
		ln -sf "/usr/share/zoneinfo/$region/$timezone" /etc/localtime
		# Sincronizar reloj del hardware con la zona horaria
		hwclock --systohc
}

# Crear usuario y establecer la contraseña para el usuario root
set_password() {
	local user="$1"
	while true; do
		whip_msg "$user" "A continuacion, se te pedira la contraseña de $user:"
		passwd "$user" && break
		whip_msg "$user" "Hubo un fallo, se te pedira de nuevo la contraseña"
	done
}

user_create(){
	username="$(whiptail --backtitle "$REPO_URL" --inputbox "Por favor, ingresa el nombre del usuario:" 10 60 3>&1 1>&2 2>&3)"
	useradd -m -G wheel,lp "$username"
	set_password "$username"
}

# Detectamos el fabricante del procesador
microcode_detect(){
manufacturer=$(grep vendor_id /proc/cpuinfo | awk '{print $1}' | head -1)
if [ "$manufacturer" == "GenuineIntel" ]; then
	echo_msg "Detectado procesador Intel."
	packages+=" intel-ucode"
elif [ "$manufacturer" == "AuthenticAMD" ]; then
	echo_msg "Detectado procesador AMD."
	packages+=" amd-ucode"
fi
}

# Instalamos GRUB
install_grub(){
	local cryptdisk cryptid decryptid boot_drive
	cryptdisk=$(lsblk -fn -o NAME | grep cryptroot -B 1 | grep -oE "[a-z].*" | head -n1)
	cryptid=$(lsblk -nd -o UUID /dev/"$cryptdisk")
	decryptid=$(lsblk -n -o UUID /dev/mapper/cryptroot)
	boot_drive=$(df /boot | awk 'NR==2 {print $1}')
	case "$boot_drive" in
	*"nvme"*)
		boot_drive="${boot_drive%p[0-9]}" ;;
	*)
		boot_drive="${boot_drive%[0-9]}" ;;
	esac

	# Instalar GRUB
	if [ ! -d /sys/firmware/efi ]; then
		grub-install --target=i386-pc --boot-directory=/boot --bootloader-id=Artix "$boot_drive" --recheck
	else
		if lsblk -f | grep crypt; then
			grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Artix --recheck --removable "$boot_drive"
		else
			grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Artix --recheck --removable "$boot_drive"
		fi
	fi

	# Configurar grub si este esta en una instalación encriptada
	lsblk -f | grep crypt && echo GRUB_ENABLE_CRYPTODISK=y >> /etc/default/grub
	lsblk -f | grep crypt && sed -i "s/\(^GRUB_CMDLINE_LINUX_DEFAULT=\".*\)\"/\1 cryptdevice=UUID=$cryptid:cryptroot root=UUID=$decryptid\"/" /etc/default/grub

	# Crear el archivo de configuración
	grub-mkconfig -o /boot/grub/grub.cfg
}

# Creamos nuestro swap
swap_create(){
	# Detectamos el tipo de partición que tenemos
	local rootype
	rootype=$( lsblk -nlf -o FSTYPE "$( df / | awk 'NR==2 {print $1}' )" )

	# Btrfs necesita un volumen solo para el swapfile, porque no puede hacer snapshots
	# de volúmenes con swapfiles
	if [ "$rootype" == "btrfs" ]; then
		btrfs subvolume create /swap
		btrfs filesystem mkswapfile --size 4g --uuid clear /swap/swapfile
		swapon /swap/swapfile
		echo "/swap/swapfile none swap defaults 0 0" | tee -a /etc/fstab
	else
		fallocate -l 4GB /swapfile
		chmod 0600 /swapfile
		mkswap /swapfile
		swapon /swapfile
		echo "/swapfile none swap defaults 0 0" | tee -a /etc/fstab
	fi
}

# Definimos el nombre de nuestra máquina y creamos el archivo hosts
hostname_config(){
	hostname=$(whiptail --backtitle "$REPO_URL" --title "Configuracion de Hostname" --inputbox "Por favor, introduce el nombre que deseas darle a tu ordenador:" 10 60 3>&1 1>&2 2>&3)
	echo "$hostname" > /etc/hostname
	curl -o /etc/hosts "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
	echo "127.0.0.1 localhost"                       | tee -a /etc/hosts && \
	echo "127.0.0.1 $hostname.localdomain $hostname" | tee -a /etc/hosts && \
	echo "127.0.0.1 localhost.localdomain"           | tee -a /etc/hosts && \
	echo "127.0.0.1 local"                           | tee -a /etc/hosts
}

# Activar repositorios de Arch Linux
arch_support(){
	# Activar lib32
	sed -i '/#\[lib32\]/{s/^#//;n;s/^.//}' /etc/pacman.conf && pacman -Sy

	# Instalar paquetes necesarios
	pacinstall archlinux-mirrorlist archlinux-keyring artix-keyring artix-archlinux-support \
	lib32-artix-archlinux-support pacman-contrib rsync lib32-elogind

	# Activar repositorios de Arch
	grep -q "^\[extra\]" /etc/pacman.conf || \
echo '[extra]
Include = /etc/pacman.d/mirrorlist-arch

[multilib]
Include = /etc/pacman.d/mirrorlist-arch' >>/etc/pacman.conf

	# Actualizar cambios
	pacman -Sy --noconfirm && \
	pacman-key --populate archlinux
	pacinstall reflector

	# Escoger mirrors más rápidos de los repositorios de Arch
	reflector --verbose --latest 10 --sort rate --download-timeout 1 --connection-timeout 1 --threads "$(nproc)" --save /etc/pacman.d/mirrorlist-arch

	# Configurar cronie para actualizar automáticamente los mirrors de Arch
	grep "reflector" /etc/crontab || \
echo "SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Escoger los mejores repositorios para Arch Linux
@hourly root reflector --verbose --latest 10 --sort rate --save /etc/pacman.d/mirrorlist-arch" > /etc/crontab
}

# Configurar la codificación del sistema
genlocale(){
	sed -i -E 's/^#(en_US\.UTF-8 UTF-8)/\1/' /etc/locale.gen
	sed -i -E 's/^#(es_ES\.UTF-8 UTF-8)/\1/' /etc/locale.gen
	locale-gen
	echo "LANG=es_ES.UTF-8" > /etc/locale.conf
}

home_keyfile(){
	local crypthome_parent
	local crypthome_parent_UUID
	local keyfile
	crypthome_parent=$(lsblk -fn -o NAME | grep crypthome -B 1 | head -n1 | grep -oE "[a-z].*")
	crypthome_parent_UUID=$(lsblk -nd -o UUID "/dev/$crypthome_parent")
	keyfile="/etc/keys/home.key"
	mkdir /etc/keys
	dd bs=512 count=4 if=/dev/urandom of=$keyfile
	while true; do
		whip_msg "LUKS" "Se va a crear un keyfile para /home. A continuacion se te pedirá la contraseña del disco /home"
		cryptsetup -v luksAddKey "/dev/$crypthome_parent" $keyfile && break
		whip_msg "LUKS" "Hubo un error, debera introducir la contraseña otra vez"
	done
	chmod 000 $keyfile
	chmod g-rwx,o-rwx /etc/keys

echo "target=home
source=UUID=\"$crypthome_parent_UUID\"
key=$keyfile
" | tee /etc/conf.d/dmcrypt
}

##########
# SCRIPT #
##########

# Establecer zona horaria
timezoneset

# Crear usuario y establecer la contraseña para el usuario root
set_password "root"
user_create

# Detectamos el fabricante del procesador
microcode_detect

# Si el sistema es UEFI, instalar efibootmgr
[ -d /sys/firmware/efi ] && \
packages+=" efibootmgr" && echo_msg "Sistema EFI detectado. Se instalará efibootmgr."

# Instalamos los paquetes necesarios
pacinstall $packages

lsblk -nl -o NAME | grep crypthome && home_keyfile

# Si se utiliza encriptación, añadir el módulo encrypt a la imagen del kernel
if ! grep -q "^HOOKS=.*encrypt.*" /etc/mkinitcpio.conf && lsblk -f | grep crypt; then
	sed -i -e '/^HOOKS=/ s/block/& encrypt/' /etc/mkinitcpio.conf
fi

if lspci | grep -i bluetooth >/dev/null || lsusb | grep -i bluetooth >/dev/null; then
	pacinstall bluez-openrc bluez-utils && \
	service_add bluetoothd
	echo_msg "Bluetooth detectado. Se instaló bluez."
fi

install_grub # Instalamos grub
swap_create # Creamos nuestro swap
mkinitcpio -P # Regenerar el initramfs
hostname_config # Definimos el nombre de nuestra máquina y creamos el archivo hosts
arch_support # Activar repositorios de Arch Linux
genlocale # Configurar la codificación del sistema

# Activamos servicios
service_add NetworkManager
service_add cupsd
service_add cronie
service_add acpid
service_add ntpd
rc-update add device-mapper boot
rc-update add dmcrypt boot
rc-update add dmeventd boot

ln -s /usr/bin/nvim /usr/local/bin/vim
ln -s /usr/bin/nvim /usr/local/bin/vi

# Clonar el repositorio completo e iniciar la última parte de la instalación
if [ ! -d /home/"$username"/.dotfiles ]; then
	su "$username" -c "git clone https://github.com/aleister888/artixRC-dotfiles.git /home/$username/.dotfiles"
else
	su "$username" -c "cd /home/$username/.dotfiles && git pull"
fi

# Configuramos sudo para stage3.sh
echo "root ALL=(ALL:ALL) ALL
%wheel ALL=(ALL) NOPASSWD: ALL" | tee /etc/sudoers

su "$username" -c "cd /home/$username/.dotfiles && ./stage3.sh"
