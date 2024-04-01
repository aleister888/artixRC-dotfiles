#!/bin/bash

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
			# Verificar si WirePlumber está en ejecución
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

# Dbus
if [ "$(pgrep -c dbus)" -lt 5 ]; then
	export "$(dbus-launch)" && dbus-update-activation-environment --all &
fi
# Disable screen diming
xset -dpms && xset s off &

# Read Xresources
[ -f "$XDG_CONFIG_HOME"/Xresources ] && xrdb -merge "$XDG_CONFIG_HOME/Xresources"

# Pipewire
pgrep pipewire || pipewire-start &

# Wallpaper
dbus-update-activation-environment --all
pgrep polkit-gnome	|| /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
pgrep gnome-keyring	|| gnome-keyring-daemon -r -d &
pgrep udiskie		|| udiskie -t -a &
pgrep picom		|| picom &
pgrep dwmblocks		|| dwmblocks &
if [ ! -e /sys/class/power_supply/BAT0 ]; then
pgrep x0vncserver	|| x0vncserver -localhost -SecurityTypes none &
fi
pgrep dunst		|| dunst &
pgrep nm-applet		|| nm-applet &
# Si se detecta una tarjeta bluetooth se inicia blueman-applet
if lspci | grep -i bluetooth >/dev/null || lsusb | grep -i bluetooth >/dev/null; then
	pgrep blueman-applet || blueman-applet &
fi

# Correct microphone level in ASUS laptops
host=$(cat /sys/devices/virtual/dmi/id/product_name)
if echo $host | grep "ASUS TUF Dash F15"; then
	mic=$(pactl list short sources | grep -E "alsa_input.pci-[0-9]*_[0-9]*_[0-9].\.[0-9].analog-stereo" | awk '{print $1}')
	pactl set-source-volume $mic 20%
fi

# Wait for wireplumber to start to add virtual mic (For sharing apps audio).
virtualmic &
ewwspawn &

# Iniciar redshift
pgrep redshift || redshift -l "$(curl -s "https://location.services.mozilla.com/v1/geolocate?key=geoclue" | jq -r '"\(.location.lat):\(.location.lng)"')" -m vidmode
