#!/bin/bash

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
pacinstall zsh dash stow

# Instalar bumblee para portatiles con graficas NVIDIA
bumblebee_install(){
	pacinstall nvidia nvidia-utils bumblebee bumblebee-openrc libva-vdpau-driver
	doas gpasswd -a "$USER" bumblebee
	service_add bumblebee
	dotfiles_install
}

# Instalar el entorno de escritorio GNOME
gnome_install(){
	pacinstall gnome gdm gdm-openrc $pipewire_packages && \
	service_add gdm && \
	whip_msg "GNOME" "Gnome se instaló correctamente"
	dotfiles_install
}

# Instalar el entorno de escritorio KDE
kde_install(){
	pacinstall plasma sddm sddm-openrc konsole $pipewire_packages && \
	service_add sddm && \
	whip_msg "KDE" "Kde Plasma se instaló correctamente"
	dotfiles_install
}

# Instalar el entorno de escritorio Xfce
xfce_install(){
	pacinstall xfce4 xfce4-goodies sddm sddm-openrc pavucontrol $pipewire_packages && \
	service_add sddm && \
	whip_msg "XFCE" "Xfce se instaló correctamente"
	dotfiles_install
}



# Configurar nitrogen
nitrogen_configure() {
# Crear el directorio ~/.config/nitrogen si no existe
mkdir -p "$HOME/.config/nitrogen"
# Crear el archivo de configuración bg-saved.cfg
echo "[xin_-1]
file=$HOME/.dotfiles/assets/wallpaper.png
mode=5
bgcolor=#000000" > "$HOME/.config/nitrogen/bg-saved.cfg"
}

dotfiles_packages(){
	local PACKAGES="polkit-gnome gnome-keyring nitrogen udiskie redshift picom tigervnc dunst xautolock xorg xorg-xinit xorg-xkill"
	pacinstall $PACKAGES
}

# Instalar mis archivos de configuración
dotfiles_install(){
	# Descargar plugins zsh
	git clone https://github.com/zsh-users/zsh-history-substring-search.git "$HOME/.dotfiles/.config/zsh/zsh-history-substring-search" >/dev/null
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.dotfiles/.config/zsh/zsh-syntax-highlighting" >/dev/null
	git clone https://github.com/zsh-users/zsh-autosuggestions.git "$HOME/.dotfiles/.config/zsh/zsh-autosuggestions" >/dev/null
	# Instalar archivos de configuración
	"$HOME/.dotfiles/update.sh"
	echo 'ZDOTDIR=$HOME/.config/zsh' | doas tee /etc/zsh/zshenv
}

# Instalar mi software suckless
suckless_install(){
	# Instalar software suckless
	pacinstall libx11 libxft libxinerama ttf-dejavu ttf-liberation
	whip_msg "suckless.org" "Compilando software suckless..."
	doas make install --directory "$HOME/.dotfiles/dwm" >/dev/null
	doas make install --directory "$HOME/.dotfiles/dmenu" >/dev/null
	doas make install --directory "$HOME/.dotfiles/dwmblocks" >/dev/null
	doas make install --directory "$HOME/.dotfiles/st" >/dev/null
}

# Iniciar dwm con xinit
xinit_make(){
echo '#!/bin/sh

[ -f $HOME/.config/Xresources ] && xrdb $HOME/.config/Xresources

while true; do
	/usr/local/bin/dwm >/dev/null 2>&1
done' | doas tee /etc/X11/xinit/xinitrc
}

gruvbox_install() {
	local THEME_DIR="/usr/share/themes"
	local ICON_DIR="/usr/share/icons"
	# Clonar el repositorio gruvbox-dark-icons-gtk en /usr/local/share/icons/
	doas git clone https://github.com/jmattheis/gruvbox-dark-icons-gtk.git $ICON_DIR/gruvbox-dark-icons-gtk >/dev/null
	# Clonar el repositorio gruvbox-dark-gtk en /usr/local/share/themes/
	doas git clone https://github.com/jmattheis/gruvbox-dark-gtk.git $THEME_DIR/gruvbox-dark-gtk >/dev/null
	# Clona el tema de gtk4
	git clone https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme.git /tmp/Gruvbox_Theme >/dev/null
	# Copia el tema deseado a la carpeta de temas
	doas cp -r /tmp/Gruvbox_Theme/themes/Gruvbox-Dark-B $THEME_DIR/Gruvbox-Dark-B
}

gtk_config() {
	# Verificar si el directorio ~/.dotfiles/.config/gtk-4.0 no existe y crearlo si es necesario
	[ ! -d "$HOME/.dotfiles/.config/gtk-4.0" ] && mkdir "$HOME/.dotfiles/.config/gtk-4.0"
	# Crear el archivo de configuración de GTK
	echo "[Settings]
	gtk-theme-name=Gruvbox-Dark-B
	gtk-icon-theme-name=gruvbox-dark-icons-gtk" > "$HOME/.dotfiles/.config/gtk-4.0/settings.ini"
	# Aplicar configuraciones utilizando stow
	sh -c "cd $HOME/.dotfiles && stow --target=${HOME}/.config/ .config/" >/dev/null
}

lf_install(){
	lf_packages="imagemagick bat cdrtools ffmpegthumbnailer poppler ueberzug odt2txt gnupg mediainfo trash-cli fzf ripgrep sxiv zathura zathura-pdf-poppler man-db atool dragon-drop mpv vlc keepassxc"
	yayinstall $lf_packages
}

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

# Instalar mi entorno Sukless
full_setup(){
	dotfiles_packages
	dotfiles_install
	suckless_install
	xinit_make
	gruvbox_install
	gtk_config
	lf_install
	qt_config
	nitrogen_configure
}



# Definir la distribución de teclado
kb_layout(){
	# Hacer un array con las diferentes distribuciones posibles
	key_layouts=$(find /usr/share/X11/xkb/symbols/ -mindepth 1 -type f | sed 's|/usr/share/X11/xkb/symbols/||' | sort | sed -n '/^.\{1,3\}$/p')
	keyboard_array=()
	for key_layout in $key_layouts; do
		keyboard_array+=("$key_layout" "$key_layout")
	done

	# Elegir layout con whiptail
	final_layout=$(whiptail --title "Teclado" --menu "Por favor, elige una distribución de teclado:" 20 70 10 ${keyboard_array[@]} 3>&1 1>&2 2>&3)
	# Configurar el layout de teclado para Xorg
echo "Section \"InputClass\"
        Identifier \"system-keyboard\"
        MatchIsKeyboard \"on\"
        Option \"XkbLayout\" \"$final_layout\"
        Option \"XkbModel\" \"pc105\"
        Option \"XkbOptions\" \"terminate:ctrl_alt_bksp\"
EndSection" | doas tee /etc/X11/xorg.conf.d/00-keyboard.conf >/dev/null
}



# Instalar yay para poder instalar paquetes del AUR
aur_install(){
	tmp_dir="/tmp/yay_install_temp"
	mkdir -p "$tmp_dir"
	git clone https://aur.archlinux.org/yay.git "$tmp_dir"
	sh -c "cd $tmp_dir && makepkg -si --noconfirm"
}



# Instalar y configurar Tauon Music Box
tauon_install(){
	music_packages="tauon-music-box pavucontrol easytag picard lrcget-bin transmission-gtk atool"
	yay -S --noconfirm --needed $music_packages
	"$HOME"/.dotfiles/tauon-config.sh
}

# Instalar Virt-Manager y configurar la virtualización
virt_install(){
	# Instalar paquetes para virtualización
	virtual_packages="looking-glass doas-sudo-shim-minimal libvirt-openrc virt-manager qemu-full"
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



# Descargar nuestras fuentes
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



# Instalar nuestras extensiones de navegador
# Código extraido de larbs.xyz/larbs.sh
# Créditos para: <luke@lukesmith.xyz>
installffaddons(){
	addonlist="decentraleyes istilldontcareaboutcookies violentmonkey checkmarks-web-ext darkreader xbs keepassxc-browser"
	addontmp="$(mktemp -d)"
	trap "rm -fr $addontmp" HUP INT QUIT TERM PWR EXIT
	IFS=' '
	sudo -u "$USER" mkdir -p "$pdir/extensions/"
	for addon in $addonlist; do
		addonurl="$(curl --silent "https://addons.mozilla.org/en-US/firefox/addon/${addon}/" | grep -o 'https://addons.mozilla.org/firefox/downloads/file/[^"]*')"
		file="${addonurl##*/}"
		curl -LOs "$addonurl" > "$addontmp/$file"
		id="$(unzip -p "$file" manifest.json | grep "\"id\"")"
		id="${id%\"*}"
		id="${id##*\"}"
		mv "$file" "$pdir/extensions/$id.xpi"
	done
	chown -R "$USER:$USER" "$pdir/extensions"
}
librewolf_configure(){
	browserdir="/home/$USER/.librewolf"
	profilesini="$browserdir/profiles.ini"
	librewolf --headless >/dev/null 2>&1 &
	sleep 1
	profile="$(grep "Default=.." "$profilesini" | sed 's/Default=//')"
	pdir="$browserdir/$profile"
	[ -d "$pdir" ] && installffaddons
	killall librewolf
}



##########################
# Instalar Drivers y X11 #
##########################

pipewire_packages="pipewire pipewire-alsa pipewire-audio pipewire-jack pipewire-pulse lib32-pipewire-jack lib32-pipewire lib32-libpipewire"
driver_options=("amd" "AMD" "nvidia" "NVIDIA" "intel" "Intel" "virtual" "Máquina Virtual" "optimus" "Portátil con NVIDIA Optimus")
graphic_driver=$(whiptail --title "Selecciona tu tarjeta gráfica" --menu "Elige una opción:" 15 60 5 \
"${driver_options[@]}" 3>&1 1>&2 2>&3)

case $graphic_driver in
	amd)
		pacinstall xf86-video-amdgpu libva-mesa-driver;;
	nvidia)
		pacinstall nvidia nvidia-utils libva-vdpau-driver;;
	intel)
		pacinstall xf86-video-intel libva-intel-driver;;
	virtual)
		echo "Estás utilizando una máquina virtual, no se requieren controladores adicionales." ;;
	optimus)
		bumblebee_install ;;
esac && \
whip_msg "Drivers" "Los drivers de video se instalaron correctamente"

##################################
# Instalar Entorno de Escritorio #
##################################

# Diferentes escritorios a elegir
desktops=(gnome "GNOME" kde "KDE Plasma" xfce "Xfce" dotfiles "Dwm")

# Mostrar el menú de selección con whiptail
desktop_choice=$(whiptail --title "Selecciona tu entorno de escritorio" --menu "Elige una opción:" 15 60 4 \
"${desktops[@]}" 3>&1 1>&2 2>&3)

case $desktop_choice in
	gnome)
		gnome_install; kb_layout ;;
	kde)
		kde_install; kb_layout ;;
	xfce)
		xfce_install; kb_layout ;;
	dotfiles)
		full_setup; kb_layout ;;
esac

#############################
# Instalar Paquetes del AUR #
#############################

whip_msg "Advertencia" "Se van a instalar paquetes del AUR."

# Instalar el ayudante del AUR: yay
[ ! -f /usr/bin/yay ] && aur_install

# Instalar paquetes básicos
base_pkgs="alsa-plugins alsa-tools alsa-utils alsa-utils atool dash dashbinsh dosfstools feh exa github-cli lostfiles syncthing dashbinsh"
yayinstall $base_pkgs

# Preguntar si instalar paquetes que pueden vulnerar la privacidad
privacy_conc="webcord-bin telegram-desktop"
whip_yes "Privacidad" "¿Deseas instalar aplicaciones que promueven plataformas propietarias (Discord y Telegram)?" && \
yayinstall $privacy_conc

# Instalar y configurar el reproductor de música
whip_yes "Tauon" "¿Deseas instalar el reproductor de música tauon y herramientas de audio?" && tauon_install

#################
# Instalar Wine #
#################

wine_packages="wine wine-mono wine-gecko winetricks"
whip_yes "WINE" "¿Deseas instalar wine?" && pacinstall $wine_packages

###################################
# Software de Producción de Audio #
###################################

daw_packages="tuxguitar reaper yabridge yabridgectl gmetronome drumgizmo wine wine-mono wine-gecko winetricks"
whip_yes "DAW" "¿Deseas instalar herramientas para músicos?" && yayinstall $daw_packages

##############################
# Software de Virtualización #
##############################

whip_yes "Virtualización" "¿Planeas en usar maquinas virtuales?" && virt_install

#########################
# Paquetes de ofimática #
#########################

office_packages="thunderbird thunderbird-dark-reader zim libreoffice"
whip_yes "Oficina" "¿Deseas instalar software de ofimática?" && pacinstall $office_packages

#############################
# Instalar paquetes básicas #
#############################

user_packages="tar gzip unzip librewolf-bin syslog-ng syslog-ng-openrc mpv timeshift irqbalance-openrc"
yayinstall $user_packages

# Activar servicios
service_add irqbalance
service_add syslog-ng

####################
# Instalar fuentes #
####################

whip_msg "Awesome Fonts" "Se van a instalar las fuentes necesarias." && fontdownload

############################
# Autoconfigurar Librewolf #
############################

whip_yes "Librewolf" "¿Desea autoconfigurar el navegador?" && librewolf_configure
