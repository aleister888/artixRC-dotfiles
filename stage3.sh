#!/bin/bash -x

# Auto-instalador para Artix OpenRC (Parte 3)
# por aleister888 <pacoe1000@gmail.com>
# Licencia: GNU GPLv3

# Esta parte del script se ejecuta como nuestro usuario creado, no como root.
# Una vez instalado yay, desinstalamos sudo y lo reemplazamos por opendoas.

# Importamos todos los componentes en los que se separa el script
PATH="$PATH:$(find ~/.dotfiles/modules -type d | paste -sd ':' -)"

# URL con el repositorio
REPO_URL="https://github.com/aleister888/artixRC-dotfiles"

# Funciones que invocaremos a menudo
whip_msg(){ # Mensajes de tailbox
	whiptail --backtitle "$REPO_URL" \
	--title "$1" --msgbox "$2" 10 60
}

whip_yes(){ # Elegir con whiptail
	whiptail --backtitle "$REPO_URL" \
	--title "$1" --yesno "$2" 10 60
}

pacinstall() { # Instalar paquetes con pacman
	sudo pacman -Sy --noconfirm --disable-download-timeout --needed "$@"
}

yayinstall() { # Instalar paquetes con yay
	yay -Sy --noconfirm --disable-download-timeout --needed "$@"
}

whip_menu(){ # Menus de whitpail
	local TITLE=$1
	local MENU=$2
	shift 2
	whiptail --backtitle "$REPO_URL" --title "$TITLE" --menu "$MENU" 15 60 5 $@ 3>&1 1>&2 2>&3
}

service_add(){ # Activar servicio
	sudo rc-update add "$1" default
}

# Paquetes

# Guardamos nuestros paquetes en un array con mapfile desde los
# diferentes archivos
mapfile -t packages < <(cat \
	"$HOME"/.dotfiles/assets/packages/appearance \
	"$HOME"/.dotfiles/assets/packages/cli-tools \
	"$HOME"/.dotfiles/assets/packages/compress \
	"$HOME"/.dotfiles/assets/packages/documents \
	"$HOME"/.dotfiles/assets/packages/fonts \
	"$HOME"/.dotfiles/assets/packages/gui-apps \
	"$HOME"/.dotfiles/assets/packages/misc \
	"$HOME"/.dotfiles/assets/packages/mozilla \
	"$HOME"/.dotfiles/assets/packages/multimedia \
	"$HOME"/.dotfiles/assets/packages/pipewire \
	"$HOME"/.dotfiles/assets/packages/services \
	"$HOME"/.dotfiles/assets/packages/system \
	"$HOME"/.dotfiles/assets/packages/x11
)
# Ya instalamos pipewire en stage1.sh, pero no los paquetes para
# 32 bits, que vienen de los repositorios de Arch Linux

# Vamos a elegir primero que paquetes instalar y que acciones tomar, y luego instalar todo conjuntamente
driver_choose(){
	# Opciones posibles
	driver_options=("amd" "AMD" "nvidia" "NVIDIA" "intel" "Intel" "virtual" "VM")
	# Elegimos nuestra tarjeta gráfica
	graphic_driver=$(whip_menu "Selecciona tu tarjeta grafica" "Elige una opcion:" \
	${driver_options[@]})
	case $graphic_driver in
	amd)
		packages+=("xf86-video-amdgpu" "mesa" "lib32-mesa" "vulkan-radeon" "lib32-vulkan-radeon") ;;
	nvidia)
		packages+=("dkms" "nvidia-dkms" "nvidia-utils" "libva-vdpau-driver" "libva-mesa-driver" "nvidia-prime" "lib32-nvidia-utils" "nvidia-utils-openrc" "opencl-nvidia") ;;
	intel)
		packages+=("xf86-video-intel" "libva-intel-driver" "lib32-libva-intel-driver" "vulkan-intel" "lib32-vulkan-intel") ;;
	virtual)
		packages+=("xf86-video-vmware" "xf86-input-vmmouse" "vulkan-virtio" "lib32-vulkan-virtio") ;;
	esac
}

# Elegir el software a instalar
packages_choose(){
	local packages_confirm="false"
	# Definimos todas las variables (menos daw, music y virt) como locales
	local noprivacy office latex

	while [ "$packages_confirm" == "false" ]; do

		variables=("virt" "music" "noprivacy" "daw" "office" "latex")

		# Reiniciamos las variables si no confirmamos la selección
		for var in "${variables[@]}"; do eval "$var=false"; done

		whip_yes "Virtualizacion" "¿Quieres instalar libvirt para ejecutar máquinas virtuales?" && \
			virt="true"
		whip_yes "Musica"         "¿Deseas instalar software para manejar tu coleccion de musica?" && \
			music="true"
		whip_yes "Privacidad"     "¿Deseas instalar Discord y Telegram?" && \
			noprivacy="true"
		whip_yes "Oficina"        "¿Deseas instalar software de ofimatica?" && \
			office="true"
		whip_yes "laTeX"          "¿Deseas instalar laTeX?" && \
			latex="true"
		whip_yes "DAW"            "¿Deseas instalar software de produccion de audio?" && \
			audioProd="true"

		# Confirmamos la selección de paquetes a instalar (o no)
		if packages_show; then
			packages_confirm=true
		else
			whip_msg "Operacion cancelada" "Se te volvera a preguntar que software desea instalar"
		fi
	done

	# Agregamos paquetes al array dependiendo de las respuestas
	if [ "$virt" == "true" ]; then
		while IFS= read -r package; do
			packages+=("$package")
		done < "$HOME/.dotfiles/assets/packages/opt/virt"
	fi
	if [ "$latex" == "true" ]; then
		while IFS= read -r package; do
			packages+=("$package")
		done < "$HOME/.dotfiles/assets/packages/opt/latex"
	fi
	if [ "$audioProd" == "true" ]; then
		while IFS= read -r package; do
			packages+=("$package")
		done < "$HOME/.dotfiles/assets/packages/opt/daw"
	fi

	[ "$music" == "true" ] && \
		packages+=("easytag" "picard" "flacon" "cuetools" "lrcget-bin" "python-tqdm")
	[ "$noprivacy" == "true" ] && \
		packages+=("discord" "telegram-desktop")
	[ "$office" == "true" ] && \
		packages+=("libreoffice" "libreoffice-fresh-es")
}

# Elegimos que paquetes instalar
packages_show(){
	local scheme # Variable con la lista de paquetes a instalar
	scheme="Se instalaran:\n"
	[ "$virt"      == "true" ] && scheme+="libvirt\n"
	[ "$music"     == "true" ] && scheme+="soft. gestión de música\n"
	[ "$noprivacy" == "true" ] && scheme+="telegram y discord\n"
	[ "$office"    == "true" ] && scheme+="soft. ofimatica\n"
	[ "$latex"     == "true" ] && scheme+="laTeX\n"
	[ "$audioProd"       == "true" ] && scheme+="Tuxguitar REAPER Metronome Audio-Plugins\n"
	whiptail --backtitle "$REPO_URL" --title "Confirmar paquetes" --yesno "$scheme" 15 60
}

# Elegimos distribución de teclado
kb_layout_select(){
	# Hacer un array con las diferentes distribuciones posibles y elegir nuestro layout
	key_layouts=$(find /usr/share/X11/xkb/symbols/ -mindepth 1 -type f  -printf "%f\n" | \
	sort -u | grep -v '...')
	keyboard_array=()
	for key_layout in $key_layouts; do
		keyboard_array+=("$key_layout" "$key_layout")
	done
	final_layout=$(whip_menu "Teclado" "Por favor, elige una distribucion de teclado:" \
	${keyboard_array[@]})
}

kb_layout_conf(){
	sudo mkdir -p /etc/X11/xorg.conf.d/ # X11
	cat <<-EOF | sudo tee /etc/X11/xorg.conf.d/00-keyboard.conf >/dev/null
		Section "InputClass"
		    Identifier "system-keyboard"
		    MatchIsKeyboard "on"
		    Option "XkbLayout" "$final_layout"
		    Option "XkbModel" "pc105"
		    Option "XkbOptions" "terminate:ctrl_alt_bksp"
		EndSection
	EOF
	# Si elegimos español, configurar el layout de la tty en español también
	[ "$final_layout" == "es" ] && sudo sed -i 's|keymap="us"|keymap="es"|' /etc/conf.d/keymaps
}

# Calcular el DPI de nuestra pantalla y configurar Xresources
xresources_make(){
	mkdir -p "$HOME/.config"
	XRES_FILE="$HOME/.config/Xresources"
	cp "$HOME/.dotfiles/assets/configs/Xresources" "$XRES_FILE"
	# Selección de resolución del monitor
	resolution=$(whip_menu "Resolucion del Monitor" "Seleccione la resolucion de su monitor:" \
		"720p" "HD" "1080p" "Full-HD" "1440p" "QHD" "2160p" "4K")

	# Selección del tamaño del monitor en pulgadas (diagonal)
	size=$(whip_menu "Tamaño del Monitor" "Seleccione el tamaño de su monitor (en pulgadas):" \
		"14" "Portatil" "15.6" "Portatil" "17" "Portatil" "24" "Escritorio" "27" "Escritorio")

	# Definimos la resolución elegida
	case $resolution in
		"720p")  width=1280; height=720 ;;
		"1080p") width=1920; height=1080 ;;
		"1440p") width=2560; height=1440 ;;
		"2160p") width=3840; height=2160 ;;
	esac

	# Calculamos el PPI y lo dividimos por 2
	display_dpi=$(echo "scale=6; sqrt($width^2 + $height^2) / $size / 2" | bc)
	# Redondeamos el PPI calculado al entero más cercano
	rounded_dpi=$(printf "%.0f" "$display_dpi")
	clear; echo "El DPI de su pantalla es: $rounded_dpi"; sleep 0.75
	# Añadimos nuestro DPI a el arcivo Xresources
	echo "Xft.dpi:$rounded_dpi" | tee -a "$XRES_FILE"
}

# Descargar los archivos de diccionario
vim_spell_download(){
	mkdir -p "$HOME/.local/share/nvim/site/spell/"
	wget "https://ftp.nluug.nl/pub/vim/runtime/spell/es.utf-8.spl" -q -O "$HOME/.local/share/nvim/site/spell/es.utf-8.spl"
	wget "https://ftp.nluug.nl/pub/vim/runtime/spell/es.utf-8.sug" -q -O "$HOME/.local/share/nvim/site/spell/es.utf-8.sug"
}

# Instalamos dwm y otras aplicaciones suckless
suckless_install(){
	# Instalar software suckless
	for app in dwm dmenu st dwmblocks
		do sudo make install --directory "$HOME/.dotfiles/$app" >/dev/null
	done
}

# Configurar keepassxc para que siga el tema de QT
keepass_configure(){
	[ ! -d "$HOME/.config/keepassxc" ] && mkdir -p "$HOME/.config/keepassxc"
	cp "$HOME/.dotfiles/assets/configs/keepassxc.ini" \
		"$HOME/.config/keepassxc/keepassxc.ini"
}

# Crear enlaces simbólicos a /usr/local/bin para ciertos scripts
scripts_link(){
	files=(
		"wake"
		"wakeme"
		"pipewire-start"
		"tray-toggle"
		"xmenu-apps"
		"rdp-connect"
	)
	for file in "${files[@]}"; do
		sudo ln -sf "$HOME/.dotfiles/bin/$file" "/usr/local/bin/$file"
	done
}

# Crear el directorio /.Trash con permisos adecuados
trash_dir(){
	sudo mkdir --parent /.Trash
	sudo chmod a+rw /.Trash
	sudo chmod +t /.Trash
}

##########################
# Aquí empieza el script #
##########################

# Instalamos yay (https://aur.archlinux.org/packages/yay)
yay-install
# Reemplazar sudo por doas
sudo sudo2doas

# Crear directorios
for dir in Documentos Música Imágenes Público Vídeos
	do mkdir -p "$HOME/$dir"
done
ln -s /tmp/ "$HOME/Descargas"

# Escogemos que drivers de vídeo instalar
driver_choose
# Elegimos que paquetes instalar
packages_choose
# Elegimos distribución de teclado
kb_layout_select
kb_layout_conf
# Calcular el DPI de nuestra pantalla y configurar Xresources
xresources_make

# Antes de instalar los paquetes, configurar makepkg para
# usar todos los núcleos durante la compliación
# Créditos para: <luke@lukesmith.xyz>
sudo sed -i "s/-j2/-j$(nproc)/;/^#MAKEFLAGS/s/^#//" /etc/makepkg.conf

# Instalar grub-btrfs solo si se detecta que / es una partición btrfs
if sudo lsblk -nlf -o FSTYPE "$( df / | awk 'NR==2 {print $1}' )" | grep btrfs; then
	packages+=("grub-btrfs")
fi

# Instalamos todos los paquetes a la vez
yayinstall "${packages[@]}"

# Instalamos dwm y otras utilidades
suckless_install

# Crear directorio para montar dispositivos android
sudo mkdir /mnt/ANDROID
sudo chown "$USER" /mnt/ANDROID

# Configuramos Tauon Music Box (Nuestro reproductor de música)
"$HOME/.dotfiles/bin/tauon-config"

# Creamos nuestro xinitrc
sudo cp "$HOME/.dotfiles/assets/configs/xinitrc" /etc/X11/xinit/xinitrc

# Configurar keepassxc para que siga el tema de QT
keepass_configure

# Suspender de forma automatica cuando la bateria cae por debajo del 10%
[ -e /sys/class/power_supply/BAT0 ] && autosuspend-conf

# Permitir hacer click tocando el trackpad (X11)
# Créditos para: <luke@lukesmith.xyz>
[ -e /sys/class/power_supply/BAT0 ] && \
sudo cp "$HOME/.dotfiles/assets/configs/40-libinput.conf" "/etc/X11/xorg.conf.d/40-libinput.conf"

# Establecemos la versión de java por defecto
sudo archlinux-java set java-17-openjdk

# Descargar los diccionarios para vim
vim_spell_download
# Instalar los archivos de configuración e instalar plugins de zsh
dotfiles-install
# Crear enlaces simbólicos a /usr/local/bin/ para ciertos scripts
scripts_link
# Crear el directorio /.Trash con permisos adecuados
trash_dir

# Configurar syncthing para que se inicie con el ordenador
echo "@reboot $USER syncthing --no-browser --no-default-folder" | sudo tee -a /etc/crontab

# Si estamos usando una máquina virtual,
# configuramos X11 para usar 1080p como resolución
[ "$graphic_driver" == "virtual" ] && \
sudo cp "$HOME/.dotfiles/assets/configs/xorg.conf" /etc/X11/xorg.conf

# Permitir a Steam controlar mandos de PlayStation 4
sudo cp "$HOME/.dotfiles/assets/udev/99-steam-controller-perms.rules" \
	/usr/lib/udev/rules.d/

# Activar servicios
service_add syslog-ng
service_add elogind
service_add earlyoom
service_add tlp

# Configurar y activar xdm
service_add xdm
sudo cp "$HOME/.dotfiles/assets/xdm/Xresources" /etc/X11/xdm/Xresources
sudo cp "$HOME/.dotfiles/assets/xdm/Xsetup_0"   /etc/X11/xdm/Xsetup_0

# Activar WiFi y Bluetooth
sudo rfkill unblock wifi
{ lspci | grep -i bluetooth || lsusb | grep -i bluetooth; } >/dev/null \
	&& sudo rfkill unblock bluetooth

# Permitir al usuario escanear redes Wi-Fi y cambiar ajustes de red
sudo usermod -aG network "$USER"
[ -e /sys/class/power_supply/BAT0 ] && \
sudo cp "$HOME/.dotfiles/assets/udev/50-org.freedesktop.NetworkManager.rules" \
	"/etc/polkit-1/rules.d/50-org.freedesktop.NetworkManager.rules"

# /etc/polkit-1/rules.d/99-artix.rules
sudo usermod -aG storage,input,users "$USER"

# Configurar el software de instalación opcional
[ "$virt" == "true" ]      && sudo virt-conf
[ "$audioProd" == "true" ] && sudo audio-production-conf
[ "$music" == "true" ]     && lrcput-install

# Configurar el audio de baja latencia
sudo audio-setup
# Configuramos el reloj según la zona horaria escogida
sudo set-clock
# Terminamos de configurar pacman
sudo pacman-conf

# Scripts de elogind
sudo install -m 755 "$HOME/.dotfiles/assets/system/nm-restart" /lib/elogind/system-sleep/nm-restart

# Script para redes con autenticación vía navegador
sudo install -m 755 "$HOME/.dotfiles/assets/system/90-open_captive_portal" /etc/NetworkManager/dispatcher.d/90-open_captive_portal

# Añadir entradas a /etc/environmentv
echo 'CARGO_HOME="~/.local/share/cargo"
GNUPGHOME="~/.local/share/gnupg"
_JAVA_OPTIONS=-Djava.util.prefs.userRoot="~/.config/java"' | sudo tee -a /etc/environment

WINEPREFIX="$HOME/.config/wineprefixes" winetricks -q mfc42

# Borrar archivos innecesarios
rm "$HOME"/.bash* 2>/dev/null
rm "$HOME"/.wget-hsts 2>/dev/null

mkdir -p "$HOME"/.local/share/gnupg

############
# Arreglos #
############

pacman -Q poppler >/dev/null 2>&1 && \
	sudo ln -s /usr/lib/libpoppler-cpp.so.2.0.0 /usr/lib/libpoppler-cpp.so.1
