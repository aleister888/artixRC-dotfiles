#!/bin/sh

# Abreviaciones
. "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/aliasrc"

# Aquí puedes colocar alias sin que estos esten
# dentro de la estructura del repositorio
if [ -e "${XDG_CONFIG_HOME:-$HOME/.config}/useralias" ]; then
	. "${XDG_CONFIG_HOME:-$HOME/.config}/useralias"
fi

if [ -d "$HOME/.local/bin" ] ; then
	PATH="$HOME/.local/bin:$PATH"
fi

# Añadir scripts de eww a $PATH
if [ -d "$HOME/.local/bin/eww" ]; then
	PATH="$HOME/.local/bin/eww:$PATH"
fi
# Añadir scripts de dwmblocks a $PATH
if [ -d "$HOME/.local/bin/sb" ]; then
	PATH="$HOME/.local/bin/sb:$PATH"
fi
# Añadir scripts a $PATH
if [ -d "$HOME/.local/bin/utils" ]; then
	PATH="$HOME/.local/bin/utils:$PATH"
fi

# Definir cursor usado por X11
export XCURSOR_PATH=/usr/share/icons:${XDG_DATA_HOME}/icons
export XCURSOR_PATH=/usr/share/icons/
export XCURSOR_THEME=capitaine-cursors
export XCURSOR_SIZE=64

# Usar el filechooser del portal GTK
export GDK_SCALE=1
export GTK_USE_PORTAL=1
export GTK_THEME=Gruvbox-Dark

# Hacer que las aplicaciones QT sigan los ajustes de QT5CT
export QT_QPA_PLATFORMTHEME="qt5ct"

# XDG
export XDG_CURRENT_DESKTOP=X-Generic

# Apps
export OPENER="xdg-open"

# Arreglar aplicaciones de java
export _JAVA_AWT_WM_NONREPARENTING=1

# XDG
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

# Apps
export EDITOR="nvim"
export SUDO_EDITOR="nvim"
export READER="zathura"
export TERMINAL="st"
export TERMTITLE="-t"
export TERMEXEC=""
export TERM="st-256color"
export BROWSER="firefox"
export VIDEO="mpv"
export PAGER="less"
export VIEWER="nsxiv"

# Limpiar el directorio ~/ de archivos de configuración
export PARALLEL_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"/parallel
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
export LF_ICONS="di=:fi=:tw=󱝏:ow=:ex=:ln=:or=󱫅:\
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
*.ttf=:*.otf=:\
*Dockerfile=:\
*.vader=:\
*.html=󰌀:\
*.docx=:\
*.epub=:\
*.kdbx=:\
*.mask=:\
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
