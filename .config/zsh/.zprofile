# Abreviaciones
. "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/aliasrc"

if [ -d "$HOME/.local/bin" ] ; then
	PATH="$HOME/.local/bin:$PATH"
fi

if [ -x /usr/local/bin/dwm ]; then
	# Añadir scripts de eww a $PATH
	if [ -d "$HOME/.local/bin/eww" ]; then
	PATH="$HOME/.local/bin/eww:$PATH"
	fi
	# Añadir scripts de dwmblocks a $PATH
	if [ -d "$HOME/.local/bin/sb" ]; then
		PATH="$HOME/.local/bin/sb:$PATH"
	fi
	# Definir localización para ser usada por Redshift
	if [ -z "$LOCATION" ]; then
		# Verificar la conexión a internet
		if ping -q -c 1 -W 1 gnu.org >/dev/null; then
			# Si hay conexión a internet, asignar el valor utilizando curl y jq
			export LOCATION=$(curl -s "https://location.services.mozilla.com/v1/geolocate?key=geoclue" | \
			jq -r '"\(.location.lat):\(.location.lng)"' &)
		else
			echo "No se pudo establecer conexión a internet."
		fi
	fi
	# Definir cursor usado por X11
	export XCURSOR_PATH=/usr/share/icons:${XDG_DATA_HOME}/icons
	export XCURSOR_PATH=/usr/share/icons/
	export XCURSOR_THEME=capitaine-cursors
	export XCURSOR_SIZE=64
	# Usar el filechooser del portal GTK
	export GDK_SCALE=1
	export GTK_USE_PORTAL=1
	# Fix for java apps
	export _JAVA_AWT_WM_NONREPARENTING=1
	# Make QT themes follow qt5ct settings
	export QT_QPA_PLATFORMTHEME="qt5ct"
	# XDG
	export XDG_CURRENT_DESKTOP=X-Generic
	export XDG_CONFIG_HOME="$HOME/.config"
	export XDG_DATA_HOME="$HOME/.local/share"
	export XDG_CACHE_HOME="$HOME/.cache"
	export XDG_STATE_HOME="$HOME/.local/state"
	# Apps
	export PIPEWIRE_LATENCY="128/48000"
fi

export EDITOR="nvim"
export SUDO_EDITOR="nvim"
export READER="zathura"
export TERMINAL="st"
export TERMTITLE="-t"
export TERMEXEC=""
export TERM="st-256color"
export BROWSER="firefox"
export VIDEO="mpv"
export OPENER="xdg-open"
export PAGER="less"
export VIEWER="nsxiv"

# Limpiar el directorio ~/ de archivos de configuración
export RUSTUP_HOME="$XDG_DATA_HOME"/rustup
export GOPATH="$XDG_DATA_HOME"/go
export TEXMFVAR="$XDG_CACHE_HOME"/texlive/texmf-var
export KODI_DATA="$XDG_DATA_HOME"/kodi
export DVDCSS_CACHE="$XDG_DATA_HOME"/dvdcss
export GNUPGHOME="${XDG_DATA_HOME:-$HOME/.local/share}/gnupg"
export CUDA_CACHE_PATH="${XDG_CACHE_HOME:-$HOME/.cache}/nv"
export GTK2_RC_FILES="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-2.0/gtkrc:${XDG_CONFIG_HOME:-$HOME/.config}/gtk-2.0/gtkfilechooser.ini"
export WINEPREFIX="${XDG_CONFIG_HOME:-$HOME/.config}/wineprefixes"
export TERMINFO_DIRS="${XDG_CONFIG_HOME:-$HOME/.config}/terminfo:/usr/share/terminfo"
export HISTFILE="${XDG_DATA_HOME:-$HOME/.local/share}/history"
export LESSHISTFILE="$XDG_CACHE_HOME"/less/history
export CARGO_HOME="$XDG_DATA_HOME"/cargo
export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"/npm/npmrc

# Iconos de lf
export LF_ICONS="di=:fi=:tw=󱝏:ow=:ex=:ln=:or=:\
*.mp3=:*.opus=:*.ogg=:*.m4a=:*.flac=:*.ape=:*.wav=:*.cue=:\
*.RPP=󰋅:*.RPP-bak=󰋅:*.rpp=󰋅:*.rpp-bak=󰋅:*.rpp-PROX=󰋅:*drums.wav=󰋅:\
*.tg=:*.gp=:*.gp3=:*.gp4=:*.gp5=:*.gpx=:*.vst3=:*.so=:\
*.mkv=:*.mp4=:*.m4v=:*.webm=:*.mpeg=:*.avi=:*.mov=:\
*.png=:*.webp=:*.ico=:*.jpg=:*.jpe=:*.jpeg=:*.JPG=:\
*.gif=:*.svg=:*.tif=:*.tiff=:*.xcf=:*.eps=:*.kra=:\
*.vim=:*.ms=:*.xml=:*.csv=:*.xlsx=:*.djvu=:*.sh=:\
*.mpg=:*.wmv=:*.m4b=:*.flv=:*.MOV=:*.kdenlive=:\
*config.h=󱁻:*config.def.h=󱁻:*.json=󱁻:*.ini=󱁻:*.yml=󱁻:\
*.reapeaks=󰋅:*other.wav=󰋅:*vocals.wav=󰋅:*bass.wav=󰋅:\
*.z64=󰖺:*.v64=󰖺:*.n64=󰖺:*.gba=󰖺:*.nes=󰖺:*.gdi=󰖺:\
*PKGBUILD=󱁼:*Makefile=󱁼:*Makefile.inc=󱁼:*.mk=󱁼:\
*.zip=:*.rar=:*.7z=:*.gz=:*.xz=:*.xnb=:\
*.conf=󱁻:*.cfg=󱁻:*.vdf=󱁻:*.dmx=󱁻:*.toml=󱁻:\
*cover.jpg=:*cover.jpeg=:*cover.png=:\
*.txt=:*.tex=:*.markdown=:*.md=:\
*.c=󱁼:*.o=󱁼:*.h=󱁼:*.go=󱁼:*.cache=󱁿:\
*.r=:*.R=:*.rmd=:*.Rmd=:*.m=:\
*.log=:*.reg=:*.aux=:*.toc=:\
*.vtt=:*.srt=:*.blend=:\
*.jar=:*.java=:*.js=:\
*.dll=:*.vst3=:*.exe=:\
*.pdf=:*.cbr=:*.cbz=:\
*README=:*LICENSE=:\
*.part=󰌹:*.torrent=󰌹:\
*.desktop=󱆭:*.lnk=󱆭:\
*.tmp=󱁿:*.history=󱁿:\
*Missing-Tabs=󰵦:\
*.iso=:*.img=:\
*Dockerfile=:\
*.vader=:\
*.html=󰌀:\
*.docx=:\
*.epub=:\
*.kdbx=:\
*.mask=:\
*.gpg=:\
*.css=󰸌:\
*.mid=󰡂:\
*.bib=:\
*.git=:\
*.bin=:\
*.py="

# lf Colors
export LF_COLORS=".github/=33:.git/=33:.git*=32:.git*=32:\
tw=01;34:ow=01;34:st=01;34:di=01;34:\
su=01;32:sg=01;32:ex=01;32:\
bd=33;01:cd=33;01:\
ln=01;36:\
so=01;35:\
or=31;01:\
pi=33:\
fi=00"

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
