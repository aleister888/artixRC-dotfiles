#!/bin/bash

# Stow archivos de configuración y scripts
sh -c "cd $HOME/.dotfiles && stow --target="${HOME}/.local/bin/" bin/" >/dev/null
sh -c "cd $HOME/.dotfiles && stow --target="${HOME}/.config/" .config/" >/dev/null
# Borrar enlaces rotos
find "$HOME/.local/bin" -type l ! -exec test -e {} \; -delete
find "$HOME/.config"    -type l ! -exec test -e {} \; -delete

# Enlazar nuestro script de inicio
ln -s ~/.dotfiles/dwm/autostart.sh ~/.local/share/dwm 2>/dev/null

# Actualizar plugins de zsh
sh -c "cd $HOME/.config/zsh/zsh-autosuggestions && git pull"
sh -c "cd $HOME/.config/zsh/zsh-history-substring-search && git pull"
sh -c "cd $HOME/.config/zsh/zsh-syntax-highlighting && git pull"
