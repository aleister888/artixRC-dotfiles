#!/bin/bash

# Auto-instalador para Artix OpenRC
# (Script Iniciador del entorno de escritorio)
# por aleister888 <pacoe1000@gmail.com>
# Licencia: GNU GPLv3

nitrogen --restore

. "$XDG_CONFIG_HOME/zsh/.zprofile"

# Cerrar instancias previas del script
INSTANCIAS="$(pgrep -c -x "$(basename "$0")")"
for i in $(seq $(($INSTANCIAS - 1))); do
	pkill -o "$(basename "$0")"
done

pkill eww

# Función para ajustar el tamaño del widget de eww y abrirlo
# si solo hay un monitor y ninguna ventana abierta
ewwspawn(){
	while true; do
	# Contamos el numero de monitores activos
	local monitors=$(xrandr --listmonitors | grep -c " .:")
	# Definir el archivo al que apunta el enlace simbólico actual
	current_link=$(readlink -f "$HOME/.config/eww/dashboard.scss")

	# Definir los archivos de los que se crearán los enlaces simbólicos
	file_1080="$HOME/.dotfiles/.config/eww/dashboard/dashboard1080p.scss"
	file_1440="$HOME/.dotfiles/.config/eww/dashboard/dashboard1440p.scss"
	file_2160="$HOME/.dotfiles/.config/eww/dashboard/dashboard2160p.scss"

	# Ejecutar xrandr y obtener la resolución vertical del monitor primario
	resolution=$(xrandr | grep -E ' connected (primary )?[0-9]+x[0-9]+' | awk -F '[x+]' '{print $2}')

	# Verificar y crear enlaces simbólicos según los rangos de resolución
	if [[ $resolution -le 1080 ]]; then
		if [[ "$current_link" != "$file_1080" ]]; then
			ln -sf "$file_1080" "$HOME/.config/eww/dashboard.scss"
		fi
	elif [[ $resolution -le 1440 ]]; then
		if [[ "$current_link" != "$file_1440" ]]; then
			ln -sf "$file_1440" "$HOME/.config/eww/dashboard.scss"
		fi
	else
		if [[ "$current_link" != "$file_2160" ]]; then
			ln -sf "$file_2160" "$HOME/.config/eww/dashboard.scss"
		fi
	fi

	# Cerrar el widget si hay mas de un monitor en uso
	if [ "$monitors" -gt 1 ] || [ "$(xdotool getactivewindow)" ]; then
		pkill eww
	# Invocar nuestro widget solo si hay un monitor, niguna ventana activa
	# y eww no esta ya en ejecución
	elif [ "$monitors" -lt 2 ] && ! pgrep eww >/dev/null; then
		# Ajustar widget en función de la resolución
		eww open dashboard &
	fi
	# Esperar antes de ejecutar el bucle otra vez
	sleep 0.05;
	done

	exit 0
}

virtualmic(){
	# Contador para evitar bucles infinitos
	counter=0
	# Realizar la comprobación una vez y salir si se encuentra el sink
	if pactl list | grep '\(Name\|Monitor Source\): my-combined-sink'; then
		exit
	else
		# En caso contrario, intentar crear el sink cada 5 segundos durante un máximo de 12 intentos
		while [ $counter -lt 6 ]; do
			# Verificar si Wireplumber está en ejecución
			if pgrep wireplumber; then
				~/.local/bin/pipewire-virtualmic &
			fi
			# Incrementar el contador
			counter=$((counter + 1))
			# Esperar 5 segundos antes del siguiente intento
			sleep 5
		done
	fi
	exit 0
}

picomstart(){
	PICOMOPTS="-c -f --vsync --config=$HOME/.config/picom/picom.conf --corner-radius"
	if [[ "$current_link" == "$file_1080" ]]; then
		picom $PICOMOPTS 12
	elif [[ "$current_link" == "$file_1440" ]]; then
		picom $PICOMOPTS 18
	else
		picom $PICOMOPTS 24
	fi
}

# Dbus
if [ "$(pgrep -c dbus)" -lt 5 ]; then
	export "$(dbus-launch)" && dbus-update-activation-environment --all &
fi
# Desactivar el atenuado de la pantalla
xset -dpms && xset s off &

# Leer la configuración Xresources
[ -f "$XDG_CONFIG_HOME"/Xresources ] && xrdb -merge "$XDG_CONFIG_HOME/Xresources"

# Pipewire
pgrep pipewire || pipewire-start &

# Iniciar el compositor (Solo en hardware real. Desactivar para máquinas virtuales)
cat /sys/devices/virtual/dmi/id/product_name | grep "Q35\|VMware" || \
pgrep picom || picomstart &

# Servicios del sistema
dbus-update-activation-environment --all
pgrep polkit-gnome	|| /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
pgrep gnome-keyring	|| gnome-keyring-daemon -r -d &
# Auto-montador de discos
pgrep udiskie		|| udiskie -t -a &
# Barra de estado
pgrep dwmblocks		|| dwmblocks &
# Applet de red
pgrep nm-applet		|| nm-applet &

# Si se detecta una tarjeta bluetooth se inicia blueman-applet
if lspci | grep -i bluetooth >/dev/null || lsusb | grep -i bluetooth >/dev/null; then
	pgrep blueman-applet || blueman-applet &
fi

# Corregir el nivel del micrófono en portátiles
if [ -e /sys/class/power_supply/BAT0 ]; then
	mic=$(pactl list short sources | \
	grep -E "alsa_input.pci-[0-9]*_[0-9]*_[0-9].\.[0-9].analog-stereo" | \
	awk '{print $1}')
	pactl set-source-volume $mic 25%
fi

# Servicio de notificaciones
pgrep dunst || dunst &

# Esperar a que se incie wireplumber para activar el micrófono virtual
# (Para compartir el audio de las aplicaciones através del micrófono)
virtualmic &
ewwspawn &

# Servidor VNC Local (Excluir portátiles)
[ ! -e /sys/class/power_supply/BAT0 ] && sh -c 'pgrep x0vncserver || x0vncserver -localhost -SecurityTypes none' &

# Iniciar redshift
pgrep redshift || redshift -l "$(curl -s "https://location.services.mozilla.com/v1/geolocate?key=geoclue" | jq -r '"\(.location.lat):\(.location.lng)"')" -m vidmode

############################
# Limpiar directorio $HOME #
############################

[ -d "$HOME/.pki" ]		&& mv -f "$HOME/.pki" "$HOME/.local/share/pki"
[ -d "$HOME/.gnupg" ]		&& mv -f "$HOME/.gnupg" "$HOME/.local/share/gnupg"
[ -d "$HOME/.java" ]		&& mv -f "$HOME/.java" "$HOME/.config/java"
[ -d "$HOME/.cargo" ]		&& mv -f "$HOME/.cargo" "$HOME/.local/share/cargo"

[ -f "$HOME/.wget-hsts" ] && rm "$HOME/.wget-hsts"

if [ -f "$HOME/.gitconfig" ]; then
	mkdir -p "$HOME/.config/git"
	mv -f "$HOME/.gitconfig" "$HOME/.config/git/config"
fi
