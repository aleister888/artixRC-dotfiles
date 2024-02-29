#!/bin/bash

# Instalar drivers de video

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
		doas pacman -S --noconfirm xf86-video-amdgpu libva-mesa-driver;;
	nvidia)
		doas pacman -S --noconfirm nvidia nvidia-utils libva-vdpau-driver;;
	intel)
		doas pacman -S --noconfirm xf86-video-intel libva-intel-driver;;
	virtual)
		echo "Estás utilizando una máquina virtual, no se requieren controladores adicionales." ;;
	optimus)
		bumblebee_install ;;
esac && \
whiptail --title "Drivers" --msgbox "Los drivers de video se instalaron correctamente" 10 60

# Instalar los paquetes básicos para gráficos acelerados
doas pacman -S --noconfirm --needed mesa mesa-utils mesa-vdpau mesa-libgl xorg xorg-xinit xorg-server

# Instalar escritorio

# Diferentes escritorios a elegir
desktops=(gnome "GNOME" kde "KDE Plasma" xfce "Xfce" dotfiles "dwm")

# Mostrar el menú de selección con whiptail
desktop_choice=$(whiptail --title "Selecciona tu entorno de escritorio" --menu "Elige una opción:" 15 60 4 \
"${desktops[@]}" 3>&1 1>&2 2>&3)

gnome_install(){
	doas pacman -S --noconfirm xorg gnome gdm gdm-openrc librewolf-extension-gnome-shell-integration && \
	doas rc-update add gdm default && \
	whiptail --title "GNOME" --msgbox "Gnome se instaló correctamente" 10 60
}

kde_install(){
	doas pacman -S --noconfirm xorg plasma sddm sddm-openrc && \
	doas rc-update add sddm default && \
	whiptail --title "KDE" --msgbox "Kde Plasma se instaló correctamente" 10 60
}

xfce_install(){
	doas pacman -S --noconfirm xfce4 xfce4-goodies sddm sddm-openrc pavucontrol && \
	doas rc-update add sddm default && \
	whiptail --title "XFCE" --msgbox "Xfce se instaló correctamente" 10 60
}

aur_install(){
	tmp_dir="/tmp/yay_install_temp"
	mkdir -p "$tmp_dir"
	git clone https://aur.archlinux.org/yay.git "$tmp_dir"
	sh -c "cd $tmp_dir && makepkg -si --noconfirm"
}

case $desktop_choice in
	gnome)
		gnome_install ;;
	kde)
		kde_install ;;
	xfce)
		xfce_install ;;
	dotfiles)
		exit 1 ;;
esac

# Instalar paquetes del AUR

whiptail --title "Advertencia" --msgbox "Se van a instalar paquetes del AUR. Es probable que necesites ingresar tu contraseña durante el proceso de instalación." 10 60

aur_install

# TODO: install extensions like larbs.sh Luke script

# basicos
# alsa-plugins alsa-tools alsa-utils alsa-utils atool dash dashbinsh dosfstools feh exa
# github-cli lostfiles 

# Aplicaciones que puedes o no querer
# bleachbit

# dwm
# breeze-snow-cursor dragon-drop dunst eww-x11 font-manager galculator gcolor2 gnome-keyring gruvbox-dark-gtk gtk-layer-shell i3lock-fancy-git irqbalance-openrc lxappearance redshift xdg-xmenu-git ttf-dejavu ttf-linux-libertine ttf-opensans otf-font-awesome

# eww

lf_packages="lf imagemagick bat cdrtools ffmpegthumbnailer poppler ueberzug odt2txt gnupg mediainfo trash-cli fzf ripgrep sxiv zathura zathura-pdf-mupdf man-db atool dragon-drop mpv vlc keepassxc"

privacy_conc="webcord-bin electronmail-bin telegram-desktop"
hiptail --title "Tauon" --yesno "¿Deseas instalar aplicaciones que promueven plataformas propietarias (Discord, Telegram y Protonmail)?" && \
yay -S --noconfirm --needed $privacy_conc

# Instalar y configurar tauon
tauon_install(){
	music_packages="tauon-music-box pavucontrol easytag picard lrcget-bin transmission-gtk"
	yay -S --noconfirm --needed $music_packages
	$HOME/.dotfiles/tauon-config.sh
}
whiptail --title "Tauon" --yesno "¿Deseas instalar el reproductor de música tauon y herramientas de audio?" 10 60 && tauon_install

wine_packages="wine wine-mono wine-gecko winetricks"
whiptail --title "Wine" --yesno "¿Deseas instalar wine?" 10 60 && \
doas pacman -S --needed --noconfirm $wine_packages

daw_packages="tuxguitar reaper yabridge yabridgectl gmetronome drumgizmo wine wine-mono wine-gecko winetricks"
whiptail --title "Wine" --yesno "¿Deseas instalar herramientas para músicos?" 10 60 && \
yay -S --needed --noconfirm $daw_packages

################
# Virt-Manager #
################

virt_install(){
	# Instalar paquetes para virtualización
	virtual_packages="looking-glass doas-sudo-shim-minimal libvirt-openrc virt-manager"
	doas pacman -S --noconfirm --needed $virtual_packages
	# Configurar QEMU para usar el usuario actual
	doas sed -i "s/^user = .*/user = \"$USER\"/" /etc/libvirt/qemu.conf
	doas sed -i "s/^group = .*/group = \"$USER\"/" /etc/libvirt/qemu.conf
	# Configurar libvirt
	doas sed -i "s/^unix_sock_group = .*/unix_sock_group = \"$USER\"/" /etc/libvirt/libvirtd.conf
	doas sed -i "s/^unix_sock_rw_perms = .*/unix_sock_rw_perms = \"0770\"/" /etc/libvirt/libvirtd.conf
	# Agregar el usuario al grupo libvirt
	doas usermod -aG libvirt $USER
	# Activar sericios necesarios
	doas rc-update add libvirtd default
	doas rc-update add virtlogd default
	# Autoinciar red virtual
	doas virsh net-autostart default
}
whiptail --title "Wine" --yesno "¿Planeas en usar maquinas virtuales?" 10 60 && virt_install

#############################
# Instalar paquetes básicos #
#############################

user_packages="irqbalance-openrc tar gzip unzip librewolf-bin syslog-ng syslog-ng-openrc thunderbird thunderbird-dark-reader mpv handbrake gimp zim libreoffice-fresh timeshift libreoffice-fresh"

yay -S --noconfirm -needed $user_packages

# Activar servicios
doas rc-update add irqbalance default
doas rc-update add syslog-ng default

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
	profile="$(grep "Default=.." $profilesini | sed 's/Default=//')"
	pdir="$browserdir/$profile"
	[ -d "$pdir" ] && installffaddons
	killall librewolf
}

whiptail --title "Librewolf" --yesno "¿Desea autoconfigurar el navegador?" 10 60 && \
librewolf_configure
