#!/bin/bash

############
## SCRIPT ##
############

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
whip_yes "DAW" "¿Deseas instalar herramientas de producción musical?" && \
yayinstall $daw_packages && \
mkdir -p $HOME/Documents/Guitarra/Tabs && \
ln -s $HOME/Documents/Guitarra/Tabs $HOME/Documents/Tabs
mkdir -p $HOME/Documents/Guitarra/REAPER\ Media && \
ln -s $HOME/Documents/Guitarra/REAPER\ Media $HOME/Documents/REAPER\ Media

# Instalar software de ofimática
office_packages="zim libreoffice"
whip_yes "Oficina" "¿Deseas instalar software de ofimática?" && pacinstall $office_packages

# Instalar rustdesk
whip_yes "Rustdesk" "¿Deseas instalar rustdesk?" && yayinstall rustdesk-bin

whip_yes "laTeX" "¿Deseas instalar laTeX?" && pacinstall texlive-core texlive-bin $(pacman -Ssq texlive)


# Activar servicios
service_add irqbalance
service_add syslog-ng

# Linkear scripts a /usr/local/bin
doas chsh -s /bin/zsh "$USER" # Seleccionar zsh como nuestro shell

# Instalar java
pacinstall jre17-openjdk jre17-openjdk-headless jdk-openjdk
doas archlinux-java set java-17-openjdk

# Instalar y activar xdm
pacinstall xorg-xdm xdm-openrc
service_add xdm

# Crear directorios
mkdir -p $HOME/Documents
mkdir -p $HOME/Downloads
mkdir -p $HOME/Music
mkdir -p $HOME/Pictures
mkdir -p $HOME/Public
mkdir -p $HOME/Videos

rm $HOME/.bash* 2>/dev/null
rm $HOME/.wget-hsts 2>/dev/null

# Permitir a Steam controlar mandos de PlayStation 4
doas cp $HOME/.dotfiles/assets/99-steam-controller-perms.rules /usr/lib/udev/rules.d/

# Borrar paquetes no necesarios
yay -Rcns $(yay -Qdtq) --noconfirm
