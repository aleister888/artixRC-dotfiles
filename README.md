<img src="https://raw.githubusercontent.com/aleister888/artix-installer/master/assets/artix-linux.png" align="left" height="90px" hspace="10px" vspace="0px">

### Artix Linux (OpenRC) - dotfiles

----

Auto-instalador de Artix Linux (OpenRC) con dmw, st, dmenu y mi configuración personal.

<p float="center">
	<img src="https://raw.githubusercontent.com/aleister888/artix-installer/main/assets/screenshots/screenshot1.jpg" width="49%" />
	<img src="https://raw.githubusercontent.com/aleister888/artix-installer/main/assets/screenshots/screenshot2.jpg" width="49%" />
</p>

---

#### Instalación

- Ejecuta como root:

```bash
bash <(curl https://raw.githubusercontent.com/aleister888/artix-installer/main/stage1.sh)
```

> [!WARNING]
> El instalador esta pensado para usarse solo desde el LiveISO de Artix Linux OpenRC. No ejecutes este programa desde tu propia instalación.

> [!NOTE]
> La instalación toma unos `30-45 minutos` aproximadamente.

---

#### Características

- **Encriptación**: `/` y `/home` encriptados; `/boot` no encriptado.
- Soporte para **btrfs** y **ext4**
- Compatible con **BIOS** y **UEFI**.
- Configuración automática de `Xorg` y `eww` basada en el DPI y la resolución.
- Entorno limpio y organizado según el estándar [XDG Base Directory](https://wiki.archlinux.org/title/XDG_Base_Directory).

---

#### Importante: Preparación del disco para encriptación

> [!CAUTION]
> Si activas la encriptación, **limpia el disco antes de usar el instalador** para proteger los datos residuales:
> ```bash
> dd if=/dev/urandom of=/dev/sdX
> ```
> Este proceso puede tardar horas según el tamaño del disco.

##### Alternativa

Tras la instalación, llena el espacio con un archivo temporal:

```bash
dd if=/dev/zero of=/home/usuario/archivo
```

Más detalles en: [Arch Wiki - dm-crypt](https://wiki.archlinux.org/title/Dm-crypt/Drive_preparation)

---

#### Tareas por realizar

- Modularizar s3 dividiendo el script de instalación en diferentes scripts.
	- De esta forma se podran instalar funcionalidades incluso despúes de haber instalado el sistema p.e. configurar libvirt.
- Arreglar la lógica de s1-s2 para permitir instalaciones fuera del LiveISO

---

#### Créditos y Referencias

Agradecimientos especiales a:

- [Luke Smith](https://github.com/LukeSmithxyz) por la inspiración y sus scripts.
- [suckless.org](https://suckless.org) por las herramientas utilizadas.
- [Sidhanth Rathod](https://github.com/siduck/dotfiles) por el widget de `eww`.

Referencias:

1. [Artix Linux Wiki](https://wiki.artixlinux.org/Main/InstallationWithFullDiskEncryption)
2. [Arch Wiki](https://wiki.archlinux.org/title/dm-crypt/Encrypting_an_entire_system)
3. [Gentoo Wiki](https://wiki.gentoo.org/wiki/Dm-crypt)
