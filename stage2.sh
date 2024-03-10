#!/usr/bin/env bash

# Funciones que invocaremos a menudo
whip_msg(){
	whiptail --title "$1" --msgbox "$2" 10 60
}

pacinstall() {
	pacman -Sy --noconfirm --needed "$@"
}

service_add(){
	doas rc-update add "$1" default
}

# Detectar el fabricante del procesador
manufacturer=$(cat /proc/cpuinfo | grep vendor_id | head -n 1 | awk '{print $3}')

# Vamos a instalar los paquetes en base-devel manualmente
# para poder prescindir de sudo y tener solo doas instalado
base_devel_doas="autoconf automake bison debugedit fakeroot flex gc gcc groff guile libisl libmpc libtool m4 make patch pkgconf texinfo which libnewt"

# Instalar el microcódigo correspondiente y paquetes de base-devel
if [ "$manufacturer" == "GenuineIntel" ]; then
	echo "Detectado procesador Intel."
	pacinstall linux-headers intel-ucode $base_devel_doas
elif [ "$manufacturer" == "AuthenticAMD" ]; then
	echo "Detectado procesador AMD."
	pacinstall linux-headers amd-ucode $base_devel_doas
else
	echo "No se pudo detectar el fabricante del procesador."
	pacinstall $base_devel_doas
fi

valid_timezone=false

while [ "$valid_timezone" == false ]; do
	# Obtener la lista de regiones disponibles
	regions=$(find /usr/share/zoneinfo -mindepth 1 -type d | sed 's|/usr/share/zoneinfo/||' | sort | uniq | grep -v "right")
	# Whiptail necesita del valoz seleccionado (izq.) y el título (der.)
	# Vamos a hacer un array para solo mostrar nuestra región
	regions_array=()
	for region in $regions; do
		regions_array+=("$region" "$region")
	done
	
	# Utilizar Whiptail para presentar las opciones de región al usuario
	region=$(whiptail --title "Selecciona una región" --menu "Por favor, elige una región:" 20 70 10 ${regions_array[@]} 3>&1 1>&2 2>&3)
	
	# Verificar si el usuario canceló la selección
	if [ $? -ne 0 ]; then
		whip_msg "Operación cancelada" "No se ha seleccionado ninguna región. La operación ha sido cancelada."
		exit 1
	fi
	
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

# Configurar la zona horaria del sistema y mostrar un mensaje de confirmación
ln -sf "/usr/share/zoneinfo/$region/$timezone" /etc/localtime && \
whip_msg "Zona horaria configurada" "La zona horaria ha sido configurada como $region/$timezone."

# Sincronizar reloj del hardware con la zona horaria
hwclock --systohc

# Descomentar las entradas en_US.UTF-8 UTF-8 y es_ES.UTF-8 en /etc/locale.gen
sed -i -E 's/^#(en_US\.UTF-8 UTF-8)/\1/' /etc/locale.gen && \
sed -i -E 's/^#(es_ES\.UTF-8 UTF-8)/\1/' /etc/locale.gen && \
whip_msg "Configuración de locales" "Las entradas en_US.UTF-8 UTF-8 y es_ES.UTF-8 UTF-8 han sido descomentadas en /etc/locale.gen."

locale-gen

echo "LANG=es_ES.UTF-8" > /etc/locale.conf

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

# Definimos nuestras variables
password=""
password_confirm=""
match=false

# Bucle para pedir al usuario que ingrese la contraseña dos veces
while [ "$match" == false ]; do
	# Pedir al usuario que ingrese la contraseña
	password=$(whiptail --title "Configuración de Contraseña de Root" --passwordbox "Por favor, ingresa la contraseña para el usuario root:" 10 60 3>&1 1>&2 2>&3)
	# Verificar si el usuario canceló la operación
	if [ $? -ne 0 ]; then
		whip_msg "Operación cancelada" "La configuración de la contraseña de root ha sido cancelada."
		exit 1
	fi
	# Pedir al usuario que confirme la contraseña
	password_confirm=$(whiptail --title "Confirmar Contraseña de Root" --passwordbox "Por favor, confirma la contraseña para el usuario root:" 10 60 3>&1 1>&2 2>&3)
	# Verificar si el usuario canceló la operación
	if [ $? -ne 0 ]; then
		whip_msg "Operación cancelada" "La confirmación de la contraseña de root ha sido cancelada."
		exit 1
	fi
	# Verificar si las contraseñas coinciden
	if [ "$password" == "$password_confirm" ]; then
		match=true
	else
		whip_msg "Error" "Las contraseñas no coinciden. Por favor, inténtalo de nuevo."
	fi
done

# Establecer la contraseña del usuario root
echo "root:$password" | chpasswd

# Mostrar un mensaje de confirmación
whip_msg "Contraseña de Root Establecida" "La contraseña del usuario root ha sido establecida correctamente."

# Vamos a instalar ahora algunos paquetes esenciales

# Instalamos efibootmgr en función de si nuestro sistema es UEFI o no
if [ -d /sys/firmware/efi ]; then
	pacinstall efibootmgr
	whip_msg "Sistema EFI" "Sistema EFI detectado. Se ha instalado efibootmgr."
fi

# Instalar paquetes comunes
pacinstall grub networkmanager networkmanager-openrc wpa_supplicant dialog dosfstools bluez-openrc bluez-utils cups cups-openrc world/freetype2 world/libjpeg-turbo

boot_part=$(df / --output=source | tail -n1)

case "$boot_part" in
*"nvme"*)
        boot_part=$(echo "$boot_part" | sed 's/p[0-9]*$//') ;;
*)
        boot_part=$(echo "$boot_part" | sed 's/[0-9]*$//') ;;
esac

# Vamos a instalar ahora grub
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

# Configurar pacman.conf

pacinstall artix-keyring artix-archlinux-support pacman-contrib rsync

# Activar lib32
sed -i '/#\[lib32\]/{s/^#//;n;s/^.//}' /etc/pacman.conf

# Escoger mirrors más rápidos
sh -c 'rankmirrors /etc/pacman.d/mirrorlist | grep -v \"#\" > /etc/pacman.d/mirrorlist-artix' # Artix

# Cambiamos /etc/pacman.conf para que use mirrorlist-artix para descargar los paquetes
if ! grep -q "/etc/pacman.d/mirrorlist-artix" /etc/pacman.conf; then
	sed -i '/^#/{;b}; s/Include = \/etc\/pacman\.d\/mirrorlist/Include = \/etc\/pacman\.d\/mirrorlist-artix/' \
	/etc/pacman.conf
fi

# Activar repositorios de arch y repositorio omniverse
grep -q "^\[extra\]" /etc/pacman.conf || \
echo '[extra]
Include = /etc/pacman.d/mirrorlist-arch

[multilib]
Include = /etc/pacman.d/mirrorlist-arch

[omniverse]
Server = https://artix.sakamoto.pl/omniverse/$arch
Server = https://eu-mirror.artixlinux.org/omniverse/$arch
Server = https://omniverse.artixlinux.org/$arch' >>/etc/pacman.conf

# Actualizar cambios
pacman -Sy --noconfirm && \
pacman-key --populate archlinux && \
whip_msg "Pacman" "Los repositorios de Arch fueron activados"

pacinstall reflector

# Escoger mirrors más rápidos
reflector --verbose --latest 10 --sort rate --save /etc/pacman.d/mirrorlist-arch # Arch

# Instalar paquetes
pacinstall tlp tlp-openrc cronie cronie-openrc realtime-privileges git

# Activar servicios
service_add NetworkManager && \
service_add bluetoothd && \
service_add cupsd && \
service_add cronie && \
service_add tlp && \
whip_msg "OpenRC" "Los servicios fueron activados correctamente"

if ! grep "rankmirrors" /etc/crontab; then
	echo "0 8 * * * root reflector --verbose --latest 10 --sort rate --save /etc/pacman.d/mirrorlist-arch" | tee -a /etc/crontab
	echo "5 8 * * * root sh -c 'rankmirrors /etc/pacman.d/mirrorlist | grep -v \"#\" > /etc/pacman.d/mirrorlist-artix'" | tee -a /etc/crontab
fi && \
whip_msg "Cronie" "Cronie fue configurado correctamente"

# Crear usuario

# Elegir nombre de usuario
username=$(whiptail --inputbox "Por favor, ingresa el nombre de usuario:" 10 60 3>&1 1>&2 2>&3)

# Elegir contraseña

# Definimos nuestras variables
user_password=""
user_password_confirm=""
match=false

# Bucle para pedir al usuario que ingrese la contraseña dos veces
while [ "$match" == false ]; do
	# Pedir al usuario que ingrese la contraseña
	user_password=$(whiptail --title "Configuración de Contraseña" --passwordbox "Por favor, ingresa la contraseña para el usuario $username:" 10 60 3>&1 1>&2 2>&3)
	# Verificar si el usuario canceló la operación
	if [ $? -ne 0 ]; then
		whip_msg "Operación cancelada" "La configuración de la contraseña ha sido cancelada."
		exit 1
	fi
	# Pedir al usuario que confirme la contraseña
	user_password_confirm=$(whiptail --title "Confirmar Contraseña" --passwordbox "Por favor, confirma la contraseña para el usuario $username:" 10 60 3>&1 1>&2 2>&3)
	# Verificar si el usuario canceló la operación
	if [ $? -ne 0 ]; then
		whip_msg "Operación cancelada" "La configuración de la contraseña ha sido cancelada."
		exit 1
	fi
	# Verificar si las contraseñas coinciden
	if [ "$user_password" == "$user_password_confirm" ]; then
		match=true
	else
		whip_msg "Error" "Las contraseñas no coinciden. Por favor, inténtalo de nuevo."
	fi
done

# Definimos los grupos
groups="wheel,lp,audio"

useradd -m -G "$groups" "$username"

echo "$username:$user_password" | chpasswd

whip_msg "$username" "El usuario $username ha sido creado exitosamente."

ln -s /usr/bin/doas /usr/bin/sudo
ln -s /usr/bin/nvim /usr/local/bin/vim

su "$username" -c "git clone https://github.com/aleister888/artixRC-dotfiles.git /home/$username/.dotfiles"
su "$username" -c "cd /home/$username/.dotfiles && ./stage3.sh"
