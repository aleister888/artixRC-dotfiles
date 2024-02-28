#!/usr/bin/bash

PKG_FILE="/tmp/update"

if [ "$1" = "revert" ]; then
	REPO=world
else
	REPO=cachyos-extra-v3
fi

echo "Limpiando cache de pacman..."
doas pacman -Scc --noconfirm >/dev/null 2>&1 && echo "Hecho!"

echo "Actualizando paquetes..."
yay -Syyu --needed --norebuild && echo "Hecho!"

echo "Buscando paquetes optimizados para x86_68-v3..."
# Haz una lista con todos los posibles paquetes a instalar
paclist cachyos-extra-v3 | awk '{print $1}' | sed "s|^|$REPO/|" > $PKG_FILE

# Borra los paquetes que dependen de systemd o son paquetes del sistema
cat $PKG_FILE | grep -v $( pacman -Qi | grep -B 8 -i 'depend' | grep -B 8 'systemd\|dbus\|device-mapper\|p11-kit\|pcsclite\|polkit\|procps-ng\|util-linux\|libp11-kit\|mkinitcpio\|openrc\|xdg\|electron' | grep -i 'nombre\|name' | grep -o 'Nombre[[:space:]]*:[[:space:]]*[^ ]*' | awk -F ": " '{print $2}' | sed ':a;N;$!ba;s/\n/\\|/g') > $PKG_FILE

# Borra paquetes que también esten en el repositorio "system" de Artix
cat $PKG_FILE | grep -v $(paclist system | awk '{print $1}' | sed ':a;N;$!ba;s/\n/\\|/g'
) > $PKG_FILE

# Excluye paquetes servicios
# 	Buscando los servicios en rc-status
cat $PKG_FILE | grep -v $(rc-status | grep -v level | awk '{print $1}' | sed ':a;N;$!ba;s/\n/\\|/g') > $PKG_FILE
#	Excluyendo paquetes que tengan una versión que acabe en -openrc
cat $PKG_FILE | grep -v $(pacman -Qqe | grep openrc | sed 's/-openrc//' | sed ':a;N;$!ba;s/\n/\\|/g') > $PKG_FILE

# Finalmente filtra solo paquetes que se hayan instalado manualmente
cat $PKG_FILE | grep $(pacman -Qqent | sed ':a;N;$!ba;s/\n/\\|/g') > $PKG_FILE

# Add packages

# Lista de paquetes
packages=(
	"thunderbird"
	"keepassxc"
	"mpv"
	"handbrake"
	"picard"
	"firejail"
	"gimp"
	"krita"
	"libreoffice-fresh"
	"monero"
	"monero-gui"
	"gnome-disk-utility"
)

# Agrega cada paquete al archivo $PKG_FILE
for package in "${packages[@]}"; do
    echo "$REPO/$package" >> $PKG_FILE
done

# Haz lo mismo para paquetes en el repositorio extra-v3

packages=(
	"zathura"
	"zathura-cb"
	"zathura-pdf-poppler"
)

for package in "${packages[@]}"; do
    echo "extra-x86-64-v3/$package" >> $PKG_FILE
done

# Excluir paquetes
grep -v "timeshift\|github-cli\|telegram\|ffmpeg" "$PKG_FILE" > "$PKG_FILE.tmp" && mv "$PKG_FILE.tmp" "$PKG_FILE"

# Borrar lineas repetidas
sort $PKG_FILE | uniq > "$PKG_FILE.tmp" && mv "$PKG_FILE.tmp" $PKG_FILE

echo "Hecho!"

# Ahora instalar los paquetes en $PKG_FILE
echo "Instalando paquetes"
yay -S $(cat $PKG_FILE) --cachedir /opt/yay-cache --norebuild --needed && \
echo "Hecho!"

# Instalar QEMU con optimizaciones para v3
echo "Actualizando QEMU"
yay -S $(yay -Q | grep qemu | awk '{print $1}' | sed "s/^/extra-x86-64-v3\//g") --needed --noconfirm >/dev/null
echo "Hecho!"

doas /usr/bin/grub-mkconfig -o /boot/grub/grub.cfg
