#!/bin/bash

if ! command -v doas &> /dev/null; then
	echo "Opendoas no está instalado. Recuerda que tiene que estar instalado y configurado para que el script funcione"
	exit 1
fi

if ! command -v bash &> /dev/null; then
	echo "Bash no está instalado. Por favor, instala Bash antes de ejecutar este script."
	exit 1
fi

if [ -z "$BASH_VERSION" ]; then
	echo "Este script debe ejecutarse con bash."
	exit 1
fi

if [ "$(id -u)" = "0" ]; then
	echo "No puedes ejecutar este script como root."
	exit 1
fi

if [ "$(pwd)" != "$HOME/.dotfiles" ]; then
	echo "Este script debe ejecutarse desde el directorio \$HOME/.dotfiles."
	exit 1
fi

# Instalar AUR helper
aurinstall() {
	# Nos aseguramos que los paquetes necesarios están instalados
	doas pacman -S --noconfirm --needed base autoconf automake binutils bison fakeroot file git \
	findutils flex gawk gcc gettext grep gzip libtool m4 make patch pkgconf sed opendoas texinfo >/dev/null
	# Nos aseguramos que tenemos un directorio donde descargar nuestro código
	if [ ! -d "$HOME/.local/src" ]; then
		mkdir -p "$HOME/.local/src"
	fi
	# Descargamos yay
	git clone https://aur.archlinux.org/yay.git "$HOME/.local/src/yay" >/dev/null
	# Lo compilamos e instalamos
	sh -c "cd $HOME/.local/src/yay && makepkg -si"
}


# Instalar paquetes desde los repositorio normales
packageinstall() {
pacman -S --noconfirm --needed alsa-tools alsa-utils arandr asciidoctor atool baobab bat bc \
bleachbit cdrtools clamav cmake cronie-openrc cuetools cups-openrc czkawka-gui debugedit \
dialog downgrade drumgizmo dunst easytag expac eza feh ffmpegthumbnailer firejail font-manager \
galculator gamemode github-cli gnome-disk-utility go gparted grub gtk-layer-shell handbrake hplip \
htop inkscape inotify-tools intel-ucode j4-dmenu-desktop kodi krita lf lib32-gamemode lib32-gst-plugins-base \
lib32-mesa-demos lib32-mesa-vdpau lib32-nss lib32-ocl-icd lib32-openssl-1.1 lib32-sdl2_image lib32-sdl2_mixer \
lib32-sdl2_ttf lib32-sdl_image lib32-sdl_mixer lib32-sdl_ttf lib32-vkd3d lib32-vulkan-validation-layers lib32-xcb-util \
libcurl-compat libcurl-gnutls libdbusmenu-gtk2 libgcrypt15 libibus libidn11 libindicator-gtk2 libjpeg6-turbo libpng12 \
libreoffice-fresh librewolf-bin librtmp0 libtiff4 libudev0-shim libvirt-openrc libvpx1.3 libxdg-basedir linux-cachyos-bore-headers \
linux-headers lostfiles lsb-release lxappearance man-db mangohud mediainfo mesa-utils meson monero-gui mpv msr-tools \
mupdf-gl neovim net-tools network-manager-applet nitrogen nsxiv odt2txt openssh-openrc otf-font-awesome p2pool pamixer pandoc-bin \
papirus-icon-theme pavucontrol perl-image-exiftool picom playerctl polkit-gnome qbittorrent-qt5 qt5ct qt5-styleplugins \
redshift reflector ripgrep rustdesk shellcheck-bin stow sunshine sxiv syncthing syslog-ng-openrc telegram-desktop thunderbird \
tigervnc timeshift tlp-openrc tor-browser ttf-linux-libertine udiskie ueberzug ufw-openrc virt-manager vkd3d vlc vulkan-tools webcord \
winetricks xautolock xf86-video-amdgpu xorg-bdftopcf xorg-fonts-100dpi xorg-fonts-75dpi xorg-font-util xorg-iceauth xorg-server \
xorg-server-devel xorg-server-xnest xorg-server-xvfb xorg-sessreg xorg-xcursorgen xorg-xdpyinfo xorg-xev xorg-xinput \
xorg-xkill xorg-xrefresh yabridge yad yay zim
}
