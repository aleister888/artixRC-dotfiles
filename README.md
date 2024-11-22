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

- Arreglar bug (instalaciones sin encriptar no funcionan)
- Crear branch para el desarrollo y actualizar el README y los script consecuentemente
- Actualizar PDF
- No configurar ajustes relacionados con el DPI en s1-s3.
	- Añadir a autostart.sh una función para detectar si el DPI está configurado
	- En caso de que no, abrir una terminal con un script de configuración
- Añadir copias de seguridad incrementales a `crypt-backup`.
- Arreglar las entradas MAN y código sobre las flags de uso (st, dmenu).
- Modularizar s3 dividiendo el script de instalación en diferentes scripts.
- Arreglar errores con GRUB en algunas placas bases (UEFI)
- Simplificar y mejorar s1 y s2
	- Permitir solo instalaciones encriptadas con BTRFS
	- Implementar ayuda para restaurar discos /home ya existentes
		- Permitir usar un disco ya encriptado, proveyendo la llave de desbloqueo
	- Arreglar la lógica de s1-s2 para permitir instalaciones fuera del LiveISO
- Preguntar si hacer `/dev/zero` a la partición ya encriptada
	- https://wiki.archlinux.org/title/Data-at-rest_encryption#Preparing_the_disk
