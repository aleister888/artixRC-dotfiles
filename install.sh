#!/bin/sh

export repoDir="/tmp/artix-installer"

# Configuramos el servidor de claves y actualizamos las claves
grep ubuntu /etc/pacman.d/gnupg/gpg.conf || \
	echo 'keyserver hkp://keyserver.ubuntu.com' |\
	tee -a /etc/pacman.d/gnupg/gpg.conf >/dev/null

pacman -Sc --noconfirm
pacman-key --populate && pacman-key --refresh-keys

# Instalamos:
# - whiptail: para la interfaz TUI
# - parted: para formatear nuestros discos
# - xkeyboard-config: para elegir el layout de teclado
# - bc: para calcular el DPI de la pantalla
# - git: para clonar el repositorio
pacman -Sy --noconfirm --needed parted libnewt xkeyboard-config bc git

# Clonamos el repositorio e iniciamos el instalador
git clone --branch noinput https://github.com/aleister888/artix-installer.git \
	$repoDir

cd $repoDir/installer; ./stage1.sh
