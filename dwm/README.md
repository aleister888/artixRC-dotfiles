# Mi build de dwm

## FAQ

> Cuales son los atajos de teclado?

Puedes consultarlos leyendo el código en [config.def.h](https://github.com/aleister888/artixRC-dotfiles/blob/main/dwm/config.def.h). O leyéndolos en la [guía de usuario](https://github.com/aleister888/artixRC-dotfiles/blob/main/assets/pdf/help.pdf)

## Modificaciones

- Modificaciones a la barra de tareas:
    - Los espacios ocupados tienen [iconos en vez de números](http://dwm.suckless.org/patches/alttagsdecoration/dwm-alttagsdecoration-2020010304-cb3f58a.diff)
    - El tamaño de la barra se puede [configurar](http://dwm.suckless.org/patches/bar_height/dwm-bar-height-spacing-6.3.diff)
    - La barra se puede [separar de los bordes](http://dwm.suckless.org/patches/barpadding/dwm-barpadding-20211020-a786211.diff) de la pantalla
    - Hacer clic derecho abre un [menú](http://dwm.suckless.org/patches/layoutmenu/dwm-layoutmenu-6.2.diff) para elegir el layout
    - El color de cada parte de la barra se puede [cambiar individualmente](http://dwm.suckless.org/patches/colorbar/dwm-colorbar-6.3.diff)
    - Los espacios seleccionados tienen una [barra](http://dwm.suckless.org/patches/underlinetags/dwm-underlinetags-6.2.diff) como indicador
    - La barra de estado se muestra para [todos los monitores](http://dwm.suckless.org/patches/statusallmons/dwm-statusallmons-6.2.diff)
    - La barra de estado permite [mostrar colores](http://dwm.suckless.org/patches/status2d/dwm-status2d-systray-6.4.diff) y tiene una barra del sistema incorporada
- Las ventanas flotantes nuevas aparecerán [centradas](http://dwm.suckless.org/patches/alwayscenter/dwm-alwayscenter-20200625-f04cac6.diff)
- Las ventanas nuevas aparecerán al final del [stack](http://dwm.suckless.org/patches/attachbottom/dwm-attachbottom-6.3.diff)
- Al iniciar dwm se ejecuta en [script](http://dwm.suckless.org/patches/autostart/dwm-autostart-20210120-cb3f58a.diff) para iniciar el entorno de escritorio
- Las ventanas se mantienen en su espacio al [reiniciar](http://dwm.suckless.org/patches/preserveonrestart/dwm-preserveonrestart-6.3.diff) dwm
- Se pueden ajustar el porcentaje de [espacio vertical](http://dwm.suckless.org/patches/cfacts/dwm-cfacts-20200913-61bb8b2.diff) que ocupan las ventanas
- Las ventanas tienen cierta [separación/huecos](http://dwm.suckless.org/patches/fullgaps/dwm-fullgaps-6.4.diff) entre ellas
- Los ajustes de ventana son para cada [espacio](http://dwm.suckless.org/patches/pertag/dwm-pertag-20200914-61bb8b2.diff) en vez de globales
- Las ventanas se pueden [re-dimensionar](https://github.com/bakkeby/patches/blob/master/dwm/dwm-resizecorners-6.3.diff) desde cualquiera de sus cuatro esquinas
- La posición y tamaño de las [ventanas flotantes](http://dwm.suckless.org/patches/save_floats/dwm-savefloats-20181212-b69c870.diff) se guardan en memoria
- Arreglar la opacidad de los [bordes](https://dwm.suckless.org/patches/alpha/dwm-fixborders-6.2.diff) de ventanas
- Atajos de teclado para [organizar el stack](https://dwm.suckless.org/patches/stacker/dwm-stacker-6.2.diff)
- Las [aplicaciones abiertas por una terminal](https://dwm.suckless.org/patches/swallow/dwm-swallow-6.3.diff) ocupan el espacio de dicha terminal
- Cada [espacio](http://dwm.suckless.org/patches/taglayouts/dwm-taglayouts-6.4.diff) tiene su plan de distribución definido
- Atajo de teclado para [cambiar entre espacios ocupados](https://github.com/bakkeby/patches/blob/master/dwm/dwm-shiftviewclients-6.2.diff) fácilmente
- [Scratchpads](https://github.com/bakkeby/patches/blob/master/dwm/dwm-renamedscratchpads-6.3.diff) (Ventanas semi-visibles)
- [Ventanas sticky](http://dwm.suckless.org/patches/sticky/dwm-sticky-6.4.diff) (Ventanas persistentes)
