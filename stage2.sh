#!/bin/bash

# Detectar el fabricante del procesador
manufacturer=$(cat /proc/cpuinfo | grep vendor_id | head -n 1 | awk '{print $3}')

# Vamos a instalar los paquetes en base-devel manualmente
# para poder prescindir de sudo y tener solo doas instalado
base_devel_doas="autoconf automake bison debugedit fakeroot flex gc gcc groff guile libisl libmpc libtool m4 make patch pkgconf texinfo which libnewt"

# Instalar el microcódigo correspondiente y paquetes de base-devel
if [ "$manufacturer" == "GenuineIntel" ]; then
	echo "Detectado procesador Intel."
	pacman -S --noconfirm linux-headers intel-ucode $base_devel_doas
elif [ "$manufacturer" == "AuthenticAMD" ]; then
	echo "Detectado procesador AMD."
	pacman -S --noconfirm linux-headers amd-ucode $base_devel_doas
else
	echo "No se pudo detectar el fabricante del procesador."
	pacman -S --noconfirm $base_devel_doas
fi

valid_timezone=false

while [ "$valid_timezone" == false ]; do
	# Obtener la lista de regiones disponibles
	regions=$(find /usr/share/zoneinfo -mindepth 1 -type d -exec basename {} \; | sort | uniq)
	
	# Utilizar Whiptail para presentar las opciones de región al usuario
	region=$(whiptail --title "Selecciona una región" --menu "Por favor, elige una región:" 20 70 10 ${regions[@]} 3>&1 1>&2 2>&3)
	
	# Verificar si el usuario canceló la selección
	if [ $? -ne 0 ]; then
		whiptail --title "Operación cancelada" --msgbox "No se ha seleccionado ninguna región. La operación ha sido cancelada." 10 60
		exit 1
	fi
	
	# Obtener la lista de zonas horarias disponibles para la región seleccionada
	timezones=$(find "/usr/share/zoneinfo/$region" -type f | sed "s|/usr/share/zoneinfo/$region/||" | sort | uniq)
	
	# Utilizar Whiptail para presentar las opciones de zona horaria al usuario dentro de la región seleccionada
	timezone=$(whiptail --title "Selecciona una zona horaria en $region" --menu "Por favor, elige una zona horaria en $region:" 20 70 10 ${timezones[@]} 3>&1 1>&2 2>&3)
	
	# Verificar si la zona horaria seleccionada es válida
	if [ -f "/usr/share/zoneinfo/$region/$timezone" ]; then
		valid_timezone=true
	else
		whiptail --title "Zona horaria no válida" --msgbox "Zona horaria no válida. Asegúrate de elegir una zona horaria válida." 10 60
	fi
done

# Configurar la zona horaria del sistema
ln -sf "/usr/share/zoneinfo/$region/$timezone" /etc/localtime

# Mostrar un mensaje de confirmación
whiptail --title "Zona horaria configurada" --msgbox "La zona horaria ha sido configurada como $region/$timezone." 10 60

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
pacman -S --noconfirm grub networkmanager networkmanager-openrc wpa_supplicant dialog dosfstools bluez-openrc bluez-utils cups cups-openrc world/freetype2 world/libjpeg-turbo

boot_part=$(df / --output=source | tail -n1)

case "$boot_part" in
*"nvme"*)
        boot_part=$(echo $boot_part | sed 's/p[0-9]*$//') ;;
*)
        boot_part=$(echo $boot_part | sed 's/[0-9]*$//') ;;
esac

# Vamos a instalar ahora grub
# Verificar si el sistema es EFI
if [ -d /sys/firmware/efi ]; then
	echo "Sistema EFI detectado. Instalando GRUB para EFI..."
	grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --removable
	grub-mkconfig -o /boot/grub/grub.cfg
	echo "GRUB instalado correctamente para EFI."
else
	echo "Sistema no EFI detectado. Instalando GRUB para BIOS..."
	grub-install --target=i386-pc --boot-directory=/boot "$boot_part" --bootloader-id=GRUB --removable
	grub-mkconfig -o /boot/grub/grub.cfg
	echo "GRUB instalado correctamente para BIOS."
fi

# Activar repositorios de arch
pacman --noconfirm --needed -S artix-keyring artix-archlinux-support >/dev/null 2>&1
grep -q "^\[extra\]" /etc/pacman.conf || \
echo "[extra]
Include = /etc/pacman.d/mirrorlist-arch

[multilib]
Include = /etc/pacman.d/mirrorlist-arch" >>/etc/pacman.conf
pacman -Sy --noconfirm
pacman-key --populate archlinux >/dev/null 2>&1

# Instalar paquetes
pacman --noconfirm --needed -S tlp tlp-openrc cronie cronie-openrc realtime-privileges git

# Activar servicios
rc-update add NetworkManager default
rc-update add bluetoothd default
rc-update add cupsd default
rc-update add cronie default
rc-update add tlp default

# Crear usuario

# Elegir nombre de usuario
while true; do
	read -p "Ingrese el nombre de usuario: " username
	read -p "Confirme el nombre de usuario: " username_confirm
	if [ "$username" = "$username_confirm" ]; then
		break
	else
		echo "Los nombres no coinciden. Inténtelo de nuevo."
	fi
done

# Elegir contraseña

while true; do
	read -s -p "Ingrese la contraseña: " password
	echo
	read -s -p "Confirme la contraseña: " password_confirm
	echo
	if [ "$password" = "$password_confirm" ]; then
		break
	else
		echo "Las contraseñas no coinciden. Inténtelo de nuevo."
	fi
done

# Definimos los grupos
groups="wheel,lp,audio"

useradd -m -G "$groups" "$username"

echo "$username:$password" | chpasswd

echo "El usuario $username ha sido creado exitosamente."

ln -s /usr/bin/doas /usr/bin/sudo
ln -s /usr/bin/nvim /usr/local/bin/vim

su "$username" -c "git clone https://github.com/aleister888/artixRC-dotfiles.git /home/$username/.dotfiles"
su "$username" -c "cd /home/$username/.dotfiles && ./stage3.sh"
