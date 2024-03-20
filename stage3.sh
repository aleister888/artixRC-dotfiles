#!/bin/bash

# Configurar el tema gtk del usuario root
#
# Adaptar el script wakeme para funcionar con cualquier tarjeta de sonido
#
# Incorpoprar un script para hacer copias de seguridad y para restaurar $HOME etc.
#
# Añadir DVDBounce y xautolock

# Funciones que invocaremos a menudo
whip_msg(){
	whiptail --title "$1" --msgbox "$2" 10 60
}

whip_yes(){
	whiptail --title "$1" --yesno "$2" 10 60
}

pacinstall() {
	doas pacman -Sy --noconfirm --needed "$@"
}

yayinstall() {
	yay -Sy --noconfirm --needed "$@"
}

service_add(){
	doas rc-update add "$1" default
}

# Instalar paquetes clave
pacinstall bc zsh dash stow pipewire pipewire-alsa pipewire-audio pipewire-jack pipewire-pulse lib32-pipewire-jack lib32-pipewire lib32-libpipewire wireplumber

video_drivers(){
	# Opciones posibles
	driver_options=("amd" "AMD" "nvidia" "NVIDIA" "intel" "Intel" "virtual" "VMWare" "optimus" "Portátil")
	# Paquetes con los drivers de nvidia
	nvidia_drivers="nvidia nvidia-utils libva-vdpau-driver libva-mesa-driver"
	# Elegimos nuestra tarjeta gráfica
	graphic_driver=$(whiptail --title "Selecciona tu tarjeta gráfica" --menu "Elige una opción:" 15 60 5 \
	${driver_options[@]} 3>&1 1>&2 2>&3)

	case $graphic_driver in
		amd)
			pacinstall mesa xf86-video-amdgpu libva-mesa-driver ;;
		nvidia)
			pacinstall mesa $nvidia_drivers ;;
		intel)
			pacinstall mesa xf86-video-intel libva-intel-driver ;;
		virtual)
			pacinstall mesa xf86-video-vmware xf86-input-vmmouse ;;
		optimus)
			# Si elegimos la opción de portátil con optimus, elegir los drivers de la igpu
			igpu_options=("amd" "AMD" "intel" "Intel") # Opciones
			igpu_driver=$(whiptail --title "Elige una opción:" --menu "Selecciona tu tarjeta gráfica integrada" \
			15 60 5 ${igpu_options[@]} 3>&1 1>&2 2>&3) # Elegimos el driver de video
			case $igpu_driver in # Agregamos el driver seleccionado a los que se instalarán
				amd) nvidia_drivers="$nvidia_drivers xf86-video-amdgpu libva-mesa-driver" ;;
				intel) nvidia_drivers="$nvidia_drivers xf86-video-intel libva-intel-driver" ;;
			esac
			pacinstall mesa bumblebee bumblebee-openrc $nvidia_drivers
			doas gpasswd -a "$USER" bumblebee
			# Bumblebee necesita de xdm para funcionar, hasta que encuentre una solución
			# no activaré el servicio.
			#service_add bumblebee
			;;
	esac
}

aur_install(){
	tmp_dir="/tmp/yay_install_temp"
	mkdir -p "$tmp_dir"
	git clone https://aur.archlinux.org/yay.git "$tmp_dir"
	sh -c "cd $tmp_dir && makepkg -si --noconfirm"
}


##############
## SUCKLESS ##
##############

# Funciones para instalar dwm y todo nuestro entorno de escritorio custom

# Configurar nuestro tema de GTK
gtk_config() {
	# Verificar si el directorio ~/.dotfiles/.config/gtk-4.0 no existe y crearlo si es necesario
	[ ! -d "$HOME/.dotfiles/.config/gtk-4.0" ] && mkdir "$HOME/.dotfiles/.config/gtk-4.0"
	# Crear el archivo de configuración de GTK
	echo "[Settings]
gtk-theme-name=Gruvbox-Dark-B
gtk-icon-theme-name=gruvbox-dark-icons-gtk" > "$HOME/.dotfiles/.config/gtk-4.0/settings.ini"
	# Aplicar configuraciones utilizando stow
	sh -c "cd $HOME/.dotfiles && stow --target=${HOME}/.config/ .config/" >/dev/null

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

xinit_make(){
echo '#!/bin/sh

[ -f $HOME/.config/Xresources ] && xrdb $HOME/.config/Xresources

while true; do
	/usr/local/bin/dwm >/dev/null 2>&1
done' | doas tee /etc/X11/xinit/xinitrc
}

# Instalar mi software suckless
suckless_install(){
	# Instalar software suckless
	pacinstall libx11 libxft libxinerama ttf-dejavu ttf-liberation
	doas make install --directory "$HOME/.dotfiles/dwm" >/dev/null
	doas make install --directory "$HOME/.dotfiles/dmenu" >/dev/null
	doas make install --directory "$HOME/.dotfiles/dwmblocks" >/dev/null
	doas make install --directory "$HOME/.dotfiles/st" >/dev/null
}

calculate_dpi() {
	resolution=$1
	size=$2
	case $resolution in
		"720p")
			width=1280
			height=720
			;;
		"1080p")
			width=1920
			height=1080
			;;
		"1440p")
			width=2560
			height=1440
			;;
		"4K")
			width=3840
			height=2160
			;;
	esac

	case $size in
		"14")
			diagonal=14
			;;
		"15.6")
			diagonal=15.6
			;;
		"17")
			diagonal=17
			;;
		"24")
			diagonal=24
			;;
		"27")
			diagonal=27
			;;
	esac

	display_dpi=$(echo "scale=2; sqrt($width^2 + $height^2) / $diagonal" | bc)
}

# Configurar Xresources teniendo en cuenta el dpi
xresources_config(){
XRES_FILE="$HOME/.dotfiles/.config/Xresources"

# Mostrar diálogo de selección de resolución y tamaño del monitor
resolution=$(whiptail --title "Resolución del Monitor" --menu "Seleccione la resolución de su monitor:" 15 60 4 \
	"720p" "" \
	"1080p" "" \
	"1440p" "" \
	"4K" "" 3>&1 1>&2 2>&3)

size=$(whiptail --title "Tamaño del Monitor" --menu "Seleccione el tamaño de su monitor (en pulgadas):" 15 60 5 \
	"14" "" \
	"15.6" "" \
	"17" "" \
	"24" "" \
	"27" "" 3>&1 1>&2 2>&3)

# Calcular DPI
calculate_dpi "$resolution" "$size"
rounded_dpi=$(echo "($display_dpi + 0.5) / 1" | bc)

# Mostrar el DPI calculado
whiptail --title "DPI Calculado" --msgbox "El DPI de su pantalla es: $rounded_dpi" 10 50

echo "Xft.dpi:$rounded_dpi" >> "$XRES_FILE"
}

# Instalar los paquetes necesarios para usar dwm como entorno de escritorio
dotfiles_packages(){
	yayinstall polkit-gnome gnome-keyring nitrogen udiskie redshift picom tigervnc dunst xautolock xorg \
	xorg-xinit xorg-xkill net-tools arandr gruvbox-dark-gtk xmenu nsxiv \
	xdg-desktop-portal-gtk gcolor2 eww j4-dmenu-desktop gnome-disk-utility lxappearance pamixer playerctl
}

# Configurar el fondo de pantalla
nitrogen_configure() {
# Crear el directorio ~/.config/nitrogen si no existe
mkdir -p "$HOME/.config/nitrogen"
# Crear el archivo de configuración bg-saved.cfg
echo "[xin_-1]
file=$HOME/.dotfiles/assets/wallpaper.png
mode=5
bgcolor=#000000" > "$HOME/.config/nitrogen/bg-saved.cfg"
}

cursor_configure(){
	mkdir -p "$HOME/.local/share/icons/default"
	echo "[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=capitaine-cursors" > "$HOME/.local/share/icons/default/index.theme"
}

dotfiles_install(){
	# Plugins de zsh a clonar
	plugins=(
		"zsh-users/zsh-history-substring-search"
		"zsh-users/zsh-syntax-highlighting"
		"zsh-users/zsh-autosuggestions"
		"MichaelAquilina/zsh-you-should-use"
	)
	# Ruta base para clonar los repositorios
	base_dir="$HOME/.dotfiles/.config/zsh"
	# Clonar cada repositorio
	for plugin in "${plugins[@]}"; do
		git clone "https://github.com/$plugin" "$base_dir/$(basename "$plugin")" >/dev/null
	done

	# Instalar archivos de configuración
	"$HOME/.dotfiles/update.sh"
	echo 'ZDOTDIR=$HOME/.config/zsh' | doas tee /etc/zsh/zshenv
}

kb_layout(){
	# Hacer un array con las diferentes distribuciones posibles
	key_layouts=$(find /usr/share/X11/xkb/symbols/ -mindepth 1 -type f | \
	sed 's|/usr/share/X11/xkb/symbols/||' | sort | sed -n '/^.\{1,3\}$/p')
	keyboard_array=()
	for key_layout in $key_layouts; do
		keyboard_array+=("$key_layout" "$key_layout")
	done

	# Elegir layout con whiptail
	final_layout=$(whiptail --title "Teclado" --menu "Por favor, elige una distribución de teclado:" \
	20 70 10 ${keyboard_array[@]} 3>&1 1>&2 2>&3)
	# Configurar el layout de teclado para Xorg
echo "Section \"InputClass\"
        Identifier \"system-keyboard\"
        MatchIsKeyboard \"on\"
        Option \"XkbLayout\" \"$final_layout\"
        Option \"XkbModel\" \"pc105\"
        Option \"XkbOptions\" \"terminate:ctrl_alt_bksp\"
EndSection" | doas tee /etc/X11/xorg.conf.d/00-keyboard.conf >/dev/null
}

fontdownload() {
	# Definir las URLs de descarga y los nombres de archivo
	AGAVE_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/Agave.zip"
	SYMBOLS_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/NerdFontsSymbolsOnly.zip"
	IOSEVKA_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/Iosevka.zip"
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

# Instalar el administrador de archivos de terminal LF
lf_install(){
	lf_packages="lf imagemagick bat cdrtools ffmpegthumbnailer poppler ueberzug odt2txt gnupg mediainfo trash-cli fzf ripgrep sxiv man-db atool dragon-drop mpv"
	yayinstall $lf_packages
}

# Instalar el reproductor de música
tauon_install(){
	yayinstall tauon-music-box
	"$HOME/.dotfiles/tauon-config.sh"
}

# Instalar nuestras extensiones de navegador
# Código extraido de larbs.xyz/larbs.sh
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

# Configurar keepassxc para que siga el tema de QT
keepass_configure(){
	[ ! -d $HOME/.config/keepassxc ] && mkdir -p $HOME/.config/keepassxc
	echo "[GUI]
ApplicationTheme=classic" > $HOME/.config/keepassxc/keepassxc.ini
}

scripts_link(){
	files=(
		"convert-2m4a"
		"convert-2mp3"
		"corruption-check"
		"exif-remove"
		"wake"
		"wakeme"
	)
	for file in "${files[@]}"; do
		doas ln -sf "$HOME/.dotfiles/bin/$file" "/usr/local/bin/$file"
	done
}

trash_dir(){
	# Crear el directorio /.Trash con permisos adecuados
	doas mkdir --parent /.Trash
	doas chmod a+rw /.Trash
	doas chmod +t /.Trash
}


syncthing_setup(){
	echo "@reboot $(whoami) syncthing --no-browser --no-default-folder" | doas tee -a /etc/crontab
}

# Instalar Virt-Manager y configurar la virtualización
virt_install(){
	# Instalar paquetes para virtualización
	virtual_packages="looking-glass doas-sudo-shim-minimal libvirt-openrc virt-manager qemu-full edk2-ovmf dnsmasq"
	yay -S --noconfirm --needed $virtual_packages
	# Configurar QEMU para usar el usuario actual
	doas sed -i "s/^user = .*/user = \"$USER\"/" /etc/libvirt/qemu.conf
	doas sed -i "s/^group = .*/group = \"$USER\"/" /etc/libvirt/qemu.conf
	# Configurar libvirt
	doas sed -i "s/^unix_sock_group = .*/unix_sock_group = \"$USER\"/" /etc/libvirt/libvirtd.conf
	doas sed -i "s/^unix_sock_rw_perms = .*/unix_sock_rw_perms = \"0770\"/" /etc/libvirt/libvirtd.conf
	# Agregar el usuario al grupo libvirt
	doas usermod -aG libvirt "$USER"
	# Activar sericios necesarios
	doas rc-update add libvirtd default
	doas rc-update add virtlogd default
	# Autoinciar red virtual
	doas virsh net-autostart default
}

############
## SCRIPT ##
############

# Instalar drivers de video
video_drivers && whip_msg "Drivers" "Los drivers de video se instalaron correctamente"

# Instalar yay para poder instalar paquetes del AUR
aur_install

# Instalar paquetes básicos
base_pkgs="alsa-plugins alsa-tools alsa-utils alsa-utils atool dash dashbinsh dosfstools feh eza github-cli lostfiles syncthing dashbinsh jq simple-mtpfs pfetch-rs-bin zathura zathura-pdf-poppler zathura-cb vlc keepassxc ttf-linux-libertine ttf-opensans pacman-contrib ntfs-3g noto-fonts-emoji network-manager-applet rsync mailcap gawk desktop-file-utils tar gzip unzip firefox-arkenfox-autoconfig firefox syslog-ng syslog-ng-openrc mpv timeshift irqbalance-openrc transmission-gtk handbrake blueman htop xdotool thunderbird thunderbird-dark-reader mate-calc xdg-user-dirs nodejs xclip papirus-icon-theme qt5ct capitaine-cursors pavucontrol wine wine-mono wine-gecko winetricks gimp i3lock-fancy-git i3lock-fancy-rapid-git perl-image-exiftool bleachbit baobab perl-file-mimeinfo fluidsynth gnu-free-fonts qt5-tools zip shellcheck-bin"
yayinstall $base_pkgs

# Instalar dwm y todos los paquetes necesarios
xinit_make
suckless_install
xresources_config
dotfiles_packages
nitrogen_configure
cursor_configure

# Instalar nuestros archivos de configuración
dotfiles_install

# Definir la distribución de teclado
kb_layout

# Descargar e instalar nuestras fuentes
fontdownload

# Instalamos el administrador de archivos
lf_install

# Instalamos y configuramos el reproductor de música
tauon_install

# Preguntamos si instalar software para audiofilos
music_packages="easytag picard atool flacon cuetools"
whip_yes "Música" "¿Deseas instalar software para manejar tu colección de música?" && \
yayinstall $music_packages

# Preparamos el uso de máquinas virtuales
whip_yes "Virtualización" "¿Planeas en usar maquinas virtuales?" && virt_install

# Preguntar si instalar paquetes que pueden vulnerar la privacidad
privacy_conc="discord forkgram-bin"
whip_yes "Privacidad" "¿Deseas instalar aplicaciones que promueven plataformas propietarias (Discord y Telegram)?" && \
yayinstall $privacy_conc

# Software de Producción de Audio
daw_packages="tuxguitar reaper yabridge yabridgectl gmetronome drumgizmo fluidsynth"
whip_yes "DAW" "¿Deseas instalar herramientas de producción musical?" && yayinstall $daw_packages

# Instalar software de ofimática
office_packages="zim libreoffice"
whip_yes "Oficina" "¿Deseas instalar software de ofimática?" && pacinstall $office_packages

# Instalar rustdesk
whip_yes "Rustdes" "¿Deseas instalar rustdesk?" && yayinstall rustdesk-bin

whip_yes "laTeX" "¿Deseas instalar laTeX?" && pacinstall texlive-core texlive-bin $(pacman -Ssq texlive)

# Configurar firefox para proteger la privacidad
firefox_configure

# Configurar keepass
keepass_configure

# Configurar la apariencia de las aplicaciones
gtk_config
qt_config

# Descargar los plugins de vim
vim_configure

# Activar servicios
service_add irqbalance
service_add syslog-ng

# Linkear scripts a /usr/local/bin
scripts_link

doas chsh -s /bin/zsh "$USER" # Seleccionar zsh como nuestro shell

# Configurar syncthing para que se inicie con el ordenador
syncthing_setup

# Crear la carpeta de basura
trash_dir

# Crear directorios
mkdir -p $HOME/Documents
mkdir -p $HOME/Downloads
mkdir -p $HOME/Music
mkdir -p $HOME/Pictures
mkdir -p $HOME/Public
mkdir -p $HOME/Videos

rm $HOME/.bash*
rm $HOME/.wget-hsts
