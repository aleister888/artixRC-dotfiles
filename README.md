<img src="https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/master/assets/artix-linux.png" align="left" height="100px" hspace="10px" vspace="0px">

# Artix (OpenRC) Dotfiles

Configuración de `Artix Linux OpenRC` y auto-instalador

<p float="center">
    <img src="https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/main/assets/screenshot1.jpg" width="49%" />
    <img src="https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/main/assets/screenshot2.jpg" width="49%" />
</p>

# Instalación

- Ejecuta el script con:

```
curl -o stage1.sh https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/main/stage1.sh
```

```
chmod +x stage1.sh && ./stage1.sh
```

- Una vez instalado el sistema, y después de iniciar sesión, pulsa `Ctrl+Alt+H` para abrir un PDF con información de como usar tu instalación y otra información útil.

# Características

- Encriptación (`/` y `/home`. `/boot` no esta encriptado) de disco
- Soporte para `btrfs`, `ext4` y `xfs`
- Soporte para `BIOS` y `UEFI`
- Configuración de `Xorg` y `eww` automática basada en tu DPI y resolución
    - _Además; dwm, st y dmenu se compilan con el tamaño de fuente recomendado_

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

[1] https://wiki.archlinux.org/title/Dm-crypt/Drive_preparation

[2] https://unix.stackexchange.com/questions/403174/why-do-you-need-to-clean-free-space-before-creating-a-luks-partition

# Restaurar partición /home encriptada

Si quieres utilizar un disco dedicado para /home, que esta encriptado, simplemente desbloquea tu volumen con `cryptsetup luksOpen` y al elegir el disco para `/home` utiliza el dispositivo desbloqueado `/dev/mapper/...` y elige no borrar la partición. Terminada la instalación restaura tu archivo de configuración de `dmcrypt` y la llave para desbloquear `/home` automáticamente

# Cosas por hacer

- Configurar automáticamente Firefox con user-overrides.js
    - _DuckDuckGO como buscador predeterminado_
    - _Desactivar el baúl de contraseñas, cuentas de Mozilla y Pocket_
    - _Añadir buscadores que usan OpenSearch (Arch Wiki, Github, ...)_
    - _Activar extensiones instaladas_
- Elegir las apps a instalar en un bucle que se acaba cuando confirmamos los cambios (Como el formateo de los discos en stage1.sh)
- Utilizar una función para todos los menús de whiptail
- Añadir capturas a la guía sobre VFIO
- Permitir usar un disco "/home" ya encriptado, proveyendo al script de la llave

# Referencias y créditos

[1] https://wiki.artixlinux.org/Main/InstallationWithFullDiskEncryption

[2] https://wiki.gentoo.org/wiki/Dm-crypt

[3] https://wiki.archlinux.org/title/dm-crypt/Encrypting_an_entire_system

[4] https://jpedmedia.com/tutorials/installations/void_install/index.html

[5] larbs.xyz/larbs.sh
