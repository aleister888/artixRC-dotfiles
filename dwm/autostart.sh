#!/usr/bin/zsh

# Cerrar instancias previas del script
INSTANCIAS="$(pgrep -c -x "$(basename "$0")")"
for i in $(seq $(($INSTANCIAS - 1))); do
	pkill -o "$(basename "$0")"
done

pkill eww

ewwspawn() {
	while true; do
		if xdotool getactivewindow; then
			pkill eww
		else
			pgrep eww || eww open dashboard &
		fi
		sleep 0.025;
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

webpage() {
	# Bucle para monitorear y reiniciar http-server si es necesario
	pgrep http-server || while true; do
		# Verificar si http-server no está en ejecución y reiniciarlo
		pgrep http-server || npx http-server ~/.local/share/startpage/ 8080 &

		# Esperar 30 segundos antes de verificar de nuevo
		sleep 5
	done
	exit 0
}

# Dbus
if [ "$(pgrep -a dbus | wc -l)" -lt 4 ]; then
	export "$(dbus-launch)" && dbus-update-activation-environment --all &
fi
# Get location for redshift
pgrep redshift || export LOCATION="$(curl -s "https://location.services.mozilla.com/v1/geolocate?key=geoclue" | jq -r '"\(.location.lat):\(.location.lng)"' &)"

# Disable screen diming
xset -dpms && xset s off &

# Read Xresources
if [ -f "$XDG_CONFIG_HOME"/Xresources ]; then
	xrdb -merge "$XDG_CONFIG_HOME"/Xresources
fi

# Pipewire
pgrep pipewire || pipewire-start &

# Wallpaper
nitrogen --restore
dbus-update-activation-environment --all
pgrep polkit-gnome	|| /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
pgrep gnome-keyring	|| gnome-keyring-daemon -r -d &
pgrep udiskie		|| udiskie -t -a &
pgrep redshift		|| redshift -l "$LOCATION" -t 5000:4000 &
pgrep syncthing		|| syncthing &
pgrep picom		|| picom &
pgrep dwmblocks		|| dwmblocks &
pgrep x0vncserver	|| x0vncserver -localhost -SecurityTypes none &
pgrep http-server	|| npx http-server ~/.local/share/startpage/ 8080 &
pgrep dunst		|| dunst &
pgrep xautolock		|| xautolock -time 5 -locker dvdbounce &
pgrep pomodorino	|| pomodorino &

#pgrep -a java | grep komga || komga --server.port=8443 --komga.config-dir=".local/share/komga" &
#pgrep sunshine || sunshine &

# Wait for wireplumber to start to add virtual mic (For sharing apps audio).
virtualmic &
webpage &
ewwspawn &

if [ ! -e /tmp/location ]; then
	echo "$LOCATION" > /tmp/location
fi
