#!/bin/bash -x

# Auto-instalador para Artix OpenRC (Parte 2)
# por aleister888 <pacoe1000@gmail.com>
# Licencia: GNU GPLv3

# TODO
# Ahora mismo la forma en la que se detecta el UUID de la partición
# LUKS es poco fiable. Lo correcto sería pasarle el UUID (o de que
# dispositivo obtenerlo) directamente desde s1 (p.e. mediante un archivo
# de texto que contenga información sobre el esquema de particionado).

# TODO
# Crear un script para actulizar los mirrolist, de forma que este no
# se intente actualizar cuando no hay conexión.

# En install_grub tendríamos que hacer que solo se añada la cadena con el
# UUID al archivo /etc/default/grub si las dos variables no estan vacías
# y son discos válidos.

# Esta parte del script se ejecuta ya dentro de la instalación (chroot).
# - Establece la zona horaria del sistema
# - Crea al usuario no-privilegiado y establecer las contraseñas
# - Instala y configurar GRUB y los servicios del sistema
# - Crea el archivo swap
# - Crea un archivo hosts
# - Activa los repositorios de Arch Linux y elegir los más rápidos
#   - Actualiza el mirrorlist periódicamente con reflector y cron

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
	echo "$1 $(tput setaf 7)$(tput setab 2)OK$(tput sgr0)"
}

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
		region=$(whiptail --backtitle "$REPO_URL" --title "Selecciona una region" \
		--menu "Por favor, elige una region:" 20 70 10 ${regions_array[@]} 3>&1 1>&2 2>&3)

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

# Función para establecer la contraseña del usuario,
# usamos passwd directamente porque es más seguro.
set_password() {
	local user="$1"
	while true; do
		whip_msg "$user" "A continuacion, se te pedira la contraseña de $user:"
		passwd "$user" && break
		whip_msg "$user" "Hubo un fallo, se te pedira de nuevo la contraseña"
	done
}

# Funcion para crear un usuario y establecer su contraseña
user_create(){
	username="$(whiptail --backtitle "$REPO_URL" --inputbox "Por favor, ingresa el nombre del usuario:" 10 60 3>&1 1>&2 2>&3)"
	useradd -m -G wheel,lp "$username"
	set_password "$username"
}

# Instalamos GRUB
install_grub(){
	local cryptdisk cryptid decryptid boot_drive
	cryptdisk=$(lsblk -fni -o NAME | grep cryptroot -B 1 | grep -oP '`-\K[[:alnum:]]*[0-9]$')
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
		grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Artix --recheck --removable "$boot_drive"
	fi

	# Si se usa encriptación, le decimos a GRUB el UUID de la partición encriptada y desencriptada.
	lsblk -fni -o NAME | grep cryptroot && echo GRUB_ENABLE_CRYPTODISK=y >> /etc/default/grub
	lsblk -fni -o NAME | grep cryptroot && sed -i "s/\(^GRUB_CMDLINE_LINUX_DEFAULT=\".*\)\"/\1 cryptdevice=UUID=$cryptid:cryptroot root=UUID=$decryptid\"/" /etc/default/grub

	# Crear el archivo de configuración
	grub-mkconfig -o /boot/grub/grub.cfg
}

# Creamos el archivo swap
swap_create(){
	# Detectamos el tipo de partición que tenemos
	local rootype
	rootype=$( lsblk -nlf -o FSTYPE "$( df / | awk 'NR==2 {print $1}' )" )

	# Btrfs necesita un volumen solo para el swapfile, porque no puede hacer snapshots
	# de volúmenes con swapfiles. Creamos para este el subvolumen swap
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
	hostname=$(whiptail --backtitle "$REPO_URL" --title "Configuracion de Hostname" \
	--inputbox "Por favor, introduce el nombre que deseas darle a tu ordenador:" 10 60 3>&1 1>&2 2>&3)
	echo "$hostname" > /etc/hostname
	# Este archivo hosts bloquea el acceso a sitios maliciosos
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
	cat <<-'EOF' >>/etc/pacman.conf
		[extra]
		Include = /etc/pacman.d/mirrorlist-arch

		[multilib]
		Include = /etc/pacman.d/mirrorlist-arch
	EOF

	# Actualizar cambios
	pacman -Sy --noconfirm && \
	pacman-key --populate archlinux
	pacinstall reflector

	# Escoger mirrors más rápidos de los repositorios de Arch
	reflector --verbose --latest 10 --sort rate --download-timeout 1 --connection-timeout 1 --threads "$(nproc)" --save /etc/pacman.d/mirrorlist-arch

	# Configurar cronie para actualizar automáticamente los mirrors de Arch
	grep "reflector" /etc/crontab || \
	cat <<-'EOF' > /etc/crontab
		SHELL=/bin/bash
		PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

		# Escoger los mejores repositorios para Arch Linux
		@hourly root ping gnu.org -c 1 && reflector --verbose --latest 10 --sort rate --save /etc/pacman.d/mirrorlist-arch
	EOF
}

# Cambiar la codificación del sistema a español
genlocale(){
	sed -i -E 's/^#(en_US\.UTF-8 UTF-8)/\1/' /etc/locale.gen
	sed -i -E 's/^#(es_ES\.UTF-8 UTF-8)/\1/' /etc/locale.gen
	locale-gen
	echo "LANG=es_ES.UTF-8" > /etc/locale.conf
}

##########
# SCRIPT #
##########

# Configurar el servidor de claves y limpiar la cache
grep ubuntu /etc/pacman.d/gnupg/gpg.conf || \
	echo 'keyserver hkp://keyserver.ubuntu.com' | \
	tee -a /etc/pacman.d/gnupg/gpg.conf >/dev/null
pacman -Sc --noconfirm
pacman-key --populate && pacman-key --refresh-keys

# Establecer zona horaria
timezoneset

# Crear usuario y establecer la contraseña para el usuario root
set_password "root"
user_create

# Si se utiliza encriptación, añadir el módulo encrypt a la imagen del kernel
if ! grep -q "^HOOKS=.*encrypt.*" /etc/mkinitcpio.conf && lsblk -fni -o NAME | grep cryptroot; then
	sed -i -e '/^HOOKS=/ s/block/& encrypt/' /etc/mkinitcpio.conf
fi

if lspci | grep -i bluetooth >/dev/null || lsusb | grep -i bluetooth >/dev/null; then
	pacinstall bluez-openrc bluez-utils && \
	service_add bluetoothd
	echo_msg "Bluetooth detectado. Se instaló bluez."
fi

# Instalamos grub
install_grub
# Creamos el archivo swap
swap_create
# Regeneramos el initramfs
mkinitcpio -P
# Definimos el nombre de nuestra máquina y creamos el archivo hosts
hostname_config
# Activar repositorios de Arch Linux
arch_support
# Configurar la codificación del sistema
genlocale

# Activamos servicios
service_add NetworkManager
service_add cupsd
service_add cronie
service_add acpid
rc-update add device-mapper boot
rc-update add dmcrypt boot
rc-update add dmeventd boot

ln -s /usr/bin/nvim /usr/local/bin/vim
ln -s /usr/bin/nvim /usr/local/bin/vi

# Clonar el repositorio completo e iniciar la última parte de la instalación
if [ ! -d /home/"$username"/.dotfiles ]; then
	# Nos aseguramos con el bucle que se clona el repositorio bien
	while true; do
		su "$username" -c \
		"git clone https://github.com/aleister888/artixRC-dotfiles.git \
		/home/$username/.dotfiles" && \
		break
	done
fi

# Configuramos sudo para stage3.sh
echo "root ALL=(ALL:ALL) ALL
%wheel ALL=(ALL) NOPASSWD: ALL" | tee /etc/sudoers

su "$username" -c "cd /home/$username/.dotfiles && ./stage3.sh"
