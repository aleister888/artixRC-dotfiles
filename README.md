<img src="https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/master/assets/artix-linux.png" align="left" height="90px" hspace="10px" vspace="0px">

### Artix Linux (OpenRC) - dotfiles

----

Auto-instalador de Artix Linux (OpenRC) con dmw, st, dmenu y mi configuración personal.

<p float="center">
	<img src="https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/main/assets/screenshots/screenshot1.jpg" width="49%" />
	<img src="https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/main/assets/screenshots/screenshot2.jpg" width="49%" />
</p>

---

#### Instalación

- Utiliza `su` para ejecutar como root:

```
curl -o stage1.sh https://raw.githubusercontent.com/aleister888/artixRC-dotfiles/main/stage1.sh && chmod +x stage1.sh && ./stage1.sh
```

> [!WARNING]
> El instalador esta pensado para usarse solo desde el LiveISO de Artix Linux OpenRC. No ejecutes este programa desde tu propia instalación.

---

#### Tareas por realizar

- Mejorar la forma en la que se detecta el UUID al instalar grub (s2)
- Actualizar PDF
- Si se detecta una resolución 2160p o más grande hacer un script TUI para configurar las aplicaciones acordemente
- Añadir copias de seguridad incrementales a `crypt-backup` y corregir el script
- Corregir los comentarios de mis builds suckless
- Modularizar s3 dividiendo el script de instalación en diferentes scripts.
	- De esta forma se podran instalar funcionalidades incluso despúes de haber instalado el sistema p.e. configurar libvirt.
- Arreglar la lógica de s1-s2 para permitir instalaciones fuera del LiveISO
- Preguntar si hacer `/dev/zero` a la partición ya encriptada
	- https://wiki.archlinux.org/title/Data-at-rest_encryption#Preparing_the_disk
