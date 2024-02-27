#!/bin/bash

# Verifica si el script se está ejecutando como root
if [ "$(id -u)" != "0" ]; then
	echo "Este instalador debe ejecutarse como root."
	exit 1
fi

# Rutas de los binarios
BIN_PATH="/usr/local/bin"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Elimina los enlaces simbólicos existentes
rm -f "$BIN_PATH/tauon-remote" "$BIN_PATH/tauon-yad"

# Crea nuevos enlaces simbólicos
ln -s "$SCRIPT_DIR/tauon-remote" "$BIN_PATH/tauon-remote"
ln -s "$SCRIPT_DIR/tauon-yad" "$BIN_PATH/tauon-yad"

echo "Tauon Remote y Tauon Yad han sido instalados correctamente en $BIN_PATH"
