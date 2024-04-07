#!/bin/bash

# Funciones que invocaremos a menudo
whip_msg(){
	whiptail --title "$1" --msgbox "$2" 10 60
}

pacinstall() {
	pacman -Sy --noconfirm --needed "$@"
}

service_add(){
	rc-update add "$1" default
}

echo_msg(){
	clear; echo "$1 $(tput setaf 7)$(tput setab 2)OK$(tput sgr0)"; sleep 1
}

# Instalamos base-devel manualmente para usar doas en vez de sudo
devel_packages="autoconf automake bison debugedit fakeroot flex gc gcc groff guile libisl libmpc libtool m4 make patch pkgconf texinfo which"
packages="$devel_packages tlp tlp-openrc cronie cronie-openrc git linux-headers linux-lts linux-lts-headers grub networkmanager networkmanager-openrc wpa_supplicant dialog dosfstools cups cups-openrc freetype2 libjpeg-turbo usbutils pciutils cryptsetup"

# Establecer zona horaria
timezoneset(){
	valid_timezone=false
	while [ "$valid_timezone" = false ]; do

		# Obtener la lista de regiones disponibles
		regions=$(find /usr/share/zoneinfo -mindepth 1 -type d | sed 's|/usr/share/zoneinfo/||' | sort -u | grep -v "right")

		# Crear un array con las regiones
		regions_array=()
		for region in $regions; do
			regions_array+=("$region" "$region")
		done

		# Utilizar Whiptail para presentar las opciones de región al usuario
		region=$(whiptail --title "Selecciona una región" --menu "Por favor, elige una región:" 20 70 10 ${regions_array[@]} 3>&1 1>&2 2>&3)

		# Obtener la lista de zonas horarias disponibles para la región seleccionada
		timezones=$(find "/usr/share/zoneinfo/$region" -type f | sed "s|/usr/share/zoneinfo/$region/||" | sort)
		timezones_array=()
		for timezone in $timezones; do
			timezones_array+=("$timezone" "$timezone")
		done

		# Utilizar Whiptail para presentar las opciones de zona horaria al usuario dentro de la región seleccionada
		timezone=$(whiptail --title "Selecciona una zona horaria en $region" --menu "Por favor, elige una zona horaria en $region:" 20 70 10 ${timezones_array[@]} 3>&1 1>&2 2>&3)

		# Verificar si la zona horaria seleccionada es válida
		if [ -f "/usr/share/zoneinfo/$region/$timezone" ]; then
			valid_timezone=true
		else
			whip_msg "Zona horaria no válida" "Zona horaria no válida. Asegúrate de elegir una zona horaria válida."
		fi
	done
		ln -sf "/usr/share/zoneinfo/$region/$timezone" /etc/localtime
		# Sincronizar reloj del hardware con la zona horaria
		hwclock --systohc
}

# Crear usuario y establecer la contraseña para el usuario root
set_password() {
	local user="$1"
	local prompt="Contraseña: $1"
	local password=""
	local confirm=""

	while true; do
		whip_msg "$user" "A continuación, se te pedirá la contraseña de $user:"
		passwd "$user" && break
		whip_msg "$user" "Hubo un fallo, se te pedirá de nuevo la contraseña"
	done
}

user_create(){
	username="$(whiptail --inputbox "Por favor, ingresa el nombre del usuario:" 10 60 3>&1 1>&2 2>&3)"
	useradd -m -G wheel,lp "$username"
	set_password "$username"
}

# Detectamos el fabricante del procesador
microcode_detect(){
manufacturer=$(cat /proc/cpuinfo | grep vendor_id | head -n 1 | awk '{print $3}')
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
	local cryptdisk="$(lsblk -lf -o NAME,FSTYPE | awk '$2 == "crypto_LUKS" {print $1}')"
	local cryptid="$(lsblk -nd -o UUID /dev/$cryptdisk)"
	local decryptid="$(lsblk -n -o UUID /dev/mapper/cryptroot)"
	local boot_drive=$(df /boot | awk 'NR==2 {print $1}')
	case "$boot_drive" in
	*"nvme"*)
	        boot_drive=$(echo $boot_drive | sed 's/p[0-9]*$//') ;;
	*)
	        boot_drive=$(echo $boot_drive | sed 's/[0-9]*$//') ;;
	esac

	# Instalar GRUB
	if [ ! -d /sys/firmware/efi ]; then
		grub-install --target=i386-pc --boot-directory=/boot --bootloader-id=Artix $boot_drive --recheck
	else
		if lsblk -f | grep crypt; then
			grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Artix --recheck $boot_drive
		else
			grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Artix --recheck $boot_drive
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
	local rootype=$( lsblk -nlf -o FSTYPE $( df / | awk 'NR==2 {print $1}' ) )

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
	hostname=$(whiptail --title "Configuración de Hostname" --inputbox "Por favor, introduce el nombre que deseas para tu host:" 10 60 3>&1 1>&2 2>&3)
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
	#
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
	reflector --verbose --latest 10 --sort rate --save /etc/pacman.d/mirrorlist-arch

	# Configurar cronie para actualizar automáticamente los mirrors de Arch
	grep "reflector" /etc/crontab || \
echo "SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 8 * * * root reflector --verbose --latest 10 --sort rate --save /etc/pacman.d/mirrorlist-arch" > /etc/crontab
}

# Configurar la codificación del sistema
genlocale(){
	sed -i -E 's/^#(en_US\.UTF-8 UTF-8)/\1/' /etc/locale.gen
	sed -i -E 's/^#(es_ES\.UTF-8 UTF-8)/\1/' /etc/locale.gen
	locale-gen
	echo "LANG=es_ES.UTF-8" > /etc/locale.conf
}

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

# Si se utiliza encriptación, añadir el módulo encrypt a la imagen del kernel
if ! grep -q "^HOOKS=.*encrypt.*" /etc/mkinitcpio.conf && lsblk -f | grep crypt; then
	sed -i -e '/^HOOKS=/ s/block/& encrypt/' /etc/mkinitcpio.conf
fi

if lspci | grep -i bluetooth >/dev/null || lsusb | grep -i bluetooth >/dev/null; then
	pacinstall bluez-openrc bluez-utils && \
	service_add bluetoothd
	echo_msg "Bluetooth detectado. Se instaló bluez."
fi

##########
# SCRIPT #
##########

# Instalamos grub
install_grub

# Creamos nuestro swap
swap_create

# Regenerar el initramfs
mkinitcpio -P

# Definimos el nombre de nuestra máquina y creamos el archivo hosts
hostname_config

# Activar repositorios de Arch Linux
arch_support

# Configurar la codificación del sistema
genlocale

service_add NetworkManager
service_add cupsd
service_add cronie
service_add tlp

# Sustituir sudo por doas
ln -s /usr/bin/doas /usr/bin/sudo
ln -s /usr/bin/nvim /usr/local/bin/vim
ln -s /usr/bin/nvim /usr/local/bin/vi

 Clonar el repositorio completo e iniciar la última parte de la instalación
if [ ! -d /home/"$username"/.dotfiles ]; then
	su "$username" -c "git clone https://github.com/aleister888/artixRC-dotfiles.git /home/$username/.dotfiles"
else
	su "$username" -c "cd /home/$username/.dotfiles && git pull"
fi

su "$username" -c "cd /home/$username/.dotfiles && ./stage3.sh"
