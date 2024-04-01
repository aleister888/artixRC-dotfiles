#!/bin/bash

# Stow archivos de configuración y scripts
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
