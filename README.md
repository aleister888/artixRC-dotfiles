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

- Una vez instalado el sistema, después de iniciar sesión; puedes pulsar `Ctrl+Alt+H` para abrir un PDF con información de como usar tu instalación y otra información útil.

# Restaurar partición /home encriptada

Si quieres utilizar un disco dedicado para /home, que esta encriptado, simplemente desbloquea tu volumen con `cryptsetup luksOpen` y al elegir el disco para `/home` utiliza el dispositivo desbloqueado `/dev/mapper/...` y elige no borrar la partición. Terminada la instalación restaura tu archivo de configuración de `dmcrypt` y la llave para desbloquear `/home` automáticamente

# TODO

- Elegir las apps a instalar en un bucle que se acaba cuando confirmamos los cambios (Como el formateo de los discos en stage1.sh)
- Añadir capturas a la guía sobre VFIO
- Permitir usar un disco "/home" ya encriptado, proveyendo al script de la llave

# Referencias

[1] https://wiki.artixlinux.org/Main/InstallationWithFullDiskEncryption

[2] https://wiki.gentoo.org/wiki/Dm-crypt

[3] https://wiki.archlinux.org/title/dm-crypt/Encrypting_an_entire_system

[4] https://jpedmedia.com/tutorials/installations/void_install/index.html
