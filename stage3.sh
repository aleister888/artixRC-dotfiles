#!/bin/bash

# Funciones que invocaremos a menudo
whip_msg(){
	whiptail --title "$1" --msgbox "$2" 10 60
}

whip_yes(){
	whiptail --title "$1" --yesno "$2" 10 60
}

pacinstall() {
	doas pacman -Sy --noconfirm --needed --asexplicit "$@"
}

yayinstall() {
	yay -Sy --noconfirm --needed --asexplicit "$@"
}

service_add(){
	doas rc-update add "$1" default
}

packages="libx11 libxft libxinerama ttf-dejavu ttf-liberation alsa-plugins alsa-tools alsa-utils alsa-utils atool dash dashbinsh dosfstools feh eza lostfiles syncthing dashbinsh jq simple-mtpfs pfetch-rs-bin zathura zathura-pdf-poppler zathura-cb vlc keepassxc ttf-linux-libertine ttf-opensans pacman-contrib ntfs-3g noto-fonts-emoji network-manager-applet rsync mailcap gawk desktop-file-utils tar gzip unzip firefox-arkenfox-autoconfig firefox syslog-ng syslog-ng-openrc mpv timeshift irqbalance-openrc transmission-gtk handbrake blueman htop xdotool thunderbird thunderbird-dark-reader mate-calc xdg-user-dirs nodejs xclip papirus-icon-theme qt5ct capitaine-cursors pavucontrol wine wine-mono wine-gecko winetricks gimp i3lock-fancy-git i3lock-fancy-rapid-git perl-image-exiftool bleachbit baobab perl-file-mimeinfo fluidsynth gnu-free-fonts qt5-tools zip shellcheck-bin cbatticon ca-certificates ca-certificates-mozilla java-environment-common jdk-openjdk extra/github-cli zsh dash stow mesa lib32-mesa polkit-gnome gnome-keyring nitrogen udiskie redshift picom tigervnc dunst xautolock xorg xorg-xinit xorg-xkill net-tools arandr gruvbox-dark-gtk nsxiv xorg-twm xorg-xclock xterm xdg-desktop-portal-gtk gcolor2 eww j4-dmenu-desktop gnome-disk-utility lxappearance pamixer playerctl lf imagemagick bat cdrtools ffmpegthumbnailer poppler ueberzug odt2txt gnupg mediainfo trash-cli fzf ripgrep sxiv man-db atool dragon-drop mpv tauon-music-box jre17-openjdk jre17-openjdk-headless jdk-openjdk xorg-xdm xdm-openrc inkscape realtime-privileges xorg-xbacklight"

# Vamos a elegir primero que paquetes instalar y que acciones tomar, y luego instalar todo conjuntamente

driver_choose(){
	# Opciones posibles
	driver_options=("amd" "AMD" "nvidia" "NVIDIA" "intel" "Intel" "virtual" "VM" "optimus" "Portátil")
	# Elegimos nuestra tarjeta gráfica
	graphic_driver=$(whiptail --title "Selecciona tu tarjeta gráfica" --menu "Elige una opción:" 15 60 5 \
	${driver_options[@]} 3>&1 1>&2 2>&3)
	case $graphic_driver in
	amd)
	packages="$packages xf86-video-amdgpu libva-mesa-driver" ;;
	nvidia)
	packages="$packages nvidia nvidia-utils libva-vdpau-driver libva-mesa-driver" ;;
	intel)
	packages="$package xf86-video-intel libva-intel-driver" ;;
	virtual)
	packages="$packages xf86-video-vmware xf86-input-vmmouse vulkan-virtio lib32-vulkan-virtio" ;;
	optimus)
	packages="$packages nvidia nvidia-utils libva-vdpau-driver libva-mesa-driver nvidia-prime"
	# Si elegimos la opción de portátil con optimus, elegir los drivers de la igpu
	igpu_options=("amd" "AMD" "intel" "Intel") # Opciones
	igpu_driver=$(whiptail --title "Elige una opción:" --menu "Selecciona tu tarjeta gráfica integrada" \
	15 60 5 ${igpu_options[@]} 3>&1 1>&2 2>&3) # Elegimos el driver de video
	case $igpu_driver in # Agregamos el driver seleccionado a los que se instalarán
		amd)   packages="$packages xf86-video-amdgpu libva-mesa-driver" ;;
		intel) packages="$packages xf86-video-intel libva-intel-driver" ;;
	esac ;;
	esac
}

# Elegir si instalar virt-manager
virt_choose(){
	if whip_yes "Virtualización" "¿Planeas en usar maquinas virtuales?"; then
		# Instalar paquetes para virtualización
		packages="$packages looking-glass libvirt-openrc virt-manager qemu-full edk2-ovmf dnsmasq"
		isvirt="true"
	fi
}

# Elegimos distribución de teclado
kb_layout_select(){
	# Hacer un array con las diferentes distribuciones posibles y elegir nuestro layout
	key_layouts=$(find /usr/share/X11/xkb/symbols/ -mindepth 1 -type f | \
	sed 's|/usr/share/X11/xkb/symbols/||' | sort | sed -n '/^.\{1,3\}$/p')
	keyboard_array=()
	for key_layout in $key_layouts; do
		keyboard_array+=("$key_layout" "$key_layout")
	done
	final_layout=$(whiptail --title "Teclado" --menu "Por favor, elige una distribución de teclado:" \
	20 70 10 ${keyboard_array[@]} 3>&1 1>&2 2>&3)
}

kb_layout_conf(){
	# Configurar el layout de teclado para Xorg
	doas mkdir -p /etc/X11/xorg.conf.d/
echo "Section \"InputClass\"
        Identifier \"system-keyboard\"
        MatchIsKeyboard \"on\"
        Option \"XkbLayout\" \"$final_layout\"
        Option \"XkbModel\" \"pc105\"
        Option \"XkbOptions\" \"terminate:ctrl_alt_bksp\"
EndSection" | doas tee /etc/X11/xorg.conf.d/00-keyboard.conf >/dev/null
	# Si elegimos español, configurar el layout de la tty en español también
	if [ "$final_layout" = "es" ]; then
		doas sed -i 's|keymap="us"|keymap="es"|' /etc/conf.d/keymaps
	fi
}

# Calcular el DPI de nuestra pantalla y configurar Xresources
xresources_make(){
	XRES_FILE="$HOME/.config/Xresources"
	cp $HOME/.dotfiles/assets/Xresources $XRES_FILE
	resolution=$(whiptail --title "Resolución del Monitor" --menu "Seleccione la resolución de su monitor:" \
	15 60 4 "720p" "" "1080p" "" "1440p" "" "4K" "" 3>&1 1>&2 2>&3)
	size=$(whiptail --title "Tamaño del Monitor" --menu "Seleccione el tamaño de su monitor (en pulgadas):" \
	15 60 5 "14" "" "15.6" "" "17" "" "24" "" "27" "" 3>&1 1>&2 2>&3)
	case $resolution in
		"720p")
			width=1280 height=720 ;;
		"1080p")
			width=1920 height=1080 ;;
		"1440p")
			width=2560 height=1440 ;;
		"4K")
			width=3840 height=2160 ;;
	esac
	display_dpi=$(echo "scale=2; sqrt($width^2 + $height^2) / $size" | bc)
	rounded_dpi=$(echo "($display_dpi + 0.5) / 1" | bc)
	clear; echo "El DPI de su pantalla es: $rounded_dpi"; sleep 1.5
	echo "Xft.dpi:$rounded_dpi" >> "$XRES_FILE"
}

# Descargar e instalar nuestras fuentes
fontdownload() {
	# Definir las URLs de descarga y los nombres de archivo
	AGAVE_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/Agave.zip"
	SYMBOLS_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/NerdFontsSymbolsOnly.zip"
	IOSEVKA_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/Iosevka.zip"
	# Archivos temporales
	AGAVE_ZIP="/tmp/Agave.zip"
	SYMBOLS_ZIP="/tmp/Symbols.zip"
	IOSEVKA_ZIP="/tmp/Iosevka.zip"
	# Definir directorios de destino
	AGAVE_DIR="/usr/share/fonts/Agave"
	SYMBOLS_DIR="/usr/share/fonts/NerdFontsSymbolsOnly"
	IOSEVKA_DIR="/usr/share/fonts/Iosevka"
	# Descargar fuentes
	echo "Descargando fuentes..."
	doas wget -q "$AGAVE_URL" -O "$AGAVE_ZIP"
	doas wget -q "$SYMBOLS_URL" -O "$SYMBOLS_ZIP"
	doas wget -q "$IOSEVKA_URL" -O "$IOSEVKA_ZIP"
	# Extraer fuentes
	echo "Extrayendo fuentes..."
	doas unzip -q "$AGAVE_ZIP" -d "$AGAVE_DIR"
	doas unzip -q "$SYMBOLS_ZIP" -d "$SYMBOLS_DIR"
	doas unzip -q "$IOSEVKA_ZIP" -d "$IOSEVKA_DIR"
	#
	if [ ! -d "$HOME/.local/share/fonts" ]; then
		mkdir -p "$HOME/.local/share/fonts"
		ln -s /usr/local/share/fonts/Iosevka "$HOME/.local/share/fonts/Iosevka"
		ln -s /usr/local/share/fonts/Agave "$HOME/.local/share/fonts/Agave"
	fi
}

# Instalar nuestras extensiones de navegador
# Código extraído de larbs.xyz/larbs.sh
# Créditos para: <luke@lukesmith.xyz>
installffaddons(){
	addonlist="ublock-origin istilldontcareaboutcookies violentmonkey checkmarks-web-ext darkreader xbs keepassxc-browser video-downloadhelper clearurls"
	addontmp="$(mktemp -d)"
	trap "rm -fr $addontmp" HUP INT QUIT TERM PWR EXIT
	IFS=' '
	mkdir -p "$pdir/extensions/"
	for addon in $addonlist; do
		if [ "$addon" = "ublock-origin" ]; then
			addonurl="$(curl -sL https://api.github.com/repos/gorhill/uBlock/releases/latest | grep -E 'browser_download_url.*firefox' | cut -d '"' -f 4)"
		else
			addonurl="$(curl --silent "https://addons.mozilla.org/en-US/firefox/addon/${addon}/" | grep -o 'https://addons.mozilla.org/firefox/downloads/file/[^"]*')"
		fi
		file="${addonurl##*/}"
		curl -LOs "$addonurl" > "$addontmp/$file"
		id="$(unzip -p "$file" manifest.json | grep "\"id\"")"
		id="${id%\"*}"
		id="${id##*\"}"
		mv "$file" "$pdir/extensions/$id.xpi"
	done
	chown -R "$USER:$USER" "$pdir/extensions"
}
firefox_configure(){
	browserdir="/home/$USER/.mozilla/firefox"
	profilesini="$browserdir/profiles.ini"
	firefox --headless >/dev/null 2>&1 &
	sleep 1
	profile="$(grep "Default=.." "$profilesini" | sed 's/Default=//')"
	pdir="$browserdir/$profile"
	[ -d "$pdir" ] && installffaddons
	killall firefox
}

# Configurar neovim e instalar los plugins
vim_configure(){
	# Instalar VimPlug
	sh -c "curl -fLo ${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim --create-dirs \
		   https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" >/dev/null
	# Instalar los plugins
	nvim +'PlugInstall --sync' +qa >/dev/null 2>&1
}

# Instalar los archivos de configuración locales y en github
dotfiles_install(){
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
	echo 'ZDOTDIR=$HOME/.config/zsh' | doas tee /etc/zsh/zshenv
	doas chsh -s /bin/zsh "$USER" # Seleccionar zsh como nuestro shell
}

# Vamos a configurar nuestro entorno de trabajo

# Instalamos dwm y otras aplicaciones suckless
suckless_install(){
	# Instalar software suckless
	if [ $resolution == "1080p" ]; then
		doas make 1080 install --directory "$HOME/.dotfiles/dwm" >/dev/null
	elif [ $resolution == "2160p" ]; then
		doas make 2160 install --directory "$HOME/.dotfiles/dwm" >/dev/null
	fi
	doas make install --directory "$HOME/.dotfiles/dmenu" >/dev/null
	doas make install --directory "$HOME/.dotfiles/dwmblocks" >/dev/null
	doas make install --directory "$HOME/.dotfiles/st" >/dev/null
	doas make install --directory "$HOME/.dotfiles/xmenu" >/dev/null
}

xinit_make(){
doas cp "$HOME/.dotfiles/assets/xinitrc" /etc/X11/xinit/xinitrc
}

# Configurar nuestro tema de QT
qt_config(){
echo "[Appearance]
color_scheme_path=$HOME/.config/qt5ct/colors/Gruvbox.conf
custom_palette=true
icon_theme=gruvbox-dark-icons-gtk
standard_dialogs=default
style=Fusion

[Fonts]
fixed=\"Iosevka Nerd Font Mono,12,-1,5,50,0,0,0,0,0,Bold\"
general=\"Iosevka Nerd Font,12,-1,5,63,0,0,0,0,0,SemiBold\"" > "$HOME/.dotfiles/.config/qt5ct/qt5ct.conf"
}

# Configurar nuestro tema de GTK
gtk_config() {
	# Verificar si el directorio ~/.dotfiles/.config/gtk-4.0 no existe y crearlo si es necesario
	[ ! -d "$HOME/.dotfiles/.config/gtk-4.0" ] && mkdir "$HOME/.dotfiles/.config/gtk-4.0"
	# Crear el archivo de configuración de GTK
	cp "$HOME/.dotfiles/assets/settings.ini" "$HOME/.dotfiles/.config/gtk-4.0/settings.ini"
	# Aplicar configuraciones utilizando stow
	sh -c "cd $HOME/.dotfiles && stow --target=${HOME}/.config/ .config/" >/dev/null
	# Definimos nuestros directorios marca-páginas
echo "file:///home/$(whoami)
file:///home/$(whoami)/Downloads
file:///home/$(whoami)/Documents
file:///home/$(whoami)/Pictures
file:///home/$(whoami)/Videos
file:///home/$(whoami)/Music" > "$HOME/.config/gtk-3.0/bookmarks"

	local THEME_DIR="/usr/share/themes"
	# Clona el tema de gtk4
	git clone https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme.git /tmp/Gruvbox_Theme >/dev/null
	# Copia el tema deseado a la carpeta de temas
	doas cp -r /tmp/Gruvbox_Theme/themes/Gruvbox-Dark-B $THEME_DIR/Gruvbox-Dark-B

	# Tema GTK para el usuario root (Para aplicaciones como Bleachbit)
	doas cp "$HOME/.dotfiles/assets/.gtkrc-2.0" /root/.gtkrc-2.0
	doas mkdir -p /root/.config/gtk-3.0
	doas mkdir -p /root/.config/gtk-4.0
	doas cp $HOME/.dotfiles/.config/gtk-3.0/settings.ini /root/.config/gtk-3.0/
	doas cp $HOME/.dotfiles/.config/gtk-4.0/settings.ini /root/.config/gtk-4.0/
}

# Configurar el fondo de pantalla
nitrogen_configure() {
# Crear el archivo de configuración bg-saved.cfg
mkdir -p "$HOME/.config/nitrogen"
echo "[xin_-1]
file=$HOME/.dotfiles/assets/wallpaper.png
mode=5
bgcolor=#000000" > "$HOME/.config/nitrogen/bg-saved.cfg"
}

# Configurar el tema del cursor
cursor_configure(){
mkdir -p "$HOME/.local/share/icons/default"
cp "$HOME/.dotfiles/assets/index.theme" "$HOME/.local/share/icons/default/index.theme"
}

# Configurar keepassxc para que siga el tema de QT
keepass_configure(){
[ ! -d $HOME/.config/keepassxc ] && \
mkdir -p $HOME/.config/keepassxc
cp "$HOME/.dotfiles/assets/keepassxc.ini" "$HOME/.config/keepassxc/keepassxc.ini"
}

# Crear enlaces simbólicos a /usr/local/bin/ para ciertos scripts
scripts_link(){
	files=(
		"convert-2m4a"
		"convert-2mp3"
		"corruption-check"
		"exif-remove"
		"wake"
		"wakeme"
		"compressed-backup"
	)
	for file in "${files[@]}"; do
		doas ln -sf "$HOME/.dotfiles/bin/$file" "/usr/local/bin/$file"
	done
}

# Crear el directorio /.Trash con permisos adecuados
trash_dir(){
	doas mkdir --parent /.Trash
	doas chmod a+rw /.Trash
	doas chmod +t /.Trash
}

# Configurar syncthing para que se inicie con el ordenador
syncthing_setup(){
	echo "@reboot $(whoami) syncthing --no-browser --no-default-folder" | doas tee -a /etc/crontab
}

# Configurar el audio de baja latencia
audio_setup(){
	doas gpasswd -a "$USER" realtime && \
	doas gpasswd -a "$USER" audio && \
	cat /etc/security/limits.conf | grep audio || \
	echo "@audio - rtprio 95
	@audio - memlock unlimited
	$(whoami) hard nofile 524288" | \
	doas tee -a /etc/security/limits.conf
}

# Si se eligió instalar virt-manager, configurarlo adecuadamente
virt_conf(){
	# Configurar QEMU para usar el usuario actual
	doas sed -i "s/^user = .*/user = \"$USER\"/" /etc/libvirt/qemu.conf
	doas sed -i "s/^group = .*/group = \"$USER\"/" /etc/libvirt/qemu.conf
	# Configurar libvirt
	doas sed -i "s/^unix_sock_group = .*/unix_sock_group = \"$USER\"/" /etc/libvirt/libvirtd.conf
	doas sed -i "s/^unix_sock_rw_perms = .*/unix_sock_rw_perms = \"0770\"/" /etc/libvirt/libvirtd.conf
	# Agregar el usuario al grupo libvirt
	doas usermod -aG libvirt,libvirt-qemu,kvm "$USER"
	# Activar sericios necesarios
	service_add libvirtd
	service_add virtlogd
	# Autoinciar red virtual
	doas virsh net-autostart default
}

##########################
# Aquí empieza el script #
##########################

# Instalamos yay
tmp_dir="/tmp/yay_install_temp"
mkdir -p "$tmp_dir"
git clone https://aur.archlinux.org/yay.git "$tmp_dir"
sh -c "cd $tmp_dir && makepkg -si --noconfirm"

# Escogemos que drivers de video instalar
driver_choose
# Elegir si instalar virt-manager
virt_choose

# Preguntamos si queremos instalar software-adicional
whip_yes "Música" "¿Deseas instalar software para manejar tu colección de música?" && \
packages="$packages easytag picard atool flacon cuetools"
#
whip_yes "Privacidad" "¿Deseas instalar aplicaciones que promueven plataformas propietarias (Discord y Telegram)?" && \
packages="$packages discord forkgram-bin"
#
if whip_yes "DAW" "¿Deseas instalar herramientas de producción musical?"; then
	packages="$packages tuxguitar reaper yabridge yabridgectl gmetronome drumgizmo fluidsynth"
	mkdir -p $HOME/Documents/Guitarra/Tabs && \
	ln -s $HOME/Documents/Guitarra/Tabs $HOME/Documents/Tabs
	mkdir -p $HOME/Documents/Guitarra/REAPER\ Media && \
	ln -s $HOME/Documents/Guitarra/REAPER\ Media $HOME/Documents/REAPER\ Media
fi
#
whip_yes "Oficina" "¿Deseas instalar software de ofimática?" && \
packages="$packages libreoffice"
#
whip_yes "laTeX" "¿Deseas instalar laTeX?" && \
packages="$packages texlive-core texlive-bin $(pacman -Ssq texlive)"

# Instalamos xkeyboard-config porque lo necesitamos para poder elegir el layout de teclado
# Instalamos pipewire antes de nada, porque si no tendremos conflictos
# (Para algunos paquetes se instala jack2 en vez de pipewire-jack por defecto).
pacinstall xkeyboard-config bc pipewire pipewire-alsa pipewire-audio pipewire-jack pipewire-pulse lib32-pipewire-jack lib32-pipewire lib32-libpipewire wireplumber

# Elegimos distribución de teclado
kb_layout_select
kb_layout_conf

# Calcular el DPI de nuestra pantalla y configurar Xresources
xresources_make

# A partir de aquí no se necesita interacción del usuario
whip_msg "Tiempo de espera" "La instalación va a terminarse, esto tomará unos 20min aprox. (Depende de la velocidad de tu conexión a Internet)"

# Instalamos todos nuestros paquetes
yayinstall $packages

# Descargar e instalar nuestras fuentes
fontdownload

doas archlinux-java set java-17-openjdk

# Configurar firefox para proteger la privacidad
firefox_configure
# Configurar neovim e instalar los plugins
vim_configure

# Instalar los archivos de configuración locales y en github
dotfiles_install

# Configuramos Tauon Music Box (Nuestro reproductor de música)
"$HOME/.dotfiles/tauon-config.sh"
# Instalamos dwm y otras utilidades
suckless_install
# Creamos nuestro xinitrc
xinit_make
# Configurar nuestro tema de QT
qt_config
# Configurar nuestro tema de GTK
gtk_config
# Configurar el fondo de pantalla
nitrogen_configure
# Configurar el tema del cursor
cursor_configure
# Configurar keepassxc para que siga el tema de QT
keepass_configure
# Crear enlaces simbólicos a /usr/local/bin/ para ciertos scripts
scripts_link
# Crear el directorio /.Trash con permisos adecuados
trash_dir
# Configurar syncthing para que se inicie con el ordenador
syncthing_setup
# Configurar el audio de baja latencia
audio_setup

# Si estamos usando una máquina virtual,
# configuramos X11 para usar 1080p como resolución

[ "$graphic_driver" == "virtual" ] && \
doas cp "$HOME/.dotfiles/assets/xorg.conf" /etc/X11/xorg.conf

# Crear directorios
mkdir -p $HOME/Documents
mkdir -p $HOME/Downloads
mkdir -p $HOME/Music
mkdir -p $HOME/Pictures
mkdir -p $HOME/Public
mkdir -p $HOME/Videos

rm $HOME/.bash* 2>/dev/null
rm $HOME/.wget-hsts 2>/dev/null

# Permitir a Steam controlar mandos de PlayStation 4
doas cp $HOME/.dotfiles/assets/99-steam-controller-perms.rules /usr/lib/udev/rules.d/

# Activar servicios
service_add irqbalance
service_add syslog-ng
service_add xdm

doas rfkill ublock wifi
doas rfkill ublock bluetooth

# Si se eligió instalar virt-manager configurarlo adecuadamente
[ "$isvirt" == "true" ] && \
virt_conf
