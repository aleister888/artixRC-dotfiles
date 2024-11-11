#!/bin/bash

# Instalador de ajustes para Artix OpenRC
# por aleister888 <pacoe1000@gmail.com>
# Licencia: GNU GPLv3


# Actualizar repositorio
sh -c "cd $HOME/.dotfiles && git pull" >/dev/null


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

# Enlazar nuestro script de inicio
[ -d "$HOME/.local/share/dwm" ] || mkdir -p "$HOME/.local/share/dwm"
ln -sf ~/.dotfiles/dwm/autostart.sh ~/.local/share/dwm/autostart.sh


#########################
# Configurar apariencia #
#########################


# Crear el archivo de configuración bg-saved.cfg
mkdir -p "$HOME/.config/nitrogen"
echo "[xin_-1]
file=$HOME/.dotfiles/assets/wallpaper
mode=5
bgcolor=#000000" > "$HOME/.config/nitrogen/bg-saved.cfg"


#######################
# Configurar GTK y QT #
#######################


ASSETDIR="$HOME/.dotfiles/assets/configs"

# Copiar la configuración de GTK
rm -rf $HOME/.config/gtk-[2-4].0
cp -r $ASSETDIR/gtk-2.0 $HOME/.config/gtk-2.0
cp -r $ASSETDIR/gtk-3.0 $HOME/.config/gtk-3.0
cp -r $ASSETDIR/gtk-4.0 $HOME/.config/gtk-4.0
if [ ! -d /usr/share/themes/Gruvbox-Dark ]; then
	# Clona el tema de gtk4
	git clone https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme.git /tmp/Gruvbox_Theme >/dev/null
	# Copia el tema deseado a la carpeta de temas
	sudo bash /tmp/Gruvbox_Theme/themes/install.sh
fi
# Tema GTK para el usuario root (Para aplicaciones como Bleachbit)
sudo mkdir -p /root/.config
sudo cp $ASSETDIR/.gtkrc-2.0 /root/.gtkrc-2.0
sudo cp -r $ASSETDIR/gtk-3.0 /root/.config/gtk-3.0/
sudo cp -r $ASSETDIR/gtk-4.0 /root/.config/gtk-4.0/
# Definimos nuestros directorios marca-páginas
echo "file:///home/$USER
file:///home/$USER/Descargas
file:///home/$USER/Documentos
file:///home/$USER/Imágenes
file:///home/$USER/Vídeos
file:///home/$USER/Música" > "$HOME/.config/gtk-3.0/bookmarks"
# Configuramos QT
mkdir -p "$HOME/.config/qt5ct" "$HOME/.config/qt6ct"
echo "[Appearance]
color_scheme_path=$HOME/.dotfiles/assets/qt-colors/Gruvbox.conf
custom_palette=true
icon_theme=Papirus-Dark
style=Fusion

[Fonts]
fixed=\"Iosevka Fixed SS05,12,0,0,0,0,0,0,0,0,Bold\"
general=\"Iosevka Fixed SS05 Semibold,12,0,0,0,0,0,0,0,0,Regular\"

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=@Invalid()
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
stylesheets=@Invalid()
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3" | \
	tee "$HOME/.config/qt5ct/qt5ct.conf" "$HOME/.config/qt6ct/qt6ct.conf" >/dev/null

# Configurar el tema del cursor
mkdir -p "$HOME/.local/share/icons/default"
cp "$HOME/.dotfiles/assets/configs/index.theme" "$HOME/.local/share/icons/default/index.theme"


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


rm -f "$HOME/.config/mimeapps.list"
rm -rf ~/.local/share/mime
mkdir -p "$HOME/.local/share/mime/packages"
sudo rm -f /usr/share/applications/mimeinfo.cache

update-mime-database ~/.local/share/mime
sudo update-mime-database /usr/share/mime

[ ! -d "$HOME/.local/share/applications" ] && \
	mkdir -p "$HOME/.local/share/applications"

# Creamos el archivo .desktop para lf
ln -s "$HOME/.dotfiles/assets/desktop/lft.desktop" "$HOME/.local/share/applications/file.desktop" 2>/dev/null
# Creamos el archivo .desktop para nvim
ln -s "$HOME/.dotfiles/assets/desktop/nvimt.desktop" "$HOME/.local/share/applications/text.desktop" 2>/dev/null


# Creamos el archivo .desktop para el visor de imagenes
cp -f "$HOME/.dotfiles/assets/desktop/image.desktop" "$HOME/.local/share/applications/image.desktop"
# Creamos el archivo .desktop para el visor de imagenes
cp -f "$HOME/.dotfiles/assets/desktop/looking-glass.desktop" "$HOME/.local/share/applications/looking-glass.desktop"

# Nuestra función para establecer nuestro visor de imagenes, video, audio y editor de texto
set_default_mime_types(){
	local pattern="$1"
	local desktop_file="$2"
	awk -v pattern="$pattern" '$0 ~ pattern {print $1}' /etc/mime.types | while read -r line; do
		xdg-mime default "$desktop_file" "$line"
	done
}

set_default_mime_types "^image" "image.desktop"

set_default_mime_types "^*/pdf" "org.pwmt.zathura.desktop"
set_default_mime_types "^video" "mpv.desktop"
set_default_mime_types "^audio" "mpv.desktop"
set_default_mime_types "^text" "text.desktop"

# Establecemos el administrador de archivos predetermiando
xdg-mime default file.desktop inode/directory
xdg-mime default file.desktop x-directory/normal
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
	sudo cp "/usr/share/applications/$entry.desktop" "/usr/local/share/applications/$entry.desktop" 2>/dev/null && \
	echo 'NoDisplay=true' | sudo tee -a "/usr/local/share/applications/$entry.desktop" >/dev/null
done

#############################
# Añadir diccionarios a vim #
#############################

[ ! -d "$HOME/.local/share/nvim/site/spell" ] && \
	mkdir -p "$HOME/.local/share/nvim/site/spell"

[ ! -f "$HOME/.local/share/nvim/site/spell/es.utf-8.spl" ] && \
wget 'https://ftp.nluug.nl/pub/vim/runtime/spell/es.utf-8.spl' -q -O \
	"$HOME/.local/share/nvim/site/spell/es.utf-8.spl"

[ ! -f "$HOME/.local/share/nvim/site/spell/es.utf-8.sug" ] && \
wget 'https://ftp.nluug.nl/pub/vim/runtime/spell/es.utf-8.sug' -q -O \
	"$HOME/.local/share/nvim/site/spell/es.utf-8.sug"
