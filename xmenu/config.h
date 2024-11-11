// Consulta el archivo LICENSE para los detalles de derechos de autor y licencia.

static struct Config config = {
	// Fuente
	.font = "Iosevka Fixed SS05:bold:pixelsize=22",

	// Esquema de colores
	.background_color = "#222222",    // Color del fondo (Normal)
	.foreground_color = "#bbbbbb",    // Color de la fuente (Normal)
	.selbackground_color = "#222222", // Color del fondo (Selección)
	.selforeground_color = "#ECECD9", // Color de la fuente (Selección)
	.separator_color = "#282828",     // Color del separador
	.border_color = "#545454",        // Color del borde

	// Tamaño (en píxeles)
	.width_pixels = 64,    // Anchura mínima del menu
	.height_pixels = 36,   // Altura de las entradas del menu
	.border_pixels = 4,    // Tamaño del borde
	.separator_pixels = 1, // Espacio alrededor de los separadores
	.gap_pixels = 4,       // Espaciado entre menus
	.max_items = 0,        // Número máximo de elementos de un menú, 0 para calcularlo basado en la altura del monitor

	// Alineación del texto:
	// - LeftAlignment
	// - CenterAlignment
	// - RightAlignment
	.alignment = LeftAlignment,

	// Los ajustes a partir de aquí no pueden establecerse en X resources

	// Geometría del triangulo a la derecha de los menus
	.triangle_width = 6,
	.triangle_height = 8,

	// El tamaño de los iconos es .height_pixels - .iconpadding * 2
	.iconpadding = 4,

	// Área alrededor del icono, el triangulo y el separador
	.horzpadding = 6,
};

// Atajos de teclado
#define KSYMFIRST   XK_VoidSymbol // Selecciona el primer ítem
#define KSYMLAST    XK_VoidSymbol // Selecciona el último ítem
#define KSYMUP      XK_VoidSymbol // Selecciona el ítem anterior
#define KSYMDOWN    XK_VoidSymbol // Selecciona el próximo ítem
#define KSYMLEFT    XK_VoidSymbol // Cierra el menú actual
#define KSYMRIGHT   XK_VoidSymbol // Ingresa al ítem seleccionado
