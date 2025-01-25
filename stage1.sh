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

REPO_URL="https://github.com/aleister888/artix-installer"

# Detectamos si el sitema es UEFI o BIOS.
if [ ! -d /sys/firmware/efi ]; then
	PART_TYPE="msdos" # MBR para BIOS
else
	PART_TYPE="gpt" # GPT para UEFI
fi

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

# Muestra como quedarían las particiones de nuestra instalación para # confirmar
# los cambios. También prepara las variables para formatear los discos
scheme_show(){
	local scheme   # Variable con el esquema de particiones completo
	local rootType # Tipo de partición/ (LUKS o normal)
	bootMount=     # Punto de montaje con la partición de arranque
	bootPart=      # Partición de arranque
	rootPart=      # Partición con el sistema

	# Establecemos la partición de arranque en función del tipo de sistema
	if [ "$PART_TYPE" == "msdos" ]; then
		bootMount="/boot"
	else
		bootMount="/boot/efi"
	fi

	# Definimos el nombre de las particiones de nuestro disco principal
	# (Los NVME tienen un sistema de nombrado distinto)
	case "$ROOT_DISK" in
		*"nvme"*)
			bootPart="$ROOT_DISK"p1
			rootPart="$ROOT_DISK"p2 ;;
		*)
			bootPart="$ROOT_DISK"1
			rootPart="$ROOT_DISK"2 ;;
	esac

	# Mostrar si la partición esta encriptada
	if [ "$crypt_root" == "true" ]; then
		rootType="LUKS"
	else
		rootType="/"
	fi

	# Creamos el esquema que whiptail nos mostrará
	scheme="/dev/$ROOT_DISK    $(lsblk -dn -o size /dev/"$ROOT_DISK")
	/dev/$bootPart  $bootMount
	/dev/$rootPart  $rootType
	"
	if [ "$crypt_root" == "true" ]; then
	scheme+="/dev/mapper/root  /"
	fi

	# Mostramos el esquema para confirmar los cambios
	if ! whiptail --backtitle "$REPO_URL" \
		--title "Confirmar particionado" \
		--yesno "$scheme" 15 60
	then
		whip_yes "Salir" "¿Desea cancelar la instalacion? En caso contrario, volvera a elegir su esquema de particiones" && \
		exit 1
	fi
}

# Función para elegir como se formatearán nuestros discos
scheme_setup(){
	while true; do
		while true; do
			ROOT_DISK=$(
				whip_menu "Discos disponibles" \
				"Selecciona un disco para la instalacion:" \
				"$(lsblk -dn -o name,size | tr '\n' ' ')"
			) && break
		done

		if whip_yes "LUKS" "¿Desea encriptar el disco duro?"; then
			crypt_root=true
		else
			crypt_root=false
		fi

		# Confirmamos los cambios
		if scheme_show; then
			break # Salir del bucle si se confirman los cambios
		else
			whip_msg "ERROR" "Hubo un error al comprobar el esquema de particiones elegido, o el usuario cancelo la operación."
		fi
	done
}

# Encriptar el disco duro
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
	# Elegimos el sistema de ficheros
	ROOT_FILESYSTEM=$(
		whip_menu "Sistema de archivos" \
		"Selecciona el sistema de archivos para /:" \
		"ext4" "Ext4" "btrfs" "Btrfs"
	)

	# Borramos la firma del disco
	wipefs --all "/dev/$ROOT_DISK"

	# Creamos nuestra tabla de particionado y partición de arranque
	if [ "$PART_TYPE" == "msdos" ]; then
		# BIOS -> MBR
		echo -e "label: dos\nstart=1MiB, size=512MiB, type=83\n" | \
		sfdisk --quiet -f "/dev/$ROOT_DISK"
		mkfs.fat -F32 "/dev/$bootPart"
	else
		# UEFI -> GPT
		parted "/dev/$ROOT_DISK" --script \
		mklabel gpt mkpart ESP fat32 1MiB 513MiB set 1 boot on
		mkfs.fat -F32 "/dev/$bootPart"
	fi

	# Creamos la partición root
	parted -s "/dev/$ROOT_DISK" mkpart primary 513MiB 100%

	# Si se eligió usar LUKS, es el momento de encriptar la partición
	if [ "$crypt_root" == "true" ]; then
		part_encrypt "/" "$rootPart" "cryptroot" && \
		# Cambiamos el indicador del disco a la partición encriptada
		rootPart="mapper/cryptroot"
	fi

	# Formateamos nuestra partición "/"
	if [ "$ROOT_FILESYSTEM" == "ext4" ]; then
		mkfs.ext4 "/dev/$rootPart"
	elif [ "$ROOT_FILESYSTEM" == "btrfs" ]; then
		mkfs.btrfs -f "/dev/$rootPart"
		mount "/dev/$rootPart" /mnt
		btrfs subvolume create /mnt/@
		btrfs subvolume create /mnt/@home
		umount /mnt
	fi
}

# Función para montar nuestras particiones
mount_partitions(){
	# Para btrfs tenemos que montar los dos subvolúmenes creados.
	# Montamos el subvolumen @ en /mnt y el subvolumen @home en /mnt/home
	if [ "$ROOT_FILESYSTEM" == "btrfs" ]; then
		mount -o noatime,compress=zstd,subvol=@ \
			"/dev/$rootPart" /mnt
		mkdir -p /mnt/home
		mount -o noatime,compress=zstd,subvol=@home \
			"/dev/$rootPart" /mnt/home
	else
		mount -o noatime "/dev/$rootPart" /mnt
	fi

	mkdir /mnt/boot

	# Montamos nuestra partición de arranque
	mount "/dev/$bootPart" /mnt/boot
	[ "$PART_TYPE" == "gpt" ] && mkdir /mnt/boot/efi
}

# Instalar paquetes con basestrap
# Ejecutamos basestrap en un bucle hasta que se ejecute correctamente
# porque el comando no tiene la opción --disable-download-timeout.
# Lo que podría hacer que la operación falle con conexiones muy lentas.
basestrap_install(){
	local basestrap_packages

	basestrap_packages="base elogind-openrc openrc linux linux-firmware"
	basestrap_packages+=" opendoas mkinitcpio wget libnewt btrfs-progs"
	basestrap_packages+=" neovim"

	# Instalamos los paquetes del grupo base-devel manualmente para luego
	# poder borrar sudo facilmente. (Si en su lugar instalamos el grupo,
	# luego será más complicado desinstalarlo)
	basestrap_packages+=" autoconf automake bison debugedit fakeroot flex"
	basestrap_packages+=" gc gcc groff guile libisl libmpc libtool m4 make"
	basestrap_packages+=" patch pkgconf texinfo which"

	basestrap_packages+=" linux-headers linux-lts linux-lts-headers"
	basestrao_packages+=" networkmanager networkmanager-openrc dosfstools"
	basestrap_packages+=" cronie cronie-openrc cups cups-openrc freetype2"
	basestrap_packages+=" libjpeg-turbo grub git wpa_supplicant usbutils"
	basestrap_packages+=" pciutils cryptsetup device-mapper-openrc dialog"
	basestrap_packages+=" cryptsetup-openrc acpid-openrc"

	# Instalamos pipewire para evitar conflictos (p.e. se isntala jack2 y no
	# pipewire-jack). Los paquetes para 32 bits se instalarán una vez
	# activados el repo multilib de Arch Linux (s3)
	basestrap_packages+=" pipewire-pulse wireplumber pipewire pipewire-alsa"
	basestrap_packages+=" pipewire-audio pipewire-jack"

	# Instalamos go y sudo para poder compilar yay más adelante (s3)
	basestrap_packages+=" go sudo"

	# Añadimos el paquete con el microcódigo de CPU correspodiente
	local manufacturer
	manufacturer=$(
		grep vendor_id /proc/cpuinfo | awk '{print $1}' | head -1
	)
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

# Elegimos distribución de teclado
kb_layout_select(){
	# Array con las diferentes distribuciones de tecladoposibles
	key_layouts=$(
		find /usr/share/X11/xkb/symbols/ -mindepth 1 -type f \
		-printf "%f\n" | sort -u | grep -v '...'
	)
	keyboard_array=()
	for key_layout in $key_layouts; do
		keyboard_array+=("$key_layout" "$key_layout")
	done

	# Elegimos nuestro layout
	final_layout=$(
		whip_menu "Teclado" \
		"Por favor, elige una distribucion de teclado:" \
		${keyboard_array[@]}
	)
}

kb_layout_conf(){
	sudo mkdir -p /mnt/etc/X11/xorg.conf.d/ # X11
	cat <<-EOF >  /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
		Section "InputClass"
		    Identifier "system-keyboard"
		    MatchIsKeyboard "on"
		    Option "XkbLayout" "$final_layout"
		    Option "XkbModel" "pc105"
		    Option "XkbOptions" "terminate:ctrl_alt_bksp"
		EndSection
	EOF
	# Si elegimos español, configurar el layout de la tty en español también
	[ "$final_layout" == "es" ] && \
		sudo sed -i 's|keymap="us"|keymap="es"|' /etc/conf.d/keymaps
}

# Calcular el DPI
calculate_dpi(){
	local resolution size width height fact displayDPI

	# Selección de resolución del monitor
	resolution=$(
		whip_menu "Resolucion del Monitor" \
		"Seleccione la resolucion de su monitor:" \
		"720p" "HD" "1080p" "Full-HD" "1440p" "QHD" "2160p" "4K"
	)

	# Selección del tamaño del monitor en pulgadas (diagonal)
	size=$(
		whip_menu "Tamaño del Monitor" \
		"Seleccione el tamaño de su monitor (en pulgadas):" \
		"14" "Portatil" \
		"15.6" "Portatil" \
		"17" "Portatil" \
		"24" "Escritorio" \
		"27" "Escritorio"
	)

	# Definimos la resolución elegida
	case $resolution in
		"720p")  width=1280; height=720;  fact="0.6";;
		"1080p") width=1920; height=1080; fact="0.6";;
		"1440p") width=2560; height=1440; fact="0.6";;
		"2160p") width=3840; height=2160; fact="1.2";;
	esac

	# Calculamos el DPI
	displayDPI=$(
		echo "scale=6; sqrt($width^2 + $height^2) / $size * $fact" | bc
	)

	# Redondeamos el DPI calculado al entero más cercano
	rounded_dpi=$(printf "%.0f" "$displayDPI")
}

get_password() {
	local password1 password2

	while true; do

		# Pedir la contraseña la primera vez
		password1=$(
			whiptail --title "Entrada de Contraseña" \
			--passwordbox "Introduce tu contraseña:" \
			8 40 3>&1 1>&2 2>&3
		)

		# Pedir la contraseña una segunda vez
		password2=$(
			whiptail --title "Confirmación de Contraseña" \
			--passwordbox "Confirma tu contraseña:" \
			8 40 3>&1 1>&2 2>&3
		)

		# Si ambas contraseñas coinciden devolver el resultado
		if [ "$password1" == "$password2" ]; then
			echo "$password1" && break
		else
			whip_msg "Error" \
			"Las contraseñas no coincide. Intentalo de nuevo"
		fi
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

# Instalamos:
# - whiptail: para la interfaz TUI
# - parted: para formatear nuestros discos
# - xkeyboard-config: para elegir el layout de teclado
# - bc: para calcular el DPI de la pantalla
pacman -Sy --noconfirm --needed parted libnewt xkeyboard-config bc

# Elegimos como se formatearán nuestros discos
scheme_setup

# Formateamos los discos
format_disks

# Montamos nuestras particiones
mount_partitions

# Elegimos distribución de teclado
kb_layout_select

# Calculamos el DPI
calculate_dpi

# Instalamos paquetes en la nueva instalación
basestrap_install

mkdir -p /mnt/etc

# Creamos el fstab
fstabgen -U /mnt >> /mnt/etc/fstab

# Montamos los directorios necesarios para el chroot
for dir in dev proc sys run; do
	mount --rbind /$dir /mnt/$dir; mount --make-rslave /mnt/$dir
done

rootPassword=$(get_password)

username="$(
	whiptail --backtitle "$REPO_URL" \
	--inputbox "Por favor, ingresa el nombre del usuario:" \
	10 60 3>&1 1>&2 2>&3
)"

userPassword=$(get_password)

artix-chroot /mnt sh -c "
	useradd -m -G wheel,lp $username
	yes $rootPassword | passwd
	yes $userPassword | passwd $username
"

# Copiamos el repositorio a la nueva instalación
cp -r "$(dirname "$0")" "/mnt/home/$username/.dotfiles"

# Hacer chroot y ejecutar la 2a parte del script
#artix-chroot /mnt bash -c "
#	export \
#	rounded_dpi=$rounded_dpi \
#"
