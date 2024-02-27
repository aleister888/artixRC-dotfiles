## Artix (OpenRC) Dotfiles

Configuración de `Artix` y auto-instalador

## Steps to Install

- Fase 1 (Instalación Base):
    - Inicia sesión como root e instala wget y parted desde la ISO con `pacman -Sy wget parted`
    - Descarga el script con: `wget https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/main/setup.sh`. Y ejecutalo
- Stage 2 (Software & Config Installation):
    - Configura tu usuario regular (añadelo al grupo wheel y dale un directorio home)
        - Inicia sesión como el usuario que acabas de crear
    - Clona este repositorio en `~/.dotfiles` con: `git clone https://github.com/aleister888/artixRC-dotfiles.git ~/.dotfiles`
    - cd `~/.dotfiles` y ejecuta `./install.sh`

- Esto instalará mis archivos de configuración ten encuenta que hay scritps que estan pensados para funcionar con mi hardware, por ejemplo, `switch-audio`, script pensado para funcionar con mi tarjeta de audio y mi placa base.
