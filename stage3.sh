#!/bin/bash -x

# Auto-instalador para Artix OpenRC (Parte 3)
# por aleister888 <pacoe1000@gmail.com>
# Licencia: GNU GPLv3

# Esta parte del script se ejecuta como nuestro usuario creado, no como root.
# Una vez instalado yay, desinstalamos sudo y lo reemplazamos por opendoas.

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

# Sistema
packages="zsh dash dashbinsh dosfstools lostfiles simple-mtpfs pacman-contrib ntfs-3g rsync mailcap gawk xdg-user-dirs nodejs perl-image-exiftool stow mesa lib32-mesa mesa-utils gnupg trash-cli net-tools xdg-desktop-portal-gtk man-db java-environment-common jdk-openjdk jre17-openjdk jdk-openjdk realtime-privileges lib32-gnutls perl-file-mimeinfo grub-hook glow kernel-modules-hook python-pynvim parallel glyr python-eyed3 sassc atomicparsley npm zenity libappimage squashfuse earlyoom-openrc autorandr"
# X11
packages+=" libx11 libxft libxinerama xorg-xkill xorg-twm xorg xorg-xinit xdotool xclip"
# Fuentes
packages+=" ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-mono ttc-iosevka-ss05 ttf-dejavu ttf-liberation ttf-linux-libertine ttf-opensans ttf-roboto noto-fonts-emoji gnu-free-fonts noto-fonts-cjk"
# Archivos comprimidos
packages+=" xarchiver atool tar unrar gzip unzip zip p7zip lha lrzip lzip lzop unarj"
# Servicios
packages+=" syslog-ng syslog-ng-openrc"
# Documentos
packages+=" poppler zathura zathura-pdf-mupdf tesseract-data-spa zathura-cb"
# Firefox y thunderbird
packages+=" arkenfox-user.js firefox thunderbird ca-certificates ca-certificates-mozilla"
# Multimedia
packages+=" alsa-plugins alsa-tools alsa-utils alsa-utils python-pypresence mpv mpv-mpris mediainfo feh vlc gimp sxiv nsxiv tauon-music-box yt-dlp"
# Herramientas de terminal
packages+=" eza jq pfetch-rs-bin htop shellcheck-bin fzf ripgrep bat cdrtools ffmpegthumbnailer odt2txt"
# Apariencia
packages+=" qt6ct qt5ct qt5-tools papirus-icon-theme"
# Aplicaciones GUI
packages+=" keepassxc qbittorrent handbrake handbrake-cli bleachbit"
# Misc
packages+=" dragon-drop syncthing fluidsynth extra/github-cli pamixer playerctl lf imagemagick inkscape go yad downgrade pv wine wine-mono wine-gecko winetricks remmina freerdp gtk-vnc libvncserver ueberzug libjpeg6-turbo lib32-libjpeg-turbo lib32-libjpeg6-turbo extra-cmake-modules gcolor3 gnome-disk-utility xautolock libqalculate redshift udiskie nitrogen picom-ftlabs-git polkit-gnome gnome-keyring dunst xmenu eww-git tigervnc gnome-firmware i3lock-fancy-rapid-git stalonetray gruvbox-dark-gtk capitaine-cursors xorg-xdm xdm-openrc network-manager-applet desktop-file-utils tlp-openrc tlp arandr pulsemixer tk extra/j4-dmenu-desktop bash-language-server acpi neovim-remote android-tools"
# Pipewire
# (Ya instalamos en stage1.sh pipewire, pero no los paquetes para 32 bits, que vienen de los repositorios de Arch Linux)
packgaes+=" lib32-pipewire-jack lib32-pipewire lib32-libpipewire"
# WM
packages+=" thunderbird-dark-reader timeshift"

# Vamos a elegir primero que paquetes instalar y que acciones tomar, y luego instalar todo conjuntamente
driver_choose(){
	# Opciones posibles
	driver_options=("amd" "AMD" "nvidia" "NVIDIA" "intel" "Intel" "virtual" "VM")
	# Elegimos nuestra tarjeta gráfica
	graphic_driver=$(whip_menu "Selecciona tu tarjeta grafica" "Elige una opcion:" \
	${driver_options[@]})
	case $graphic_driver in
	amd)
		packages+=" xf86-video-amdgpu mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon" ;;
	nvidia)
		packages+=" dkms nvidia-dkms nvidia-utils libva-vdpau-driver libva-mesa-driver nvidia-prime lib32-nvidia-utils nvidia-utils-openrc opencl-nvidia" ;;
	intel)
		packages+=" xf86-video-intel libva-intel-driver lib32-libva-intel-driver vulkan-intel lib32-vulkan-intel" ;;
	virtual)
		packages+=" xf86-video-vmware xf86-input-vmmouse vulkan-virtio lib32-vulkan-virtio" ;;
	esac
}

# Elegir el software a instalar
packages_choose(){
	local packages_confirm="false"
	# Definimos todas las variables menos daw y virt como locales
	local music noprivacy office latex

	while [ "$packages_confirm" == "false" ]; do
		variables=("virt" "music" "noprivacy" "daw" "office" "latex")
		# Reiniciamos las variables si no confirmamos la selección
		for var in "${variables[@]}"; do eval "$var=false"; done

		whip_yes "Virtualizacion" "¿Planeas en usar maquinas virtuales?" && \
			virt="true"
		whip_yes "Musica" "¿Deseas instalar software para manejar tu coleccion de musica?" && \
			music="true"
		whip_yes "Privacidad" "¿Deseas instalar aplicaciones que promueven plataformas propietarias (Discord y Telegram)?" && \
			noprivacy="true"
		whip_yes "Oficina" "¿Deseas instalar software de ofimatica?" && \
			office="true"
		whip_yes "laTeX" "¿Deseas instalar laTeX? (Esto llevara mucho tiempo)" && \
			latex="true"
		whip_yes "DAW" "¿Deseas instalar software de produccion de audio?" && \
			daw="true"

		if packages_show; then
			packages_confirm=true
		else
			whip_msg "Operacion cancelada" "Se te volvera a preguntar que software desea instalar"
		fi
	done

	[ "$virt"	== "true" ] && packages+=" looking-glass libvirt-openrc virt-manager qemu-base edk2-ovmf dnsmasq qemu-audio-spice qemu-hw-display-qxl qemu-chardev-spice qemu-hw-usb-redirect qemu-hw-usb-host qemu-hw-display-virtio-gpu qemu-hw-display-virtio-gpu-gl qemu-hw-display-virtio-gpu-pci qemu-hw-display-virtio-gpu-pci-gl qemu-hw-display-virtio-vga qemu-hw-display-virtio-vga-gl bridge-utils"

	if [ "$music" == "true" ]; then
		# Instalamos python-tqdm porque es una dependencia de lrcput
		packages+=" easytag picard flacon cuetools lrcget-bin python-tqdm"

		lrcput_location="$HOME/.local/bin/lrcput"
		mkdir -p "$HOME/.local/bin"
		wget -q "https://raw.githubusercontent.com/JustOptimize/lrcput/refs/heads/main/lrcput.py" -O "$lrcput_location"
		sed -i '1i #!/usr/bin/python' "$lrcput_location"
		chmod +x "$lrcput_location"
	fi

	[ "$noprivacy" == "true" ] && \
		packages+=" discord telegram-desktop"
	[ "$office" == "true" ] && \
		packages+=" libreoffice"
	[ "$latex" == "true" ] && \
		packages+=" texlive-core texlive-bin texlive-langspanish texlive-bibtexextra texlive-binextra texlive-context texlive-fontsextra texlive-fontsrecommended texlive-fontutils texlive-formatsextra texlive-latex texlive-latexextra texlive-latexrecommended texlive-mathscience texlive-music texlive-pictures texlive-plaingeneric texlive-pstricks texlive-publishers texlive-xetex"

	if [ "$daw" == "true" ]; then
		packages+=" gmetronome tuxguitar-bin reaper yabridge yabridgectl drumgizmo surge-xt-clap surge-xt-vst3 surge-xt"
		# El paquete tuxguitar-bin guarda el archivo .desktop de la aplicación en un directorio no estándar.
		# Con esto enlazamos los archivos necesarios en /usr/share para que el sistema los reconozca.
		sudo ln -s /opt/tuxguitar/share/applications/tuxguitar.desktop /usr/share/applications/
		[ ! -d /usr/share/icons/hicolor/96x96/apps ] && sudo mkdir -p /usr/share/icons/hicolor/96x96/apps
		sudo ln -s /opt/tuxguitar/share/pixmaps/tuxguitar.png /usr/share/icons/hicolor/96x96/apps/
		sudo ln -s /usr/bin/tuxguitar-bin /usr/bin/tuxguitar
	fi
}

# Elegimos que paquetes instalar
packages_show(){
	local scheme # Variable con la lista de paquetes a instalar
	scheme="Se instalaran:\n"
	[ "$virt"      == "true" ] && scheme+="Virt-Manager\n"
	[ "$music"     == "true" ] && scheme+="Easytag Picard Flacon Cuetools Lrcget\n"
	[ "$noprivacy" == "true" ] && scheme+="Telegram Discord\n"
	[ "$office"    == "true" ] && scheme+="Libreoffice\n"
	[ "$latex"     == "true" ] && scheme+="TeX-live\n"
	[ "$daw"       == "true" ] && scheme+="Tuxguitar REAPER Metronome Audio-Plugins\n"
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
	echo "Section \"InputClass\"
	Identifier \"system-keyboard\"
	MatchIsKeyboard \"on\"
	Option \"XkbLayout\" \"$final_layout\"
	Option \"XkbModel\" \"pc105\"
	Option \"XkbOptions\" \"terminate:ctrl_alt_bksp\"
EndSection" | sudo tee /etc/X11/xorg.conf.d/00-keyboard.conf >/dev/null
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

# Instalar los archivos de configuración e instalar plugins de zsh
dotfiles_install(){
	# Crear la carpeta ~/.config
	mkdir -p "$HOME/.config"
	# Plugins de zsh a clonar
	plugins=(
		"zsh-users/zsh-history-substring-search"
		"zsh-users/zsh-syntax-highlighting"
		"zsh-users/zsh-autosuggestions"
		"MichaelAquilina/zsh-you-should-use"
	)
	# Ruta done para clonar los repositorios
	base_dir="$HOME/.dotfiles/.config/zsh"
	# Clonamos cada repositorio
	for plugin in "${plugins[@]}"; do
		git clone "https://github.com/$plugin" "$base_dir/$(basename "$plugin")" >/dev/null
	done
	# Instalamos nuestros archivos de configuración
	"$HOME/.dotfiles/update.sh"
	echo "ZDOTDIR=\$HOME/.config/zsh" | sudo tee /etc/zsh/zshenv
	sudo chsh -s /bin/zsh "$USER" # Seleccionar zsh como nuestro shell
}

# Instalamos dwm y otras aplicaciones suckless
suckless_install(){
	# Instalar software suckless
	for app in dwm dmenu st; do sudo make install --directory "$HOME/.dotfiles/$app" >/dev/null; done
	sudo make install --directory "$HOME/.dotfiles/dwmblocks" >/dev/null
	sudo make install --directory "$HOME/.dotfiles/xmenu" >/dev/null
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
		"lock"
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

# Configurar el audio de baja latencia
audio_setup(){
	sudo usermod -aG realtime,audio,video,optical,uucp "$USER"
	grep audio /etc/security/limits.conf || \
	echo "@audio - rtprio 95
	@audio - memlock unlimited
	$USER hard nofile 524288" | \
	sudo tee -a /etc/security/limits.conf
}

# Si se eligió instalar virt-manager, configurarlo adecuadamente
virt_conf(){
	# Configurar QEMU para usar el usuario actual
	sudo sed -i "s/^#user = .*/user = \"$USER\"/" /etc/libvirt/qemu.conf
	sudo sed -i "s/^#group = .*/group = \"$USER\"/" /etc/libvirt/qemu.conf
	# Configurar libvirt
	sudo sed -i "s/^#unix_sock_group = .*/unix_sock_group = \"$USER\"/" /etc/libvirt/libvirtd.conf
	sudo sed -i "s/^#unix_sock_rw_perms = .*/unix_sock_rw_perms = \"0770\"/" /etc/libvirt/libvirtd.conf
	# Agregar el usuario al grupo libvirt
	sudo usermod -aG libvirt,libvirt-qemu,kvm "$USER"
	# Activar sericios necesarios
	service_add libvirtd
	service_add virtlogd
	# Autoinciar red virtual
	#sudo virsh net-autostart default
}

##########################
# Aquí empieza el script #
##########################

# Instalamos yay (https://aur.archlinux.org/packages/yay)
tmp_dir="/tmp/yay_install_temp"
mkdir -p "$tmp_dir"
git clone https://aur.archlinux.org/yay.git "$tmp_dir"
sh -c "cd $tmp_dir && makepkg -si --noconfirm"

# Reemplazar sudo por doas
echo 'permit nopass keepenv setenv { XAUTHORITY LANG LC_ALL } :wheel' | \
	sudo tee /etc/doas.conf
sudo chown -c root:root /etc/doas.conf
sudo chmod -c 0400 /etc/doas.conf
sudo rm /etc/sudoers
doas pacman -Rcns sudo --noconfirm
yayinstall doas-sudo-shim

# Escogemos que drivers de vídeo instalar
driver_choose

# Crear directorios
for dir in Documentos Descargas Música Imágenes Público Vídeos; do mkdir -p "$HOME/$dir"; done

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
	packages+=" grub-btrfs"
fi

# Instalamos todos los paquetes a la vez
yayinstall $packages

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
if [ -e /sys/class/power_supply/BAT0 ]; then
	sudo install -m 755 "$HOME/.dotfiles/assets/system/auto-suspend" \
		/usr/local/bin/auto-suspend
	sudo install -m 755 "$HOME/.dotfiles/assets/system/auto-suspend-loop" \
		/usr/local/bin/auto-suspend-loop
	sudo install -m 755 "$HOME/.dotfiles/assets/system/auto-suspend-service" \
		/etc/init.d/auto-suspend
	service_add auto-suspend
fi

# Permitir hacer click tocando el trackpad (X11)
# Créditos para: <luke@lukesmith.xyz>
[ -e /sys/class/power_supply/BAT0 ] && \
sudo cp "$HOME/.dotfiles/assets/configs/40-libinput.conf" "/etc/X11/xorg.conf.d/40-libinput.conf"

# Bloquear la pantalla al suspender el portátil
sudo install -m 755 "$HOME/.dotfiles/assets/system/display-lock" /lib/elogind/system-sleep/display-lock

# Establecemos la versión de java por defecto
sudo archlinux-java set java-17-openjdk

# Descargar los diccionarios para vim
vim_spell_download
# Instalar los archivos de configuración e instalar plugins de zsh
dotfiles_install
# Crear enlaces simbólicos a /usr/local/bin/ para ciertos scripts
scripts_link
# Crear el directorio /.Trash con permisos adecuados
trash_dir

# Configurar syncthing para que se inicie con el ordenador
echo "@reboot $USER syncthing --no-browser --no-default-folder" | sudo tee -a /etc/crontab

# Configurar el audio de baja latencia
audio_setup

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

# Si se eligió instalar virt-manager configurarlo adecuadamente
[ "$virt" == "true" ] && virt_conf

# Scripts de elogind
sudo install -m 755 "$HOME/.dotfiles/assets/system/nm-restart" /lib/elogind/system-sleep/nm-restart

# Añadir entradas a /etc/environment
echo 'CARGO_HOME="~/.local/share/cargo"
GNUPGHOME="~/.local/share/gnupg"
_JAVA_OPTIONS=-Djava.util.prefs.userRoot="~/.config/java"' | sudo tee -a /etc/environment

WINEPREFIX="$HOME/.config/wineprefixes" winetricks -q mfc42
#WINEPREFIX="$HOME/.config/wineprefixes" winetricks -q dotnet45

# Borrar archivos innecesarios
rm "$HOME"/.bash* 2>/dev/null
rm "$HOME"/.wget-hsts 2>/dev/null
