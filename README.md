<img src="https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/master/assets/artix-linux.png" align="left" height="100px" hspace="10px" vspace="0px">

# Artix (OpenRC) Dotfiles

Configuración de `Artix Linux OpenRC` y auto-instalador

<p float="center">
    <img src="https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/main/assets/screenshots/screenshot1.jpg" width="49%" />
    <img src="https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/main/assets/screenshots/screenshot2.jpg" width="49%" />
</p>

# Instalación

- Ejecuta como root:

```
curl -o stage1.sh https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/main/stage1.sh && chmod +x stage1.sh && ./stage1.sh
```

> [!NOTA]
> - La instalación toma _(con una conexión de `40mb/s`)_ unos `25 minutos` aproximadamente.
> - Una vez instalado el sistema, y después de iniciar sesión, pulsa `Ctrl+Alt+H` para abrir un PDF con información sobre como usar el administrador de ventanas _(dwm)_ y otra información útil _(como configurar ssh, firefox, etc.)_.

# Características

- Encriptación (`/` y `/home`) de disco (`/boot` queda sin encriptar).
- Soporte para `btrfs`, `ext4` y `xfs`
- Soporte para `BIOS` y `UEFI`
- Configuración de `Xorg` y `eww` automática, basada en el DPI y resolución de la pantalla.
    - _Además; dwm, st y dmenu se compilan con el tamaño de fuente recomendado para tu resolución_
- Entorno configurado para minimizar el número de archivos en `~/` 
    - https://wiki.archlinux.org/title/XDG_Base_Directory

# Atención!

Si quieres encriptar tu disco duro para proteger la información que contiene, es __muy recomendado__ que vacíes la información sin encriptar que contenía antes. Para esto puedes llenar el disco duro de información aleatoria antes de encriptarlo _(ejecutando `dd if=/dev/urandom of=/dev/ejemplo`)_, o para mas eficiencia, llenarlo de ceros una vez encriptado y que el cipher se encargue de que el disco se llene de información aleatoria _(ejecutando `dd if=/dev/zero of=/dev/mapper/ejemplo`)_ __[1]__.

Una vez encriptado el disco duro, toda la información que se guarde a partir de encriptarlo estará protegida. Sin embargo, si no se realiza este proceso antes, toda la información que se guardó en el disco duro anteriormente y que no ha sido sobrescrita todavía, _seguirá estando disponible (sin encriptar) para ser analizada con herramientas forensicas_.

El proceso mencionado anteriormente tomará horas, dependiendo de la velocidad y tamaño de tu dispositivo de almacenamiento. Si no tienes el tiempo para borrar toda la información antes de instalar nada, puedes instalar el sistema operativo de manera normal y una vez instalado llenar el disco creando un archivo que lo llene _(menos seguro)_ con `dd if=/dev/zero of=/home/usuario/archivo`.

Y cuando el archivo llene el sistema de archivos puedes borrarlo y habrás sobrescrito la información que había en el disco _(Este metodo no es tan seguro porque no garantiza que se sobrescriba por completo todos los sectores del disco, tenemos el sistema de ficheros como intermediario, que puede estar dejando espacios libres en el disco duro)_.

`El mejor balance entre eficiencia y seguridad viene de llenar la partición ya encriptada con ceros, y el cipher se encargará de llenar /dev/mapper/ejemplo de información aleatoria [1]`

- [1] https://wiki.archlinux.org/title/Dm-crypt/Drive_preparation
- [2] https://unix.stackexchange.com/questions/403174/why-do-you-need-to-clean-free-space-before-creating-a-luks-partition

# Restaurar partición /home encriptada

Si quieres utilizar un disco dedicado para /home, que esta encriptado, simplemente desbloquea tu volumen con `cryptsetup luksOpen` y al elegir el disco para `/home` utiliza el dispositivo desbloqueado `/dev/mapper/...` y elige no borrar la partición. Terminada la instalación restaura tu archivo de configuración de `dmcrypt` y la llave para desbloquear `/home` automáticamente

# Instalar solo scripts

Para instalar solo los scripts de este repositorio ejecuta desde el directorio del repositorio (con stow instalado):

```
mkdir -p "$HOME/.local/bin"; stow --target="${HOME}/.local/bin/" bin/
cp assets/pdf/help.pdf "${HOME}/.local/bin/"
```

# Cosas por hacer

- Añadir un README.md a dwm explicando que es un fork, los patches que hay, etc.
- Mejorar script de particionado/instalación
    - Preguntar si hacer `/dev/zero` a la partición, una vez ya encriptada
    - Permitir usar un disco "/home" ya encriptado, proveyendo al script de la llave
    - Arreglar instalación fuera del LiveISO

# Recursos/fuentes usadas y Créditos

- [3] https://gitlab.com/risingprismtv/single-gpu-passthrough
- [4] https://wiki.artixlinux.org/Main/InstallationWithFullDiskEncryption
- [5] https://wiki.gentoo.org/wiki/Dm-crypt
- [6] https://wiki.archlinux.org/title/dm-crypt/Encrypting_an_entire_system
- [7] https://jpedmedia.com/tutorials/installations/void_install/index.html
- [8] https://github.com/LukeSmithxyz/LARBS
- [9] https://github.com/LukeSmithxyz/voidrice
   - Créditos a Luke Smith por sus scripts, que sirvieron de referencia y base para implementar algunas de las funciones de este autoinstalador. Y por su build de st.
- [10] https://suckless.org
   - Créditos al equipo de suckless.org por todo el software suyo utilizado en este repositorio
- [11] https://github.com/siduck/dotfiles
    - Créditos a Sidhanth Rathod, de quien saque código para el widget de eww
- [12] Menú de aplicaciones: https://github.com/phillbush/xmenu
- [13] Salvapantallas: https://github.com/George-lewis/DVDBounce
- [14] Barra de estado: https://github.com/torrinfail/dwmblocks
- [15] Fondo de pantalla: https://gruvbox-wallpapers.pages.dev/
