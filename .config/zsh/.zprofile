# Iniciar dwm
if [ -x "/usr/local/bin/dwm" ]; then
	if [ "$(tty)" = "/dev/tty1" ]; then
		if [ "$(pgrep -c dbus)" -lt 5 ]; then
			export $(dbus-launch) && dbus-update-activation-environment --all &
	        	startx
		else
	        	startx
		fi
	fi
	if [ "$(tty)" = "/dev/tty1" ]; then
		exit 0
	fi
fi
