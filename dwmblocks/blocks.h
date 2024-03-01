static char delim[] ="";
static unsigned int delimLen = 0;

static const Block blocks[] = {
	// Título                     Comando                Tiempo de Actualización Señal de Actualización
	// ¿Que canción esta sonando?
	{"^d^"                        ,"sb-tauon",                                1, 20},
	// Espacio libre
	{" ^d^^c#D79921^ ^c#FABD2F^" ,"df -h /home | awk '/[0-9]/ {print $4}'", 30,  0},
	// Version del kernel
	{" ^d^^c#458588^ ^c#83A598^" ,"uname -r | cut -d '-' -f 1",              0,  0},
	// Icono para el volumen
	{" ^d^^c#B16286^"             ,"sb-vol-icon",                             1, 10},
	// Nivel de volumen
	{" ^c#D3869B^"                ,"echo $(pamixer --get-volume)%",           1, 10},
	// Ram usada
	{" ^d^^c#98971a^ ^c#b8bb26^" ,"sb-mem",                                 10,  0},
	// Fecha
	{" ^d^^c#D65D0E^ ^c#FE8019^" ,"date +'%d/%m'",                         900,  0},
	// Hora
	{" ^d^^c#CC241D^ ^c#FB4934^" ,"date +'%I:%M '",                           5,  0},
};
