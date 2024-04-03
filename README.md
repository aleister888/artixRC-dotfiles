<img src="https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/master/assets/artix-linux.png" align="left" height="100px" hspace="10px" vspace="0px">

## Artix (OpenRC) Dotfiles

Configuración de `Artix Linux OpenRC` y auto-instalador

<p float="center">
    <img src="https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/main/assets/screenshot1.jpg" width="49%" />
    <img src="https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/main/assets/screenshot2.jpg" width="49%" />
</p>

## Instalación

- Ejecuta el script con:
    - `curl -o stage1.sh https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/main/stage1.sh`
    - `chmod +x stage1.sh && ./stage1.sh`
- Una vez instalado el sistema, después de iniciar sesión; puedes pulsar `Ctrl+Alt+H` para abrir un PDF con información de como usar tu instalación y otra información útil.

# TODO

- Establecer apps por defecto en update.sh
- Configurar LF como administrador de archivos por defecto
- Mejorar stage1.sh y añadir encriptación del disco duro
- Añadir capturas a la guía sobre VFIO
- Clasificar paquetes en stage3 (librerias, aplicaciones, etc), para mantener la lista mas fácilmente
- Arreglar el script wakeme
- Borde de color especial para ventanas sticky
- Solo instalar bluetooth si se detecta un dispositivo bluetooth
