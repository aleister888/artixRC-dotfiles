#!/bin/bash

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
	file_2160="$HOME/.dotfiles/.config/eww/dashboard/dashboard2160p.scss"

	# Ejecutar xrandr y obtener la resolución vertical del monitor primario
	resolution=$(xrandr | grep -E ' connected (primary )?[0-9]+x[0-9]+' | awk -F '[x+]' '{print $2}')

	# Verificar y crear enlaces simbólicos según los rangos de resolución
	if [[ $resolution -ge 2160 ]]; then
		[[ "$current_link" != "$file_2160" ]] && ln -sf "$file_2160" "$XDG_CONFIG_HOME/eww/dashboard.scss"
	else
		[[ "$current_link" != "$file_1080" ]] && ln -sf "$file_1080" "$XDG_CONFIG_HOME/eww/dashboard.scss"
	fi

	# Cerrar el widget si hay mas de un monitor en uso o alguna ventana activa
	if [ "$monitors" -gt 1 ] || xdotool getactivewindow &>/dev/null || pgrep i3lock &>/dev/null; then
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

	# Si alguno de estos procesos esta activo, no mostrar el salvapantallas
	processes=("i3lock" "display-lock")
	for process in "${processes[@]}"; do
		! pgrep "$process" > /dev/null
		resultado=$((resultado + $?))
	done

	activewindow="$(xdotool getwindowclassname "$(xdotool getactivewindow)")"

	# Si alguna de estas aplicaciones esta enfocada y reproduciendo vídeo/audio, no mostrar el salvapantallas
	players=("vlc" "firefox" "mpv")
	for player in "${players[@]}"; do
		[ "$(playerctl --player "$player" status)" == "Playing" ] && \
		[ "$activewindow" = "$player" ] && \
		resultado=1
	done

	# Si alguna de estas aplicaciones esta enfocada, no mostrar el salvapantallas
	apps="looking-glass\|TuxGuitar"
		echo "$activewindow" | grep "$apps" && \
	resultado=1

	# Reinciar xautolock en función de los resultados
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

# Hacer que npm user la especificación de directorios XDG
npm_xdg(){
	local configdir
	configdir="$(dirname "$NPM_CONFIG_USERCONFIG")"
	mkdir -p "$configdir"
	cat <<-'EOF' | tee "$NPM_CONFIG_USERCONFIG"
		prefix=${XDG_DATA_HOME}/npm
		cache=${XDG_CACHE_HOME}/npm
		init-module=${XDG_CONFIG_HOME}/npm/config/npm-init.js
		tmp=${XDG_RUNTIME_DIR}/npm
		logfile=${XDG_CACHE_HOME}/npm/logs/npm.log
	EOF

	mv "$HOME/.npm/_cacache" "$XDG_CACHE_HOME/npm" 2>/dev/null
	mv "$HOME/.npm/_logs" "$XDG_CACHE_HOME/npm/logs" 2>/dev/null
	rm -rf "$HOME/.npm"
}

merge_delete(){
	local og xdg
	og="$1"; xdg="$2"
	if [ -d "$og" ]; then
		cp -r "$og" "$xdg"
		rm -rf "$og"
	fi
}

moveto_xdg(){
	local og xdg
	og="$1"; xdg="$2"
	if [ -f "$og" ]; then
		mkdir "$(dirname "$xdg")"
		mv -f "$og" "$xdg"
	fi
}

move_hardcoded_dir(){
	local og xdg
	og="$1"; xdg="$2"
	if [ ! -L "$og" ] && [ -d "$og" ]; then
		merge_delete "$og" "$xdg"
		ln -s "$xdg" "$og"
	fi
}

# Mover archivos según la especificación XDG

[ -d "$HOME/.npm" ] && npm_xdg

merge_delete "$HOME/.pki"   "$XDG_DATA_HOME/pki/"
merge_delete "$HOME/.gnupg" "$XDG_DATA_HOME/gnupg"
merge_delete "$HOME/.cargo" "$XDG_DATA_HOME/cargo"
merge_delete "$HOME/go"     "$XDG_DATA_HOME/go"

moveto_xdg "$HOME/.pulse-cookie" "$XDG_CONFIG_HOME/pulse/cookie"
moveto_xdg "$HOME/.gitconfig"    "$XDG_CONFIG_HOME/git/config"

move_hardcoded_dir "$HOME/.java"             "$XDG_CONFIG_HOME/java"
move_hardcoded_dir "$HOME/.eclipse"          "$XDG_CONFIG_HOME/eclipse"
move_hardcoded_dir "$HOME/eclipse-workspace" "$XDG_DATA_HOME/eclipse-workspace"
move_hardcoded_dir "$HOME/.codetogether"     "$HOME/.config/codetogether"
move_hardcoded_dir "$HOME/.webclipse"        "$HOME/.config/webclipse"

sleep 10; rm "$HOME/.xsession-errors"

# Borrar archivos
rm -f "$HOME/.wget-hsts"
rm -rf \
	"$HOME/Escritorio" \
	"$XDG_CONFIG_HOME/menus" \
	"$XDG_DATA_HOME/desktop-directories" \
	"$XDG_DATA_HOME/applications/wine"*
