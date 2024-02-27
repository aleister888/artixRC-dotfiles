## Artix (OpenRC) Dotfiles

Configuración de `Artix` y auto-instalador

## Steps to Install

- Fase 1 (Instalación Base):
    - Inicia sesión como root e instala wget y parted desde la ISO con `pacman -Sy wget parted`
    - Descarga la 1a parte del script con: `wget https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/main/stage1.sh`. Y ejecutalo
- Stage 2 (Software & Config Installation):
    - Ya estas dentro de tu instalación de Artix como root!
    - Instala wget con `pacman -S wget`
    - Descarga la 2a parte del script con: `wget https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/main/stage2.sh`. Y ejecutala
