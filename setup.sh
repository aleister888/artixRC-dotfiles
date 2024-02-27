#!/bin/sh

# Nos aseguramos que los paquetes necesarios están instalados
doas pacman -S --noconfirm --needed base autoconf automake binutils bison fakeroot file git \
findutils flex gawk gcc gettext grep gzip libtool m4 make patch pkgconf sed opendoas texinfo >/dev/null

ln -s /usr/bin/doas /usr/bin/sudo

echo "# Wheel users
permit persist keepenv setenv { XAUTHORITY LANG LC_ALL } :wheel

permit nopass :wheel as root cmd pacman
permit nopass :wheel as root cmd cat
permit nopass :wheel as root cmd /usr/bin/grub-mkconfig" > /etc/doas.conf
