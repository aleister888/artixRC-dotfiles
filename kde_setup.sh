#!/bin/bash

# Funciones para instalar paquetes
pacinstall() {
	doas pacman -Sy --noconfirm --needed "$@"
}
yayinstall() {
	yay -Sy --noconfirm --needed "$@"
}
whip_yes(){
	whiptail --title "$1" --yesno "$2" 10 60
}

# Instalamos whiptail y otros paquetes
sudo pacman -Sy --noconfirm --needed zsh dash stow libnewt

# Borramos el grupo base-devel
sudo pacman -R --noconfirm base-devel 2>/dev/null
# Instalamos los paquetes que nos interesan manualmente
base_devel_doas="autoconf automake bison debugedit fakeroot flex gc gcc groff guile libisl libmpc libtool m4 make patch pkgconf texinfo which opendoas firefox"
sudo pacman -Sy --noconfirm --needed $base_devel_doas


# Activamos doas y borramos sudo
echo "permit nopass keepenv setenv { XAUTHORITY LANG LC_ALL } :wheel" | \
sudo tee /etc/doas.conf
sudo pacman -R sudo
doas ln -s /usr/bin/doas /usr/bin/sudo
doas ln -s /usr/bin/nvim /usr/local/bin/vim


# Instalamos yay
tmp_dir="/tmp/yay_install_temp"
mkdir -p "$tmp_dir"
git clone https://aur.archlinux.org/yay.git "$tmp_dir"
sh -c "cd $tmp_dir && makepkg -si --noconfirm"


# Instalamos nuestros archivos de configuración
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
	"$HOME/.dotfiles/desktop-update.sh"
	echo 'ZDOTDIR=$HOME/.config/zsh' | doas tee /etc/zsh/zshenv
	doas chsh -s /bin/zsh "$USER" # Seleccionar zsh como nuestro shell
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

syncthing_setup(){
	case "$(readlink -f /sbin/init)" in
	*systemd*)
		pacinstall cronie
		doas systemctl enable crond
		;;
	*)
		pacinstall cronie cronie-openrc
		doas rc-update add cronie default
		;;
	esac
	echo "@reboot $(whoami) syncthing --no-browser --no-default-folder" | doas tee -a /etc/crontab
}


# Instalar Virt-Manager y configurar la virtualización
virt_install(){
	# Instalar paquetes para virtualización
	virtual_packages="looking-glass doas-sudo-shim-minimal virt-manager qemu-full edk2-ovmf dnsmasq"
	case "$(readlink -f /sbin/init)" in
	*systemd*)
		virtual_packages="$virtual_packages libvirt"
		;;
	*)
		virtual_packages="$virtual_packages libvirt-openrc"
		;;
	esac
	yay -S --noconfirm --needed $virtual_packages
	# Configurar QEMU para usar el usuario actual
	doas sed -i "s/^user = .*/user = \"$USER\"/" /etc/libvirt/qemu.conf
	doas sed -i "s/^group = .*/group = \"$USER\"/" /etc/libvirt/qemu.conf
	# Configurar libvirt
	doas sed -i "s/^unix_sock_group = .*/unix_sock_group = \"$USER\"/" /etc/libvirt/libvirtd.conf
	doas sed -i "s/^unix_sock_rw_perms = .*/unix_sock_rw_perms = \"0770\"/" /etc/libvirt/libvirtd.conf
	# Agregar el usuario al grupo libvirt
	doas usermod -aG libvirt "$USER"
	doas usermod -aG libvirt-qemu "$USER"
	# Activar sericios necesarios
	case "$(readlink -f /sbin/init)" in
	*systemd*)
		doas systemctl enable libvirtd
		doas systemctl enable virtlogd
		;;
	*)
		doas rc-update add libvirtd default
		doas rc-update add virtlogd default
		;;
	esac
	# Autoinciar red virtual
	doas virsh net-autostart default
}

# Instalar paquetes para hacer funcionar lf
lf_packages="lf bc imagemagick bat cdrtools ffmpegthumbnailer poppler ueberzug odt2txt gnupg mediainfo trash-cli fzf ripgrep sxiv man-db atool dragon-drop mpv atool eza jq rsync tar gzip unzip mpv transmission-qt"
yayinstall $lf_packages

# Instalar firefox y configurarlo
yayinstall firefox firefox-arkenfox-autoconfig
firefox_configure

# Instalar y configurar vim
yayinstall neovim nodejs
vim_configure

# Instalar otros paquetes
yayinstall pavucontrol github-cli dashbinsh simple-mtpfs pfetch-rs-bin thunderbird thunderbird-dark-reader keepassxc mate-calc gnu-free-fonts ttf-linux-libertine ttf-opensans

dotfiles_install

# Preparamos el uso de máquinas virtuales
whip_yes "Virtualización" "¿Planeas en usar maquinas virtuales?" && virt_install

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

syncthing_setup
