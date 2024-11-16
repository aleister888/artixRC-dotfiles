// Consulta el archivo LICENSE para los detalles de derechos de autor y licencia.

// Tamaño de la fuente y los bordes (1080p)
static const char *fonts[] = { "Iosevka Term SS05:pixelsize=24:bold" };
static unsigned int border_width = 5;

static int topbar         = 1;    // Mostar en la parte superior (-b = inferior)
static int centered       = 1;    // Centrar la ventana (-c)
static int min_width      = 500;  // Mínimo de caractéres cuando esta centrado
static const int user_bh  = 0;    // Añadir este número de pixeles al ancho
static const char *prompt = NULL; // Texto a mostrar a la izquierda (-p)
static unsigned int lines = 6;    // Número de lineas (-l)

static const char *colors[SchemeLast][2] = {
	// Colores       Fuente     Fondo
	[SchemeNorm] = { "#EBDBB2", "#1D2021" },
	[SchemeSel]  = { "#EBDBB2", "#282828" },
	[SchemeOut]  = { "#000000", "#00ffff" },
};

// Caractéres no considerados parte de una palabra al borrar palabras
// Por ejemplo: " /?\"&[]"
static const char worddelimiters[] = " ";
