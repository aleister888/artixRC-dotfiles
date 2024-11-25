#!/bin/sh

tmp_dir="/tmp/yay_install_temp"
mkdir -p "$tmp_dir"
git clone https://aur.archlinux.org/yay.git "$tmp_dir"
sh -c "cd $tmp_dir && makepkg -si --noconfirm"

yay -Sy --noconfirm --disable-download-timeout --needed \
	texlive-core texlive-bin texlive-langspanish texlive-bibtexextra texlive-binextra texlive-context texlive-fontsextra texlive-fontsrecommended texlive-fontutils texlive-formatsextra texlive-latex texlive-latexextra texlive-latexrecommended texlive-mathscience texlive-music texlive-pictures texlive-plaingeneric texlive-pstricks texlive-publishers texlive-xetex \
	nodejs jdk-openjdk git

mkdir -p ~/.local/share ~/.config
git clone --branch dev --single-branch \
	https://github.com/aleister888/artixRC-dotfiles.git ~/.local/share/dots

ln -s ~/.local/share/dots/.config/nvim ~/.config/nvim
