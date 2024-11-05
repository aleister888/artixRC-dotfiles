> [!CAUTION]
> - DWM está configurado para compilar en x86-64-v3 (config.mk: march=x86-64-v3)

Puedes consultar los atajos de teclado leyendo el código en [config.def.h](https://github.com/aleister888/artixRC-dotfiles/blob/main/dwm/config.def.h) (`static const Key keys[]`). O en la [guía de usuario](https://github.com/aleister888/artixRC-dotfiles/blob/main/assets/pdf/help.pdf) (_Ctrl+Alt+H_ para abrirla).

## Modificaciones

- Al iniciar dwm se ejecuta un script que inicia el entorno de escritorio: [dwm-autostart-20210120-cb3f58a.diff](http://dwm.suckless.org/patches/autostart/dwm-autostart-20210120-cb3f58a.diff)
- Las ventanas se mantienen en su espacio al reiniciar dwm: [dwm-preserveonrestart-6.3.diff](http://dwm.suckless.org/patches/preserveonrestart/dwm-preserveonrestart-6.3.diff)
- Se pueden ajustar el porcentaje de espacio vertical que ocupan las ventanas: [dwm-cfacts-20200913-61bb8b2.diff](http://dwm.suckless.org/patches/cfacts/dwm-cfacts-20200913-61bb8b2.diff)
- Las ventanas tienen una separación ajustable entre ellas: [dwm-fullgaps-6.4.diff](http://dwm.suckless.org/patches/fullgaps/dwm-fullgaps-6.4.diff)
- Los ajustes de ventana son para cada espacio en vez de globales [dwm-pertag-20200914-61bb8b2.diff](http://dwm.suckless.org/patches/pertag/dwm-pertag-20200914-61bb8b2.diff)
- Las ventanas se pueden re-dimensionar desde cualquiera de sus cuatro esquinas: [dwm-resizecorners-6.3.diff](https://github.com/bakkeby/patches/blob/master/dwm/dwm-resizecorners-6.3.diff)
- La posición y tamaño de las ventanas flotantes se guardan en memoria: [dwm-savefloats-20181212-b69c870.diff](http://dwm.suckless.org/patches/save_floats/dwm-savefloats-20181212-b69c870.diff)
- Arreglar la opacidad de los bordes de ventanas: [dwm-fixborders-6.2.diff](https://dwm.suckless.org/patches/alpha/dwm-fixborders-6.2.diff)
- Atajos de teclado para organizar el stack: [dwm-stacker-6.2.diff](https://dwm.suckless.org/patches/stacker/dwm-stacker-6.2.diff)
- Las aplicaciones abiertas por una terminal ocupan el espacio de dicha terminal: [dwm-swallow-6.3.diff](https://dwm.suckless.org/patches/swallow/dwm-swallow-6.3.diff)
- Atajo de teclado para cambiar entre espacios ocupados fácilmente: [dwm-shiftviewclients-6.2.diff](https://github.com/bakkeby/patches/blob/master/dwm/dwm-shiftviewclients-6.2.diff)
- Ventanas semi-visibles: [dwm-renamedscratchpads-6.3.diff](https://github.com/bakkeby/patches/blob/master/dwm/dwm-renamedscratchpads-6.3.diff)
- Ventanas persistentes: [dwm-sticky-6.4.diff](http://dwm.suckless.org/patches/sticky/dwm-sticky-6.4.diff)
- Layout deck: [dwm-deck-6.2.diff](http://dwm.suckless.org/patches/deck/dwm-deck-6.2.diff)
		- [dwm-deck-tilegap-6.1.diff](http://dwm.suckless.org/patches/deck/dwm-deck-tilegap-6.1.diff)
- Pantalla completa falsa: [dwm-selectivefakefullscreen-20201130-97099e7.diff](https://dwm.suckless.org/patches/selectivefakefullscreen/dwm-selectivefakefullscreen-20201130-97099e7.diff)
- __Modificaciones a la barra de tareas:__
	- Los espacios ocupados tienen iconos en vez de números: [dwm-alttagsdecoration-2020010304-cb3f58a.diff](http://dwm.suckless.org/patches/alttagsdecoration/dwm-alttagsdecoration-2020010304-cb3f58a.diff)
	- El tamaño de la barra se puede configurar: [dwm-bar-height-spacing-6.3.diff](http://dwm.suckless.org/patches/bar_height/dwm-bar-height-spacing-6.3.diff)
	- Hacer clic derecho abre un menú para elegir el layout: [dwm-layoutmenu-6.2.diff](http://dwm.suckless.org/patches/layoutmenu/dwm-layoutmenu-6.2.diff)
	- Los espacios seleccionados tienen una barra como indicador: [dwm-underlinetags-6.2.diff](http://dwm.suckless.org/patches/underlinetags/dwm-underlinetags-6.2.diff)
		- Además, los espacios se colorean al seleccionarlos:
		- https://github.com/fitrh/dwm/commit/d139433339ed9289293d7353c279052d7fe3507e
		- https://github.com/fitrh/dwm/commit/4e8cc1d41979ab729229940bd85825326d9c66ba
	- Se pueden usar colores en la barra de estado: [dwm-status2d-systray-6.4.diff](https://dwm.suckless.org/patches/status2d/dwm-status2d-6.3.diff)
	- Las ventanas flotantes nuevas aparecerán centradas: [dwm-alwayscenter-20200625-f04cac6.diff](http://dwm.suckless.org/patches/alwayscenter/dwm-alwayscenter-20200625-f04cac6.diff)
	- Las ventanas nuevas aparecerán al final del stack: [dwm-attachbottom-6.3.diff](http://dwm.suckless.org/patches/attachbottom/dwm-attachbottom-6.3.diff)
