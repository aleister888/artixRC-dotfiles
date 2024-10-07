#!/bin/bash

# Instalador de ajustes para Artix OpenRC
# por aleister888 <pacoe1000@gmail.com>
# Licencia: GNU GPLv3


# Actualizar repositorio
sh -c "cd $HOME/.dotfiles && git pull" >/dev/null


# Si el script se ejecuta con -f, arreglar los permisos de todos los archivos en $HOME
while getopts ":f" opt; do
	case $opt in
	f)
		# Arreglar los permisos de los directorios
		find "$HOME" -type d -exec chmod 700 {} +
		# Arreglar los permisos de los archivos multimedia
		find "$HOME" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \
		-o -iname "*.mp3" -o -iname "*.wav" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.txt" \) \
		-exec chmod 600 {} +
		;;
	\?)
		echo "Opción inválida: -$OPTARG" >&2
		exit 1
		;;
	esac
done


#######################################
# Archivos de configuración y scripts #
#######################################


# Crear los directorios necesarios
[ -d "$HOME/.config" ]		|| mkdir -p "$HOME/.config"
[ -d "$HOME/.local/bin" ]	|| mkdir -p "$HOME/.local/bin"
[ -d "$HOME/.local/share" ]	|| mkdir -p "$HOME/.local/share"
[ -d "$HOME/.cache" ]		|| mkdir -p "$HOME/.cache"

# Instalar archivos de configuración y scripts
sh -c "cd $HOME/.dotfiles && stow --target=${HOME}/.local/bin/ bin/" >/dev/null
sh -c "cd $HOME/.dotfiles && stow --target=${HOME}/.config/ .config/" >/dev/null
ln -s $HOME/.dotfiles/.profile $HOME/.profile 2>/dev/null
ln -s $HOME/.dotfiles/.profile $HOME/.config/zsh/.zprofile 2>/dev/null

# Borrar enlaces rotos
find "$HOME/.local/bin"	-type l ! -exec test -e {} \; -delete
find "$HOME/.config"	-type l ! -exec test -e {} \; -delete

if [ ! -e /usr/bin/plasmashell ]; then
	# Enlazar nuestro script de inicio
	[ -d "$HOME/.local/share/dwm" ] || mkdir -p "$HOME/.local/share/dwm"
	ln -sf ~/.dotfiles/dwm/autostart.sh ~/.local/share/dwm/autostart.sh
else # Crear .desktop para iniciar pipewire (En caso de que xdg-autostart falle)
	cp ~/.dotfiles/assets/desktop/pipewire.desktop ~/.local/share/applications/
fi

# Descargar shader de mpv
[ ! -e "$HOME/.config/mpv/shaders/crt-lottes.glsl" ] && \
	wget -q "https://raw.githubusercontent.com/hhirtz/mpv-retro-shaders/master/crt-lottes.glsl" \
	-O "$HOME/.config/mpv/shaders/crt-lottes.glsl" >/dev/null


#########################
# Configurar apariencia #
#########################


if [ ! -e /usr/bin/plasmashell ]; then
	# Crear el archivo de configuración bg-saved.cfg
	mkdir -p "$HOME/.config/nitrogen"
	echo "[xin_-1]
	file=$HOME/.dotfiles/assets/wallpaper
	mode=5
	bgcolor=#000000" > "$HOME/.config/nitrogen/bg-saved.cfg"
fi


##################################################
# Configurar GTK y QT (Si KDE no está instalado) #
##################################################


ASSETDIR="$HOME/.dotfiles/assets/configs"
THEME_DIR="/usr/share/themes"

# Copiar la configuración de GTK
if [ ! -e /usr/bin/plasmashell ]; then
	rm -rf $HOME/.config/gtk-[2-4].0
	cp -r $ASSETDIR/gtk-2.0 $HOME/.config/gtk-2.0
	cp -r $ASSETDIR/gtk-3.0 $HOME/.config/gtk-3.0
	cp -r $ASSETDIR/gtk-4.0 $HOME/.config/gtk-4.0
	if [ ! -d /usr/share/themes/Gruvbox-Dark ]; then
		# Clona el tema de gtk4
		git clone https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme.git /tmp/Gruvbox_Theme >/dev/null
		# Copia el tema deseado a la carpeta de temas
		doas bash /tmp/Gruvbox_Theme/themes/install.sh
	fi
	# Tema GTK para el usuario root (Para aplicaciones como Bleachbit)
	doas mkdir -p /root/.config
	doas cp $ASSETDIR/.gtkrc-2.0 /root/.gtkrc-2.0
	doas cp -r $ASSETDIR/gtk-3.0 /root/.config/gtk-3.0/
	doas cp -r $ASSETDIR/gtk-4.0 /root/.config/gtk-4.0/
	# Definimos nuestros directorios marca-páginas
	echo "file:///home/$USER
	file:///home/$USER/Descargas
	file:///home/$USER/Documentos
	file:///home/$USER/Imágenes
	file:///home/$USER/Vídeos
	file:///home/$USER/Música" > "$HOME/.config/gtk-3.0/bookmarks"
	# Configuramos QT
	echo "[Appearance]
	color_scheme_path=$HOME/.config/qt5ct/colors/Gruvbox.conf
	custom_palette=true
	icon_theme=gruvbox-dark-icons-gtk
	standard_dialogs=default
	style=Fusion
	
	[Fonts]
	fixed=\"Iosevka Nerd Font,12,0,0,0,0,0,0,0,0,Bold\"
	general=\"Iosevka Nerd FontMono,12,0,0,0,0,0,0,0,0,SemiBold\"" > "$HOME/.dotfiles/.config/qt5ct/qt5ct.conf"
	
	# Configurar el tema del cursor
	mkdir -p "$HOME/.local/share/icons/default"
	cp "$HOME/.dotfiles/assets/configs/index.theme" "$HOME/.local/share/icons/default/index.theme"
fi


###############
# Plugins ZSH #
###############


plugin_install(){
	git clone "https://github.com/$1" "$HOME/.dotfiles/.config/zsh/$(basename "$1")" >/dev/null
}

# Instalar los plugins de zsh que no estén ya instalados
[ ! -e "$HOME/.config/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \
	plugin_install zsh-users/zsh-autosuggestions
[ ! -e "$HOME/.config/zsh/zsh-history-substring-search/zsh-history-substring-search.plugin.zsh" ] && \
	plugin_install zsh-users/zsh-history-substring-search
[ ! -e "$HOME/.config/zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && \
	plugin_install zsh-users/zsh-syntax-highlighting
[ ! -e "$HOME/.config/zsh/zsh-you-should-use/you-should-use.plugin.zsh" ] && \
	plugin_install MichaelAquilina/zsh-you-should-use
[ ! -d "$HOME/.config/zsh/ohmyzsh" ] && mkdir -p "$HOME/.config/zsh/ohmyzsh"
	wget -q "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/dirhistory/dirhistory.plugin.zsh" \
	-O "$HOME/.config/zsh/ohmyzsh/dirhistory.plugin.zsh"

# Actualizar plugins de zsh
sh -c "cd $HOME/.config/zsh/zsh-autosuggestions && git pull" >/dev/null
sh -c "cd $HOME/.config/zsh/zsh-history-substring-search && git pull" >/dev/null
sh -c "cd $HOME/.config/zsh/zsh-syntax-highlighting && git pull" >/dev/null
sh -c "cd $HOME/.config/zsh/zsh-you-should-use && git pull" >/dev/null


############################
# Aplicaciones por defecto #
############################


if [ ! -e /usr/bin/plasmashell ]; then
	rm -f "$HOME/.config/mimeapps.list"
	rm -rf ~/.local/share/mime
	mkdir -p "$HOME/.local/share/mime/packages"
	doas rm -f /usr/share/applications/mimeinfo.cache
fi

update-mime-database ~/.local/share/mime
doas update-mime-database /usr/share/mime

[ ! -d "$HOME/.local/share/applications" ] && \
	mkdir -p "$HOME/.local/share/applications"

# Creamos el archivo .desktop para lf
[ ! -e "$HOME/.local/share/applications/lft.desktop" ] && \
cp -f "$HOME/.dotfiles/assets/desktop/lft.desktop" "$HOME/.local/share/applications/lft.desktop"

# Creamos el archivo .desktop para nvim
[ ! -e "$HOME/.local/share/applications/nvimt.desktop" ] && \
cp -f "$HOME/.dotfiles/assets/desktop/nvimt.desktop" "$HOME/.local/share/applications/nvimt.desktop"

# Creamos el archivo .desktop para el visor de imagenes
[ ! -e "$HOME/.local/share/applications/image.desktop" ] && \
cp -f "$HOME/.dotfiles/assets/desktop/image.desktop" "$HOME/.local/share/applications/image.desktop"

# Creamos el archivo .desktop para el visor de imagenes
[ ! -e "$HOME/.local/share/applications/looking-glass.desktop" ] && \
cp -f "$HOME/.dotfiles/assets/desktop/looking-glass.desktop" "$HOME/.local/share/applications/looking-glass.desktop"

# Nuestra función para establecer nuestro visor de imagenes, video, audio y editor de texto
set_default_mime_types(){
	local pattern="$1"
	local desktop_file="$2"
	awk -v pattern="$pattern" '$0 ~ pattern {print $1}' /etc/mime.types | while read -r line; do
		xdg-mime default "$desktop_file" "$line"
	done
}

if [ ! -e /usr/bin/plasmashell ]; then
	set_default_mime_types "^*/pdf" "org.pwmt.zathura.desktop"
	set_default_mime_types "^image" "image.desktop"
else
	set_default_mime_types "^*/pdf" "okularApplication_pdf.desktop"
	set_default_mime_types "^image" "org.kde.gwenview.desktop"
fi
set_default_mime_types "^video" "mpv.desktop"
set_default_mime_types "^audio" "mpv.desktop"
set_default_mime_types "^text" "nvimt.desktop"

# Establecemos el administrador de archivos predetermiando
xdg-mime default lfst.desktop inode/directory
xdg-mime default lfst.desktop x-directory/normal
update-desktop-database "$HOME/.local/share/applications"


mkdir -p "$HOME/.local/share/dbus-1/services/" # Usar xdg-open para firefox
echo "Exec=/bin/false" > "$HOME/.local/share/dbus-1/services/org.freedesktop.FileManager1.service"
xdg-settings set default-web-browser firefox.desktop 2>/dev/null # Establecer navegador predeterminado


# Definir asociaciones para archivos de Microsoft Excel
excel_associations=(
	"application/msexcel"
	"application/excel"
	"application/vnd.ms-excel"
	"application/x-msexcel"
	"application/x-dos_ms_excel"
	"application/x-excel"
	"application/vnd.sun.xml.calc"
	"application/vnd.sun.xml.calc.template"
)

# Definir asociaciones para archivos de Microsoft PowerPoint
powerpoint_associations=(
	"application/mspowerpoint"
	"application/vnd.apple.keynote"
	"application/vnd.ms-powerpoint"
	"application/vnd.openxmlformats-officedocument.presentationml.presentation"
	"application/vnd.openxmlformats-officedocument.presentationml.slide"
	"application/vnd.openxmlformats-officedocument.presentationml.slideshow"
	"application/vnd.openxmlformats-officedocument.presentationml.template"
)

# Definir asociaciones para archivos de Microsoft Word
word_associations=(
	"application/msword"
	"application/macwriteii"
	"application/rtf"
	"application/vnd.ms-word"
	"application/vnd.oasis.opendocument.text"
	"application/vnd.oasis.opendocument.text-flat-xml"
	"application/x-mswrite"
	"application/vnd.stardivision.writer-global"
	"application/x-doc"
	"application/vnd.oasis.opendocument.text-master"
	"application/vnd.oasis.opendocument.text-master-template"
	"application/vnd.oasis.opendocument.text-template"
	"application/vnd.oasis.opendocument.text-web"
	"application/vnd.openxmlformats-officedocument.wordprocessingml.document"
	"application/vnd.openxmlformats-officedocument.wordprocessingml.template"
	"application/vnd.wordperfect"
	"application/wordperfect"
	"application/x-abiword"
	"application/x-aportisdoc"
	"application/vnd.sun.xml.writer"
	"application/vnd.sun.xml.writer.global"
)

# Definir asociaciones para archivos de Microsoft Excel
for association in "${excel_associations[@]}"; do
	xdg-mime default libreoffice-calc.desktop "$association"
done

# Definir asociaciones para archivos de Microsoft PowerPoint
for association in "${powerpoint_associations[@]}"; do
	xdg-mime default libreoffice-impress.desktop "$association"
done

# Definir asociaciones para archivos de Microsoft Word
for association in "${word_associations[@]}"; do
	xdg-mime default libreoffice-writer.desktop "$association"
done


# Ocultar archivos .desktop innecesarios
desktopent=(
	"xdvi"
	"envy24control"
	"echomixer"
	"hdajackretask"
	"hdspconf"
	"hdspmixer"
	"hwmixvolume"
	"qvidcap"
	"qv4l2"
	"Surge-XT"
	"Surge-XT-FX"
	"jconsole-java-openjdk"
	"jshell-java-openjdk"
	"lstopo"
)
# Ruta done para clonar los repositorios
# Clonamos cada repositorio
for entry in "${desktopent[@]}"; do
	doas cp "/usr/share/applications/$entry.desktop" "/usr/local/share/applications/$entry.desktop" && \
	echo 'NoDisplay=true' | doas tee -a "/usr/local/share/applications/$entry.desktop"
done
