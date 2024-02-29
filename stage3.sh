#!/bin/bash

##########################
# Instalar Drivers y X11 #
##########################

# Diferentes opciones a elegir
driver_options=("amd" "AMD" "nvidia" "NVIDIA" "intel" "Intel" "virtual" "Máquina Virtual" "optimus" "Portátil con NVIDIA Optimus")

graphic_driver=$(whiptail --title "Selecciona tu tarjeta gráfica" --menu "Elige una opción:" 15 60 5 \
"${driver_options[@]}" 3>&1 1>&2 2>&3)

bumblebee_install(){
	doas pacman -S --noconfirm nvidia nvidia-utils \
	bumblebee bumblebee-openrc libva-vdpau-driver
	doas gpasswd -a "$USER" bumblebee
	doas rc-update add bumblebee default
}

case $graphic_driver in
	amd)
		doas pacman -S --noconfirm --needed xf86-video-amdgpu libva-mesa-driver;;
	nvidia)
		doas pacman -S --noconfirm --needed nvidia nvidia-utils libva-vdpau-driver;;
	intel)
		doas pacman -S --noconfirm --needed xf86-video-intel libva-intel-driver;;
	virtual)
		echo "Estás utilizando una máquina virtual, no se requieren controladores adicionales." ;;
	optimus)
		bumblebee_install ;;
esac && \
whiptail --title "Drivers" --msgbox "Los drivers de video se instalaron correctamente" 10 60

# Instalar los paquetes básicos para gráficos acelerados
doas pacman -S --noconfirm --needed mesa mesa-utils mesa-vdpau mesa-libgl xorg xorg-xinit xorg-server

##############
# Escritorio #
##############

pipewire_packages="pipewire pipewire-alsa pipewire-audio pipewire-jack pipewire-pulse lib32-pipewire-jack lib32-pipewire lib32-libpipewire"

# Diferentes escritorios a elegir
desktops=(gnome "GNOME" kde "KDE Plasma" xfce "Xfce" dotfiles "Dwm")

# Mostrar el menú de selección con whiptail
desktop_choice=$(whiptail --title "Selecciona tu entorno de escritorio" --menu "Elige una opción:" 15 60 4 \
"${desktops[@]}" 3>&1 1>&2 2>&3)

gnome_install(){
	doas pacman -S --noconfirm --needed gnome gdm gdm-openrc "$pipewire_packages" && \
	doas rc-update add gdm default && \
	whiptail --title "GNOME" --msgbox "Gnome se instaló correctamente" 10 60
}

kde_install(){
	doas pacman -S --noconfirm --needed plasma sddm sddm-openrc konsole "$pipewire_packages" && \
	doas rc-update add sddm default && \
	whiptail --title "KDE" --msgbox "Kde Plasma se instaló correctamente" 10 60
}

xfce_install(){
	doas pacman -S --noconfirm --needed xfce4 xfce4-goodies sddm sddm-openrc pavucontrol "$pipewire_packages" && \
	doas rc-update add sddm default && \
	whiptail --title "XFCE" --msgbox "Xfce se instaló correctamente" 10 60
}

dotfiles_install(){
	# Descargar plugins zsh
	git clone https://github.com/zsh-users/zsh-history-substring-search.git "$HOME/.dotfiles/.config/zsh/zsh-history-substring-search" >/dev/null
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.dotfiles/.config/zsh/zsh-syntax-highlighting" >/dev/null
	git clone https://github.com/zsh-users/zsh-autosuggestions.git "$HOME/.dotfiles/.config/zsh/zsh-autosuggestions" >/dev/null
	# Instalar archivos de configuración
	"$HOME"/.dotfiles/update.sh
}

suckless_install(){
	# Instalar software suckless
	whiptail --title "suckless.org" --msgbox "Compilando software suckless" 10 60
	doas make install --directory "$HOME/aleister/.dotfiles/dwm" >/dev/null 2>&1
	doas make install --directory "$HOME/aleister/.dotfiles/dmenu" >/dev/null 2>&1
	doas make install --directory "$HOME/aleister/.dotfiles/dwmblocks" >/dev/null 2>&1
	doas make install --directory "$HOME/aleister/.dotfiles/st" >/dev/null 2>&1
	# Iniciar dwm con xinit
echo "#!/bin/sh

[ -f \$HOME/.config/Xresources ] && xrdb \$HOME/.config/Xresources

while true; do
    /usr/local/bin/dwm 2>/dev/null
done" | doas tee /etc/X11/xinit/xinitrc >/dev/null
}

kb_layout(){
	# Hacer un array con los diferentes layouts de teclado posibles
	key_layouts=$(find /usr/share/X11/xkb/symbols/ -mindepth 1 -type f | sed 's|/usr/share/X11/xkb/symbols/||' | sort | uniq | grep -v ...)
	keyboard_array=()
	for key_layout in $key_layouts; do
		keyboard_array+=("$key_layout" "$key_layout")
	done

	# Elegir layout con whiptail
	final_layout=$(whiptail --title "Teclado" --menu "Por favor, elige una distribución de teclado:" 20 70 10 "${keyboard_array[@]}" 3>&1 1>&2 2>&3)
echo "Section \"InputClass\"
        Identifier \"system-keyboard\"
        MatchIsKeyboard \"on\"
        Option \"XkbLayout\" \"$final_layout\"
        Option \"XkbModel\" \"pc105\"
        Option \"XkbOptions\" \"terminate:ctrl_alt_bksp\"
EndSection" | doas tee /etc/X11/xorg.conf.d/00-keyboard.conf >/dev/null
}

case $desktop_choice in
	gnome)
		kb_layout; gnome_install ;;
	kde)
		kb_layout; kde_install ;;
	xfce)
		kb_layout; xfce_install ;;
	dotfiles)
		kb_layout; exit 1 ;;
esac

#############################
# Instalar paquetes del AUR #
#############################

whiptail --title "Advertencia" --msgbox "Se van a instalar paquetes del AUR. Es probable que necesites ingresar tu contraseña durante el proceso de instalación." 10 60

aur_install(){
	tmp_dir="/tmp/yay_install_temp"
	mkdir -p "$tmp_dir"
	git clone https://aur.archlinux.org/yay.git "$tmp_dir"
	sh -c "cd $tmp_dir && makepkg -si --noconfirm"
}

# Instalar el ayudante del AUR: yay
[ ! -f /usr/bin/yay ] && aur_install

# Basicos
base_pkgs="alsa-plugins alsa-tools alsa-utils alsa-utils atool dash dashbinsh dosfstools feh exa github-cli lostfiles"
yay -S --noconfirm --needed "$base_pkgs"

# Aplicaciones que puedes o no querer
# bleachbit handbrake gimp keepassxc 

# dwm
# breeze-snow-cursor dragon-drop dunst eww-x11 font-manager galculator gcolor2 gnome-keyring gruvbox-dark-gtk gtk-layer-shell i3lock-fancy-git irqbalance-openrc lxappearance redshift xdg-xmenu-git ttf-dejavu ttf-linux-libertine ttf-opensans otf-font-awesome

# eww

#lf_packages="lf imagemagick bat cdrtools ffmpegthumbnailer poppler ueberzug odt2txt gnupg mediainfo trash-cli fzf ripgrep sxiv zathura zathura-pdf-mupdf man-db atool dragon-drop mpv vlc keepassxc"

privacy_conc="webcord-bin electronmail-bin telegram-desktop"
whiptail --title "Tauon" --yesno "¿Deseas instalar aplicaciones que promueven plataformas propietarias (Discord, Telegram y Protonmail)?" 10 60 && \
yay -S --noconfirm --needed "$privacy_conc"

###############################
# Instalar y configurar tauon #
###############################

tauon_install(){
	music_packages="tauon-music-box pavucontrol easytag picard lrcget-bin transmission-gtk atool"
	yay -S --noconfirm --needed "$music_packages"
	"$HOME"/.dotfiles/tauon-config.sh
}

whiptail --title "Tauon" --yesno "¿Deseas instalar el reproductor de música tauon y herramientas de audio?" 10 60 && tauon_install

########
# Wine #
########

wine_packages="wine wine-mono wine-gecko winetricks"
whiptail --title "Wine" --yesno "¿Deseas instalar wine?" 10 60 && \
doas pacman -S --needed --noconfirm "$wine_packages"

####################
# Audio Production #
####################

daw_packages="tuxguitar reaper yabridge yabridgectl gmetronome drumgizmo wine wine-mono wine-gecko winetricks"
whiptail --title "Wine" --yesno "¿Deseas instalar herramientas para músicos?" 10 60 && \
yay -S --needed --noconfirm "$daw_packages"

################
# Virt-Manager #
################

virt_install(){
	# Instalar paquetes para virtualización
	virtual_packages="looking-glass doas-sudo-shim-minimal libvirt-openrc virt-manager"
	yay -S --noconfirm --needed "$virtual_packages"
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
whiptail --title "Wine" --yesno "¿Planeas en usar maquinas virtuales?" 10 60 && virt_install

########################
# Paquetes de oficinia #
########################

office_packages="thunderbird thunderbird-dark-reader zim libreoffice"
whiptail --title "Oficina" --yesno "¿Deseas instalar software de ofimática?" 10 60 && \
doas pacman -S --noconfirm --needed "$office_packages"

#############################
# Instalar paquetes básicos #
#############################

user_packages="tar gzip unzip librewolf-bin syslog-ng syslog-ng-openrc mpv timeshift irqbalance-openrc"

yay -S --noconfirm --needed "$user_packages"

# Activar servicios
doas rc-update add irqbalance default
doas rc-update add syslog-ng default

###########
# Fuentes #
###########

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

whiptail --title "Awesome Fonts" --msgbox "Se van a instalar las fuentes necesarias." 10 60 && \
fontdownload

########################
# Configurar Librewolf #
########################

# Código modificado procedente de: larbs.xyz/larbs.sh
# https://github.com/LukeSmithxyz/voidrice

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

whiptail --title "Librewolf" --yesno "¿Desea autoconfigurar el navegador?" 10 60 && \
librewolf_configure
