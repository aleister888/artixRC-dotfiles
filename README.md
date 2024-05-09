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
curl -o stage1.sh https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/main/stage1.sh
```

```
chmod +x stage1.sh && ./stage1.sh
```

- Una vez instalado el sistema, y después de iniciar sesión, pulsa `Ctrl+Alt+H` para abrir un PDF con información de como usar tu instalación y otra información útil.

La instalación toma, con una conexión de `40mb/s`, unos `25 minutos` (aproximadamente).

# Características

- Encriptación (`/` y `/home`. `/boot` no esta encriptado) de disco
- Soporte para `btrfs`, `ext4` y `xfs`
- Soporte para `BIOS` y `UEFI`
- Configuración de `Xorg` y `eww` automática, basada en el DPI y resolución de la pantalla.
    - _Además; dwm, st y dmenu se compilan con el tamaño de fuente recomendado_
- Entorno configurado para minimizar el número de archivos en `~/` 
    - https://wiki.archlinux.org/title/XDG_Base_Directory

# Atención!

Si quieres utilizar encriptación para proteger tus datos, es __obligatorio__ vaciar el disco antes de la instalación llenándolo con información aleatoria. En caso contrario, la información que no se haya sobrescrito después de encriptar el disco _seguirá estando disponible para ser analizada con herramientas forensicas_.

Para borrar toda la información contenida en el disco ejecuta: _(Sustituye el ejemplo por tu dipositivo)_

```
dd if=/dev/urandom of=/dev/ejemplo
```

Este proceso tomará horas, dependiendo de la velocidad y tamaño de tu dispositivo de almacenamiento. Si no tienes el tiempo para borrar toda la información, puedes instalar el sistema operativo de manera normal y una vez instalado llenar el disco crendo un archivo que lo llene _(menos seguro)_ con: _(Sustituye el archivo por uno que se encuentre en un directorio contenido por el disco que quieres asegurar)_

```
dd if=/dev/zero of=/home/usuario/archivo
```

Y cuando el archivo llene el sistema de archivos puedes borrarlo y habrás sobrescrito la información que había en el disco _(Este metodo no es tan seguro porque no garantiza que se sobrescriba por completo todos los sectores del disco, tenemos el sistema de ficheros como intermediario)_.

`El mejor balance entre eficiencia y seguridad viene de llenar la partición ya encriptada con ceros, y el cipher se encargará de llenar /dev/mapper/ejemplo de información aleatoria [1]`

- [1] https://wiki.archlinux.org/title/Dm-crypt/Drive_preparation
- [2] https://unix.stackexchange.com/questions/403174/why-do-you-need-to-clean-free-space-before-creating-a-luks-partition

# Restaurar partición /home encriptada

Si quieres utilizar un disco dedicado para /home, que esta encriptado, simplemente desbloquea tu volumen con `cryptsetup luksOpen` y al elegir el disco para `/home` utiliza el dispositivo desbloqueado `/dev/mapper/...` y elige no borrar la partición. Terminada la instalación restaura tu archivo de configuración de `dmcrypt` y la llave para desbloquear `/home` automáticamente

# Cosas por hacer

- Preguntar si hacer `/dev/zero` a la partición, una vez ya encriptada
- Configurar automáticamente Firefox con user-overrides.js
    - _Desactivar el baúl de contraseñas_
- Añadir capturas a la guía sobre VFIO
- Permitir usar un disco "/home" ya encriptado, proveyendo al script de la llave
- Añadir la opción de instalar KDE con SDDM en vez de dwm

# Referencias y créditos

- [1] https://wiki.artixlinux.org/Main/InstallationWithFullDiskEncryption
- [2] https://wiki.gentoo.org/wiki/Dm-crypt
- [3] https://wiki.archlinux.org/title/dm-crypt/Encrypting_an_entire_system
- [4] https://jpedmedia.com/tutorials/installations/void_install/index.html
- [5] https://github.com/LukeSmithxyz/LARBS
- [6] https://github.com/LukeSmithxyz/voidrice
    - Créditos a Luke Smith por sus scripts, que sirvieron de referncia y base para implementar algunas de las funciones de este autoinstalador. Y por su build de st.
- [7] https://suckless.org
    - Créditos al equipo de suckless.org por todo el software suyo utilizado en este repositorio
- [8] https://github.com/siduck/dotfiles
    - Créditos a Sidhanth Rathod, de quien saque código para el widget de eww
- [9] https://github.com/phillbush/xmenu
- [10] https://github.com/George-lewis/DVDBounce
