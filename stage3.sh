#!/bin/bash

doas pacman -Syu --noconfirm

# Instalar drivers de video

# Diferentes opciones a elegir
driver_options=("amd" "AMD" "nvidia" "NVIDIA" "intel" "Intel" "virtual" "Máquina Virtual" "optimus" "Portátil con NVIDIA Optimus")

graphic_driver=$(whiptail --title "Selecciona tu tarjeta gráfica" --menu "Elige una opción:" 15 60 5 \
"${driver_options[@]}" 3>&1 1>&2 2>&3)

bumblebee_install(){
	doas pacman -S --noconfirm nvidia nvidia-utils bumblebee bumblebee-openrc
	doas gpasswd -a $USER bumblebee
	doas rc-update add bumblebeed default
}

case $graphic_driver in
	amd)
		doas pacman -S --noconfirm xf86-video-amdgpu ;;
	nvidia)
		doas pacman -S --noconfirm nvidia nvidia-utils ;;
	intel)
		doas pacman -S --noconfirm xf86-video-intel ;;
	virtual)
		echo "Estás utilizando una máquina virtual, no se requieren controladores adicionales." ;;
	optimus)
		bumblebee_install ;;
esac && \
whiptail --title "Drivers" --msgbox "Los drivers de video se instalaron correctamente"

# Instalar los paquetes básicos para gráficos acelerados
sudo pacman -S mesa mesa-libgl xorg xorg-xinit xorg-server xorg-server-utils

# Instalar escritorio

# Diferentes escritorios a elegir
desktops=(gnome "GNOME" kde "KDE Plasma" xfce "Xfce" dotfiles "Dotfiles")

# Mostrar el menú de selección con whiptail
desktop_choice=$(whiptail --title "Selecciona tu entorno de escritorio" --menu "Elige una opción:" 15 60 4 \
"${desktops[@]}" 3>&1 1>&2 2>&3)

gnome_install(){
doas pacman -S --noconfirm xorg gnome gnome-extra gdm gdm-openrc && \
rc-update add gdm default && \
whiptail --title "GNOME" --msgbox "Gnome se instaló correctamente"
}

kde_install(){
doas pacman -S --noconfirm xorg sddm plasma kde-applications sddm-openrc && \
rc-update add sddm default && \
whiptail --title "KDE" --msgbox "Kde Plasma se instaló correctamente"
}

xfce_install(){
doas pacman -S --noconfirm xfce4 xfce4-goodies lightdm lightdm-gtk-greeter lightdm-openrc && \
rc-update add lightdm
doas sed -i 's/^#greeter-session=.*/greeter-session=lightdm-gtk-greeter/' /etc/lightdm/lightdm.conf
whiptail --title "XFCE" --msgbox "Xfce se instaló correctamente"
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

echo $choice
