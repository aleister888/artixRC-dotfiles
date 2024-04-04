#!/bin/bash

#######################################
# Archivos de configuración y scripts #
#######################################

[ ! -d "$HOME/.config" ] && mkdir -p "$HOME/.config"
[ ! -d "$HOME/.local/bin" ] && mkdir -p "$HOME/.local/bin"
sh -c "cd $HOME/.dotfiles && stow --target="${HOME}/.local/bin/" bin/" >/dev/null
sh -c "cd $HOME/.dotfiles && stow --target="${HOME}/.config/" .config/" >/dev/null
ln -s $HOME/.dotfiles/.profile $HOME/ 2>/dev/null
# Borrar enlaces rotos
find "$HOME/.local/bin" -type l ! -exec test -e {} \; -delete
find "$HOME/.config"    -type l ! -exec test -e {} \; -delete

# Enlazar nuestro script de inicio
[ ! -d "$HOME/.local/share/dwm" ] && mkdir -p "$HOME/.local/share/dwm"
ln -s ~/.dotfiles/dwm/autostart.sh ~/.local/share/dwm/autostart.sh 2>/dev/null

###############
# Plugins ZSH #
###############

plugin_install(){
	git clone "https://github.com/$1" "$HOME/.dotfiles/.config/zsh/$(basename "$1")"
}

[ ! -e $HOME/.config/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
     plugin_install zsh-users/zsh-autosuggestions
[ ! -e $HOME/.config/zsh/zsh-history-substring-search/zsh-history-substring-search.plugin.zsh ] && \
     plugin_install zsh-users/zsh-history-substring-search
[ ! -e $HOME/.config/zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
     plugin_install zsh-users/zsh-syntax-highlighting
[ ! -e $HOME/.config/zsh/zsh-you-should-use/you-should-use.plugin.zsh ] && \
	plugin_install MichaelAquilina/zsh-you-should-use

# Actualizar plugins de zsh
sh -c "cd $HOME/.config/zsh/zsh-autosuggestions && git pull"
sh -c "cd $HOME/.config/zsh/zsh-history-substring-search && git pull"
sh -c "cd $HOME/.config/zsh/zsh-syntax-highlighting && git pull"
sh -c "cd $HOME/.config/zsh/zsh-you-should-use && git pull"

############################
# Aplicaciones por defecto #
############################

# Borramos ajustes ya guardados
rm -f $HOME/.config/mimeapps.list
rm -f $HOME/.local/share/applications/defaults.list
doas rm -f /user/share/applications/mimeinfo.cache
update-mime-database ~/.local/share/mime

[ ! -d "$HOME/.local/share/applications" ] && mkdir -p "$HOME/.local/share/applications"
# Creamos el archivo .desktop para lf
[ ! -e "$HOME/.local/share/applications/lft.desktop" ] && \
echo '[Desktop Entry]
Type=Application
Name=lf File Manager (St)
Comment=Simple terminal-based file manager
Exec=st -e lf %u
Terminal=false
Icon=utilities-terminal
Categories=System;FileTools;FileManager
GenericName=File Manager
MimeType=inode/directory;' > "$HOME/.local/share/applications/lft.desktop"

# Creamos el archivo .desktop para nvim
[ ! -e "$HOME/.local/share/applications/nvimt.desktop" ] && \
echo '[Desktop Entry]
Type=Application
Name=Neovim (St)
Comment=Simple terminal-based text editor
Exec=st -e nvim %F
Terminal=false
Icon=nvim
Categories=Utility;TextEditor;
MimeType=text/english;text/plain;text/x-makefile;text/x-c++hdr;text/x-c++src;text/x-chdr;text/x-csrc;text/x-java;text/x-moc;text/x-pascal;text/x-tcl;text/x-tex;application/x-shellscript;text/x-c;text/x-c++;' > "$HOME/.local/share/applications/nvimt.desktop"

# Nuestra función para establecer nuestro visor de imagenes, video, audio y editor de texto
set_default_mime_types(){
	local pattern="$1"
	local desktop_file="$2"
	awk -v pattern="$pattern" '$0 ~ pattern {print $1}' /etc/mime.types | while read -r line; do
		xdg-mime default "$desktop_file" "$line"
	done
}

set_default_mime_types "^image" "nsxiv.desktop"
set_default_mime_types "^video" "mpv.desktop"
set_default_mime_types "^audio" "mpv.desktop"
set_default_mime_types "^text" "nvimt.desktop"

# Establecemos por defecto el administrador de archivos
xdg-mime default lfst.desktop inode/directory
xdg-mime default lfst.desktop x-directory/normal
update-desktop-database "$HOME/.local/share/applications"
# Usar xdg-open para firefox
mkdir -p "$HOME/.local/share/dbus-1/services/"
echo "Exec=/bin/false" > "$HOME/.local/share/dbus-1/services/org.freedesktop.FileManager1.service"

xdg-settings set default-web-browser firefox.desktop 2>/dev/null

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
	"application/x-dbase"
	"application/x-dbf"
	"application/x-123"
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
	"application/prs.plucker"
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
