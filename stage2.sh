#!/bin/bash

# Detectar el fabricante del procesador
manufacturer=$(cat /proc/cpuinfo | grep vendor_id | head -n 1 | awk '{print $3}')

# Instalar el microcódigo correspondiente
if [ "$manufacturer" == "GenuineIntel" ]; then
	echo "Detectado procesador Intel."
	pacman -S --noconfirm intel-ucode
elif [ "$manufacturer" == "AuthenticAMD" ]; then
	echo "Detectado procesador AMD."
	pacman -S --noconfirm amd-ucode
else
	echo "No se pudo detectar el fabricante del procesador."
fi

valid_timezone=false

while [ "$valid_timezone" == false ]; do
	# Preguntar al usuario por la zona horaria
	echo "Por favor, introduce tu zona horaria (por ejemplo, Europe/Madrid):"
	read timezone
	
	# Verificar si la zona horaria es válida
	if [ -f "/usr/share/zoneinfo/$timezone" ]; then
		valid_timezone=true
	else
		echo "Zona horaria no válida. Asegúrate de ingresar una zona horaria válida."
	fi
done

# Configurar la zona horaria del sistema
ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime

echo "Zona horaria configurada correctamente a $timezone."

hwclock --systohc

# Descomentar las entradas en_US.UTF-8 UTF-8 y es_ES.UTF-8 en /etc/locale.gen
sed -i -E 's/^#(en_US\.UTF-8 UTF-8)/\1/' /etc/locale.gen && \
sed -i -E 's/^#(es_ES\.UTF-8 UTF-8)/\1/' /etc/locale.gen && \
echo "Las entradas en_US.UTF-8 UTF-8 y es_ES.UTF-8 UTF-8 han sido descomentadas en /etc/locale.gen"

locale-gen

echo "LANG=es_ES.UTF-8" > /etc/locale.conf
echo "artix" > /etc/hostname

# Descargar archivo hosts con bloqueo de sitios indeseados
curl -o /etc/hosts "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"

echo "127.0.0.1 localhost"			| tee -a /etc/hosts
echo "127.0.0.1 artix.localdomain artix"	| tee -a /etc/hosts
echo "127.0.0.1 localhost.localdomain"		| tee -a /etc/hosts
echo "127.0.0.1 local"				| tee -a /etc/hosts

# Establecer la contraseña del usuario root
while true; do
		read -sp "Introduce la contraseña para el usuario root: " password
		echo ""

		read -sp "Confirma la contraseña: " password_confirm
		echo ""

		# Verificar si las contraseñas coinciden
		if [ "$password" = "$password_confirm" ]; then
				break
		else
				echo "Las contraseñas no coinciden. Por favor, inténtalo de nuevo."
		fi
done

# Establecer la contraseña del usuario root
echo "root:$password" | chpasswd

echo "La contraseña del usuario root establecida."

# Vamos a instalar ahora algunos paquetes esenciales

# Instalamos efibootmgr en función de si nuestro sistema es UEFI o no
if [ -d /sys/firmware/efi ]; then
	pacman -S --noconfirm efibootmgr
	echo "Sistema EFI detectado. Se ha instalado efibootmgr."
fi

# Instalar paquetes comunes
pacman -S --noconfirm grub networkmanager networkmanager-openrc wpa_supplicant dialog dosfstools linux-headers bluez-openrc bluez-utils cups cups-openrc world/freetype2 world/libjpeg-turbo

# Vamos a instalar ahora grub
# Verificar si el sistema es EFI
if [ -d /sys/firmware/efi ]; then
	echo "Sistema EFI detectado. Instalando GRUB para EFI..."
	grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
	grub-mkconfig -o /boot/grub/grub.cfg
	echo "GRUB instalado correctamente para EFI."
else
	disk=$(lsblk -no pkname $(mount | grep 'on / ' | awk '{print $1}' | sort | uniq))
		if [ -z "$DISK" ]; then
			echo "No se pudo determinar el disco. Abortando."
			exit 1
		fi
	echo "Sistema no EFI detectado. Instalando GRUB para BIOS..."
	grub-install --target=i386-pc /dev/$DISK
	grub-mkconfig -o /boot/grub/grub.cfg
	echo "GRUB instalado correctamente para BIOS."
fi

# Activar serivicios
rc-update add NetworkManager default
rc-update add bluetoothd default
rc-update cupsd default
