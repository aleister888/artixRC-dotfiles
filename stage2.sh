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

# Detectar el fabricante del procesador
manufacturer=$(cat /proc/cpuinfo | grep vendor_id | head -n 1 | awk '{print $3}')

# Vamos a instalar los paquetes en base-devel manualmente
# para poder prescindir de sudo y tener solo doas instalado
base_devel_doas="autoconf automake bison debugedit fakeroot flex gc gcc groff guile libisl libmpc libtool m4 make patch pkgconf texinfo which"

# Instalar el microcódigo correspondiente y paquetes de base-devel
if [ "$manufacturer" == "GenuineIntel" ]; then
	echo "Detectado procesador Intel."
	pacinstall linux-headers intel-ucode $base_devel_doas
elif [ "$manufacturer" == "AuthenticAMD" ]; then
	echo "Detectado procesador AMD."
	pacinstall linux-headers amd-ucode $base_devel_doas
else
	echo "No se pudo detectar el fabricante del procesador."
	pacinstall linux-headers $base_devel_doas
fi

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

# Configurar la codificación del sistema
genlocale(){
sed -i -E 's/^#(en_US\.UTF-8 UTF-8)/\1/' /etc/locale.gen
sed -i -E 's/^#(es_ES\.UTF-8 UTF-8)/\1/' /etc/locale.gen
locale-gen
echo "LANG=es_ES.UTF-8" > /etc/locale.conf
}

hostname_config(){
	# Definir el nombre de nuestra máquina
	hostname=$(whiptail --title "Configuración de Hostname" --inputbox "Por favor, introduce el nombre que deseas para tu host:" 10 60 3>&1 1>&2 2>&3)
	echo "$hostname" > /etc/hostname
	# Descargar archivo hosts con bloqueo de sitios indeseados
	curl -o /etc/hosts "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"

	echo "127.0.0.1 localhost"                       | tee -a /etc/hosts && \
	echo "127.0.0.1 $hostname.localdomain $hostname" | tee -a /etc/hosts && \
	echo "127.0.0.1 localhost.localdomain"           | tee -a /etc/hosts && \
	echo "127.0.0.1 local"                           | tee -a /etc/hosts && \
	whip_msg "/etc/hosts" "El archivo /etc/hosts fue configurado correctamente"
}

root_password(){
	local password=""
	local password_confirm=""
	local match="false"

	# Bucle para pedir al usuario que ingrese la contraseña dos veces
	while [ "$match" == false ]; do # Mientras las contraseñas no coincidan se volverá a pedir que se introduzcan
		# Pedir al usuario que ingrese la contraseña
		password=$(whiptail --title "Configuración de Contraseña de Root" \
			--passwordbox "Por favor, ingresa la contraseña para el usuario root:" 10 60 3>&1 1>&2 2>&3)
		# Pedir al usuario que confirme la contraseña
		password_confirm=$(whiptail --title "Confirmar Contraseña de Root" \
			--passwordbox "Por favor, confirma la contraseña para el usuario root:" 10 60 3>&1 1>&2 2>&3)
		# Verificar si las contraseñas coinciden
		if [ -n "$password" ]; then # Si una de las contraseñas es vacía, repetir el proceso
			if [ "$password" == "$password_confirm" ]; then
				match=true
			else
				whip_msg "Error" "Las contraseñas no coinciden. Por favor, inténtalo de nuevo."
			fi
		else
			whip_msg "Error" "No se permiten contraseñas vacías. Por favor, inténtalo de nuevo."
		fi
	done

	# Establecer la contraseña del usuario root
	echo "root:$password" | chpasswd
}

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
		whip_msg "GRUB" "GRUB fue instalado correctamente (EFI)."
	else
		echo "Sistema no EFI detectado. Instalando GRUB para BIOS..."
		grub-install --target=i386-pc --boot-directory=/boot "$boot_part" --bootloader-id=GRUB --removable && \
		grub-mkconfig -o /boot/grub/grub.cfg && \
		whip_msg "GRUB" "GRUB fue instalado correctamente (BIOS)."
	fi
}

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
	if ! grep "reflector" /etc/crontab; then
		echo "0 8 * * * root reflector --verbose --latest 10 --sort rate --save /etc/pacman.d/mirrorlist-arch" | tee -a /etc/crontab
	fi
}

services_install(){
# Instalar paquetes
pacinstall tlp tlp-openrc cronie cronie-openrc realtime-privileges git

# Activar servicios
service_add NetworkManager
service_add bluetoothd
service_add cupsd
service_add cronie
service_add tlp
}

# Creamos nuestro usuario regular y le damos permisos de administrador
user_create(){
	# Elegir nombre de usuario
	username=$(whiptail --inputbox "Por favor, ingresa el nombre de usuario:" 10 60 3>&1 1>&2 2>&3)

	## Elegir contraseña

	# Definimos nuestras variables
	local user_password=""
	local user_password_confirm=""
	local match=false

	# Bucle para pedir al usuario que ingrese la contraseña dos veces
	while [ "$match" == false ]; do
		# Pedir al usuario que ingrese la contraseña
		user_password=$(whiptail --title "Configuración de Contraseña" --passwordbox "Por favor, ingresa la contraseña para el usuario $username:" 10 60 3>&1 1>&2 2>&3)
		# Pedir al usuario que confirme la contraseña
		user_password_confirm=$(whiptail --title "Confirmar Contraseña" --passwordbox "Por favor, confirma la contraseña para el usuario $username:" 10 60 3>&1 1>&2 2>&3)
		# Verificar si las contraseñas coinciden
		if [ -n "$user_password" ]; then # Si una de las contraseñas es vacía, repetir el proceso
			if [ "$user_password" == "$user_password_confirm" ]; then
				match=true
			else
				whip_msg "Error" "Las contraseñas no coinciden. Por favor, inténtalo de nuevo."
			fi
		else
			whip_msg "Error" "No se permiten contraseñas vacías. Por favor, inténtalo de nuevo."
		fi
	done

	groups="wheel,lp,audio" # Definimos los grupos
	useradd -m -G "$groups" "$username" # Añadimos el usuario a dichos grupos
	echo "$username:$user_password" | chpasswd # Establecemos la contraseña para el usuario
}

if timezoneset; then
	whip_msg "Zona horaria configurada" "La zona horaria ha sido configurada como $region/$timezone."
fi

if genlocale; then
	whip_msg "Locale" "Se estableción el locale como en_US.UTF-8 UTF-8 y es_ES.UTF-8 UTF-8."
fi

if hostname_config; then
	whip_msg "Hostname" "El nombre de la máquina se configuró correctamente"
fi

if root_password; then
	whip_msg "Contraseña de Root Establecida" "La contraseña del usuario root ha sido establecida correctamente."
fi

# Si el sistema es UEFI, instalar efibootmgr
if [ -d /sys/firmware/efi ]; then
	pacinstall efibootmgr
	whip_msg "Sistema EFI" "Sistema EFI detectado. Se ha instalado efibootmgr."
fi

pacinstall grub networkmanager networkmanager-openrc wpa_supplicant dialog dosfstools bluez-openrc bluez-utils cups cups-openrc freetype2 libjpeg-turbo

install_grub

if arch_support; then
	whip_msg "Pacman" "Los repositorios de Arch fueron activados correctamente"
fi

if services_install; then
	whip_msg "Servicios" "Los servicios se configuraron correctamente"
fi

if user_create; then
	whip_msg "$username" "El usuario $username ha sido creado exitosamente."
fi

# Sustituir sudo por doas
ln -s /usr/bin/doas /usr/bin/sudo
ln -s /usr/bin/nvim /usr/local/bin/vim

# Clonar el repositorio completo y terminar la instalación
su "$username" -c "git clone https://github.com/aleister888/artixRC-dotfiles.git /home/$username/.dotfiles"
su "$username" -c "cd /home/$username/.dotfiles && curl -s https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/main/stage3.sh | bash"
