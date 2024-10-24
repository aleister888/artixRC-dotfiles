// Consulta el archivo LICENSE para los detalles de derechos de autor y licencia.

#define DLINES "16" // Lineas para los comandos de dmenu
#define TERM   "st" // Terminal
#define TERMT  "-t" // Flag usada para determinar el título de la terminal
#define TERMC  "st-256color" // Clase de ventana de la terminal
#define BROWSER "firefox" // Navegador Web

// Tamaño de la fuente y los margenes
static const char *fonts[] = { "Symbols Nerd Font:pixelsize=24","Iosevka Nerd Font:bold:pixelsize=24" };
static const unsigned int gappx = 24;

// Constantes
static const unsigned int borderpx       = gappx/5;   // Borde en pixeles de las ventanas
static const int vertpad                 = gappx;     // Separación vertical de la barra
static const int sidepad                 = gappx;     // Separación horizontal de la barra
static const int user_bh                 = gappx/4*3; // Altura barra: 0 por defecto, >= 1 Altura añadida
static const unsigned int snap           = 0;         // Pixeles de cercanía para pegarse al borde (0 = desactivado)
static const unsigned int systraypinning = 0;         // Monitor para la barra de tareas (0: Monitor seleccionado, >0 Monitor X)
static const unsigned int systrayspacing = gappx/2;   // Espaciado de la barra de tareas
static const int systraypinningfailfirst = 1;         // Monitor barra (Seguro) 1: Barra de tareas en el 1er monitor
static const int showsystray             = 1;         // ¿Barra de tareas? (0: Desactivada)
static const int swallowfloating         = 0;         // 1 Significa tragarse nuevas ventanas por defecto
static const int showbar                 = 1;         // 0 Para desactivar la barra
static const int topbar                  = 1;         // 0 Para la barra en la parte inferior
static const int allowkill               = 1;         // ¿Permitir cerrar clientes por defecto?
static const float mfact                 = 0.45;      // Factor de escalado de la zona principal [0.05..0.95]
static const int nmaster                 = 1;         // Número de clientes en la zona principal
static const int resizehints             = 1;         // 1 ¿Respetar pistas de dibujado al re-dimensionar ventanas no-flotantes?
static const int lockfullscreen          = 1;         // 1 Fuerza el foco en las ventanas en pantalla completa
static const unsigned int colorfultag    = 1;         // 1, Los indicadores de espacio son coloridos
static const unsigned int ulinepad       = 0;         // Espaciado horizontal entre subrayado y el indicador del espacio de trabajo
static const unsigned int ulinestroke    = 0;         // Grosor/Altura del subrayado
static const unsigned int ulinevoffset   = 0;         // Espacio entre el subrayado y el borde inferior de la barra
static const int ulineall                = 0;         // 1 para mostrar el subrayado en todos los espacios, 0 para mostrarlo en los seleccionados
static const char background[]           = "#1D2021";
static const char background_sel[]       = "#282828";
static const char foreground[]           = "#EBDBB2";
static const char col_red[]              = "#FB4934";
static const char col_green[]            = "#B8BB26" ;
static const char col_yellow[]           = "#FABD2F" ;
static const char col_blue[]             = "#83A598";
static const char col_purple[]           = "#D3869B";
static const char col_aqua[]             = "#8EC07C" ;
static const char col_orange[]           = "#FE8019";


static const char *colors[][3] = {
	// Colores:             Fuente      Fondo           Borde
	[SchemeNorm]        = { foreground, background,     col_blue   }, // Color de las ventanas normales
	[SchemeSel]         = { foreground, background_sel, col_orange }, // Color de las ventanas seleccionadas
	[SchemeStatus]      = { foreground, background,     "#000000"  }, // Color de los espacios por defecto
	[SchemeTagsNorm]    = { foreground, background,     "#000000"  }, // Información (Normal)
	[SchemeTagsSel]     = { foreground, background_sel, "#000000"  }, // Color de los espacios seleccionados
	[SchemeInfoNorm]    = { foreground, background,     "#000000"  }, // Estado/información
	[SchemeInfoSel]     = { foreground, background_sel, "#000000"  }, // Información (Seleccionada)
	[SchemeScratchNorm] = { "#000000",  "#000000",      col_blue   }, // Scratchpad (Normal)
	[SchemeScratchSel]  = { "#000000",  "#000000",      col_purple }, // Scratchpad (Seleccionado)
	[SchemeStickyNorm]  = { "#000000",  "#000000",      background_sel }, // Scratchpad (Normal)
	[SchemeStickySel]   = { "#000000",  "#000000",      col_yellow }, // Scratchpad (Seleccionado)
	[SchemeTag1]        = { col_purple, background_sel, "#000000"  }, // Colores de los espacios 1-12
	[SchemeTag2]        = { col_aqua,   background_sel, "#000000"  },
	[SchemeTag3]        = { col_orange, background_sel, "#000000"  },
	[SchemeTag4]        = { col_red,    background_sel, "#000000"  },
	[SchemeTag5]        = { col_aqua,   background_sel, "#000000"  },
	[SchemeTag6]        = { col_blue,   background_sel, "#000000"  },
	[SchemeTag7]        = { col_green,  background_sel, "#000000"  },
	[SchemeTag8]        = { col_yellow, background_sel, "#000000"  },
	[SchemeTag9]        = { col_purple, background_sel, "#000000"  },
	[SchemeTag10]       = { col_orange, background_sel, "#000000"  },
	[SchemeTag11]       = { col_orange, background_sel, "#000000"  },
	[SchemeTag12]       = { col_orange, background_sel, "#000000"  },
	// Los valores con "#000000" no son usados pero no pueden estar vacios
};

static const int tagschemes[] = {
	SchemeTag1,  SchemeTag2,  SchemeTag3,
	SchemeTag4,  SchemeTag5,  SchemeTag6,
	SchemeTag7,  SchemeTag8,  SchemeTag9,
	SchemeTag10, SchemeTag11, SchemeTag12,
};

typedef struct {
	const char *name;
	const void *cmd;
} Sp;

// Nombre de los espacios cuando estan vacios y cuando tienen ventanas. Layout por defecto
static const char *tags[]	= { "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c"};
static const char *alttags[]	= { "", "", "󰈹", "", "󰙯", "", "󰋅", "", "󰊗", "A", "B", "C"};
static const int taglayouts[]	= {   2,   0,   0,   0,   2,   0,   0,   0,   0,   0,   0,   0};

// Reglas pre-establecidas para colocar las ventanas
static const Rule rules[] = {
	// Clase      Instancia Título          Espacio Flotante Terminal -Tragado Monitor Scratch
	// Terminal
	{ TERMC,		NULL,	NULL,	0,	0,	1,	0,	-1,     0},
	// Ventanas flotantes
	{ "Yad",		NULL,	NULL,	0,	1,	0,	0,	-1,     0},
	{ "Gcolor3",		NULL,	NULL,	0,	1,	0,	0,	-1,     0},
	{ "pavucontrol",	NULL,	NULL,	0,	1,	0,	0,	-1,     0},
	{ "Alarm-clock-applet",	NULL,	NULL,	0,	1,	0,	0,	-1,     0},
	{ "Galculator",		NULL,	NULL,	0,	1,	0,	0,	-1,     0},
	{ "easyeffects",	NULL,	NULL,	0,	1,	0,	0,	-1,     0},
	// Espacio 1: Música
	{ "tauonmb",		NULL,	NULL,	1 << 0,	0,	0,	0,	-1,     0},
	// Espacio 2: Correo
	{ "thunderbird",	NULL,	NULL,	1 << 1,	0,	0,	0,	-1,     0},
	{ "electron-mail",	NULL,	NULL,	1 << 1,	0,	0,	0,	-1,     0},
	// Espacio 3: Internet
	// Espacio 4: Oficina
	{ "Zim",		NULL,	NULL,	1 << 3,	0,	0,	0,	-1,     0},
	{ "Soffice",		NULL,	NULL,	1 << 3,	0,	0,	0,	-1,     0},
	// Espacio 5: Chats
	{ "discord",		NULL,	NULL,	1 << 4,	0,	0,	0,	-1,     0},
	{ "TelegramDesktop",	NULL,	NULL,	1 << 4,	0,	0,	0,	-1,     0},
	{ "TelegramDesktop","telegram-desktop","Media viewer",1 << 4,1,0,0,	-1,     0},
	// Espacio 6: Virtualización
	{ "Virt-manager",	NULL,	NULL,	1 << 5,	0,	0,	0,	-1,     0},
	{ "looking-glass-client",NULL,	NULL,	1 << 5,	0,	0,	0,	-1,     0},
	// Espacio 7: Guitarra/Producción Musical || Organizar/Descargar Música
	{ "TuxGuitar",		NULL,	NULL,	1 << 6,	0,	0,	0,	-1,     0},
	{ "Gmetronome",		NULL,	NULL,	1 << 6,	1,	0,	0,	-1,     0},
	{ "REAPER",		NULL,	NULL,	1 << 6,	0,	0,	0,	-1,     0},
	{ "Guitarix",		NULL,	NULL,	1 << 6,	0,	0,	0,	-1,     0},
	{ "transmission-gtk",	NULL,	NULL,	1 << 6,	0,	0,	0,	-1,     0},
	{ "qBittorrent",	NULL,	NULL,	1 << 6,	0,	0,	0,	-1,     0},
	{ "Lrcget",		NULL,	NULL,	1 << 6,	0,	0,	0,	-1,     0},
	{ "Easytag",		NULL,	NULL,	1 << 6,	0,	0,	0,	-1,     0},
	{ "Picard",		NULL,	NULL,	1 << 6,	0,	0,	0,	-1,     0},
	// Espacio 8: Gráficos || Utilidades/Configuración
	{ "krita",		NULL,	NULL,	1 << 7,	0,	0,	0,	-1,     0},
	{ "Fr.handbrake.ghb",	NULL,	NULL,	1 << 7,	0,	0,	0,	-1,     0},
	{ "Gimp",		NULL,	NULL,	1 << 7,	0,	0,	0,	-1,     0},
	{ "KeePassXC",		NULL,	NULL,	1 << 7,	0,	0,	0,	-1,     0},
	{ "Timeshift-gtk",	NULL,	NULL,	1 << 7,	0,	0,	0,	-1,     0},
	{ "BleachBit",		NULL,	NULL,	1 << 7,	0,	0,	0,	-1,     0},
	{ "Gnome-disks",	NULL,	NULL,	1 << 7,	0,	0,	0,	-1,     0},
	{ "Nitrogen",		NULL,	NULL,	1 << 7,	1,	0,	0,	-1,     0},
	{ "Blueman-manager",	NULL,	NULL,	1 << 7,	0,	0,	0,	-1,     0},
	{ "Lxappearance",	NULL,	NULL,	1 << 7,	0,	0,	0,	-1,     0},
	{ "qt5ct",		NULL,	NULL,	1 << 7,	0,	0,	0,	-1,     0},
	{ "baobab",		NULL,	NULL,	1 << 7,	0,	0,	0,	-1,     0},
	// Espacio 9: Juegos
	{ "steam",		NULL,	NULL,	1 << 8,	0,	0,	0,	-1,     0},
	{ "Lutris",		NULL,	NULL,	1 << 8,	0,	0,	0,	-1,     0},
	{ "ProtonUp-Qt",	NULL,	NULL,	1 << 8,	0,	0,	0,	-1,     0},
	{ "heroic",		NULL,	NULL,	1 << 8,	0,	0,	0,	-1,     0},
	{ "MultiMC",		NULL,	NULL,	1 << 8,	1,	0,	0,	-1,     0},
	{ "Minecraft* 1.16.5",	NULL,	NULL,	1 << 8,	0,	0,	0,	-1,     0},
	{ "Minecraft* 1.21",	NULL,	NULL,	1 << 8, 0,	0,	0,	-1,	0},
	// Scratchpad
	{ NULL,	NULL,"scratchpad",              0,      1,      1,      1,      -1,     's'},
};

#include "layouts.c" // Archivo con los layouts

static const Layout layouts[] = {
	{ "[]=",	tile }, // Layout por defecto
	{ "><>",	NULL }, // Ningún layout significa comportamiento flotante
	{ "[M]",	monocle }, // Las ventanas ocupan toda la pantalla
	{ "|M|",	centeredmaster }, // 3 Columnas (Zona principal centrada)
	{ "|||",	col }, // Columnas (Zona principal a la izquierda)
	{ "TTT",	bstack }, // Zona principal en la parte superior
	{ "[@]",	spiral }, // Layouts fibonacci
	{ "[\\]",	dwindle },
	{ "[D]",	deck },
};

// Definiciones de las Teclas
#define MODKEY Mod1Mask // Super (Win) como modificador
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,			KEY,	view,		{.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,		KEY,	toggleview,	{.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,		KEY,	tag,		{.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask,	KEY,	toggletag,	{.ui = 1 << TAG} },
#define STACKKEYS(MOD,ACTION) \
/* Poner el foco/Mover a la posición anterior */		{ MOD, XK_comma,  ACTION##stack, {.i = INC(-1) } }, \
/* Poner el foco/Mover a la posición posterior */		{ MOD, XK_period, ACTION##stack, {.i = INC(+1) } }, \
/* Poner el foco/Mover a la primera ventana principal */	{ MOD, XK_minus,  ACTION##stack, {.i = 0 } },

// Invocador de comandos
#define SHCMD(cmd) { .v = (const char*[]){ "/usr/bin/zsh", "-c", cmd, NULL } }

// Comandos
static char dmenumon[2] = "0"; // Comando para ejecutar dmenu
static const char *dmenucmd[] = { "dbus-launch", "dmenu_run",
"-m",	dmenumon,	"-nb", background,
"-nf",	foreground,	"-sb", background_sel,
"-sf",	foreground,	"-c","-l", DLINES, NULL };
static const char *termcmd[]  = { TERM, NULL };      // Terminal
static const char *layoutmenu_cmd = "layoutmenu.sh"; // Script para cambiar el layout
static const char *scratchpadcmd[] = { "s", NULL };  // Tecla para los scratchpads
static const char *spawnscratchpadcmd[] = { TERM, TERMT, "scratchpad", NULL }; // Comando para invocar un scratchpad

#include <X11/XF86keysym.h> // Incluir teclas especiales

static const Key keys[] = {
	// Modificador                  Tecla      Función           Argumento
	// Abrir dmenu
	{ MODKEY|ControlMask,           XK_h,      spawn,            SHCMD("zathura ~/.dotfiles/assets/pdf/help.pdf") },
	{ MODKEY,                       XK_p,      spawn,            {.v = dmenucmd } },
	{ MODKEY|ShiftMask,             XK_p,      spawn,            SHCMD("j4-dmenu-desktop --dmenu 'dmenu -c -l 12'") },
	{ MODKEY|ControlMask,           XK_p,      spawn,            SHCMD("dmenu -C -l 1 | tr -d '\n' | xclip -selection clipboard") },
	{ MODKEY,                       XK_t,      spawn,            SHCMD("tray-toggle") },
	// Abrir terminal
	{ MODKEY|ShiftMask,             XK_Return, spawn,            {.v = termcmd } },
	// Configurar pantallas
	{ MODKEY,                       XK_F1,     spawn,            SHCMD("monitor-layout && nitrogen --restore") },
	{ MODKEY|ShiftMask,             XK_F1,     spawn,            SHCMD("arandr") },
	// Abrir aplicaciones más usadas
	{ MODKEY,                       XK_F2,     spawn,            {.v = (const char*[]){ BROWSER, NULL } } },
	{ MODKEY,                       XK_F3,     spawn,            {.v = (const char*[]){ TERM, "lf", NULL } } },
	{ MODKEY|ShiftMask,             XK_F3,     spawn,            {.v = (const char*[]){ TERM, "lf", "/run/media/", NULL } } },
	{ MODKEY,                       XK_F4,     spawn,            SHCMD("tauon") },
	// Montar/Desmontar dispositivos android
	{ MODKEY,                       XK_F5,     spawn,            SHCMD("android-mount") },
	{ MODKEY|ShiftMask,             XK_F5,     spawn,            SHCMD("android-umount") },
	// Menu de apagado
	{ MODKEY,                       XK_F11,    spawn,            SHCMD("powermenu") },
	// Cerrar dwm
	{ MODKEY|ShiftMask,             XK_F11,    spawn,            SHCMD("pkill dwm") },
	// Ajustes de audio
	{ MODKEY,                       XK_F12,    spawn,            SHCMD("pavucontrol") },
	{ MODKEY|ShiftMask,             XK_F12,    spawn,            SHCMD("pipewire-virtualmic-select") },
	// Cambiar música
	{ MODKEY,                       XK_z,      spawn,            SHCMD("playerctl -p tauon previous; pkill -54 dwmblocks") },
	{ MODKEY,                       XK_x,      spawn,            SHCMD("playerctl -p tauon next; pkill -54 dwmblocks") },
	{ MODKEY|ShiftMask,             XK_z,      spawn,            SHCMD("playerctl -p tauon play-pause; pkill -54 dwmblocks") },
	{ MODKEY|ShiftMask,             XK_x,      spawn,            SHCMD("playerctl -p tauon play-pause; pkill -54 dwmblocks") },
	{ 0,                XF86XK_AudioPlay,      spawn,            SHCMD("playerctl -p tauon play-pause; pkill -54 dwmblocks") },
	// Cambiar volumen
	{ 0,         XF86XK_AudioLowerVolume,      spawn,            SHCMD("pactl set-sink-volume @DEFAULT_SINK@ -5%; pkill -44 dwmblocks") },
	{ 0,         XF86XK_AudioRaiseVolume,      spawn,            SHCMD("volinc 5; pkill -44 dwmblocks") },
	{ 0,                XF86XK_AudioMute,      spawn,            SHCMD("pactl set-sink-mute @DEFAULT_SINK@ toggle; pkill -44 dwmblocks") },
	{ MODKEY,                       XK_n,      spawn,            SHCMD("pactl set-sink-volume @DEFAULT_SINK@ -10%; pkill -44 dwmblocks") },
	{ MODKEY,                       XK_m,      spawn,            SHCMD("volinc 10; pkill -44 dwmblocks") },
	{ MODKEY|ControlMask,           XK_n,      spawn,            SHCMD("pactl set-sink-mute @DEFAULT_SINK@ toggle; pkill -44 dwmblocks") },
	{ MODKEY|ControlMask,           XK_m,      spawn,            SHCMD("pactl set-sink-mute @DEFAULT_SINK@ toggle; pkill -44 dwmblocks") },
	{ MODKEY|ShiftMask,             XK_n,      spawn,            SHCMD("pactl set-sink-volume @DEFAULT_SINK@ 32768; pkill -44 dwmblocks") },
	{ MODKEY|ShiftMask,             XK_m,      spawn,            SHCMD("pactl set-sink-volume @DEFAULT_SINK@ 65536; pkill -44 dwmblocks") },
	// Cambiar brillo (Portátiles)
	{ 0,        XF86XK_MonBrightnessDown,      spawn,            SHCMD("brightchange dec") },
	{ 0,          XF86XK_MonBrightnessUp,      spawn,            SHCMD("brightchange inc") },
	// Activar/Desactivar Micrófono (Portátiles)
	{ 0,             XF86XK_AudioMicMute,      spawn,            SHCMD("amixer sset Capture toggle") },
	// Forzar cerrar ventana
	{ MODKEY|ShiftMask,             XK_c,      spawn,            SHCMD("xkill") },
	// Tomar capturas de pantalla
	{ 0,                            XK_Print,  spawn,            SHCMD("screenshot all_clip") },
	{ ShiftMask,                    XK_Print,  spawn,            SHCMD("screenshot selection_clip") },
	{ MODKEY,                       XK_o,      spawn,            SHCMD("screenshot all_clip") },
	{ MODKEY|ShiftMask,             XK_o,      spawn,            SHCMD("screenshot selection_clip") },
	{ MODKEY|ControlMask,           XK_o,      spawn,            SHCMD("screenshot all_save") },
	{ MODKEY|ShiftMask|ControlMask, XK_o,      spawn,            SHCMD("screenshot selection_save") },
	// Mostrar/Ocultar barra
	{ MODKEY,                       XK_b,      togglebar,        {0} },
	// Cambiar de espacio
	{ MODKEY,                       XK_q,      shiftviewclients, { .i = -1 } },
	{ MODKEY,                       XK_w,      shiftviewclients, { .i = +1 } },
	// Cambiar foco/Mover ventana
	STACKKEYS(MODKEY,                                            focus)
	STACKKEYS(MODKEY|ShiftMask,                                  push)
	// Incrementar/Decrementar el número de ventanas de la zona principal
	{ MODKEY,                       XK_j,      incnmaster,       {.i = +1 } },
	{ MODKEY,                       XK_k,      incnmaster,       {.i = -1 } },
	// Incrementar/Decrementar el tamaño de la zona principal y las ventanas
	{ MODKEY,                       XK_u,      setmfact,         {.f = -0.025} },
	{ MODKEY,                       XK_i,      setmfact,         {.f = +0.025} },
	{ MODKEY|ShiftMask,             XK_u,      setcfact,         {.f = -0.25} },
	{ MODKEY|ShiftMask,             XK_i,      setcfact,         {.f = +0.25} },
	// Cerrar aplicación
	{ MODKEY|ShiftMask,             XK_q,      killclient,       {0} },
	// Hacer/Deshacer ventana flotante
	{ MODKEY|ShiftMask,             XK_space,  togglefloating,   {0} },
	// Cambiar de monitor / Mover las ventanas entre monitores
	// (Sólo para teclado español, "´" y "ç" son teclas del layout español)
	{ MODKEY,                       XK_dead_acute, focusmon,     {.i = -1 } },
	{ MODKEY,                       XK_ccedilla,   focusmon,     {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_dead_acute, tagmon,       {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_ccedilla,   tagmon,       {.i = +1 } },
	// Scratchpads
	{ MODKEY,                       XK_s,      togglescratch,    {.v = scratchpadcmd } },
	{ MODKEY|ShiftMask,             XK_s,      scratchtoggle,    {.v = scratchpadcmd } },
	{ MODKEY,                       XK_f,      spawn,            {.v = spawnscratchpadcmd } },
	// Hacer/Deshacer ventana permamente
	{ MODKEY|ControlMask,           XK_s,      togglesticky,     {0} },
	// Cambiar la distribución de las ventanas
	{ MODKEY,                       XK_e,      setlayout,        {.v = &layouts[0]} },
	{ MODKEY,                       XK_r,      setlayout,        {.v = &layouts[1]} },
	{ MODKEY|ShiftMask,             XK_e,      setlayout,        {.v = &layouts[2]} },
	{ MODKEY|ShiftMask,             XK_r,      setlayout,        {.v = &layouts[3]} },
	{ MODKEY,                       XK_y,      setlayout,        {.v = &layouts[4]} },
	{ MODKEY|ShiftMask,             XK_y,      setlayout,        {.v = &layouts[5]} },
	// Cambiar espacio entre ventanas
	{ MODKEY|ControlMask,           XK_period, setgaps,          {.i = -12 } },
	{ MODKEY|ControlMask,           XK_comma,  setgaps,          {.i = +12 } },
	// Teclas para cada espacio
	TAGKEYS(                        XK_1,                        0)
	TAGKEYS(                        XK_2,                        1)
	TAGKEYS(                        XK_3,                        2)
	TAGKEYS(                        XK_4,                        3)
	TAGKEYS(                        XK_5,                        4)
	TAGKEYS(                        XK_6,                        5)
	TAGKEYS(                        XK_7,                        6)
	TAGKEYS(                        XK_8,                        7)
	TAGKEYS(                        XK_9,                        8)
	TAGKEYS(                        XK_0,                        9)
	TAGKEYS(                        XK_apostrophe,              10)
	TAGKEYS(                        XK_exclamdown,              11)
};

// Botónes del ratón
// Click puede ser ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, o ClkRootWin
static const Button buttons[] = {
	// Click                Combinación     Botón           Función         Argumento
	{ ClkLtSymbol,          0,              Button1,        setlayout,      {.v = &layouts[0]} },
	{ ClkLtSymbol,          0,              Button3,        layoutmenu,     {0} },
	{ ClkStatusText,        0,              Button2,        spawn,          {.v = termcmd } },
	{ ClkRootWin,           0,              Button3,        spawn,          SHCMD("xdg-xmenu") },
	{ ClkRootWin,           0,              Button2,        spawn,          SHCMD("xmenu-apps") },
	{ ClkClientWin,         MODKEY|ControlMask,Button1,     movemouse,      {0} },
	{ ClkClientWin,         MODKEY|ControlMask,Button3,     resizemouse,    {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};
