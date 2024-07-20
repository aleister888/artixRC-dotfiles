<img src="https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/master/assets/artix-linux.png" align="left" height="100px" hspace="10px" vspace="0px">

# Artix (OpenRC) Dotfiles

Configuración de `Artix Linux OpenRC` y auto-instalador

<p float="center">
    <img src="https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/main/assets/screenshots/screenshot1.jpg" width="49%" />
    <img src="https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/main/assets/screenshots/screenshot2.jpg" width="49%" />
</p>

## Instalación

- Ejecuta como root:

```
curl -o stage1.sh https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/main/stage1.sh && chmod +x stage1.sh && ./stage1.sh
```

> [!WARNING]
> El instalador esta pensado para usarse solo desde el LiveISO de Artix Linux OpenRC

> [!NOTE]
> - La instalación toma _(con una conexión de `40mb/s`)_ unos `25 minutos` aproximadamente.
> - Una vez instalado el sistema, y después de iniciar sesión, pulsa `Ctrl+Alt+H` para abrir un [PDF](https://github.com/aleister888/artixRC-dotfiles/blob/main/assets/pdf/help.pdf) con información sobre como usar el administrador de ventanas _(dwm)_ y otra información útil _(como configurar ssh, firefox, etc.)_.

## Características

- Auto-particionado de discos, y soporte para encriptación con [LUKS](https://en.wikipedia.org/wiki/Linux_Unified_Key_Setup) (`/boot` queda sin encriptar)
- Soporte para `BIOS` y `UEFI`
- Entorno configurado para minimizar el número de archivos en `$HOME`
    - https://wiki.archlinux.org/title/XDG_Base_Directory

> [!CAUTION]
> Si quieres encriptar tu disco duro para proteger la información que contiene, es __obligatorio__ que lo vacíes de toda la información que contenía anteriormente, pues esta seguirá almacenada en el disco sin encriptar hasta que sea sobrescrita. Podemos hacer esto de 3 formas distintas, cada una menos segura/fiable que la anterior:
> - Llenar de información aleatoria el dispositivo: `dd if=/dev/urandom of=/dev/ejemplo`
> - Llenar la partición ya encriptada de zeros: `dd if=/dev/zero of=/dev/mapper/test`
> - Llenando el sistema de archivos (una vez ya instalado el sistema) de zeros creando un archivo que llene la partición, y luego borrandolo.
>   - Para esto ejecuta: `dd if=/dev/zero of=/disco/archivo` y borra el archivo cuando se llene el disco.

- [1] https://wiki.archlinux.org/title/Dm-crypt/Drive_preparation
- [2] https://unix.stackexchange.com/questions/403174/why-do-you-need-to-clean-free-space-before-creating-a-luks-partition

## Restaurar partición /home encriptada

Si quieres utilizar un disco dedicado para /home, que esta encriptado, simplemente desbloquea tu volumen con `cryptsetup luksOpen` y al elegir el disco para `/home` utiliza el dispositivo desbloqueado `/dev/mapper/...` y elige no borrar la partición. Terminada la instalación restaura tu archivo de configuración de `dmcrypt` y la llave para desbloquear `/home` automáticamente

> [!TIP]
> Para instalar solo los scripts de este repositorio ejecuta _desde el directorio del repositorio_ (con stow instalado):
> - `mkdir -p "$HOME/.local/bin"; stow --target="${HOME}/.local/bin/" bin/`

## Cosas por hacer

- Limpiar el código de xmenu
- Arreglar las entradas MAN y código sobre las flags de uso
- Añadir README explicativo a: bin, assets, dwmblocks y xmenu.
- Reevisar todo el código de dwm y st (Identación y añadir comentarios en castellano)
- Crear un setup equivalente para [OpenBSD](https://github.com/aleister888/openBSD-dotfiles)
- Añadir copias de seguridad incrementales a crypt-backup
- Mejorar script de particionado/instalación
    - Preguntar si hacer `/dev/zero` a la partición, una vez ya encriptada
    - Permitir usar un disco "/home" ya encriptado, proveyendo al script de la llave
    - Arreglar instalación fuera del LiveISO

## Recursos/fuentes usadas y Créditos

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
- [16] Filtro para mpv: https://github.com/hhirtz/mpv-retro-shaders
- [17] Script para las contraseñas: https://github.com/neelkamal0310/keepassxc-dmenu/blob/main/keepmenu
