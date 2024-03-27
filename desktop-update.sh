#!/bin/bash

# Stow archivos de configuración y scripts
[ ! -d "$HOME/.config" ] && mkdir -p "$HOME/.config"
[ ! -d "$HOME/.local/bin" ] && mkdir -p "$HOME/.local/bin"
sh -c "cd $HOME/.dotfiles && stow --target="${HOME}/.local/bin/" bin/" >/dev/null
ln -s $HOME/.dotfiles/.config/lf $HOME/.config/
ln -s $HOME/.dotfiles/.config/nvim $HOME/.config/
ln -s $HOME/.dotfiles/.config/zsh $HOME/.config/
ln -s $HOME/.dotfiles/.profile $HOME/
# Borrar enlaces rotos
find "$HOME/.local/bin" -type l ! -exec test -e {} \; -delete
find "$HOME/.config"    -type l ! -exec test -e {} \; -delete

# Actualizar plugins de zsh
sh -c "cd $HOME/.config/zsh/zsh-autosuggestions && git pull"
sh -c "cd $HOME/.config/zsh/zsh-history-substring-search && git pull"
sh -c "cd $HOME/.config/zsh/zsh-syntax-highlighting && git pull"
sh -c "cd $HOME/.config/zsh/zsh-you-should-use && git pull"
