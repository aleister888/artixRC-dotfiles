#!/bin/bash
# shellcheck source=/dev/null

# Auto-instalador para Artix OpenRC
# (Script Iniciador del entorno de escritorio)
# por aleister888 <pacoe1000@gmail.com>
# Licencia: GNU GPLv3

source "$HOME/.dotfiles/.profile"

XDG_RUNTIME_DIR=/run/user/$(id -u)
export XDG_RUNTIME_DIR

# Mostramos el fondo de pantalla
nitrogen --restore

# Leemos nuestro perfil de zsh
. "$XDG_CONFIG_HOME/zsh/.zprofile"

# Cerrar instancias previas del script
INSTANCIAS="$(pgrep -c -x "$(basename "$0")")"
for _ in $(seq $((INSTANCIAS - 1))); do
	pkill -o "$(basename "$0")"
done

# Cerramos eww
pkill eww

#############
# Funciones #
#############

# Función para ajustar el tamaño del widget de eww en función de la resolución
# y abrirlo solo si hay un único monitor y ninguna ventana abierta
ewwspawn(){
	while true; do
	local monitors
	local resolution
	# Contamos el numero de monitores activos
	monitors=$(xrandr | awk '/ connected/ { print $1 }' | wc -l)
	# Definir el archivo al que apunta el enlace simbólico actual
	current_link=$(readlink -f "$XDG_CONFIG_HOME/eww/dashboard.scss")

	# Definir los archivos de los que se crearán los enlaces simbólicos
	file_1080="$HOME/.dotfiles/.config/eww/dashboard/dashboard1080p.scss"
	file_1440="$HOME/.dotfiles/.config/eww/dashboard/dashboard1440p.scss"
	file_2160="$HOME/.dotfiles/.config/eww/dashboard/dashboard2160p.scss"

	# Ejecutar xrandr y obtener la resolución vertical del monitor primario
	resolution=$(xrandr | grep -E ' connected (primary )?[0-9]+x[0-9]+' | awk -F '[x+]' '{print $2}')

	# Verificar y crear enlaces simbólicos según los rangos de resolución
	if [[ $resolution -le 1080 ]]; then
		[[ "$current_link" != "$file_1080" ]] && ln -sf "$file_1080" "$XDG_CONFIG_HOME/eww/dashboard.scss"
	elif [[ $resolution -le 1440 ]]; then
		[[ "$current_link" != "$file_1440" ]] && ln -sf "$file_1440" "$XDG_CONFIG_HOME/eww/dashboard.scss"
	else
		[[ "$current_link" != "$file_2160" ]] && ln -sf "$file_2160" "$XDG_CONFIG_HOME/eww/dashboard.scss"
	fi

	# Cerrar el widget si hay mas de un monitor en uso o alguna ventana activa
	if [ "$monitors" -gt 1 ] || xdotool getactivewindow >/dev/null; then
		pkill eww
	# Invocar nuestro widget si hay un solo monitor activo y eww no esta ya en ejecución
	elif [ "$monitors" -lt 2 ] && ! pgrep eww >/dev/null; then
		eww open dashboard &
	fi
	# Esperar antes de ejecutar el bucle otra vez
	sleep 0.2
	done
}

virtualmic(){
	# Contador para evitar bucles infinitos
	local counter=0
	# Salir si se encuentra el sink
	pactl list | grep '\(Name\|Monitor Source\): my-combined-sink' && exit

	# En caso contrario, intentar crear el sink cada 5 segundos durante un máximo de 5 intentos
	while [ $counter -lt 6 ]; do
		# Verificar si Wireplumber está en ejecución
		pgrep wireplumber && ~/.local/bin/pipewire-virtualmic &
		# Esperar 5 segundos antes del siguiente intento
		counter=$((counter + 1))
		sleep 5
	done
	exit
}

##########
# Script #
##########

# Dbus
if [ "$(pgrep -c dbus)" -lt 5 ]; then
	export "$(dbus-launch)" && dbus-update-activation-environment --all &
fi

# Desactivar el atenuado de la pantalla
xset -dpms && xset s off &

# Leer la configuración Xresources
[ -f "$XDG_CONFIG_HOME/Xresources" ] && xrdb -merge "$XDG_CONFIG_HOME/Xresources"

# Pipewire
pgrep pipewire || pipewire-start &

# Iniciar el compositor (Solo en hardware real. Desactivar para máquinas virtuales)
grep "Q35\|VMware" /sys/devices/virtual/dmi/id/product_name || \
pgrep picom || picom &

# Servicios del sistema
dbus-update-activation-environment --all
pgrep polkit-gnome	|| /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
pgrep gnome-keyring	|| gnome-keyring-daemon -r -d &
pgrep udiskie		|| udiskie -t -a & # Auto-montador de discos
pgrep dwmblocks		|| dwmblocks & # Barra de estado
pgrep nm-applet		|| nm-applet & # Applet de red

# Si se detecta una tarjeta bluetooth, iniciar blueman-applet
if lspci | grep -i bluetooth >/dev/null || lsusb | grep -i bluetooth >/dev/null; then
	pgrep blueman-applet || blueman-applet &
fi

# Corregir el nivel del micrófono en portátiles
if [ -e /sys/class/power_supply/BAT0 ]; then
	mic=$(pactl list short sources | \
	grep -E "alsa_input.pci-[0-9]*_[0-9]*_[0-9].\.[0-9].analog-stereo" | \
	awk '{print $1}')
	pactl set-source-volume "$mic" 25%
fi

# Servicio de notificaciones
pgrep dunst || dunst &

# Esperar a que se incie wireplumber para activar el micrófono virtual
# (Para compartir el audio de las aplicaciones através del micrófono)
virtualmic &
ewwspawn &

# Salvapantallas
xautolock -time 5 -locker screensaver &

while true; do
	resultado=0 # Reinicamos la variable antes de hacer las comprobaciones
	# Si alguna de estas aplicaciones esta activa, no mostrar el salvapantallas
	processes=("i3lock" "mpv" "vlc" "looking-glass" "display-lock")
	for process in "${processes[@]}"; do
		! pgrep "$process" > /dev/null
		resultado=$((resultado + $?))
	done
	# Si firefox esta reproduciendo contenido, no mostrar el salvapantallas
	[ "$(playerctl --player firefox status)" == "Playing" ] && \
	resultado=1
	# Reinciar el contador de xautolock en función de los resultados
	[ "$resultado" -ne 0 ] && xautolock -enable && pkill dvdbounce
	sleep 0.5 # Esperar 0.5s antes de hacer la siguiente comprobación
done &

# Servidor VNC Local (Solo para equipos que no lleven batería)
[ ! -e /sys/class/power_supply/BAT0 ] && sh -c 'pgrep x0vncserver || x0vncserver -localhost -SecurityTypes none' &

# Iniciar hydroxide si está instalado
# https://github.com/emersion/hydroxide?tab=readme-ov-file#usage
# IMAP: localhost, 1143, None, Normal password (Servidores Incoming & Outgoing)
[ -f /usr/bin/hydroxide ] && hydroxide imap &

############################
# Limpiar directorio $HOME #
############################

# Mover archivos según la especificación XDG

[ -d "$HOME/.pki" ] && {
	rsync -a --delete "$HOME/.pki/" "$XDG_DATA_HOME/pki/"
	rm -rf "$HOME/.pki"
}

[ -f "$HOME/.pulse-cookie" ] && {
	mkdir -p "$XDG_CONFIG_HOME/pulse"
	mv -f "$HOME/.pulse-cookie" "$XDG_CONFIG_HOME/pulse/cookie"
}

[ -f "$HOME/.gitconfig" ] && {
	mkdir -p "$XDG_CONFIG_HOME/git"
	mv -f "$HOME/.gitconfig" "$XDG_CONFIG_HOME/git/config"
}

[ -d "$HOME/.gnupg" ]	&& mv -f "$HOME/.gnupg" "$XDG_DATA_HOME/gnupg"
[ -d "$HOME/.java" ]	&& mv -f "$HOME/.java" "$XDG_CONFIG_HOME/java"
[ -d "$HOME/.cargo" ]	&& mv -f "$HOME/.cargo" "$XDG_DATA_HOME/cargo"
[ -d "$HOME/go" ]	&& mv -f "$HOME/go" "$XDG_DATA_HOME/go"

# Borrar archivos
rm -f "$HOME/.wget-hsts"
rm -rf "$XDG_DATA_HOME/desktop-directories" "$XDG_DATA_HOME/applications/wine"* "$XDG_CONFIG_HOME/menus"

# Borrar el lockfile de firefox
while true; do
	pgrep firefox && find "$HOME/.mozilla" -name "*.parentlock" -delete
	sleep 1
done &

# Arreglar bug con Thinkpad T14s (Gen 1)
if [ "$(< /sys/devices/virtual/dmi/id/board_name)" = "20UJS21R00" ]; then
	pactl set-sink-mute @DEFAULT_SINK@ toggle
	pactl set-sink-mute @DEFAULT_SINK@ toggle
fi
