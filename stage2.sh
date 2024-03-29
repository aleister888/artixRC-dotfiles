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
packages="$devel_packages tlp tlp-openrc cronie cronie-openrc realtime-privileges git linux-headers grub networkmanager networkmanager-openrc wpa_supplicant dialog dosfstools bluez-openrc bluez-utils cups cups-openrc freetype2 libjpeg-turbo"

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
	local username="$1"
	local prompt="Contraseña: $1"
	local password=""
	local password_confirm=""
	local match=false

	while [ "$match" == false ]; do
		password=$(whiptail --title "$prompt" --passwordbox "Por favor, ingresa la contraseña para el usuario $username:" 10 60 3>&1 1>&2 2>&3)
		password_confirm=$(whiptail --title "Confirmar Contraseña" --passwordbox "Por favor, confirma la contraseña para el usuario $username:" 10 60 3>&1 1>&2 2>&3)
		if [ "$password" == "$password_confirm" ]; then
			match=true
		else
			whip_msg "Error" "Las contraseñas no coinciden. Por favor, inténtalo de nuevo."
		fi
	done

	echo "$username:$password" | chpasswd
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
	packages="$packages intel-ucode"
elif [ "$manufacturer" == "AuthenticAMD" ]; then
	echo_msg "Detectado procesador AMD."
	packages="$packages amd-ucode"
fi
}

# Instalamos grub
install_grub(){
	boot_part=$(df / --output=source | tail -n1)

	case "$boot_part" in
	*"nvme"*)
	        boot_part=$(echo $boot_part | sed 's/p[0-9]*$//') ;;
	*)
	        boot_part=$(echo $boot_part | sed 's/[0-9]*$//') ;;
	esac

	# Verificar si el sistema es EFI
	if [ -d /sys/firmware/efi ]; then
		echo "Sistema EFI detectado. Instalando GRUB para EFI..."
		grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --removable && \
		grub-mkconfig -o /boot/grub/grub.cfg && \
		echo_msg "GRUB fue instalado correctamente (EFI)."
	else
		echo "Sistema no EFI detectado. Instalando GRUB para BIOS..."
		grub-install --target=i386-pc --boot-directory=/boot "$boot_part" --bootloader-id=GRUB --removable && \
		grub-mkconfig -o /boot/grub/grub.cfg && \
		echo_msg "GRUB fue instalado correctamente (BIOS)."
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

# Configurar la codificación del sistema
genlocale(){
sed -i -E 's/^#(en_US\.UTF-8 UTF-8)/\1/' /etc/locale.gen
sed -i -E 's/^#(es_ES\.UTF-8 UTF-8)/\1/' /etc/locale.gen
locale-gen
echo "LANG=es_ES.UTF-8" > /etc/locale.conf
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
	reflector --verbose --latest 10 --sort rate --save /etc/pacman.d/mirrorlist-arch
	# Configurar cronie para que se actualize automáticamente la selección de mirrors
	grep "reflector" /etc/crontab || \
echo "SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 8 * * * root reflector --verbose --latest 10 --sort rate --save /etc/pacman.d/mirrorlist-arch" > /etc/crontab
}

# Establecer zona horaria
timezoneset

# Crear usuario y establecer la contraseña para el usuario root
set_password "root"
user_create

# Detectamos el fabricante del procesador
microcode_detect

# Si el sistema es UEFI, instalar efibootmgr
if [ -d /sys/firmware/efi ]; then
	packages="$packages efibootmgr"
	echo_msg "Sistema EFI detectado. Se ha instalado efibootmgr."
fi

# Instalamos los paquetes necesarios
pacinstall $packages

# Instalamos grub
install_grub

# Definimos el nombre de nuestra máquina y creamos el archivo hosts
hostname_config

# Configurar la codificación del sistema
genlocale

# Activar repositorios de Arch Linux
arch_support

service_add NetworkManager
service_add bluetoothd
service_add cupsd
service_add cronie
service_add tlp

# Sustituir sudo por doas
ln -s /usr/bin/doas /usr/bin/sudo
ln -s /usr/bin/nvim /usr/local/bin/vim

# Clonar el repositorio completo e iniciar la última parte de la instalación
if [ ! -d /home/"$username"/.dotfiles ]; then
	su "$username" -c "git clone https://github.com/aleister888/artixRC-dotfiles.git /home/$username/.dotfiles"
else
	su "$username" -c "cd /home/$username/.dotfiles && git pull"
fi

su "$username" -c "cd /home/$username/.dotfiles && ./stage3.sh"
