// Consulta el archivo LICENSE para los detalles de derechos de autor y licencia.

// Tamaño de las fuentes
static char *font = "Iosevka Nerd Font:bold:pixelsize=24"; // Fuente principal
static char *font2[] = { "Symbols Nerd Font:style=Regular:pixelsize=20" }; // Fuente secundaria

static int borderpx = 2; // Margen

// Qué programa se ejecuta con `exec` depende de estas reglas de precedencia:
// 1: Programa pasado con -e
// 2: `scroll` y/o `utmp`
// 3: Variable de entorno SHELL
// 4: Valor de `shell` en /etc/passwd
// 5: Valor de `shell` en config.h
//
static char *shell = "/bin/sh";
char *utmp = NULL;
// Programa de desplazamiento: para habilitar, usa una cadena como "scroll"
char *scroll = NULL;
char *stty_args = "stty raw pass8 nl -echo -iexten -cstopb 38400";

// Secuencia de identificación devuelta en DA y DECID
char *vtiden = "\033[?6c";

// Kerning / multiplicadores del cuadro delimitador de caracteres
static float cwscale = 1.0;
static float chscale = 1.0;

// Cadena de delimitadores de palabras
// Ejemplo más avanzado: L" `'\"()[]{}"
wchar_t *worddelimiters = L" ";

// Tiempos de espera para selección (en milisegundos)
static unsigned int doubleclicktimeout = 300;
static unsigned int tripleclicktimeout = 600;

// Pantallas alternativas
int allowaltscreen = 1;

// Permitir ciertas operaciones de ventana no interactivas
// (inseguras) como: establecer el texto del portapapeles
int allowwindowops = 0;

// Rango de latencia de dibujo en ms - desde nuevo contenido/pulsación de tecla/etc. hasta el dibujo
// Dentro de este rango, st dibuja cuando el contenido deja de llegar (inactividad). Generalmente
// está cerca de `minlatency`, pero espera más tiempo para actualizaciones lentas y evitar un
// dibujo parcial. Un `minlatency` bajo causará más desgarro y parpadeo, ya que puede "detectar"
// la inactividad demasiado pronto
static double minlatency = 8;
static double maxlatency = 33;

// Timeout de parpadeo (establecer en 0 para deshabilitar el parpadeo)
// para el atributo de parpadeo del terminal
static unsigned int blinktimeout = 800;

// Grosor del subrayado y de los cursores de barra
static unsigned int cursorthickness = 2;

// Volumen del timbre. Debe ser un valor entre -100 y 100. Usa 0 para desactivarlo
static int bellvolume = 0;

// Valor predeterminado de TERM
char *termname = "st-256color";

// Espacios por tabulación
//
// Cuando cambies este valor, no olvides adaptar el valor de »it« en
// st.info e instalar el st.info en el entorno donde uses esta versión de st
// 	it#$tabspaces,
//
// En segundo lugar, asegúrate de que tu kernel no expanda tabulaciones. Al ejecutar `stty -a`
// debería aparecer »tab0«. Puedes decirle al terminal que no expanda tabulaciones
// ejecutando el siguiente comando:
// 	stty tabs

unsigned int tabspaces = 8;

// Opacidad del fondo
float alpha = 0.8;

// Colores del terminal (los 16 primeros se usan en secuencias de escape)
static const char *colorname[] = {
	// 8 colores normales
	[0]  = "#101010", // Contraste fuerte: #1d2021 / contraste suave: #32302f
	[1]  = "#cc241d", // Rojo
	[2]  = "#98971a", // Verde
	[3]  = "#d79921", // Amarillo
	[4]  = "#458588", // Azul
	[5]  = "#b16286", // Magenta
	[6]  = "#689d6a", // Cian
	[7]  = "#a89984", // Blanco

	// 8 colores brillantes
	[8]  = "#928374", // Negro
	[9]  = "#fb4934", // Rojo
	[10] = "#b8bb26", // Verde
	[11] = "#fabd2f", // Amarillo
	[12] = "#83a598", // Azul
	[13] = "#d3869b", // Magenta
	[14] = "#8ec07c", // Cian
	[15] = "#ebdbb2", // Blanco
};

// Colores predeterminados (índice de colorname)
// Fuente, fondo, cursor, cursor invertido
unsigned int defaultfg = 15;
unsigned int defaultbg = 0;
unsigned int defaultcs = 15;
static unsigned int defaultrcs = 257;

// Forma predeterminada del cursor
// 2: Bloque ("█")
// 4: Subrayado ("_")
// 6: Barra ("|")
// 7: Muñeco de nieve ("☃")
static unsigned int cursorshape = 2;

// Número predeterminado de columnas y filas
static unsigned int cols = 80;
static unsigned int rows = 24;

// Color y forma predeterminados del cursor del ratón
static unsigned int mouseshape = XC_xterm;
static unsigned int mousefg = 7;
static unsigned int mousebg = 0;

// Color utilizado para mostrar atributos de fuente cuando fontconfig
// selecciona una fuente que no coincide con las solicitadas
static unsigned int defaultattr = 11;

// Forzar selección/atajos del ratón mientras la máscara está activa
// (cuando MODE_MOUSE está activado). Ten en cuenta que si quieres
// usar `ShiftMask` con `selmasks`, establece esto en otro modificador,
// o en 0 para no usarlo
static uint forcemousemod = ShiftMask;

// Atajos internos del ratón
// Ten en cuenta que mapear `Button1` impedirá la selección
static MouseShortcut mshortcuts[] = {
	// Modificador	Botón		Función		Argumento	Liberación
	{ XK_ANY_MOD,	Button2,	selpaste,	{.i = 0}, 1 },
	{ ShiftMask,	Button4,	ttysend,	{.s = "\033[5;2~"} },
	{ ShiftMask,	Button5,	ttysend,	{.s = "\033[6;2~"} },
	{ XK_ANY_MOD,	Button4,	kscrollup,	{.i = 1}, 0, /* !alt */ -1 },
	{ XK_ANY_MOD,	Button5,	kscrolldown,	{.i = 1}, 0, /* !alt */ -1 },
};

// Atajos internos de teclado
#define MODKEY Mod1Mask
#define TERMMOD (ControlMask|ShiftMask)

static char *openurlcmd[] = { "/bin/sh", "-c", "st-urlhandler -o", "externalpipe", NULL };

static Shortcut shortcuts[] = {
	// Modificador		Tecla		Función		Argumento
	{ XK_ANY_MOD,		XK_Break,	sendbreak,	{.i =  0} },
	{ ControlMask,		XK_Print,	toggleprinter,	{.i =  0} },
	{ ShiftMask,		XK_Print,	printscreen,	{.i =  0} },
	{ XK_ANY_MOD,		XK_Print,	printsel,	{.i =  0} },
	{ ControlMask,		XK_plus,	zoom,		{.f = +1} },
	{ ControlMask,		XK_minus,	zoom,		{.f = -1} },
	{ TERMMOD,		XK_Prior,	zoom,		{.f = +1} },
	{ TERMMOD,		XK_Next,	zoom,		{.f = -1} },
	{ TERMMOD,		XK_Home,	zoomreset,	{.f =  0} },
	// Copiar/Pegar
	{ MODKEY,		XK_c,		clipcopy,	{.i =  0} },
	{ MODKEY,		XK_v,		clippaste,	{.i =  0} },
	{ TERMMOD,		XK_Y,		selpaste,	{.i =  0} },
	{ ShiftMask,		XK_Insert,	selpaste,	{.i =  0} },
	{ TERMMOD,		XK_Num_Lock,	numlock,	{.i =  0} },
	// Abrir URL
	{ MODKEY,		XK_l,		externalpipe,	{.v = openurlcmd } },
};

// Teclas especiales (cambia y recompila st.info en consecuencia)
//
// Valor de máscara:
// * Usa `XK_ANY_MOD` para coincidir con la tecla sin importar el estado de los modificadores
// * Usa `XK_NO_MOD` para coincidir solo con la tecla (sin modificadores)
//
// Valor de `appkey`:
// 	0: sin valor
// 	> 0: modo de aplicación del teclado numérico habilitado
// 		= 2: term.numlock = 1
// 	< 0: modo de aplicación del teclado numérico deshabilitado
//
// Valor de `appcursor`:
// 	0: sin valor
// 	> 0: modo de aplicación del cursor habilitado
// 	< 0: modo de aplicación del cursor deshabilitado
//
// Ten cuidado con el orden de las definiciones porque st busca en
// esta tabla secuencialmente, por lo que cualquier `XK_ANY_MOD` debe estar en la última
// posición para una tecla
//
// Si quieres que las teclas diferentes de las teclas de función de X11 (0xFD00 - 0xFFFF)
// se mapeen a continuación, añádelas a este array
static KeySym mappedkeys[] = { -1 };

// Bits de estado a ignorar al coincidir eventos de tecla o botón. Por defecto,
// numlock (Mod2Mask) y la disposición del teclado (XK_SWITCH_MOD) son ignorados
static uint ignoremod = Mod2Mask|XK_SWITCH_MOD;

// Este es el enorme array de teclas que define toda la compatibilidad con el mundo de Linux
// Por favor, decide sobre los cambios con sabiduría
static Key key[] = {
	// Keysym           Máscara         Cadena      appkey appcursor
	{ XK_KP_Home,       ShiftMask,      "\033[2J",       0,   -1},
	{ XK_KP_Home,       ShiftMask,      "\033[1;2H",     0,   +1},
	{ XK_KP_Home,       XK_ANY_MOD,     "\033[H",        0,   -1},
	{ XK_KP_Home,       XK_ANY_MOD,     "\033[1~",       0,   +1},
	{ XK_KP_Up,         XK_ANY_MOD,     "\033Ox",       +1,    0},
	{ XK_KP_Up,         XK_ANY_MOD,     "\033[A",        0,   -1},
	{ XK_KP_Up,         XK_ANY_MOD,     "\033OA",        0,   +1},
	{ XK_KP_Down,       XK_ANY_MOD,     "\033Or",       +1,    0},
	{ XK_KP_Down,       XK_ANY_MOD,     "\033[B",        0,   -1},
	{ XK_KP_Down,       XK_ANY_MOD,     "\033OB",        0,   +1},
	{ XK_KP_Left,       XK_ANY_MOD,     "\033Ot",       +1,    0},
	{ XK_KP_Left,       XK_ANY_MOD,     "\033[D",        0,   -1},
	{ XK_KP_Left,       XK_ANY_MOD,     "\033OD",        0,   +1},
	{ XK_KP_Right,      XK_ANY_MOD,     "\033Ov",       +1,    0},
	{ XK_KP_Right,      XK_ANY_MOD,     "\033[C",        0,   -1},
	{ XK_KP_Right,      XK_ANY_MOD,     "\033OC",        0,   +1},
	{ XK_KP_Prior,      ShiftMask,      "\033[5;2~",     0,    0},
	{ XK_KP_Prior,      XK_ANY_MOD,     "\033[5~",       0,    0},
	{ XK_KP_Begin,      XK_ANY_MOD,     "\033[E",        0,    0},
	{ XK_KP_End,        ControlMask,    "\033[J",       -1,    0},
	{ XK_KP_End,        ControlMask,    "\033[1;5F",    +1,    0},
	{ XK_KP_End,        ShiftMask,      "\033[K",       -1,    0},
	{ XK_KP_End,        ShiftMask,      "\033[1;2F",    +1,    0},
	{ XK_KP_End,        XK_ANY_MOD,     "\033[4~",       0,    0},
	{ XK_KP_Next,       ShiftMask,      "\033[6;2~",     0,    0},
	{ XK_KP_Next,       XK_ANY_MOD,     "\033[6~",       0,    0},
	{ XK_KP_Insert,     ShiftMask,      "\033[2;2~",    +1,    0},
	{ XK_KP_Insert,     ShiftMask,      "\033[4l",      -1,    0},
	{ XK_KP_Insert,     ControlMask,    "\033[L",       -1,    0},
	{ XK_KP_Insert,     ControlMask,    "\033[2;5~",    +1,    0},
	{ XK_KP_Insert,     XK_ANY_MOD,     "\033[4h",      -1,    0},
	{ XK_KP_Insert,     XK_ANY_MOD,     "\033[2~",      +1,    0},
	{ XK_KP_Delete,     ControlMask,    "\033[M",       -1,    0},
	{ XK_KP_Delete,     ControlMask,    "\033[3;5~",    +1,    0},
	{ XK_KP_Delete,     ShiftMask,      "\033[2K",      -1,    0},
	{ XK_KP_Delete,     ShiftMask,      "\033[3;2~",    +1,    0},
	{ XK_KP_Delete,     XK_ANY_MOD,     "\033[3~",       -1,    0},
	{ XK_KP_Delete,     XK_ANY_MOD,     "\033[3~",      +1,    0},
	{ XK_KP_Multiply,   XK_ANY_MOD,     "\033Oj",       +2,    0},
	{ XK_KP_Add,        XK_ANY_MOD,     "\033Ok",       +2,    0},
	{ XK_KP_Enter,      XK_ANY_MOD,     "\033OM",       +2,    0},
	{ XK_KP_Enter,      XK_ANY_MOD,     "\r",           -1,    0},
	{ XK_KP_Subtract,   XK_ANY_MOD,     "\033Om",       +2,    0},
	{ XK_KP_Decimal,    XK_ANY_MOD,     "\033On",       +2,    0},
	{ XK_KP_Divide,     XK_ANY_MOD,     "\033Oo",       +2,    0},
	{ XK_KP_0,          XK_ANY_MOD,     "\033Op",       +2,    0},
	{ XK_KP_1,          XK_ANY_MOD,     "\033Oq",       +2,    0},
	{ XK_KP_2,          XK_ANY_MOD,     "\033Or",       +2,    0},
	{ XK_KP_3,          XK_ANY_MOD,     "\033Os",       +2,    0},
	{ XK_KP_4,          XK_ANY_MOD,     "\033Ot",       +2,    0},
	{ XK_KP_5,          XK_ANY_MOD,     "\033Ou",       +2,    0},
	{ XK_KP_6,          XK_ANY_MOD,     "\033Ov",       +2,    0},
	{ XK_KP_7,          XK_ANY_MOD,     "\033Ow",       +2,    0},
	{ XK_KP_8,          XK_ANY_MOD,     "\033Ox",       +2,    0},
	{ XK_KP_9,          XK_ANY_MOD,     "\033Oy",       +2,    0},
	{ XK_Up,            ShiftMask,      "\033[1;2A",     0,    0},
	{ XK_Up,            Mod1Mask,       "\033[1;3A",     0,    0},
	{ XK_Up,         ShiftMask|Mod1Mask,"\033[1;4A",     0,    0},
	{ XK_Up,            ControlMask,    "\033[1;5A",     0,    0},
	{ XK_Up,      ShiftMask|ControlMask,"\033[1;6A",     0,    0},
	{ XK_Up,       ControlMask|Mod1Mask,"\033[1;7A",     0,    0},
	{ XK_Up,ShiftMask|ControlMask|Mod1Mask,"\033[1;8A",  0,    0},
	{ XK_Up,            XK_ANY_MOD,     "\033[A",        0,   -1},
	{ XK_Up,            XK_ANY_MOD,     "\033OA",        0,   +1},
	{ XK_Down,          ShiftMask,      "\033[1;2B",     0,    0},
	{ XK_Down,          Mod1Mask,       "\033[1;3B",     0,    0},
	{ XK_Down,       ShiftMask|Mod1Mask,"\033[1;4B",     0,    0},
	{ XK_Down,          ControlMask,    "\033[1;5B",     0,    0},
	{ XK_Down,    ShiftMask|ControlMask,"\033[1;6B",     0,    0},
	{ XK_Down,     ControlMask|Mod1Mask,"\033[1;7B",     0,    0},
	{ XK_Down,ShiftMask|ControlMask|Mod1Mask,"\033[1;8B",0,    0},
	{ XK_Down,          XK_ANY_MOD,     "\033[B",        0,   -1},
	{ XK_Down,          XK_ANY_MOD,     "\033OB",        0,   +1},
	{ XK_Left,          ShiftMask,      "\033[1;2D",     0,    0},
	{ XK_Left,          Mod1Mask,       "\033[1;3D",     0,    0},
	{ XK_Left,       ShiftMask|Mod1Mask,"\033[1;4D",     0,    0},
	{ XK_Left,          ControlMask,    "\033[1;5D",     0,    0},
	{ XK_Left,    ShiftMask|ControlMask,"\033[1;6D",     0,    0},
	{ XK_Left,     ControlMask|Mod1Mask,"\033[1;7D",     0,    0},
	{ XK_Left,ShiftMask|ControlMask|Mod1Mask,"\033[1;8D",0,    0},
	{ XK_Left,          XK_ANY_MOD,     "\033[D",        0,   -1},
	{ XK_Left,          XK_ANY_MOD,     "\033OD",        0,   +1},
	{ XK_Right,         ShiftMask,      "\033[1;2C",     0,    0},
	{ XK_Right,         Mod1Mask,       "\033[1;3C",     0,    0},
	{ XK_Right,      ShiftMask|Mod1Mask,"\033[1;4C",     0,    0},
	{ XK_Right,         ControlMask,    "\033[1;5C",     0,    0},
	{ XK_Right,   ShiftMask|ControlMask,"\033[1;6C",     0,    0},
	{ XK_Right,    ControlMask|Mod1Mask,"\033[1;7C",     0,    0},
	{ XK_Right,ShiftMask|ControlMask|Mod1Mask,"\033[1;8C",0,   0},
	{ XK_Right,         XK_ANY_MOD,     "\033[C",        0,   -1},
	{ XK_Right,         XK_ANY_MOD,     "\033OC",        0,   +1},
	{ XK_ISO_Left_Tab,  ShiftMask,      "\033[Z",        0,    0},
	{ XK_Return,        Mod1Mask,       "\033\r",        0,    0},
	{ XK_Return,        XK_ANY_MOD,     "\r",            0,    0},
	{ XK_Insert,        ShiftMask,      "\033[4l",      -1,    0},
	{ XK_Insert,        ShiftMask,      "\033[2;2~",    +1,    0},
	{ XK_Insert,        ControlMask,    "\033[L",       -1,    0},
	{ XK_Insert,        ControlMask,    "\033[2;5~",    +1,    0},
	{ XK_Insert,        XK_ANY_MOD,     "\033[4h",      -1,    0},
	{ XK_Insert,        XK_ANY_MOD,     "\033[2~",      +1,    0},
	{ XK_Delete,        ControlMask,    "\033[M",       -1,    0},
	{ XK_Delete,        ControlMask,    "\033[3;5~",    +1,    0},
	{ XK_Delete,        ShiftMask,      "\033[2K",      -1,    0},
	{ XK_Delete,        ShiftMask,      "\033[3;2~",    +1,    0},
	{ XK_Delete,        XK_ANY_MOD,     "\033[3~",       -1,    0},
	{ XK_Delete,        XK_ANY_MOD,     "\033[3~",      +1,    0},
	{ XK_BackSpace,     XK_NO_MOD,      "\177",          0,    0},
	{ XK_BackSpace,     Mod1Mask,       "\033\177",      0,    0},
	{ XK_Home,          ShiftMask,      "\033[2J",       0,   -1},
	{ XK_Home,          ShiftMask,      "\033[1;2H",     0,   +1},
	{ XK_Home,          XK_ANY_MOD,     "\033[H",        0,   -1},
	{ XK_Home,          XK_ANY_MOD,     "\033[1~",       0,   +1},
	{ XK_End,           ControlMask,    "\033[J",       -1,    0},
	{ XK_End,           ControlMask,    "\033[1;5F",    +1,    0},
	{ XK_End,           ShiftMask,      "\033[K",       -1,    0},
	{ XK_End,           ShiftMask,      "\033[1;2F",    +1,    0},
	{ XK_End,           XK_ANY_MOD,     "\033[4~",       0,    0},
	{ XK_Prior,         ControlMask,    "\033[5;5~",     0,    0},
	{ XK_Prior,         ShiftMask,      "\033[5;2~",     0,    0},
	{ XK_Prior,         XK_ANY_MOD,     "\033[5~",       0,    0},
	{ XK_Next,          ControlMask,    "\033[6;5~",     0,    0},
	{ XK_Next,          ShiftMask,      "\033[6;2~",     0,    0},
	{ XK_Next,          XK_ANY_MOD,     "\033[6~",       0,    0},
	{ XK_F1,            XK_NO_MOD,      "\033OP" ,       0,    0},
	{ XK_F1, /* F13 */  ShiftMask,      "\033[1;2P",     0,    0},
	{ XK_F1, /* F25 */  ControlMask,    "\033[1;5P",     0,    0},
	{ XK_F1, /* F37 */  Mod4Mask,       "\033[1;6P",     0,    0},
	{ XK_F1, /* F49 */  Mod1Mask,       "\033[1;3P",     0,    0},
	{ XK_F1, /* F61 */  Mod3Mask,       "\033[1;4P",     0,    0},
	{ XK_F2,            XK_NO_MOD,      "\033OQ" ,       0,    0},
	{ XK_F2, /* F14 */  ShiftMask,      "\033[1;2Q",     0,    0},
	{ XK_F2, /* F26 */  ControlMask,    "\033[1;5Q",     0,    0},
	{ XK_F2, /* F38 */  Mod4Mask,       "\033[1;6Q",     0,    0},
	{ XK_F2, /* F50 */  Mod1Mask,       "\033[1;3Q",     0,    0},
	{ XK_F2, /* F62 */  Mod3Mask,       "\033[1;4Q",     0,    0},
	{ XK_F3,            XK_NO_MOD,      "\033OR" ,       0,    0},
	{ XK_F3, /* F15 */  ShiftMask,      "\033[1;2R",     0,    0},
	{ XK_F3, /* F27 */  ControlMask,    "\033[1;5R",     0,    0},
	{ XK_F3, /* F39 */  Mod4Mask,       "\033[1;6R",     0,    0},
	{ XK_F3, /* F51 */  Mod1Mask,       "\033[1;3R",     0,    0},
	{ XK_F3, /* F63 */  Mod3Mask,       "\033[1;4R",     0,    0},
	{ XK_F4,            XK_NO_MOD,      "\033OS" ,       0,    0},
	{ XK_F4, /* F16 */  ShiftMask,      "\033[1;2S",     0,    0},
	{ XK_F4, /* F28 */  ControlMask,    "\033[1;5S",     0,    0},
	{ XK_F4, /* F40 */  Mod4Mask,       "\033[1;6S",     0,    0},
	{ XK_F4, /* F52 */  Mod1Mask,       "\033[1;3S",     0,    0},
	{ XK_F5,            XK_NO_MOD,      "\033[15~",      0,    0},
	{ XK_F5, /* F17 */  ShiftMask,      "\033[15;2~",    0,    0},
	{ XK_F5, /* F29 */  ControlMask,    "\033[15;5~",    0,    0},
	{ XK_F5, /* F41 */  Mod4Mask,       "\033[15;6~",    0,    0},
	{ XK_F5, /* F53 */  Mod1Mask,       "\033[15;3~",    0,    0},
	{ XK_F6,            XK_NO_MOD,      "\033[17~",      0,    0},
	{ XK_F6, /* F18 */  ShiftMask,      "\033[17;2~",    0,    0},
	{ XK_F6, /* F30 */  ControlMask,    "\033[17;5~",    0,    0},
	{ XK_F6, /* F42 */  Mod4Mask,       "\033[17;6~",    0,    0},
	{ XK_F6, /* F54 */  Mod1Mask,       "\033[17;3~",    0,    0},
	{ XK_F7,            XK_NO_MOD,      "\033[18~",      0,    0},
	{ XK_F7, /* F19 */  ShiftMask,      "\033[18;2~",    0,    0},
	{ XK_F7, /* F31 */  ControlMask,    "\033[18;5~",    0,    0},
	{ XK_F7, /* F43 */  Mod4Mask,       "\033[18;6~",    0,    0},
	{ XK_F7, /* F55 */  Mod1Mask,       "\033[18;3~",    0,    0},
	{ XK_F8,            XK_NO_MOD,      "\033[19~",      0,    0},
	{ XK_F8, /* F20 */  ShiftMask,      "\033[19;2~",    0,    0},
	{ XK_F8, /* F32 */  ControlMask,    "\033[19;5~",    0,    0},
	{ XK_F8, /* F44 */  Mod4Mask,       "\033[19;6~",    0,    0},
	{ XK_F8, /* F56 */  Mod1Mask,       "\033[19;3~",    0,    0},
	{ XK_F9,            XK_NO_MOD,      "\033[20~",      0,    0},
	{ XK_F9, /* F21 */  ShiftMask,      "\033[20;2~",    0,    0},
	{ XK_F9, /* F33 */  ControlMask,    "\033[20;5~",    0,    0},
	{ XK_F9, /* F45 */  Mod4Mask,       "\033[20;6~",    0,    0},
	{ XK_F9, /* F57 */  Mod1Mask,       "\033[20;3~",    0,    0},
	{ XK_F10,           XK_NO_MOD,      "\033[21~",      0,    0},
	{ XK_F10, /* F22 */ ShiftMask,      "\033[21;2~",    0,    0},
	{ XK_F10, /* F34 */ ControlMask,    "\033[21;5~",    0,    0},
	{ XK_F10, /* F46 */ Mod4Mask,       "\033[21;6~",    0,    0},
	{ XK_F10, /* F58 */ Mod1Mask,       "\033[21;3~",    0,    0},
	{ XK_F11,           XK_NO_MOD,      "\033[23~",      0,    0},
	{ XK_F11, /* F23 */ ShiftMask,      "\033[23;2~",    0,    0},
	{ XK_F11, /* F35 */ ControlMask,    "\033[23;5~",    0,    0},
	{ XK_F11, /* F47 */ Mod4Mask,       "\033[23;6~",    0,    0},
	{ XK_F11, /* F59 */ Mod1Mask,       "\033[23;3~",    0,    0},
	{ XK_F12,           XK_NO_MOD,      "\033[24~",      0,    0},
	{ XK_F12, /* F24 */ ShiftMask,      "\033[24;2~",    0,    0},
	{ XK_F12, /* F36 */ ControlMask,    "\033[24;5~",    0,    0},
	{ XK_F12, /* F48 */ Mod4Mask,       "\033[24;6~",    0,    0},
	{ XK_F12, /* F60 */ Mod1Mask,       "\033[24;3~",    0,    0},
	{ XK_F13,           XK_NO_MOD,      "\033[1;2P",     0,    0},
	{ XK_F14,           XK_NO_MOD,      "\033[1;2Q",     0,    0},
	{ XK_F15,           XK_NO_MOD,      "\033[1;2R",     0,    0},
	{ XK_F16,           XK_NO_MOD,      "\033[1;2S",     0,    0},
	{ XK_F17,           XK_NO_MOD,      "\033[15;2~",    0,    0},
	{ XK_F18,           XK_NO_MOD,      "\033[17;2~",    0,    0},
	{ XK_F19,           XK_NO_MOD,      "\033[18;2~",    0,    0},
	{ XK_F20,           XK_NO_MOD,      "\033[19;2~",    0,    0},
	{ XK_F21,           XK_NO_MOD,      "\033[20;2~",    0,    0},
	{ XK_F22,           XK_NO_MOD,      "\033[21;2~",    0,    0},
	{ XK_F23,           XK_NO_MOD,      "\033[23;2~",    0,    0},
	{ XK_F24,           XK_NO_MOD,      "\033[24;2~",    0,    0},
	{ XK_F25,           XK_NO_MOD,      "\033[1;5P",     0,    0},
	{ XK_F26,           XK_NO_MOD,      "\033[1;5Q",     0,    0},
	{ XK_F27,           XK_NO_MOD,      "\033[1;5R",     0,    0},
	{ XK_F28,           XK_NO_MOD,      "\033[1;5S",     0,    0},
	{ XK_F29,           XK_NO_MOD,      "\033[15;5~",    0,    0},
	{ XK_F30,           XK_NO_MOD,      "\033[17;5~",    0,    0},
	{ XK_F31,           XK_NO_MOD,      "\033[18;5~",    0,    0},
	{ XK_F32,           XK_NO_MOD,      "\033[19;5~",    0,    0},
	{ XK_F33,           XK_NO_MOD,      "\033[20;5~",    0,    0},
	{ XK_F34,           XK_NO_MOD,      "\033[21;5~",    0,    0},
	{ XK_F35,           XK_NO_MOD,      "\033[23;5~",    0,    0},
};

// Máscaras de tipos de selección
// Usa las mismas máscaras que de costumbre
// Button1Mask siempre está desactivado, para que las máscaras coincidan entre ButtonPress,
// ButtonRelease y MotionNotify
// Si no se encuentra coincidencia, se usa la selección regular
static uint selmasks[] = {
	[SEL_RECTANGULAR] = Mod1Mask,
};

// Caracteres imprimibles en ASCII, utilizados para estimar el ancho de avance
// de caracteres anchos individuales
static char ascii_printable[] =
	" !\"#$%&'()*+,-./0123456789:;<=>?"
	"@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_"
	"`abcdefghijklmnopqrstuvwxyz{|}~";
