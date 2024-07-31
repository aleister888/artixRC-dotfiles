#!/bin/bash


# Instalador para Ubuntu WSL
# Ejectua con:
# 	curl -o wsl.sh https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/main/wsl-install.sh && chmod +x wsl.sh && ./wsl.sh


# Instalar paquetes

sudo apt update
sudo add-apt-repository ppa:neovim-ppa/stable
sudo apt install neovim zsh golang


# Configurar zsh

mkdir -p "$HOME/.config/zsh"
ln -s "$HOME/.profile" "$HOME/.config/zsh/.zprofile"

# Descargar configuración de zsh
wget -q "https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/main/.config/zsh/.zshrc" \
	-O "$HOME/.config/zsh/.zshrc"
wget -q "https://github.com/aleister888/artixRC-dotfiles/blob/main/.config/zsh/aliasrc" \
	-O "$HOME/.config/zsh/aliasrc"
wget -q "https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/main/.profile" \
	-O "$HOME/.profile"

# Instalar los plugins de zsh que no estén ya instalados
plugin_install(){
	git clone "https://github.com/$1" "$HOME/.dotfiles/.config/zsh/$(basename "$1")" >/dev/null
}
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

# Establecer zsh como la shell por defecto
chsh -s "$(which zsh)"


# Configurar neovim

# Descargar configuración
mkdir -p "$HOME/.config/zsh"
git clone "https://github.com/aleister888/artixRC-dotfiles.git" "$HOME/.config/dotsrepo"
cp -r "$HOME/.config/dotsrepo/.config/nvim" "$HOME/.config/nvim"

# Instalar vimplug
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
	https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'