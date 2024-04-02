#!/bin/sh
location="$HOME/.local/share/wordlist"
spanish="$location/spanish.wordlist"

if [ ! -d "$location" ]; then
	mkdir -p "$location"
fi

# Descargar wordlist en español para generar contraseñas
wget -O $spanish https://raw.githubusercontent.com/danielmiessler/SecLists/master/Miscellaneous/Moby-Project/Moby-Language-II/spanish.txt
sed -i 's/a`/á/g; s/e`/é/g; s/i`/í/g; s/o`/ó/g; s/u`/ú/g; s/A`/Á/g; s/E`/É/g; s/I`/Í/g; s/O`/Ó/g; s/U`/Ú/g; s/\\/ñ/g' $spanish
