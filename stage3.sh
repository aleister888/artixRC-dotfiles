#!/bin/bash

# Auto-instalador para Artix OpenRC (Parte 3)
# por aleister888 <pacoe1000@gmail.com>
# Licencia: GNU GPLv3

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

whip_menu(){
	local TITLE=$1
	local MENU=$2
	shift 2
	whiptail --title "$TITLE" --menu "$MENU" 15 60 5 $@ 3>&1 1>&2 2>&3
}

service_add(){
	doas rc-update add "$1" default
}

# Paquetes
packages="zsh dash dashbinsh dosfstools lostfiles simple-mtpfs pacman-contrib ntfs-3g network-manager-applet rsync mailcap gawk desktop-file-utils timeshift xdg-user-dirs nodejs i3lock-fancy-git i3lock-fancy-rapid-git perl-image-exiftool stow mesa lib32-mesa mesa-utils polkit-gnome gnome-keyring gnupg trash-cli java-environment-common jdk-openjdk dunst net-tools arandr xdg-desktop-portal-gtk j4-dmenu-desktop man-db jre17-openjdk jdk-openjdk realtime-privileges lib32-gnutls perl-file-mimeinfo"
# X11
packages+=" libx11 libxft libxinerama xorg-xkill xorg-twm xorg xorg-xinit xdotool xclip"
# Fuentes
packages+=" ttf-dejavu ttf-liberation ttf-linux-libertine ttf-opensans noto-fonts-emoji gnu-free-fonts"
# Archivos comprimidos
packages+=" atool tar unrar gzip unzip zip p7zip"
# Servicios
packages+=" syslog-ng syslog-ng-openrc xorg-xdm xdm-openrc irqbalance-openrc"
# Documentos
packages+=" poppler zathura zathura-pdf-poppler zathura-cb"
# Firefox y thunderbird
packages+=" arkenfox-user.js firefox thunderbird thunderbird-dark-reader ca-certificates ca-certificates-mozilla"
# Multimedia
packages+=" alsa-plugins alsa-tools alsa-utils alsa-utils python-pypresence mpv tauon-music-box mediainfo feh vlc pavucontrol gimp sxiv nsxiv"
# Herramientas de terminal
packages+=" eza jq pfetch-rs-bin htop shellcheck-bin fzf ripgrep bat cdrtools ffmpegthumbnailer odt2txt dragon-drop"
# Apariencia
packages+=" papirus-icon-theme qt5ct capitaine-cursors qt5-tools nitrogen picom gruvbox-dark-gtk lxappearance"
# Aplicaciones GUI
packages+=" keepassxc transmission-gtk handbrake mate-calc bleachbit baobab udiskie gcolor2 eww gnome-disk-utility"
# Misc
packages+=" syncthing wine-staging wine-mono wine-gecko winetricks fluidsynth extra/github-cli redshift tigervnc pamixer playerctl lf imagemagick ueberzug inkscape go yad downgrade pv grub-hook"

if lspci | grep -i bluetooth >/dev/null || lsusb | grep -i bluetooth >/dev/null; then
	packages+=" blueman"
fi

# Vamos a elegir primero que paquetes instalar y que acciones tomar, y luego instalar todo conjuntamente

driver_choose(){
	# Opciones posibles
	driver_options=("amd" "AMD" "nvidia" "NVIDIA" "intel" "Intel" "virtual" "VM" "optimus" "Portátil")
	# Elegimos nuestra tarjeta gráfica
	graphic_driver=$(whip_menu "Selecciona tu tarjeta gráfica" "Elige una opción:" \
	${driver_options[@]})
	case $graphic_driver in
	amd)
		packages+=" xf86-video-amdgpu libva-mesa-driver lib32-vulkan-radeon" ;;
	nvidia)
		packages+=" dkms nvidia-dkms nvidia-utils libva-vdpau-driver libva-mesa-driver nvidia-prime lib32-nvidia-utils nvidia-utils-openrc opencl-nvidia" ;;
	intel)
		packages+=" xf86-video-intel libva-intel-driver lib32-vulkan-intel" ;;
	virtual)
		packages+=" xf86-video-vmware xf86-input-vmmouse vulkan-virtio lib32-vulkan-virtio" ;;
	esac
}

# Elegimos que paquetes instalar
packages_show(){
	local scheme # Variable con la lista de paquetes a instalar
	scheme="Se instalarán:\n"
[ "$virt"      == "true" ] && scheme+="Virt-Manager\n"
[ "$music"     == "true" ] && scheme+="Easytag Picard Flacon Cuetools\n"
[ "$noprivacy" == "true" ] && scheme+="Telegram Discord\n"
[ "$daw"       == "true" ] && scheme+="Tuxguitar REAPER Metronome Audio-Plugins\n"
[ "$office"    == "true" ] && scheme+="Libreoffice\n"
[ "$latex"     == "true" ] && scheme+="TeX-live\n"
	whiptail --title "Confirmar paquetes" --yesno "$scheme" 15 60 
}

packages_choose(){
local packages_confirm="false"
local virt
local music
local noprivacy
local daw
local office
local latex

while [ "$packages_confirm" == "false" ]; do
	if whip_yes "Virtualización" "¿Planeas en usar maquinas virtuales?"; then
		virt="true"
	else
		virt="false"
	fi

	if whip_yes "Música" "¿Deseas instalar software para manejar tu colección de música?"; then
		music="true"
	else
		music="false"
	fi

	if whip_yes "Privacidad" "¿Deseas instalar aplicaciones que promueven plataformas propietarias (Discord y Telegram)?"; then
		noprivacy="true"
	else
		noprivacy="false"
	fi

	if whip_yes "DAW" "¿Deseas instalar un lector de partituras?"; then
		daw="true"
	else
		daw="false"
	fi

	if whip_yes "Oficina" "¿Deseas instalar software de ofimática?"; then
		office="true"
	else
		office="false"
	fi

	if whip_yes "laTeX" "¿Deseas instalar laTeX? (Esto llevará mucho tiempo)"; then
		latex="true"
	else
		latex="false"
	fi

	if packages_show; then
		packages_confirm=true
	else
		whip_msg "Cancelación" "Se te volverá a preguntar que software desea instalar"
	fi
done

[ "$virt"      == "true" ] && \
packages+=" looking-glass libvirt-openrc virt-manager qemu-full edk2-ovmf dnsmasq" && isvirt="true"
[ "$music"     == "true" ] && packages+=" easytag picard flacon cuetools"
[ "$noprivacy" == "true" ] && packages+=" discord forkgram-bin"
[ "$daw"       == "true" ] && \
packages+=" tuxguitar reaper yabridge yabridgectl gmetronome drumgizmo clap-plugins vst3-plugins surge-xt" && \
	mkdir -p "$HOME/Documents/Guitarra/Tabs" && \
	ln -s "$HOME/Documents/Guitarra/Tabs" "$HOME/Documents/Tabs"
	mkdir -p "$HOME/Documents/Guitarra/REAPER Media" && \
	ln -s "$HOME/Documents/Guitarra/REAPER Media" "$HOME/Documents/REAPER Media"
[ "$office"    == "true" ] && packages+=" libreoffice"
[ "$latex"     == "true" ] && packages+=" texlive-core texlive-bin $(pacman -Ssq texlive)"
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
	final_layout=$(whip_menu "Teclado" "Por favor, elige una distribución de teclado:" \
	${keyboard_array[@]})
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
	mkdir -p "$HOME/.config"
	XRES_FILE="$HOME/.config/Xresources"
	cp "$HOME/.dotfiles/assets/configs/Xresources" "$XRES_FILE"
	resolution=$(whip_menu "Resolución del Monitor" "Seleccione la resolución de su monitor:" \
	"720p" "720p" "1080p" "1080p" "1440p" "1440p" "4K" "4K")
	size=$(whip_menu "Tamaño del Monitor" "Seleccione el tamaño de su monitor (en pulgadas):" \
	"14" "14" "15.6" "15.6" "17" "17" "24" "24" "27" "27")
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
# https://github.com/LukeSmithxyz/voidrice
# Créditos para: Luke Smith <luke@lukesmith.xyz>
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
makeuserjs(){
	# Get the Arkenfox user.js and prepare it.
	arkenfox="$pdir/arkenfox.js"
	overrides="$pdir/user-overrides.js"
	userjs="$pdir/user.js"
	ln -fs "$HOME/.dotfiles/assets/configs/user-overrides.js" "$overrides"
	[ ! -f "$arkenfox" ] && curl -sL "https://raw.githubusercontent.com/arkenfox/user.js/master/user.js" > "$arkenfox"
	cat "$arkenfox" "$overrides" | tee "$userjs"
	doas chown "$USER" "$arkenfox" "$userjs"
	# Install the updating script.
	doas mkdir -p /usr/local/lib /etc/pacman.d/hooks
	doas install -m 755 "$HOME/.dotfiles/bin/arkenfox-auto-update" /usr/local/lib/arkenfox-auto-update
	# Trigger the update when needed via a pacman hook.
	echo "[Trigger]
Operation = Upgrade
Type = Package
Target = firefox
Target = librewolf
Target = librewolf-bin
[Action]
Description=Update Arkenfox user.js
When=PostTransaction
Depends=arkenfox-user.js
Exec=/usr/local/lib/arkenfox-auto-update" | doas tee /etc/pacman.d/hooks/arkenfox.hook
}
firefox_configure(){
	browserdir="/home/$USER/.mozilla/firefox"
	profilesini="$browserdir/profiles.ini"
	firefox --headless >/dev/null 2>&1 &
	sleep 1
	profile="$(grep "Default=.." "$profilesini" | sed 's/Default=//')"
	pdir="$browserdir/$profile"
	[ -d "$pdir" ] && makeuserjs
	[ -d "$pdir" ] && installffaddons
	killall firefox
}

# Configurar neovim e instalar los plugins
vim_configure(){
	# Descargar diccionarios
	mkdir -p "$HOME/.local/share/nvim/site/spell/"
	wget "https://ftp.nluug.nl/pub/vim/runtime/spell/es.utf-8.spl" -q -O "$HOME/.local/share/nvim/site/spell/es.utf-8.spl"
	wget "https://ftp.nluug.nl/pub/vim/runtime/spell/es.utf-8.sug" -q -O "$HOME/.local/share/nvim/site/spell/es.utf-8.sug"
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
	if [ "$resolution" == "720p" ] || [ "$resolution" == "1080p" ]; then
		doas make 1080 install --directory "$HOME/.dotfiles/dwm" >/dev/null
		doas make 1080 install --directory "$HOME/.dotfiles/dmenu" >/dev/null
		doas make 1080 install --directory "$HOME/.dotfiles/st" >/dev/null
	else
		doas make 2160 install --directory "$HOME/.dotfiles/dwm" >/dev/null
		doas make 2160 install --directory "$HOME/.dotfiles/dmenu" >/dev/null
		doas make 2160 install --directory "$HOME/.dotfiles/st" >/dev/null
	fi
	doas make install --directory "$HOME/.dotfiles/dwmblocks" >/dev/null
	doas make install --directory "$HOME/.dotfiles/xmenu" >/dev/null
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
	cp "$HOME/.dotfiles/assets/configs/settings.ini" "$HOME/.dotfiles/.config/gtk-4.0/settings.ini"
	# Aplicar configuraciones utilizando stow
	sh -c "cd $HOME/.dotfiles && stow --target=${HOME}/.config/ .config/" >/dev/null
	# Definimos nuestros directorios marca-páginas
echo "file:///home/$USER
file:///home/$USER/Downloads
file:///home/$USER/Documents
file:///home/$USER/Pictures
file:///home/$USER/Videos
file:///home/$USER/Music" > "$HOME/.config/gtk-3.0/bookmarks"

	local THEME_DIR="/usr/share/themes"
	# Clona el tema de gtk4
	git clone https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme.git /tmp/Gruvbox_Theme >/dev/null
	# Copia el tema deseado a la carpeta de temas
	doas cp -r /tmp/Gruvbox_Theme/themes/Gruvbox-Dark-B $THEME_DIR/Gruvbox-Dark-B

	# Tema GTK para el usuario root (Para aplicaciones como Bleachbit)
	doas cp "$HOME/.dotfiles/assets/configs/.gtkrc-2.0" /root/.gtkrc-2.0
	doas mkdir -p /root/.config
	doas cp -r $HOME/.dotfiles/.config/gtk-3.0 /root/.config/gtk-3.0/
	doas cp -r $HOME/.dotfiles/.config/gtk-4.0 /root/.config/gtk-4.0/
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
cp "$HOME/.dotfiles/assets/configs/index.theme" "$HOME/.local/share/icons/default/index.theme"
}

# Configurar keepassxc para que siga el tema de QT
keepass_configure(){
	[ ! -d $HOME/.config/keepassxc ] && mkdir -p $HOME/.config/keepassxc
	cp "$HOME/.dotfiles/assets/configs/keepassxc.ini" "$HOME/.config/keepassxc/keepassxc.ini"
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

# Configurar el audio de baja latencia
audio_setup(){
	doas usermod -aG realtime,audio,video $USER
	cat /etc/security/limits.conf | grep audio || \
	echo "@audio - rtprio 95
	@audio - memlock unlimited
	$USER hard nofile 524288" | \
	doas tee -a /etc/security/limits.conf
}

# Si se eligió instalar virt-manager, configurarlo adecuadamente
virt_conf(){
	# Configurar QEMU para usar el usuario actual
	doas sed -i "s/^#user = .*/user = \"$USER\"/" /etc/libvirt/qemu.conf
	doas sed -i "s/^#group = .*/group = \"$USER\"/" /etc/libvirt/qemu.conf
	# Configurar libvirt
	doas sed -i "s/^#unix_sock_group = .*/unix_sock_group = \"$USER\"/" /etc/libvirt/libvirtd.conf
	doas sed -i "s/^#unix_sock_rw_perms = .*/unix_sock_rw_perms = \"0770\"/" /etc/libvirt/libvirtd.conf
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

# Elegimos que paquetes instalar
packages_choose

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

# Antes de instalar los paquetes, configurar makepkg para
# usar todos los núcleos durante la compliación
# Créditos para: <luke@lukesmith.xyz>
doas sed -i "s/-j2/-j$(nproc)/;/^#MAKEFLAGS/s/^#//" /etc/makepkg.conf

# Instalamos todos los paquetes a la vez
yayinstall $packages

# Descargar e instalar nuestras fuentes
fontdownload

doas archlinux-java set java-17-openjdk

# Configurar firefox para proteger la privacidad
firefox_configure
# Configurar Transmission
"$HOME/.dotfiles/bin/transmission-config"
# Configurar neovim e instalar los plugins
vim_configure

# Instalar los archivos de configuración locales y en github
mkdir -p "$HOME/.config"
dotfiles_install

# Configuramos Tauon Music Box (Nuestro reproductor de música)
"$HOME/.dotfiles/bin/tauon-config"
# Instalamos dwm y otras utilidades
suckless_install
# Creamos nuestro xinitrc
doas cp "$HOME/.dotfiles/assets/configs/xinitrc" /etc/X11/xinit/xinitrc
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
echo "@reboot $USER syncthing --no-browser --no-default-folder" | doas tee -a /etc/crontab
# Configurar el audio de baja latencia
audio_setup

# Si estamos usando una máquina virtual,
# configuramos X11 para usar 1080p como resolución

[ "$graphic_driver" == "virtual" ] && \
doas cp "$HOME/.dotfiles/assets/configs/xorg.conf" /etc/X11/xorg.conf

# Crear directorios
for dir in Documents Downloads Music Pictures Public Videos; do mkdir -p "$HOME/$dir"; done

rm $HOME/.bash* 2>/dev/null
rm $HOME/.wget-hsts 2>/dev/null

# Permitir a Steam controlar mandos de PlayStation 4
doas cp $HOME/.dotfiles/assets/configs/99-steam-controller-perms.rules /usr/lib/udev/rules.d/

# Descargar wordlist
"$HOME/.dotfiles/bin/wordlist"

# Activar servicios
service_add irqbalance
service_add syslog-ng
service_add elogind
service_add xdm

doas rfkill unblock wifi
if lspci | grep -i bluetooth >/dev/null || lsusb | grep -i bluetooth >/dev/null; then
	doas rfkill unblock bluetooth
fi

# Configurar xdm
doas cp "$HOME/.dotfiles/assets/xdm/Xresources" /etc/X11/xdm/Xresources
doas cp "$HOME/.dotfiles/assets/xdm/Xsetup_0"   /etc/X11/xdm/Xsetup_0

# Permitir al usuario escanear redes Wi-Fi y cambiar ajustes de red
doas usermod -aG network $USER
[ -e /sys/class/power_supply/BAT0 ] && \
doas cp "$HOME/.dotfiles/assets/configs/50-org.freedesktop.NetworkManager.rules" "/etc/polkit-1/rules.d/50-org.freedesktop.NetworkManager.rules"

# Suspender de forma automatica cuando la bateria cae por debajo del 5%
[ -e /sys/class/power_supply/BAT0 ] && \
doas cp "$HOME/.dotfiles/assets/configs/99-lowbat.rules" "/etc/udev/rules.d/99-lowbat.rules"

# /etc/polkit-1/rules.d/99-artix.rules
doas usermod -aG storage,input,users $USER

# Permitir hacer click tocando el trackpad
# Créditos para: <luke@lukesmith.xyz>
[ -e /sys/class/power_supply/BAT0 ] && \
doas cp "$HOME/.dotfiles/assets/configs/40-libinput.conf" "/etc/X11/xorg.conf.d/40-libinput.conf"

# Crear directorio para montar dispositivos android
doas mkdir /mnt/ANDROID
doas chown $USER /mnt/ANDROID

# Si se eligió instalar virt-manager configurarlo adecuadamente
[ "$isvirt" == "true" ] && virt_conf

doas install -m 755 "$HOME/.dotfiles/assets/configs/nm-restart" /lib/elogind/system-sleep/nm-restart
