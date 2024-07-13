// Consulta el archivo LICENSE para los detalles de derechos de autor y licencia.

#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <pwd.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <sys/ioctl.h>
#include <sys/select.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <termios.h>
#include <unistd.h>
#include <wchar.h>

#include "st.h"
#include "win.h"

#if   defined(__linux)
	#include <pty.h>
#elif defined(__OpenBSD__) || defined(__NetBSD__) || defined(__APPLE__)
	#include <util.h>
#elif defined(__FreeBSD__) || defined(__DragonFly__)
	#include <libutil.h>
#endif

// Tamaños arbitrarios
#define UTF_INVALID   0xFFFD
#define UTF_SIZ       4
#define ESC_BUF_SIZ   (128*UTF_SIZ)
#define ESC_ARG_SIZ   16
#define STR_BUF_SIZ   ESC_BUF_SIZ
#define STR_ARG_SIZ   ESC_ARG_SIZ
#define HISTSIZE      2000
#define RESIZEBUFFER  1000

// Macros
#define IS_SET(flag)	((term.mode & (flag)) != 0)
#define ISCONTROLC0(c)	(BETWEEN(c, 0, 0x1f) || (c) == 0x7f)
#define ISCONTROLC1(c)	(BETWEEN(c, 0x80, 0x9f))
#define ISCONTROL(c)	(ISCONTROLC0(c) || ISCONTROLC1(c))
#define ISDELIM(u)	(u && wcschr(worddelimiters, u))

#define TLINE(y) ( \
(y) < term.scr ? term.hist[(term.histi + (y) - term.scr + 1 + HISTSIZE) % HISTSIZE] \
: term.line[(y) - term.scr] )
#define TLINE_HIST(y)	((y) <= HISTSIZE-term.row+2 ? term.hist[(y)] : term.line[(y-HISTSIZE+term.row-3)])

#define TLINEABS(y) ((y) < 0 ? term.hist[(term.histi + (y) + 1 + HISTSIZE) % HISTSIZE] : term.line[(y)])

#define UPDATEWRAPNEXT(alt, col) do { \
	if ((term.c.state & CURSOR_WRAPNEXT) && term.c.x + term.wrapcwidth[alt] < col) { \
		term.c.x += term.wrapcwidth[alt]; \
		term.c.state &= ~CURSOR_WRAPNEXT; \
	} \
} while (0);

enum term_mode {
	MODE_WRAP        = 1 << 0,
	MODE_INSERT      = 1 << 1,
	MODE_ALTSCREEN   = 1 << 2,
	MODE_CRLF        = 1 << 3,
	MODE_ECHO        = 1 << 4,
	MODE_PRINT       = 1 << 5,
	MODE_UTF8        = 1 << 6,
};

enum scroll_mode {
	SCROLL_RESIZE = -1,
	SCROLL_NOSAVEHIST = 0,
	SCROLL_SAVEHIST = 1
};

enum cursor_movement {
	CURSOR_SAVE,
	CURSOR_LOAD
};

enum cursor_state {
	CURSOR_DEFAULT  = 0,
	CURSOR_WRAPNEXT = 1,
	CURSOR_ORIGIN   = 2
};

enum charset {
	CS_GRAPHIC0,
	CS_GRAPHIC1,
	CS_UK,
	CS_USA,
	CS_MULTI,
	CS_GER,
	CS_FIN
};

enum escape_state {
	ESC_START      = 1,
	ESC_CSI        = 2,
	ESC_STR        = 4,  // DCS, OSC, PM, APC
	ESC_ALTCHARSET = 8,
	ESC_STR_END    = 16, // La última cadena fue encontrada
	ESC_TEST       = 32, // Entrar en modo de prueba
	ESC_UTF8       = 64,
};

typedef struct {
	Glyph attr; // Atributos del caracter
	int x;
	int y;
	char state;
} TCursor;

typedef struct {
	int mode;
	int type;
	int snap;
	// Variables
	// nb: Coordenadas del principio de la selección (Normalizadas)
	// ne: Coordenadas del final de la selección (Normalizadas)
	// ob: Coordenadas del principio de la selección (Originales)
	// oe: Coordenadas del final de la selección (Originales)
	struct {
		int x, y;
	} nb, ne, ob, oe;

	int alt;
} Selection;

// Representación interna de la pantalla
typedef struct {
	int row; // Fila nb
	int col; // Columna nb
	Line *line; // Pantalla
	Line hist[HISTSIZE]; // Buffer de historial
	int histi; // Índice de historial
	int histf; // Entrada del historial disponible nb
	int scr; // Retroceder
	int wrapcwidth[2]; // Usado para actualizar WRAPNEXT cuando cambia el tamaño de la ventana
	int *dirty; // Nivel de suciedad de las lineas
	TCursor c; // Cursor
	int ocx; // Última columna del cursor
	int ocy; // Última fila del cursor
	int top; // Limite superior del retroceso
	int bot; // Limite inferior del retroceso
	int mode; // Opciones del modo de la terminal
	int esc; // Señales del estado de salida
	char trantbl[4]; // Tabla de tradución de los surtidos de caracteres
	int charset; // Surtidos de caracteres
	int icharset; // Surtidos de caracteres elegido para la secuencia
	int *tabs;
	Rune lastc; // Ultimo caracter impreso fuera de la secuencia, 0 si es de control
} Term;

// Estructuras de secuencia de escape CSI
// ESC '[' [[ [<priv>] <arg> [;]] <modo> [<modo>]]
typedef struct {
	char buf[ESC_BUF_SIZ]; // Cadena sin procesar
	size_t len; // longitud de la cadena sin procesar
	char priv;
	int arg[ESC_ARG_SIZ];
	int narg; // Número de argumentos
	char mode[2];
} CSIEscape;

// Estructuras de secuencia de escape STR
// Tipo ESC [[ [<priv>] <arg> [;]] <mode>] ESC '\'
typedef struct {
	char type; // Tipo ESC ...
	char *buf; // Cadena sin procesar asignada
	size_t siz; // Tamaño de la asignación
	size_t len; // Longitud de la cadena sin procesar
	char *args[STR_ARG_SIZ];
	int narg; // Número de argumentos
} STREscape;

static void execsh(char *, char **);
static void stty(char **);
static void sigchld(int);
static void ttywriteraw(const char *, size_t);

static void csidump(void);
static void csihandle(void);
static void csiparse(void);
static void csireset(void);
static void osc_color_response(int, int, int);
static int eschandle(uchar);
static void strdump(void);
static void strhandle(void);
static void strparse(void);
static void strreset(void);

static void tprinter(char *, size_t);
static void tdumpsel(void);
static void tdumpline(int);
static void tdump(void);
static void tclearregion(int, int, int, int, int);
static void tcursor(int);
static void tclearglyph(Glyph *, int);
static void tresetcursor(void);
static void tdeletechar(int);
static void tdeleteline(int);
static void tinsertblank(int);
static void tinsertblankline(int);
static int tlinelen(Line len);
static int tiswrapped(Line line);
static char *tgetglyphs(char *, const Glyph *, const Glyph *);
static size_t tgetline(char *, const Glyph *);
static void tmoveto(int, int);
static void tmoveato(int, int);
static void tnewline(int);
static void tputtab(int);
static void tputc(Rune);
static void treset(void);
static void tscrollup(int, int, int, int);
static void tscrolldown(int, int);
static void treflow(int, int);
static void rscrolldown(int);
static void tresizedef(int, int);
static void tresizealt(int, int);
static void tsetattr(const int *, int);
static void tsetchar(Rune, const Glyph *, int, int);
static void tsetdirt(int, int);
static void tsetscroll(int, int);
static void tswapscreen(void);
static void tloaddefscreen(int, int);
static void tloadaltscreen(int, int);
static void tsetmode(int, int, const int *, int);
static int twrite(const char *, int, int);
static void tfulldirt(void);
static void tcontrolcode(uchar );
static void tdectest(char );
static void tdefutf8(char);
static int32_t tdefcolor(const int *, int *, int);
static void tdeftran(char);
static void tstrsequence(uchar);

static void drawregion(int, int, int, int);

static void selnormalize(void);
static void selscroll(int, int, int);
static void selmove(int);
static void selremove(void);
static int regionselected(int, int, int, int);
static void selsnap(int *, int *, int);

static size_t utf8decode(const char *, Rune *, size_t);
static Rune utf8decodebyte(char, size_t *);
static char utf8encodebyte(Rune, size_t);
static size_t utf8validate(Rune *, size_t);

static char *base64dec(const char *);
static char base64dec_getc(const char **);

static ssize_t xwrite(int, const char *, size_t);

// Variables globales
static Term term;
static Selection sel;
static CSIEscape csiescseq;
static STREscape strescseq;
static int iofd = 1;
static int cmdfd;
static pid_t pid;

static const uchar utfbyte[UTF_SIZ + 1] = { 0x80,     0,      0xC0,   0xE0,   0xF0 };
static const uchar utfmask[UTF_SIZ + 1] = { 0xC0,     0x80,   0xE0,   0xF0,   0xF8 };
static const Rune utfmin[UTF_SIZ + 1]   = { 0,        0,      0x80,   0x800,  0x10000 };
static const Rune utfmax[UTF_SIZ + 1]   = { 0x10FFFF, 0x7F,   0x7FF,  0xFFFF, 0x10FFFF };

ssize_t
xwrite(int fd, const char *s, size_t len)
{
	size_t aux = len;
	ssize_t r;

	while (len > 0) {
		r = write(fd, s, len);
		if (r < 0)
			return r;
		len -= r;
		s += r;
	}

	return aux;
}

void *
xmalloc(size_t len)
{
	void *p;

	if (!(p = malloc(len)))
		die("malloc: %s\n", strerror(errno));

	return p;
}

void *
xrealloc(void *p, size_t len)
{
	if ((p = realloc(p, len)) == NULL)
		die("realloc: %s\n", strerror(errno));

	return p;
}

char *
xstrdup(const char *s)
{
	char *p;

	if ((p = strdup(s)) == NULL)
		die("strdup: %s\n", strerror(errno));

	return p;
}

size_t
utf8decode(const char *c, Rune *u, size_t clen)
{
	size_t i, j, len, type;
	Rune udecoded;

	*u = UTF_INVALID;
	if (!clen)
		return 0;
	udecoded = utf8decodebyte(c[0], &len);
	if (!BETWEEN(len, 1, UTF_SIZ))
		return 1;
	for (i = 1, j = 1; i < clen && j < len; ++i, ++j) {
		udecoded = (udecoded << 6) | utf8decodebyte(c[i], &type);
		if (type != 0)
			return j;
	}
	if (j < len)
		return 0;
	*u = udecoded;
	utf8validate(u, len);

	return len;
}

Rune
utf8decodebyte(char c, size_t *i)
{
	for (*i = 0; *i < LEN(utfmask); ++(*i))
		if (((uchar)c & utfmask[*i]) == utfbyte[*i])
			return (uchar)c & ~utfmask[*i];

	return 0;
}

size_t
utf8encode(Rune u, char *c)
{
	size_t len, i;

	len = utf8validate(&u, 0);
	if (len > UTF_SIZ)
		return 0;

	for (i = len - 1; i != 0; --i) {
		c[i] = utf8encodebyte(u, 0);
		u >>= 6;
	}
	c[0] = utf8encodebyte(u, len);

	return len;
}

char
utf8encodebyte(Rune u, size_t i)
{
	return utfbyte[i] | (u & ~utfmask[i]);
}

size_t
utf8validate(Rune *u, size_t i)
{
	if (!BETWEEN(*u, utfmin[i], utfmax[i]) || BETWEEN(*u, 0xD800, 0xDFFF))
		*u = UTF_INVALID;
	for (i = 1; *u > utfmax[i]; ++i);

	return i;
}

char
base64dec_getc(const char **src)
{
	while (**src && !isprint((unsigned char)**src))
		(*src)++;
	return **src ? *((*src)++) : '=';  // Emular el margen si la cadena termina
}

char *
base64dec(const char *src)
{
	size_t in_len = strlen(src);
	char *result, *dst;
	static const char base64_digits[256] = {
		[43] = 62, 0, 0, 0, 63, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61,
		0, 0, 0, -1, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
		13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 0, 0, 0, 0,
		0, 0, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39,
		40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51
	};

	if (in_len % 4)
		in_len += 4 - (in_len % 4);
	result = dst = xmalloc(in_len / 4 * 3 + 1);
	while (*src) {
		int a = base64_digits[(unsigned char) base64dec_getc(&src)];
		int b = base64_digits[(unsigned char) base64dec_getc(&src)];
		int c = base64_digits[(unsigned char) base64dec_getc(&src)];
		int d = base64_digits[(unsigned char) base64dec_getc(&src)];

		// Entrada no válida. 'a' puede ser -1, por ejemplo si src es "\n" (cadena C)
		if (a == -1 || b == -1)
			break;

		*dst++ = (a << 2) | ((b & 0x30) >> 4);
		if (c == -1)
			break;
		*dst++ = ((b & 0x0f) << 4) | ((c & 0x3c) >> 2);
		if (d == -1)
			break;
		*dst++ = ((c & 0x03) << 6) | d;
	}
	*dst = '\0';
	return result;
}

void
selinit(void)
{
	sel.mode = SEL_IDLE;
	sel.snap = 0;
	sel.ob.x = -1;
}

int
tlinelen(Line line)
{
	int i = term.col - 1;

	for (; i >= 0 && !(line[i].mode & (ATTR_SET | ATTR_WRAP)); i--);
	return i + 1;
}

int
tiswrapped(Line line)
{
	int len = tlinelen(line);

	return len > 0 && (line[len - 1].mode & ATTR_WRAP);
}

char *
tgetglyphs(char *buf, const Glyph *gp, const Glyph *lgp)
{
	while (gp <= lgp)
		if (gp->mode & ATTR_WDUMMY) {
			gp++;
		} else {
			buf += utf8encode((gp++)->u, buf);
		}
	return buf;
}

size_t
tgetline(char *buf, const Glyph *fgp)
{
	char *ptr;
	const Glyph *lgp = &fgp[term.col - 1];

	while (lgp > fgp && !(lgp->mode & (ATTR_SET | ATTR_WRAP)))
		lgp--;
	ptr = tgetglyphs(buf, fgp, lgp);
	if (!(lgp->mode & ATTR_WRAP))
		*(ptr++) = '\n';
	return ptr - buf;
}

int
tlinehistlen(int y)
{
	int i = term.col;

	if (TLINE_HIST(y)[i - 1].mode & ATTR_WRAP)
		return i;

	while (i > 0 && TLINE_HIST(y)[i - 1].u == ' ')
		--i;

	return i;
}

void
selstart(int col, int row, int snap)
{
	selclear();
	sel.mode = SEL_EMPTY;
	sel.type = SEL_REGULAR;
	sel.alt = IS_SET(MODE_ALTSCREEN);
	sel.snap = snap;
	sel.oe.x = sel.ob.x = col;
	sel.oe.y = sel.ob.y = row;
	selnormalize();

	if (sel.snap != 0)
		sel.mode = SEL_READY;
	tsetdirt(sel.nb.y, sel.ne.y);
}

void
selextend(int col, int row, int type, int done)
{
	int oldey, oldex, oldsby, oldsey, oldtype;

	if (sel.mode == SEL_IDLE)
		return;
	if (done && sel.mode == SEL_EMPTY) {
		selclear();
		return;
	}

	oldey = sel.oe.y;
	oldex = sel.oe.x;
	oldsby = sel.nb.y;
	oldsey = sel.ne.y;
	oldtype = sel.type;

	sel.oe.x = col;
	sel.oe.y = row;
	sel.type = type;
	selnormalize();

	if (oldey != sel.oe.y || oldex != sel.oe.x ||
	oldtype != sel.type || sel.mode == SEL_EMPTY)
		tsetdirt(MIN(sel.nb.y, oldsby), MAX(sel.ne.y, oldsey));

	sel.mode = done ? SEL_IDLE : SEL_READY;
}

void
selnormalize(void)
{
	int i;

	if (sel.type == SEL_REGULAR && sel.ob.y != sel.oe.y) {
		sel.nb.x = sel.ob.y < sel.oe.y ? sel.ob.x : sel.oe.x;
		sel.ne.x = sel.ob.y < sel.oe.y ? sel.oe.x : sel.ob.x;
	} else {
		sel.nb.x = MIN(sel.ob.x, sel.oe.x);
		sel.ne.x = MAX(sel.ob.x, sel.oe.x);
	}
	sel.nb.y = MIN(sel.ob.y, sel.oe.y);
	sel.ne.y = MAX(sel.ob.y, sel.oe.y);

	selsnap(&sel.nb.x, &sel.nb.y, -1);
	selsnap(&sel.ne.x, &sel.ne.y, +1);

	// Expandir la selección sobre saltos de línea
	if (sel.type == SEL_RECTANGULAR)
		return;

	i = tlinelen(TLINE(sel.nb.y));
	if (sel.nb.x > i)
		sel.nb.x = i;
	if (sel.ne.x >= tlinelen(TLINE(sel.ne.y)))
		sel.ne.x = term.col - 1;
}

int
regionselected(int x1, int y1, int x2, int y2)
{
	if (sel.ob.x == -1 || sel.mode == SEL_EMPTY ||
		sel.alt != IS_SET(MODE_ALTSCREEN) || sel.nb.y > y2 || sel.ne.y < y1)
		return 0;

	return (sel.type == SEL_RECTANGULAR) ? sel.nb.x <= x2 && sel.ne.x >= x1
		: (sel.nb.y != y2 || sel.nb.x <= x2) &&
		(sel.ne.y != y1 || sel.ne.x >= x1);
}

int
selected(int x, int y)
{
	return regionselected(x, y, x, y);
}

void
selsnap(int *x, int *y, int direction)
{
	int newx, newy, xt, yt;
	int rtop = 0, rbot = term.row - 1;
	int delim, prevdelim;
	const Glyph *gp, *prevgp;

	if (!IS_SET(MODE_ALTSCREEN))
		rtop += -term.histf + term.scr, rbot += term.scr;

	switch (sel.snap) {
	case SNAP_WORD:
		// Ajustar si la palabra se ajusta al final o al principio de una línea
		prevgp = &TLINE(*y)[*x];
		prevdelim = ISDELIM(prevgp->u);
		for (;;) {
			newx = *x + direction;
			newy = *y;
			if (!BETWEEN(newx, 0, term.col - 1)) {
				newy += direction;
				newx = (newx + term.col) % term.col;
				if (!BETWEEN(newy, rtop, rbot))
					break;

				if (direction > 0)
					yt = *y, xt = *x;
				else
					yt = newy, xt = newx;
				if (!(TLINE(yt)[xt].mode & ATTR_WRAP))
					break;
			}

			if (newx >= tlinelen(TLINE(newy)))
				break;

			gp = &TLINE(newy)[newx];
			delim = ISDELIM(gp->u);
			if (!(gp->mode & ATTR_WDUMMY) && (delim != prevdelim ||
			(delim && !(gp->u == ' ' && prevgp->u == ' '))))
				break;

			*x = newx;
			*y = newy;
			prevgp = gp;
			prevdelim = delim;
		}
		break;
	case SNAP_LINE:
		// Ajustar alrededor si la línea anterior o la actual ha
		// establecido ATTR_WRAP en su final. Entonces toda la
		// línea línea anterior será seleccionada
		*x = (direction < 0) ? 0 : term.col - 1;
		if (direction < 0) {
			for (; *y > rtop; *y -= 1) {
				if (!tiswrapped(TLINE(*y-1)))
					break;
			}
		} else if (direction > 0) {
			for (; *y < rbot; *y += 1) {
				if (!tiswrapped(TLINE(*y)))
					break;
			}
		}
		break;
	}
}

char *
getsel(void)
{
	char *str, *ptr;
	int y, lastx, linelen;
	const Glyph *gp, *lgp;

	if (sel.ob.x == -1 || sel.alt != IS_SET(MODE_ALTSCREEN))
		return NULL;

	str = xmalloc((term.col + 1) * (sel.ne.y - sel.nb.y + 1) * UTF_SIZ);
	ptr = str;

	// Añadir todos los conjuntos y glifos seleccionados a la selección
	for (y = sel.nb.y; y <= sel.ne.y; y++) {
		Line line = TLINE(y);

		if ((linelen = tlinelen(line)) == 0) {
			*ptr++ = '\n';
			continue;
		}

		if (sel.type == SEL_RECTANGULAR) {
			gp = &line[sel.nb.x];
			lastx = sel.ne.x;
		} else {
			gp = &line[sel.nb.y == y ? sel.nb.x : 0];
			lastx = (sel.ne.y == y) ? sel.ne.x : term.col-1;
		}
		lgp = &line[MIN(lastx, linelen-1)];

		ptr = tgetglyphs(ptr, gp, lgp);
		// Copiar y pegar los finales de línea es inconsistente
		// La mejor solución parece ser producir '\n' cuando
		// algo se copia de st y convertir '\n' a '\r', cuando se pega
		if ((y < sel.ne.y || lastx >= linelen) &&
			(!(lgp->mode & ATTR_WRAP) || sel.type == SEL_RECTANGULAR))
			*ptr++ = '\n';
	}
	*ptr = '\0';
	return str;
}

void
selclear(void)
{
	if (sel.ob.x == -1)
		return;
	selremove();
	tsetdirt(sel.nb.y, sel.ne.y);
}

void
selremove(void)
{
	sel.mode = SEL_IDLE;
	sel.ob.x = -1;
}

void
die(const char *errstr, ...)
{
	va_list ap;

	va_start(ap, errstr);
	vfprintf(stderr, errstr, ap);
	va_end(ap);
	exit(1);
}

void
execsh(char *cmd, char **args)
{
	char *sh, *prog, *arg;
	const struct passwd *pw;

	errno = 0;
	if ((pw = getpwuid(getuid())) == NULL) {
		if (errno)
			die("getpwuid: %s\n", strerror(errno));
		else
			die("who are you?\n");
	}

	if ((sh = getenv("SHELL")) == NULL)
		sh = (pw->pw_shell[0]) ? pw->pw_shell : cmd;

	if (args) {
		prog = args[0];
		arg = NULL;
	} else if (scroll) {
		prog = scroll;
		arg = utmp ? utmp : sh;
	} else if (utmp) {
		prog = utmp;
		arg = NULL;
	} else {
		prog = sh;
		arg = NULL;
	}
	DEFAULT(args, ((char *[]) {prog, arg, NULL}));

	unsetenv("COLUMNS");
	unsetenv("LINES");
	unsetenv("TERMCAP");
	setenv("LOGNAME", pw->pw_name, 1);
	setenv("USER", pw->pw_name, 1);
	setenv("SHELL", sh, 1);
	setenv("HOME", pw->pw_dir, 1);
	setenv("TERM", termname, 1);

	signal(SIGCHLD, SIG_DFL);
	signal(SIGHUP, SIG_DFL);
	signal(SIGINT, SIG_DFL);
	signal(SIGQUIT, SIG_DFL);
	signal(SIGTERM, SIG_DFL);
	signal(SIGALRM, SIG_DFL);

	execvp(prog, args);
	_exit(1);
}

void
sigchld(int a)
{
	int stat;
	pid_t p;

	if ((p = waitpid(pid, &stat, WNOHANG)) < 0)
		die("waiting for pid %hd failed: %s\n", pid, strerror(errno));

	if (pid != p) {
		if (p == 0 && wait(&stat) < 0)
			die("wait: %s\n", strerror(errno));

		// Reinstalar el gestor sigchld
		signal(SIGCHLD, sigchld);
		return;
	}

	if (WIFEXITED(stat) && WEXITSTATUS(stat))
		die("child exited with status %d\n", WEXITSTATUS(stat));
	else if (WIFSIGNALED(stat))
		die("child terminated due to signal %d\n", WTERMSIG(stat));
	_exit(0);
}

void
stty(char **args)
{
	char cmd[_POSIX_ARG_MAX], **p, *q, *s;
	size_t n, siz;

	if ((n = strlen(stty_args)) > sizeof(cmd)-1)
		die("incorrect stty parameters\n");
	memcpy(cmd, stty_args, n);
	q = cmd + n;
	siz = sizeof(cmd) - n;
	for (p = args; p && (s = *p); ++p) {
		if ((n = strlen(s)) > siz-1)
			die("stty parameter length too long\n");
		*q++ = ' ';
		memcpy(q, s, n);
		q += n;
		siz -= n + 1;
	}
	*q = '\0';
	if (system(cmd) != 0)
		perror("Couldn't call stty");
}

int
ttynew(const char *line, char *cmd, const char *out, char **args)
{
	int m, s;

	if (out) {
		term.mode |= MODE_PRINT;
		iofd = (!strcmp(out, "-")) ?
			  1 : open(out, O_WRONLY | O_CREAT, 0666);
		if (iofd < 0) {
			fprintf(stderr, "Error opening %s:%s\n",
				out, strerror(errno));
		}
	}

	if (line) {
		if ((cmdfd = open(line, O_RDWR)) < 0)
			die("open line '%s' failed: %s\n",
			line, strerror(errno));
		dup2(cmdfd, 0);
		stty(args);
		return cmdfd;
	}

	// Parece funcionar en Linux, OpenBSD y FreeBSD
	if (openpty(&m, &s, NULL, NULL, NULL) < 0)
		die("openpty failed: %s\n", strerror(errno));

	switch (pid = fork()) {
	case -1:
		die("fork failed: %s\n", strerror(errno));
		break;
	case 0:
		close(iofd);
		close(m);
		setsid(); // Crear un nuevo grupo de procesos
		dup2(s, 0);
		dup2(s, 1);
		dup2(s, 2);
		if (ioctl(s, TIOCSCTTY, NULL) < 0)
			die("ioctl TIOCSCTTY failed: %s\n", strerror(errno));
		if (s > 2)
			close(s);
#ifdef __OpenBSD__
		if (pledge("stdio getpw proc exec", NULL) == -1)
			die("pledge\n");
#endif
		execsh(cmd, args);
		break;
	default:
#ifdef __OpenBSD__
		if (pledge("stdio rpath tty proc", NULL) == -1)
			die("pledge\n");
#endif
		close(s);
		cmdfd = m;
		signal(SIGCHLD, sigchld);
		break;
	}
	return cmdfd;
}

size_t
ttyread(void)
{
	static char buf[BUFSIZ];
	static int buflen = 0;
	int ret, written;

	// Añadir los bytes leídos a los bytes no procesados
	ret = read(cmdfd, buf+buflen, LEN(buf)-buflen);

	switch (ret) {
	case 0:
		exit(0);
	case -1:
		die("couldn't read from shell: %s\n", strerror(errno));
	default:
		buflen += ret;
		written = twrite(buf, buflen, 0);
		buflen -= written;
		// Mantener una secuencia de bits UTF-8 incompleta para la siguiente llamada
		if (buflen > 0)
			memmove(buf, buf + written, buflen);
		return ret;
	}
}

void
ttywrite(const char *s, size_t n, int may_echo)
{
	const char *next;

	kscrolldown(&((Arg){ .i = term.scr }));
	if (may_echo && IS_SET(MODE_ECHO))
		twrite(s, n, 1);

	if (!IS_SET(MODE_CRLF)) {
		ttywriteraw(s, n);
		return;
	}

	// Esto es similar a como el kernel maneja ONLCR para las tty
	while (n > 0) {
		if (*s == '\r') {
			next = s + 1;
			ttywriteraw("\r\n", 2);
		} else {
			next = memchr(s, '\r', n);
			DEFAULT(next, s + n);
			ttywriteraw(s, next - s);
		}
		n -= next - s;
		s = next;
	}
}

void
ttywriteraw(const char *s, size_t n)
{
	fd_set wfd, rfd;
	ssize_t r;
	size_t lim = 256;

	// Recuerda que estamos usando una pty, que puede ser una línea de modem
	// Escribir demasiado atascará la línea. Por eso estamos haciendo este apaño
	while (n > 0) {
		FD_ZERO(&wfd);
		FD_ZERO(&rfd);
		FD_SET(cmdfd, &wfd);
		FD_SET(cmdfd, &rfd);

		// Comprobar que podemos escribir
		if (pselect(cmdfd+1, &rfd, &wfd, NULL, NULL, NULL) < 0) {
			if (errno == EINTR)
				continue;
			die("select failed: %s\n", strerror(errno));
		}
		if (FD_ISSET(cmdfd, &wfd)) {
			// Escribir solo los bytes escritos por ttywrite() o el
			// por defecto de 256, que parece ser un valor razonable
			// para una linea serie. Valores mayores podrían atascar la Entrada/Salida
			if ((r = write(cmdfd, s, (n < lim)? n : lim)) < 0)
				goto write_error;
			if (r < n) {
				// No pudimos escribir todo. Esto significa que el
				// buffer se está llenando otra vez. Vacíelo
				if (n < lim)
					lim = ttyread();
				n -= r;
				s += r;
			} else {
				// Todos los bytes han sido escritos
				break;
			}
		}
		if (FD_ISSET(cmdfd, &rfd))
			lim = ttyread();
	}
	return;

write_error:
	die("write error on tty: %s\n", strerror(errno));
}

void
ttyresize(int tw, int th)
{
	struct winsize w;

	w.ws_row = term.row;
	w.ws_col = term.col;
	w.ws_xpixel = tw;
	w.ws_ypixel = th;
	if (ioctl(cmdfd, TIOCSWINSZ, &w) < 0)
		fprintf(stderr, "Couldn't set window size: %s\n", strerror(errno));
}

void
ttyhangup(void)
{
	// Enviar SIGHUP al shell
	kill(pid, SIGHUP);
}

int
tattrset(int attr)
{
	int i, j;

	for (i = 0; i < term.row-1; i++) {
		for (j = 0; j < term.col-1; j++) {
			if (term.line[i][j].mode & attr)
				return 1;
		}
	}

	return 0;
}

void
tsetdirt(int top, int bot)
{
	int i;

	LIMIT(top, 0, term.row-1);
	LIMIT(bot, 0, term.row-1);

	for (i = top; i <= bot; i++)
		term.dirty[i] = 1;
}

void
tsetdirtattr(int attr)
{
	int i, j;

	for (i = 0; i < term.row-1; i++) {
		for (j = 0; j < term.col-1; j++) {
			if (term.line[i][j].mode & attr) {
				term.dirty[i] = 1;
				break;
			}
		}
	}
}

int tisaltscr(void)
{
	return IS_SET(MODE_ALTSCREEN);
}

void
tfulldirt(void)
{
	for (int i = 0; i < term.row; i++)
		term.dirty[i] = 1;
}

void
tcursor(int mode)
{
	static TCursor c[2];
	int alt = IS_SET(MODE_ALTSCREEN);

	if (mode == CURSOR_SAVE) {
		c[alt] = term.c;
	} else if (mode == CURSOR_LOAD) {
		term.c = c[alt];
		tmoveto(c[alt].x, c[alt].y);
	}
}

void
tresetcursor(void)
{
	term.c = (TCursor){ { .mode = ATTR_NULL, .fg = defaultfg, .bg = defaultbg },
		.x = 0, .y = 0, .state = CURSOR_DEFAULT };
}

void
treset(void)
{
	uint i;
	int x, y;

	tresetcursor();

	memset(term.tabs, 0, term.col * sizeof(*term.tabs));
	for (i = tabspaces; i < term.col; i += tabspaces)
		term.tabs[i] = 1;
	term.top = 0;
	term.histf = 0;
	term.scr = 0;
	term.bot = term.row - 1;
	term.mode = MODE_WRAP|MODE_UTF8;
	memset(term.trantbl, CS_USA, sizeof(term.trantbl));
	term.charset = 0;

	selremove();
	for (i = 0; i < 2; i++) {
	tcursor(CURSOR_SAVE); // Restablecer cursor guardado
		for (y = 0; y < term.row; y++)
			for (x = 0; x < term.col; x++)
				tclearglyph(&term.line[y][x], 0);
		tswapscreen();
	}
	tfulldirt();
}

void
tnew(int col, int row)
{
	int i, j;

	for (i = 0; i < 2; i++) {
		term.line = xmalloc(row * sizeof(Line));
		for (j = 0; j < row; j++)
			term.line[j] = xmalloc(col * sizeof(Glyph));
		term.col = col, term.row = row;
		tswapscreen();
	}
	term.dirty = xmalloc(row * sizeof(*term.dirty));
	term.tabs = xmalloc(col * sizeof(*term.tabs));
	for (i = 0; i < HISTSIZE; i++)
		term.hist[i] = xmalloc(col * sizeof(Glyph));
	treset();
}

// Manejar con cuidado
void
tswapscreen(void)
{
	static Line *altline;
	static int altcol, altrow;
	Line *tmpline = term.line;
	int tmpcol = term.col, tmprow = term.row;

	term.line = altline;
	term.col = altcol, term.row = altrow;
	altline = tmpline;
	altcol = tmpcol, altrow = tmprow;
	term.mode ^= MODE_ALTSCREEN;
}

void
tloaddefscreen(int clear, int loadcursor)
{
	int col, row, alt = IS_SET(MODE_ALTSCREEN);

	if (alt) {
		if (clear)
			tclearregion(0, 0, term.col-1, term.row-1, 1);
		col = term.col, row = term.row;
		tswapscreen();
	}
	if (loadcursor)
		tcursor(CURSOR_LOAD);
	if (alt)
		tresizedef(col, row);
}

void
tloadaltscreen(int clear, int savecursor)
{
	int col, row, def = !IS_SET(MODE_ALTSCREEN);

	if (savecursor)
		tcursor(CURSOR_SAVE);
	if (def) {
		col = term.col, row = term.row;
		tswapscreen();
		term.scr = 0;
		tresizealt(col, row);
	}
	if (clear)
		tclearregion(0, 0, term.col-1, term.row-1, 1);
}

int
tisaltscreen(void)
{
	return IS_SET(MODE_ALTSCREEN);
}

void
kscrolldown(const Arg* a)
{
	int n = a->i;

	if (!term.scr || IS_SET(MODE_ALTSCREEN))
		return;

	if (n < 0)
		n = MAX(term.row / -n, 1);

	if (n <= term.scr) {
		term.scr -= n;
	} else {
		n = term.scr;
		term.scr = 0;
	}

	if (sel.ob.x != -1 && !sel.alt)
		selmove(-n); // Invalidar cambio en term.scr
	tfulldirt();
}

void
kscrollup(const Arg* a)
{
	int n = a->i;

	if (!term.histf || IS_SET(MODE_ALTSCREEN))
		return;

	if (n < 0)
		n = MAX(term.row / -n, 1);

	if (term.scr + n <= term.histf) {
		term.scr += n;
	} else {
		n = term.histf - term.scr;
		term.scr = term.histf;
	}

	if (sel.ob.x != -1 && !sel.alt)
		selmove(n); // Invalidar cambio en term.scr
	tfulldirt();
}

void
tscrolldown(int top, int n)
{
	int i, bot = term.bot;
	Line temp;

	if (n <= 0)
		return;
	n = MIN(n, bot-top+1);

	tsetdirt(top, bot-n);
	tclearregion(0, bot-n+1, term.col-1, bot, 1);

	for (i = bot; i >= top+n; i--) {
		temp = term.line[i];
		term.line[i] = term.line[i-n];
		term.line[i-n] = temp;
	}

	if (sel.ob.x != -1 && sel.alt == IS_SET(MODE_ALTSCREEN))
		selscroll(top, bot, n);
}

void
tscrollup(int top, int bot, int n, int mode)
{
	int i, j, s;
	int alt = IS_SET(MODE_ALTSCREEN);
	int savehist = !alt && top == 0 && mode != SCROLL_NOSAVEHIST;
	Line temp;

	if (n <= 0)
		return;
	n = MIN(n, bot-top+1);

	if (savehist) {
		for (i = 0; i < n; i++) {
			term.histi = (term.histi + 1) % HISTSIZE;
			temp = term.hist[term.histi];
			for (j = 0; j < term.col; j++)
				tclearglyph(&temp[j], 1);
			term.hist[term.histi] = term.line[i];
			term.line[i] = temp;
		}
		term.histf = MIN(term.histf + n, HISTSIZE);
		s = n;
		if (term.scr) {
			j = term.scr;
			term.scr = MIN(j + n, HISTSIZE);
			s = j + n - term.scr;
		}
		if (mode != SCROLL_RESIZE)
			tfulldirt();
	} else {
		tclearregion(0, top, term.col-1, top+n-1, 1);
		tsetdirt(top+n, bot);
	}

	for (i = top; i <= bot-n; i++) {
		temp = term.line[i];
		term.line[i] = term.line[i+n];
		term.line[i+n] = temp;
	}

	if (sel.ob.x != -1 && sel.alt == alt) {
		if (!savehist) {
			selscroll(top, bot, -n);
		} else if (s > 0) {
			selmove(-s);
			if (-term.scr + sel.nb.y < -term.histf)
				selremove();
		}
	}
}

void
selmove(int n)
{
	sel.ob.y += n, sel.nb.y += n;
	sel.oe.y += n, sel.ne.y += n;
}

void
selscroll(int top, int bot, int n)
{
	// Convertir las coordenadas absolutas en relativas
	top += term.scr, bot += term.scr;

	if (BETWEEN(sel.nb.y, top, bot) != BETWEEN(sel.ne.y, top, bot)) {
		selclear();
	} else if (BETWEEN(sel.nb.y, top, bot)) {
		selmove(n);
		if (sel.nb.y < top || sel.ne.y > bot)
			selclear();
	}
}

void
tnewline(int first_col)
{
	int y = term.c.y;

	if (y == term.bot) {
		tscrollup(term.top, term.bot, 1, SCROLL_SAVEHIST);
	} else {
		y++;
	}
	tmoveto(first_col ? 0 : term.c.x, y);
}

void
csiparse(void)
{
	char *p = csiescseq.buf, *np;
	long int v;
	int sep = ';'; // Dos puntos o punto y coma, pero no ambos

	csiescseq.narg = 0;
	if (*p == '?') {
		csiescseq.priv = 1;
		p++;
	}

	csiescseq.buf[csiescseq.len] = '\0';
	while (p < csiescseq.buf+csiescseq.len) {
		np = NULL;
		v = strtol(p, &np, 10);
		if (np == p)
			v = 0;
		if (v == LONG_MAX || v == LONG_MIN)
			v = -1;
		csiescseq.arg[csiescseq.narg++] = v;
		p = np;
		if (sep == ';' && *p == ':')
			sep = ':'; // Permitir anular a dos puntos una vez
		if (*p != sep || csiescseq.narg == ESC_ARG_SIZ)
			break;
		p++;
	}
	csiescseq.mode[0] = *p++;
	csiescseq.mode[1] = (p < csiescseq.buf+csiescseq.len) ? *p : '\0';
}

// Para movimientos absolutos del usuario, cuando decom está configurado
void
tmoveato(int x, int y)
{
	tmoveto(x, y + ((term.c.state & CURSOR_ORIGIN) ? term.top: 0));
}

void
tmoveto(int x, int y)
{
	int miny, maxy;

	if (term.c.state & CURSOR_ORIGIN) {
		miny = term.top;
		maxy = term.bot;
	} else {
		miny = 0;
		maxy = term.row - 1;
	}
	term.c.state &= ~CURSOR_WRAPNEXT;
	term.c.x = LIMIT(x, 0, term.col-1);
	term.c.y = LIMIT(y, miny, maxy);
}

void
tsetchar(Rune u, const Glyph *attr, int x, int y)
{
	static const char *vt100_0[62] = { // 0x41 - 0x7e
		"↑", "↓", "→", "←", "█", "▚", "☃", // A - G
		0, 0, 0, 0, 0, 0, 0, 0, // H - O
		0, 0, 0, 0, 0, 0, 0, 0, // P - W
		0, 0, 0, 0, 0, 0, 0, " ", // X - _
		"◆", "▒", "␉", "␌", "␍", "␊", "°", "±", // ` - g
		"␤", "␋", "┘", "┐", "┌", "└", "┼", "⎺", // h - o
		"⎻", "─", "⎼", "⎽", "├", "┤", "┴", "┬", // p - w
		"│", "≤", "≥", "π", "≠", "£", "·", // x - ~
	};

	// La tabla es orgullosamente robada de rxvt
	if (term.trantbl[term.charset] == CS_GRAPHIC0 &&
	   BETWEEN(u, 0x41, 0x7e) && vt100_0[u - 0x41])
		utf8decode(vt100_0[u - 0x41], &u, UTF_SIZ);

	if (term.line[y][x].mode & ATTR_WIDE) {
		if (x+1 < term.col) {
			term.line[y][x+1].u = ' ';
			term.line[y][x+1].mode &= ~ATTR_WDUMMY;
		}
	} else if (term.line[y][x].mode & ATTR_WDUMMY) {
		term.line[y][x-1].u = ' ';
		term.line[y][x-1].mode &= ~ATTR_WIDE;
  }

	term.dirty[y] = 1;
	term.line[y][x] = *attr;
	term.line[y][x].u = u;
	term.line[y][x].mode |= ATTR_SET;
}

void
tclearglyph(Glyph *gp, int usecurattr)
{
	if (usecurattr) {
		gp->fg = term.c.attr.fg;
		gp->bg = term.c.attr.bg;
	} else {
		gp->fg = defaultfg;
		gp->bg = defaultbg;
	}
	gp->mode = ATTR_NULL;
	gp->u = ' ';
}

void
tclearregion(int x1, int y1, int x2, int y2, int usecurattr)
{
	int x, y;

	// regionselected() toma coordenadas relativas
	if (regionselected(x1+term.scr, y1+term.scr, x2+term.scr, y2+term.scr))
		selremove();

	for (y = y1; y <= y2; y++) {
		term.dirty[y] = 1;
		for (x = x1; x <= x2; x++)
			tclearglyph(&term.line[y][x], usecurattr);
	}
}

void
tdeletechar(int n)
{
	int src, dst, size;
	Line line;

	if (n <= 0)
		return;
	dst = term.c.x;
	src = MIN(term.c.x + n, term.col);
	size = term.col - src;
	if (size > 0) { // Si no, src apuntaria fuera del array
			// https://stackoverflow.com/questions/29844298
		line = term.line[term.c.y];
		memmove(&line[dst], &line[src], size * sizeof(Glyph));
	}
	tclearregion(dst + size, term.c.y, term.col - 1, term.c.y, 1);
}

void
tinsertblank(int n)
{
	int src, dst, size;
	Line line;

	if (n <= 0)
		return;
	dst = MIN(term.c.x + n, term.col);
	src = term.c.x;
	size = term.col - dst;
	if (size > 0) { // Si no, dst apuntaria fuera del array
		line = term.line[term.c.y];
		memmove(&line[dst], &line[src], size * sizeof(Glyph));
	}
	tclearregion(src, term.c.y, dst - 1, term.c.y, 1);
}

void
tinsertblankline(int n)
{
	if (BETWEEN(term.c.y, term.top, term.bot))
		tscrolldown(term.c.y, n);
}

void
tdeleteline(int n)
{
	if (BETWEEN(term.c.y, term.top, term.bot))
		tscrollup(term.c.y, term.bot, n, SCROLL_NOSAVEHIST);
}

int32_t
tdefcolor(const int *attr, int *npar, int l)
{
	int32_t idx = -1;
	uint r, g, b;

	switch (attr[*npar + 1]) {
	case 2: // Color directo en espacio RGB
		if (*npar + 4 >= l) {
			fprintf(stderr,
				"erresc(38): Incorrect number of parameters (%d)\n",
				*npar);
			break;
		}
		r = attr[*npar + 2];
		g = attr[*npar + 3];
		b = attr[*npar + 4];
		*npar += 4;
		if (!BETWEEN(r, 0, 255) || !BETWEEN(g, 0, 255) || !BETWEEN(b, 0, 255))
			fprintf(stderr, "erresc: bad rgb color (%u,%u,%u)\n",
				r, g, b);
		else
			idx = TRUECOLOR(r, g, b);
		break;
	case 5: // Color indexado
		if (*npar + 2 >= l) {
			fprintf(stderr,
				"erresc(38): Incorrect number of parameters (%d)\n",
				*npar);
			break;
		}
		*npar += 2;
		if (!BETWEEN(attr[*npar], 0, 255))
			fprintf(stderr, "erresc: bad fgcolor %d\n", attr[*npar]);
		else
			idx = attr[*npar];
		break;
	case 0: // Implementado y definido (sólo fuente)
	case 1: // Transparente
	case 3: // Color directo en espacio CMY
	case 4: // Color directo en espacio CMYK
	default:
		fprintf(stderr,
			"erresc(38): gfx attr %d unknown\n", attr[*npar]);
		break;
	}

	return idx;
}

void
tsetattr(const int *attr, int l)
{
	int i;
	int32_t idx;

	for (i = 0; i < l; i++) {
		switch (attr[i]) {
		case 0:
			term.c.attr.mode &= ~(
				ATTR_BOLD       |
				ATTR_FAINT      |
				ATTR_ITALIC     |
				ATTR_UNDERLINE  |
				ATTR_BLINK      |
				ATTR_REVERSE    |
				ATTR_INVISIBLE  |
				ATTR_STRUCK     );
			term.c.attr.fg = defaultfg;
			term.c.attr.bg = defaultbg;
			break;
		case 1:
			term.c.attr.mode |= ATTR_BOLD;
			break;
		case 2:
			term.c.attr.mode |= ATTR_FAINT;
			break;
		case 3:
			term.c.attr.mode |= ATTR_ITALIC;
			break;
		case 4:
			term.c.attr.mode |= ATTR_UNDERLINE;
			break;
		case 5: // Parpadeo lento
			// FALLTHROUGH
		case 6: // Parpadeo rapido
			term.c.attr.mode |= ATTR_BLINK;
			break;
		case 7:
			term.c.attr.mode |= ATTR_REVERSE;
			break;
		case 8:
			term.c.attr.mode |= ATTR_INVISIBLE;
			break;
		case 9:
			term.c.attr.mode |= ATTR_STRUCK;
			break;
		case 22:
			term.c.attr.mode &= ~(ATTR_BOLD | ATTR_FAINT);
			break;
		case 23:
			term.c.attr.mode &= ~ATTR_ITALIC;
			break;
		case 24:
			term.c.attr.mode &= ~ATTR_UNDERLINE;
			break;
		case 25:
			term.c.attr.mode &= ~ATTR_BLINK;
			break;
		case 27:
			term.c.attr.mode &= ~ATTR_REVERSE;
			break;
		case 28:
			term.c.attr.mode &= ~ATTR_INVISIBLE;
			break;
		case 29:
			term.c.attr.mode &= ~ATTR_STRUCK;
			break;
		case 38:
			if ((idx = tdefcolor(attr, &i, l)) >= 0)
				term.c.attr.fg = idx;
			break;
		case 39:
			term.c.attr.fg = defaultfg;
			break;
		case 48:
			if ((idx = tdefcolor(attr, &i, l)) >= 0)
				term.c.attr.bg = idx;
			break;
		case 49:
			term.c.attr.bg = defaultbg;
			break;
		default:
			if (BETWEEN(attr[i], 30, 37)) {
				term.c.attr.fg = attr[i] - 30;
			} else if (BETWEEN(attr[i], 40, 47)) {
				term.c.attr.bg = attr[i] - 40;
			} else if (BETWEEN(attr[i], 90, 97)) {
				term.c.attr.fg = attr[i] - 90 + 8;
			} else if (BETWEEN(attr[i], 100, 107)) {
				term.c.attr.bg = attr[i] - 100 + 8;
			} else {
				fprintf(stderr,
					"erresc(default): gfx attr %d unknown\n",
					attr[i]);
				csidump();
			}
			break;
		}
	}
}

void
tsetscroll(int t, int b)
{
	int temp;

	LIMIT(t, 0, term.row-1);
	LIMIT(b, 0, term.row-1);
	if (t > b) {
		temp = t;
		t = b;
		b = temp;
	}
	term.top = t;
	term.bot = b;
}

void
tsetmode(int priv, int set, const int *args, int narg)
{
	const int *lim;

	for (lim = args + narg; args < lim; ++args) {
		if (priv) {
			switch (*args) {
			case 1: // DECCKM - Tabla de cursores
				xsetmode(set, MODE_APPCURSOR);
				break;
			case 5: // DECSCNM - Modo reverso
				xsetmode(set, MODE_REVERSE);
				break;
			case 6: // DECOM - Origen
				MODBIT(term.c.state, set, CURSOR_ORIGIN);
				tmoveato(0, 0);
				break;
			case 7: // DECAWM - Auto wrap
				MODBIT(term.mode, set, MODE_WRAP);
				break;
			case 0:  // Error (IGNORADO)
			case 2:  // DECANM - ANSI/VT52 (IGNORADO)
			case 3:  // DECCOLM - Columna (IGNORADO)
			case 4:  // DECSCLM - Desplazarse(IGNORADO)
			case 8:  // DECARM - Autorepetir (IGNORADO)
			case 18: // DECPFF - Alimentación de la impresión (IGNORADO)
			case 19: // DECPEX - Alcance de la impresora (IGNORADO)
			case 42: // DECNRCM - Caracteres nacionales (IGNORADO)
			case 12: // att610 - Empezar cursor parpadeante (IGNORADO)
				break;
			case 25: // DECTCEM - Habilitación del cursor de texto
				xsetmode(!set, MODE_HIDE);
				break;
			case 9: // Modo de compatibilidad de ratones con X10
				xsetpointermotion(0);
				xsetmode(0, MODE_MOUSE);
				xsetmode(set, MODE_MOUSEX10);
				break;
			case 1000: // 1000: Reportar botón presionado
				xsetpointermotion(0);
				xsetmode(0, MODE_MOUSE);
				xsetmode(set, MODE_MOUSEBTN);
				break;
			case 1002: // 1002: Reportar movimiento o botón presionado
				xsetpointermotion(0);
				xsetmode(0, MODE_MOUSE);
				xsetmode(set, MODE_MOUSEMOTION);
				break;
			case 1003: // 1003: Activar todos los movimientos del ratón
				xsetpointermotion(set);
				xsetmode(0, MODE_MOUSE);
				xsetmode(set, MODE_MOUSEMANY);
				break;
			case 1004: // 1004: Enviar eventos de enfoque a la tty
				xsetmode(set, MODE_FOCUS);
				break;
			case 1006: // 1006: Modo de informe ampliado
				xsetmode(set, MODE_MOUSESGR);
				break;
			case 1034:
				xsetmode(set, MODE_8BIT);
				break;
			case 1049: // Cambiar pantalla y establecer/restaurar cursor como xterm
			case 47: // Intercambiar pantallas
			case 1047: // Intercambiar pantalla, borrar todas las pantallas alternativas
				if (!allowaltscreen)
					break;
				if (set)
					tloadaltscreen(*args == 1049, *args == 1049);
				else
					tloaddefscreen(*args == 1047, *args == 1049);
				break;
			case 1048:
				if (!allowaltscreen)
					break;
				tcursor((set) ? CURSOR_SAVE : CURSOR_LOAD);
				break;
			case 2004: // 2004: Modo de pegado entre corchetes
				xsetmode(set, MODE_BRCKTPASTE);
				break;
			// Modos de ratón no implementados. Ver comentarios debajo:
			case 1001: // Modo de resaltado del ratón; puede colgar el
				   // terminal por diseño si implementado
			case 1005: // Modo de ratón UTF-8, confundirá aplicaciones que
				   // no soporten UTF-8 y luit
			case 1015: // Cursor de urxvt; incompatible y
				   // puede confundirse con otros códigos códigos
				break;
			default:
				fprintf(stderr,
					"erresc: unknown private set/reset mode %d\n",
					*args);
				break;
			}
		} else {
			switch (*args) {
			case 0: // Error (IGNORADO)
				break;
			case 2:
				xsetmode(set, MODE_KBDLOCK);
				break;
			case 4:  // IRM - Reemplazo de inserción
				MODBIT(term.mode, set, MODE_INSERT);
				break;
			case 12: // SRM - Enviar/Recibir
				MODBIT(term.mode, !set, MODE_ECHO);
				break;
			case 20: // Salto de línea/nueva línea
				MODBIT(term.mode, set, MODE_CRLF);
				break;
			default:
				fprintf(stderr,
					"erresc: unknown set/reset mode %d\n",
					*args);
				break;
			}
		}
	}
}

void
csihandle(void)
{
	char buf[40];
	int n, x;

	switch (csiescseq.mode[0]) {
	default:
	unknown:
		fprintf(stderr, "erresc: unknown csi ");
		csidump();
		// die("");
		break;
	case '@': // ICH - Insertar <n> caracteres vacios
		DEFAULT(csiescseq.arg[0], 1);
		tinsertblank(csiescseq.arg[0]);
		break;
	case 'A': // CUU - Mover el cursor <n> veces arriba
		DEFAULT(csiescseq.arg[0], 1);
		tmoveto(term.c.x, term.c.y-csiescseq.arg[0]);
		break;
	case 'B': // CUD - Mover el cursor <n> veces abajo
	case 'e': // VPR - Mover el cursor <n> veces abajo
		DEFAULT(csiescseq.arg[0], 1);
		tmoveto(term.c.x, term.c.y+csiescseq.arg[0]);
		break;
	case 'i': // MC - Copia de medios
		switch (csiescseq.arg[0]) {
		case 0:
			tdump();
			break;
		case 1:
			tdumpline(term.c.y);
			break;
		case 2:
			tdumpsel();
			break;
		case 4:
			term.mode &= ~MODE_PRINT;
			break;
		case 5:
			term.mode |= MODE_PRINT;
			break;
		}
		break;
	case 'c': // DA - Atributos del dispositivo
		if (csiescseq.arg[0] == 0)
			ttywrite(vtiden, strlen(vtiden), 0);
		break;
	case 'b': // REP - Si el último caracter es imprimible, imprímelo <n> veces mas
		LIMIT(csiescseq.arg[0], 1, 65535);
		if (term.lastc)
			while (csiescseq.arg[0]-- > 0)
				tputc(term.lastc);
		break;
	case 'C': // CUF - Mover el cursor <n> veces hacia adelante
	case 'a': // HPR - Mover el cursor <n> veces hacia adelante
		DEFAULT(csiescseq.arg[0], 1);
		tmoveto(term.c.x+csiescseq.arg[0], term.c.y);
		break;
	case 'D': // CUB - Mover el cursor <n> veces hacia atrás
		DEFAULT(csiescseq.arg[0], 1);
		tmoveto(term.c.x-csiescseq.arg[0], term.c.y);
		break;
	case 'E': // CNL - Mover el cursor <n> veces abajo y a la primera columna
		DEFAULT(csiescseq.arg[0], 1);
		tmoveto(0, term.c.y+csiescseq.arg[0]);
		break;
	case 'F': // CPL - Mover el cursor <n> veces arriba y a la primera columna
		DEFAULT(csiescseq.arg[0], 1);
		tmoveto(0, term.c.y-csiescseq.arg[0]);
		break;
	case 'g': // TBC - Limpiar tabulaciones
		switch (csiescseq.arg[0]) {
		case 0: // Limpiar el tab stop actual
			term.tabs[term.c.x] = 0;
			break;
		case 3: // Limpiar todas las tabulaciones
			memset(term.tabs, 0, term.col * sizeof(*term.tabs));
			break;
		default:
			goto unknown;
		}
		break;
	case 'G': // CHA - Moverse de columna
	case '`': // HPA
		DEFAULT(csiescseq.arg[0], 1);
		tmoveto(csiescseq.arg[0]-1, term.c.y);
		break;
	case 'H': // CUP - Moverse al la columna y fila indicadas
	case 'f': // HVP
		DEFAULT(csiescseq.arg[0], 1);
		DEFAULT(csiescseq.arg[1], 1);
		tmoveato(csiescseq.arg[1]-1, csiescseq.arg[0]-1);
		break;
	case 'I': // CHT - Tabulación hacia adelante del cursor: <n> tabulaciones
		DEFAULT(csiescseq.arg[0], 1);
		tputtab(csiescseq.arg[0]);
		break;
	case 'J': // ED - Limpiar pantalla
		switch (csiescseq.arg[0]) {
		case 0: // Abajo
			tclearregion(term.c.x, term.c.y, term.col-1, term.c.y, 1);
			if (term.c.y < term.row-1) {
				tclearregion(0, term.c.y+1, term.col-1, term.row-1, 1);
			}
			break;
		case 1: // Arriba
			if (term.c.y >= 1)
				tclearregion(0, 0, term.col-1, term.c.y-1, 1);
			tclearregion(0, term.c.y, term.c.x, term.c.y, 1);
			break;
		case 2: // Todo
			if (IS_SET(MODE_ALTSCREEN)) {
  			tclearregion(0, 0, term.col-1, term.row-1, 1);
  			break;
			}
			// Esto es loo que hace vte:
			// tscrollup(0, term.row-1, term.row, SCROLL_SAVEHIST);

			// Y esto es lo que hace alacritty:
			for (n = term.row-1; n >= 0 && tlinelen(term.line[n]) == 0; n--);
			if (n >= 0)
				tscrollup(0, term.row-1, n+1, SCROLL_SAVEHIST);
			tscrollup(0, term.row-1, term.row-n-1, SCROLL_NOSAVEHIST);
		break;
		default:
			goto unknown;
		}
		break;
	case 'K': // EL - Limpiar lineas
		switch (csiescseq.arg[0]) {
		case 0: // Derecha
			tclearregion(term.c.x, term.c.y, term.col-1, term.c.y, 1);
			break;
		case 1: // Izquierda
			tclearregion(0, term.c.y, term.c.x, term.c.y, 1);
			break;
		case 2: // Todo
			tclearregion(0, term.c.y, term.col-1, term.c.y, 1);
			break;
		}
		break;
	case 'S': // SU - Desplazarse <n> lineas arriba
		if (csiescseq.priv) break;
		DEFAULT(csiescseq.arg[0], 1);
		// xterm, urxvt, alacritty guardan esto en el historial
		tscrollup(term.top, term.bot, csiescseq.arg[0], SCROLL_SAVEHIST);
		break;
	case 'T': // SD - Desplazarse <n> lineas abajo
		DEFAULT(csiescseq.arg[0], 1);
		tscrolldown(term.top, csiescseq.arg[0]);
		break;
	case 'L': // IL - Insertar <n> lineas vacías
		DEFAULT(csiescseq.arg[0], 1);
		tinsertblankline(csiescseq.arg[0]);
		break;
	case 'l': // RM - Modo reset
		tsetmode(csiescseq.priv, 0, csiescseq.arg, csiescseq.narg);
		break;
	case 'M': // DL - Borrar <n> lineas
		DEFAULT(csiescseq.arg[0], 1);
		tdeleteline(csiescseq.arg[0]);
		break;
	case 'X': // ECH - Borrar <n> caracteres
		if (csiescseq.arg[0] < 0)
			return;
		DEFAULT(csiescseq.arg[0], 1);
		x = MIN(term.c.x + csiescseq.arg[0], term.col) - 1;
		tclearregion(term.c.x, term.c.y, x, term.c.y, 1);
		break;
	case 'P': // DCH - Borrar <n> caracteres
		DEFAULT(csiescseq.arg[0], 1);
		tdeletechar(csiescseq.arg[0]);
		break;
	case 'Z': // CBT - Tabulación del cursor hacia atrás <n> tabulaciones
		DEFAULT(csiescseq.arg[0], 1);
		tputtab(-csiescseq.arg[0]);
		break;
	case 'd': // VPA - Moverse a la <columna>
		DEFAULT(csiescseq.arg[0], 1);
		tmoveato(term.c.x, csiescseq.arg[0]-1);
		break;
	case 'h': // SM - Establecer el modo terminal
		tsetmode(csiescseq.priv, 1, csiescseq.arg, csiescseq.narg);
		break;
	case 'm': // SGR - Atributo terminal (color)
		tsetattr(csiescseq.arg, csiescseq.narg);
		break;
	case 'n': // DSR - Informe de estado del dispositivo
		switch (csiescseq.arg[0]) {
		case 5: // Informe de estado "OK" `Encendido`
			ttywrite("\033[0n", sizeof("\033[0n") - 1, 0);
			break;
		case 6: // Posición del cursor del informe (CPR) "<fila>;<columna>R"
			n = snprintf(buf, sizeof(buf), "\033[%i;%iR",
				term.c.y+1, term.c.x+1);
			ttywrite(buf, n, 0);
			break;
		default:
			goto unknown;
		}
		break;
	case 'r': // DECSTBM - Establecer región de desplazamiento
		if (csiescseq.priv) {
			goto unknown;
		} else {
			DEFAULT(csiescseq.arg[0], 1);
			DEFAULT(csiescseq.arg[1], term.row);
			tsetscroll(csiescseq.arg[0]-1, csiescseq.arg[1]-1);
			tmoveato(0, 0);
		}
		break;
	case 's': // DECSC - Guardar la posición del cursor (ANSI.SYS)
		tcursor(CURSOR_SAVE);
		break;
	case 'u': // DECRC - Restaurar posición del cursor (ANSI.SYS)
		tcursor(CURSOR_LOAD);
		break;
	case ' ':
		switch (csiescseq.mode[1]) {
		case 'q': // DECSCUSR - Establecer el estilo del cursor
			if (xsetcursor(csiescseq.arg[0]))
				goto unknown;
			break;
		default:
			goto unknown;
		}
		break;
	case 't': // Operaciones de pila
		switch (csiescseq.arg[0]) {
		case 22: // Operaciones de pila de títulos
			switch (csiescseq.arg[1]) {
			case 0:
			case 1:
			case 2:
				xpushtitle();
				break;
			default:
				goto unknown;
			}
			break;
		case 23: // Sacar el último título de la pila
			switch (csiescseq.arg[1]) {
			case 0:
			case 1:
			case 2:
				xsettitle(NULL, 1);
				break;
			default:
				goto unknown;
			}
			break;
		default:
			goto unknown;
		}
	}
}

void
csidump(void)
{
	size_t i;
	uint c;

	fprintf(stderr, "ESC[");
	for (i = 0; i < csiescseq.len; i++) {
		c = csiescseq.buf[i] & 0xff;
		if (isprint(c)) {
			putc(c, stderr);
		} else if (c == '\n') {
			fprintf(stderr, "(\\n)");
		} else if (c == '\r') {
			fprintf(stderr, "(\\r)");
		} else if (c == 0x1b) {
			fprintf(stderr, "(\\e)");
		} else {
			fprintf(stderr, "(%02x)", c);
		}
	}
	putc('\n', stderr);
}

void
csireset(void)
{
	memset(&csiescseq, 0, sizeof(csiescseq));
}

void
osc_color_response(int num, int index, int is_osc4)
{
	int n;
	char buf[32];
	unsigned char r, g, b;

	if (xgetcolor(is_osc4 ? num : index, &r, &g, &b)) {
		fprintf(stderr, "erresc: failed to fetch %s color %d\n",
		is_osc4 ? "osc4" : "osc",
		is_osc4 ? num : index);
		return;
	}

	n = snprintf(buf, sizeof buf, "\033]%s%d;rgb:%02x%02x/%02x%02x/%02x%02x\007",
		is_osc4 ? "4;" : "", num, r, r, g, g, b, b);
	if (n < 0 || n >= sizeof(buf)) {
		fprintf(stderr, "error: %s while printing %s response\n",
		n < 0 ? "snprintf failed" : "truncation occurred",
		is_osc4 ? "osc4" : "osc");
	} else {
		ttywrite(buf, n, 1);
	}
}

void
strhandle(void)
{
	char *p = NULL, *dec;
	int j, narg, par;
	const struct { int idx; char *str; } osc_table[] = {
		{ defaultfg, "foreground" },
		{ defaultbg, "background" },
		{ defaultcs, "cursor" }
	};

	term.esc &= ~(ESC_STR_END|ESC_STR);
	strparse();
	par = (narg = strescseq.narg) ? atoi(strescseq.args[0]) : 0;

	switch (strescseq.type) {
	case ']': // OSC - Comando del sistema operativo
		switch (par) {
		case 0:
			if (narg > 1) {
				xsettitle(strescseq.args[1], 0);
				xseticontitle(strescseq.args[1]);
			}
			return;
		case 1:
			if (narg > 1)
				xseticontitle(strescseq.args[1]);
			return;
		case 2:
			if (narg > 1)
				xsettitle(strescseq.args[1], 0);
			return;
		case 52:
			if (narg > 2 && allowwindowops) {
				dec = base64dec(strescseq.args[2]);
				if (dec) {
					xsetsel(dec);
					xclipcopy();
				} else {
					fprintf(stderr, "erresc: invalid base64\n");
				}
			}
			return;
		case 10:
		case 11:
		case 12:
			if (narg < 2)
				break;
			p = strescseq.args[1];
			if ((j = par - 10) < 0 || j >= LEN(osc_table))
				break; // No debería ser posible

			if (!strcmp(p, "?")) {
				osc_color_response(par, osc_table[j].idx, 0);
			} else if (xsetcolorname(osc_table[j].idx, p)) {
				fprintf(stderr, "erresc: invalid %s color: %s\n",
					osc_table[j].str, p);
			} else {
				tfulldirt();
			}
			return;
		case 4: // Conjunto de colores
			if (narg < 3)
				break;
			p = strescseq.args[2];
			// Continuación
		case 104: // Reajuste de color
			j = (narg > 1) ? atoi(strescseq.args[1]) : -1;

			if (p && !strcmp(p, "?")) {
				osc_color_response(j, 0, 1);
			} else if (xsetcolorname(j, p)) {
				if (par == 104 && narg <= 1) {
					xloadcols();
					return; // Restablecimiento del color sin parámetro
				}
				fprintf(stderr, "erresc: invalid color j=%d, p=%s\n",
					j, p ? p : "(null)");
			} else {
				// TODO: si se cambia el color de `defaultbg`,
				// los bordes estarán sucios
				tfulldirt();
			}
			return;
		}
		break;
	case 'k': // Compatibilidad con el establecimiento de títulos antiguos
		xsettitle(strescseq.args[0], 0);
		return;
	case 'P': // DCS - Cadena de control del dispositivo
	case '_': // APC - Comando de programa de aplicación
	case '^': // PM - Mensaje privado
		return;
	}

	fprintf(stderr, "erresc: unknown str ");
	strdump();
}

void
strparse(void)
{
	int c;
	char *p = strescseq.buf;

	strescseq.narg = 0;
	strescseq.buf[strescseq.len] = '\0';

	if (*p == '\0')
		return;

	while (strescseq.narg < STR_ARG_SIZ) {
		strescseq.args[strescseq.narg++] = p;
		while ((c = *p) != ';' && c != '\0')
			++p;
		if (c == '\0')
			return;
		*p++ = '\0';
	}
}

void
externalpipe(const Arg *arg)
{
	int to[2];
	char buf[UTF_SIZ];
	void (*oldsigpipe)(int);
	Glyph *bp, *end;
	int lastpos, n, newline;

	if (pipe(to) == -1)
		return;

	switch (fork()) {
	case -1:
		close(to[0]);
		close(to[1]);
		return;
	case 0:
		dup2(to[0], STDIN_FILENO);
		close(to[0]);
		close(to[1]);
		execvp(((char **)arg->v)[0], (char **)arg->v);
		fprintf(stderr, "st: execvp %s\n", ((char **)arg->v)[0]);
		perror("failed");
		exit(0);
	}

	close(to[0]);
	// Ignorar SIGPIPE por ahora, en caso de que el proceso hijo termine temprano
	oldsigpipe = signal(SIGPIPE, SIG_IGN);
	newline = 0;
	for (n = 0; n <= HISTSIZE + 2; n++) {
		bp = TLINE_HIST(n);
		lastpos = MIN(tlinehistlen(n) + 1, term.col) - 1;
		if (lastpos < 0)
			break;
		if (lastpos == 0)
			continue;
		end = &bp[lastpos + 1];
		for (; bp < end; ++bp)
			if (xwrite(to[1], buf, utf8encode(bp->u, buf)) < 0)
				break;
		if ((newline = TLINE_HIST(n)[lastpos].mode & ATTR_WRAP))
			continue;
		if (xwrite(to[1], "\n", 1) < 0)
			break;
		newline = 0;
	}
	if (newline)
		(void)xwrite(to[1], "\n", 1);
	close(to[1]);
	// Restaurar
	signal(SIGPIPE, oldsigpipe);
}

void
strdump(void)
{
	size_t i;
	uint c;

	fprintf(stderr, "ESC%c", strescseq.type);
	for (i = 0; i < strescseq.len; i++) {
		c = strescseq.buf[i] & 0xff;
		if (c == '\0') {
			putc('\n', stderr);
			return;
		} else if (isprint(c)) {
			putc(c, stderr);
		} else if (c == '\n') {
			fprintf(stderr, "(\\n)");
		} else if (c == '\r') {
			fprintf(stderr, "(\\r)");
		} else if (c == 0x1b) {
			fprintf(stderr, "(\\e)");
		} else {
			fprintf(stderr, "(%02x)", c);
		}
	}
	fprintf(stderr, "ESC\\\n");
}

void
strreset(void)
{
	strescseq = (STREscape){
		.buf = xrealloc(strescseq.buf, STR_BUF_SIZ),
		.siz = STR_BUF_SIZ,
	};
}

void
sendbreak(const Arg *arg)
{
	if (tcsendbreak(cmdfd, 0))
		perror("Error sending break");
}

void
tprinter(char *s, size_t len)
{
	if (iofd != -1 && xwrite(iofd, s, len) < 0) {
		perror("Error writing to output file");
		close(iofd);
		iofd = -1;
	}
}

void
toggleprinter(const Arg *arg)
{
	term.mode ^= MODE_PRINT;
}

void
printscreen(const Arg *arg)
{
	tdump();
}

void
printsel(const Arg *arg)
{
	tdumpsel();
}

void
tdumpsel(void)
{
	char *ptr;

	if ((ptr = getsel())) {
		tprinter(ptr, strlen(ptr));
		free(ptr);
	}
}

void
tdumpline(int n)
{
	char str[(term.col + 1) * UTF_SIZ];
	tprinter(str, tgetline(str, &term.line[n][0]));
}

void
tdump(void)
{
	int i;

	for (i = 0; i < term.row; ++i)
		tdumpline(i);
}

void
tputtab(int n)
{
	uint x = term.c.x;

	if (n > 0) {
		while (x < term.col && n--)
			for (++x; x < term.col && !term.tabs[x]; ++x)
				/* Nada */ ;
	} else if (n < 0) {
		while (x > 0 && n++)
			for (--x; x > 0 && !term.tabs[x]; --x)
				/* Nada */ ;
	}
	term.c.x = LIMIT(x, 0, term.col-1);
}

void
tdefutf8(char ascii)
{
	if (ascii == 'G')
		term.mode |= MODE_UTF8;
	else if (ascii == '@')
		term.mode &= ~MODE_UTF8;
}

void
tdeftran(char ascii)
{
	static char cs[] = "0B";
	static int vcs[] = {CS_GRAPHIC0, CS_USA};
	char *p;

	if ((p = strchr(cs, ascii)) == NULL) {
		fprintf(stderr, "esc unhandled charset: ESC ( %c\n", ascii);
	} else {
		term.trantbl[term.icharset] = vcs[p - cs];
	}
}

void
tdectest(char c)
{
	int x, y;

	if (c == '8') { // Prueba de alineación de pantalla DEC
		for (x = 0; x < term.col; ++x) {
			for (y = 0; y < term.row; ++y)
				tsetchar('E', &term.c.attr, x, y);
		}
	}
}

void
tstrsequence(uchar c)
{
	switch (c) {
	case 0x90:   // DCS - Cadena de Control de Dispositivo
		c = 'P';
		break;
	case 0x9f:   // APC - Comando de Programa de Aplicación
		c = '_';
		break;
	case 0x9e:   // PM - Mensaje privado
		c = '^';
		break;
	case 0x9d:   // OSC - Comando del sistema operativo
		c = ']';
		break;
	}
	strreset();
	strescseq.type = c;
	term.esc |= ESC_STR;
}

void
tcontrolcode(uchar ascii)
{
	switch (ascii) {
	case '\t': // HT
		tputtab(1);
		return;
	case '\b': // BS
		tmoveto(term.c.x-1, term.c.y);
		return;
	case '\r': // CR
		tmoveto(0, term.c.y);
		return;
	case '\f': // LF
	case '\v': // VT
	case '\n': // LF
		// Ir a la primer acolumna si el modo esta establecido
		tnewline(IS_SET(MODE_CRLF));
		return;
	case '\a': // BEL
		if (term.esc & ESC_STR_END) {
			// Compatibilidad retroactiva con xterm
			strhandle();
		} else {
			xbell();
		}
		break;
	case '\033': // ESC
		csireset();
		term.esc &= ~(ESC_CSI|ESC_ALTCHARSET|ESC_TEST);
		term.esc |= ESC_START;
		return;
	case '\016': // SO (LS1 - Bloqueo de mayúsculas 1)
	case '\017': // SI (LS0 - Bloqueo de mayúsculas 0)
		term.charset = 1 - (ascii - '\016');
		return;
	case '\032': // SUB
		tsetchar('?', &term.c.attr, term.c.x, term.c.y);
		// Continuación
	case '\030': // CAN
		csireset();
		break;
	case '\005': // ENQ (IGNORADO)
	case '\000': // NUL (IGNORADO)
	case '\021': // XON (IGNORADO)
	case '\023': // XOFF (IGNORADO)
	case 0177: // DEL (IGNORADO)
		return;
	case 0x80: // TODO: PAD
	case 0x81: // TODO: HOP
	case 0x82: // TODO: BPH
	case 0x83: // TODO: NBH
	case 0x84: // TODO: IND
		break;
	case 0x85: // NEL - Linea siguiente
		tnewline(1); // Ir a la primera columna
		break;
	case 0x86: // TODO: SSA
	case 0x87: // TODO: ESA
		break;
	case 0x88: // HTS - Parada de tabulación horizontal
		term.tabs[term.c.x] = 1;
		break;
	case 0x89: // TODO: HTJ
	case 0x8a: // TODO: VTS
	case 0x8b: // TODO: PLD
	case 0x8c: // TODO: PLU
	case 0x8d: // TODO: RI
	case 0x8e: // TODO: SS2
	case 0x8f: // TODO: SS3
	case 0x91: // TODO: PU1
	case 0x92: // TODO: PU2
	case 0x93: // TODO: STS
	case 0x94: // TODO: CCH
	case 0x95: // TODO: MW
	case 0x96: // TODO: SPA
	case 0x97: // TODO: EPA
	case 0x98: // TODO: SOS
	case 0x99: // TODO: SGCI
		break;
	case 0x9a: // DECID - Identificar terminal
		ttywrite(vtiden, strlen(vtiden), 0);
		break;
	case 0x9b: // TODO: CSI
	case 0x9c: // TODO: ST
		break;
	case 0x90: // DCS - Cadena de control del dispositivo */
	case 0x9d: // OSC - Comando del sistema operativo */
	case 0x9e: // PM - Mensaje Privado */
	case 0x9f: // APC - Comando de programa de aplicación */
		tstrsequence(ascii);
		return;
	}
	// Solo los caracteres CAN, SUB, \a y C1 interrumpen una secuencia
	term.esc &= ~(ESC_STR_END|ESC_STR);
}

// Devuelve 1 cuando la secuencia ha terminado y no necesita leer
// más caracteres para esta secuencia; de lo contrario, devuelve 0
int
eschandle(uchar ascii)
{
	switch (ascii) {
	case '[':
		term.esc |= ESC_CSI;
		return 0;
	case '#':
		term.esc |= ESC_TEST;
		return 0;
	case '%':
		term.esc |= ESC_UTF8;
		return 0;
	case 'P': // DCS - Cadena de control del dispositivo
	case '_': // APC - Comando de programa de aplicación
	case '^': // PM - Mensaje Privado
	case ']': // OSC - Comando del sistema operativo
	case 'k': // Compatibilidad con el establecimiento de títulos antiguos
		tstrsequence(ascii);
		return 0;
	case 'n': // LS2 - Bloqueo de mayúsculas 2
	case 'o': // LS3 - Bloqueo de mayúsculas 3
		term.charset = 2 + (ascii - 'n');
		break;
	case '(': // GZD4 - Establecer el conjunto de caracteres primario G0
	case ')': // G1D4 - Establecer el conjunto de caracteres secundario G1
	case '*': // G2D4 - Establecer el conjunto de caracteres terciario G2
	case '+': // G3D4 - Establecer el conjunto de caracteres cuaternario G3
		term.icharset = ascii - '(';
		term.esc |= ESC_ALTCHARSET;
		return 0;
	case 'D': // IND - Avance de línea
		if (term.c.y == term.bot) {
			tscrollup(term.top, term.bot, 1, SCROLL_SAVEHIST);
		} else {
			tmoveto(term.c.x, term.c.y+1);
		}
		break;
	case 'E': // NEL - Siguiente linea
		tnewline(1); // Ir siempre a la primera columna
		break;
	case 'H': // HTS - Parada de tabulación horizontal
		term.tabs[term.c.x] = 1;
		break;
	case 'M': // RI - Índice inverso
		if (term.c.y == term.top) {
			tscrolldown(term.top, 1);
		} else {
			tmoveto(term.c.x, term.c.y-1);
		}
		break;
	case 'Z': // DECID - Identificar terminal
		ttywrite(vtiden, strlen(vtiden), 0);
		break;
	case 'c': // RIS - Volver al estado inicial
		treset();
		xfreetitlestack();
		resettitle();
		xloadcols();
		xsetmode(0, MODE_HIDE);
		break;
	case '=': // DECPAM - Teclado de Aplicación
		xsetmode(1, MODE_APPKEYPAD);
		break;
	case '>': // DECPNM - Teclado normal
		xsetmode(0, MODE_APPKEYPAD);
		break;
	case '7': // DECSC - Guardar cursor
		tcursor(CURSOR_SAVE);
		break;
	case '8': // DECRC - Restaurar cursor
		tcursor(CURSOR_LOAD);
		break;
	case '\\': // ST - Finalizador de cadenas
		if (term.esc & ESC_STR_END)
			strhandle();
		break;
	default:
		fprintf(stderr, "erresc: unknown sequence ESC 0x%02X '%c'\n",
			(uchar) ascii, isprint(ascii)? ascii:'.');
		break;
	}
	return 1;
}

void
tputc(Rune u)
{
	char c[UTF_SIZ];
	int control;
	int width, len;
	Glyph *gp;

	control = ISCONTROL(u);
	if (u < 127 || !IS_SET(MODE_UTF8)) {
		c[0] = u;
		width = len = 1;
	} else {
		len = utf8encode(u, c);
		if (!control && (width = wcwidth(u)) == -1)
			width = 1;
	}

	if (IS_SET(MODE_PRINT))
		tprinter(c, len);

	// La secuencia STR debe comprobarse antes que cualquier otra
	// porque consume todos los caracteres siguientes hasta recibir
	// un ESC, un SUB, un ST, o cualquier otro carácter de control C1
	if (term.esc & ESC_STR) {
		if (u == '\a' || u == 030 || u == 032 || u == 033 ||
		   ISCONTROLC1(u)) {
			term.esc &= ~(ESC_START|ESC_STR);
			term.esc |= ESC_STR_END;
			goto check_control_code;
		}

		if (strescseq.len+len >= strescseq.siz) {
			// Aquí hay un bug en los terminales. Si el usuario nunca envía
			// algún código para detener el comando str o esc, entonces st
			// dejará de responder. Pero esto es mejor que
			// fallar silenciosamente con caracteres desconocidos. Por lo menos
			// entonces los usuarios informarán del fallo

			// En el caso de que los usuarios alguna vez se fijen, aquí está el código:
			// term.esc = 0;
			// strhandle();
			if (strescseq.siz > (SIZE_MAX - UTF_SIZ) / 2)
				return;
			strescseq.siz *= 2;
			strescseq.buf = xrealloc(strescseq.buf, strescseq.siz);
		}

		memmove(&strescseq.buf[strescseq.len], c, len);
		strescseq.len += len;
		return;
	}

check_control_code:
	// Las acciones de los códigos de control deben realizarse en cuanto llegan
	// porque pueden estar incrustadas dentro de una secuencia de control, y
	// no deben causar conflictos con las secuencias
	if (control) {
		// En el modo UTF-8, los caracteres de control C1 son ignorados
		if (IS_SET(MODE_UTF8) && ISCONTROLC1(u))
			return;
		tcontrolcode(u);
		// Los códigos de control nunca se muestran
		if (!term.esc)
			term.lastc = 0;
		return;
	} else if (term.esc & ESC_START) {
		if (term.esc & ESC_CSI) {
			csiescseq.buf[csiescseq.len++] = u;
			if (BETWEEN(u, 0x40, 0x7E)
					|| csiescseq.len >= \
					sizeof(csiescseq.buf)-1) {
				term.esc = 0;
				csiparse();
				csihandle();
			}
			return;
		} else if (term.esc & ESC_UTF8) {
			tdefutf8(u);
		} else if (term.esc & ESC_ALTCHARSET) {
			tdeftran(u);
		} else if (term.esc & ESC_TEST) {
			tdectest(u);
		} else {
			if (!eschandle(u))
				return;
			// La secuencia ya ha terminado
		}
		term.esc = 0;
		// Todos los caracteres que forman parte
		// de una secuencia no son impresos
		return;
	}
	// selected() toma coordenadas relativas
	if (selected(term.c.x + term.scr, term.c.y + term.scr))
		selclear();

	gp = &term.line[term.c.y][term.c.x];
	if (IS_SET(MODE_WRAP) && (term.c.state & CURSOR_WRAPNEXT)) {
		gp->mode |= ATTR_WRAP;
		tnewline(1);
		gp = &term.line[term.c.y][term.c.x];
	}

	if (IS_SET(MODE_INSERT) && term.c.x+width < term.col) {
		memmove(gp+width, gp, (term.col - term.c.x - width) * sizeof(Glyph));
		gp->mode &= ~ATTR_WIDE;
	}

	if (term.c.x+width > term.col) {
		if (IS_SET(MODE_WRAP))
			tnewline(1);
		else
			tmoveto(term.col - width, term.c.y);
		gp = &term.line[term.c.y][term.c.x];
	}

	tsetchar(u, &term.c.attr, term.c.x, term.c.y);
	term.lastc = u;

	if (width == 2) {
		gp->mode |= ATTR_WIDE;
		if (term.c.x+1 < term.col) {
			if (gp[1].mode == ATTR_WIDE && term.c.x+2 < term.col) {
				gp[2].u = ' ';
				gp[2].mode &= ~ATTR_WDUMMY;
			}
			gp[1].u = '\0';
			gp[1].mode = ATTR_WDUMMY;
		}
	}
	if (term.c.x+width < term.col) {
		tmoveto(term.c.x+width, term.c.y);
	} else {
		term.wrapcwidth[IS_SET(MODE_ALTSCREEN)] = width;
		term.c.state |= CURSOR_WRAPNEXT;
	}
}

int
twrite(const char *buf, int buflen, int show_ctrl)
{
	int charsize;
	Rune u;
	int n;

	for (n = 0; n < buflen; n += charsize) {
		if (IS_SET(MODE_UTF8)) {
			// Procesa un caracter uft8 completo
			charsize = utf8decode(buf + n, &u, buflen - n);
			if (charsize == 0)
				break;
		} else {
			u = buf[n] & 0xFF;
			charsize = 1;
		}
		if (show_ctrl && ISCONTROL(u)) {
			if (u & 0x80) {
				u &= 0x7f;
				tputc('^');
				tputc('[');
			} else if (u != '\n' && u != '\r' && u != '\t') {
				u ^= 0x40;
				tputc('^');
			}
		}
		tputc(u);
	}
	return n;
}

void
treflow(int col, int row)
{
	int i, j;
	int oce, nce, bot, scr;
	int ox = 0, oy = -term.histf, nx = 0, ny = -1, len;
	int cy = -1; // Intermediario para la nueva coordenada Y del cursor
	int nlines;
	Line *buf, line;

	// Coordenada y del final de la línea del cursor
	for (oce = term.c.y; oce < term.row - 1 &&
		tiswrapped(term.line[oce]); oce++);

	nlines = term.histf + oce + 1;
	if (col < term.col) {
		// Cada línea puede ocupar este número líneas después del reajuste */
		j = (term.col + col - 1) / col;
		nlines = j * nlines;
		if (nlines > HISTSIZE + RESIZEBUFFER + row) {
			nlines = HISTSIZE + RESIZEBUFFER + row;
			oy = -(nlines / j - oce - 1);
		}
	}
	buf = xmalloc(nlines * sizeof(Line));
	do {
		if (!nx)
			buf[++ny] = xmalloc(col * sizeof(Glyph));
		if (!ox) {
			line = TLINEABS(oy);
			len = tlinelen(line);
		}
		if (oy == term.c.y) {
			if (!ox)
				len = MAX(len, term.c.x + 1);
			// Actualizar cursor
			if (cy < 0 && term.c.x - ox < col - nx) {
				term.c.x = nx + term.c.x - ox, cy = ny;
				UPDATEWRAPNEXT(0, col);
			}
		}
		// Poner las líneas reajustadas en buf
		if (col - nx > len - ox) {
			memcpy(&buf[ny][nx], &line[ox], (len-ox) * sizeof(Glyph));
			nx += len - ox;
			if (len == 0 || !(line[len - 1].mode & ATTR_WRAP)) {
				for (j = nx; j < col; j++)
					tclearglyph(&buf[ny][j], 0);
				nx = 0;
			} else if (nx > 0) {
				buf[ny][nx - 1].mode &= ~ATTR_WRAP;
			}
			ox = 0, oy++;
		} else if (col - nx == len - ox) {
			memcpy(&buf[ny][nx], &line[ox], (col-nx) * sizeof(Glyph));
			ox = 0, oy++, nx = 0;
		} else/* if (col - nx < len - ox) */{
			memcpy(&buf[ny][nx], &line[ox], (col-nx) * sizeof(Glyph));
			ox += col - nx;
			buf[ny][col - 1].mode |= ATTR_WRAP;
			nx = 0;
		}
	} while (oy <= oce);
	if (nx)
		for (j = nx; j < col; j++)
			tclearglyph(&buf[ny][j], 0);

	// Liberar líneas adicionales
	for (i = row; i < term.row; i++)
		free(term.line[i]);
	// Re-dimensionar a la nueva altura
	term.line = xrealloc(term.line, row * sizeof(Line));

	bot = MIN(ny, row - 1);
	scr = MAX(row - term.row, 0);
	// Actualizar las coordenadas y del final de la línea del cursor
	nce = MIN(oce + scr, bot);
	// Actualizar las coordenadas y del cursor
	term.c.y = nce - (ny - cy);
	if (term.c.y < 0) {
		j = nce, nce = MIN(nce + -term.c.y, bot);
		term.c.y += nce - j;
		while (term.c.y < 0) {
			free(buf[ny--]);
			term.c.y++;
		}
	}
	// Alojar nuevas filas
	for (i = row - 1; i > nce; i--) {
		term.line[i] = xmalloc(col * sizeof(Glyph));
		for (j = 0; j < col; j++)
			tclearglyph(&term.line[i][j], 0);
	}
	// Area visible completa
	for (/*i = nce */; i >= term.row; i--, ny--)
		term.line[i] = buf[ny];
	for (/*i = term.row - 1 */; i >= 0; i--, ny--) {
		free(term.line[i]);
		term.line[i] = buf[ny];
	}
	// Llenar líneas en el búfer de historial y actualizar term.histf
	for (/*i = -1 */; ny >= 0 && i >= -HISTSIZE; i--, ny--) {
		j = (term.histi + i + 1 + HISTSIZE) % HISTSIZE;
		free(term.hist[j]);
		term.hist[j] = buf[ny];
	}
	term.histf = -i - 1;
	term.scr = MIN(term.scr, term.histf);
	// Re-dimensionar el resto de las lineas del historial
	for (/*i = -term.histf - 1 */; i >= -HISTSIZE; i--) {
		j = (term.histi + i + 1 + HISTSIZE) % HISTSIZE;
		term.hist[j] = xrealloc(term.hist[j], col * sizeof(Glyph));
	}
	free(buf);
}

void
rscrolldown(int n)
{
	int i;
	Line temp;

	// Nunca puede ser verdad (Por ahora)
	// if (IS_SET(MODE_ALTSCREEN))
	// 	return;

	if ((n = MIN(n, term.histf)) <= 0)
		return;

	for (i = term.c.y + n; i >= n; i--) {
		temp = term.line[i];
		term.line[i] = term.line[i-n];
		term.line[i-n] = temp;
	}
	for (/*i = n - 1 */; i >= 0; i--) {
		temp = term.line[i];
		term.line[i] = term.hist[term.histi];
		term.hist[term.histi] = temp;
		term.histi = (term.histi - 1 + HISTSIZE) % HISTSIZE;
	}
	term.c.y += n;
	term.histf -= n;
	if ((i = term.scr - n) >= 0) {
		term.scr = i;
	} else {
		term.scr = 0;
		if (sel.ob.x != -1 && !sel.alt)
			selmove(-i);
	}
}

void
tresize(int col, int row)
{
	int *bp;

	// col y row son siempre MAX(_, 1)
	// if (col < 1 || row < 1) {
	// 	fprintf(stderr, "tresize: error resizing to %dx%d\n", col, row);
	// 	return;
	// }

	term.dirty = xrealloc(term.dirty, row * sizeof(*term.dirty));
	term.tabs = xrealloc(term.tabs, col * sizeof(*term.tabs));
	if (col > term.col) {
		bp = term.tabs + term.col;
		memset(bp, 0, sizeof(*term.tabs) * (col - term.col));
		while (--bp > term.tabs && !*bp)
			/* Nada */ ;
		for (bp += tabspaces; bp < term.tabs + col; bp += tabspaces)
			*bp = 1;
	}

	if (IS_SET(MODE_ALTSCREEN))
		tresizealt(col, row);
	else
		tresizedef(col, row);
}

void
tresizedef(int col, int row)
{
	int i, j;

	// Salir de la función si las dimensiones no han cambiado
	if (term.col == col && term.row == row) {
		tfulldirt();
		return;
	}
	if (col != term.col) {
		if (!sel.alt)
			selremove();
		treflow(col, row);
	} else {
		// Deslizar la pantalla hacia arriba si de otro modo el cursor saldría de la pantalla
		if (term.c.y >= row) {
			tscrollup(0, term.row - 1, term.c.y - row + 1, SCROLL_RESIZE);
			term.c.y = row - 1;
		}
		for (i = row; i < term.row; i++)
			free(term.line[i]);

		// Re-dimensionar a la nueva altura
		term.line = xrealloc(term.line, row * sizeof(Line));
		// Alojar cualquier nueva fila
		for (i = term.row; i < row; i++) {
			term.line[i] = xmalloc(col * sizeof(Glyph));
			for (j = 0; j < col; j++)
				tclearglyph(&term.line[i][j], 0);
		}
		// Deslizarse hacia abajo tanto como la altura haya incrementado
		rscrolldown(row - term.row);
	}
	// Actualizar el tamaño del terminal
	term.col = col, term.row = row;
	// Reiniciar la region de deslizado
	term.top = 0, term.bot = row - 1;
	// Marcar todas las lineas como sucias
	tfulldirt();
}

void
tresizealt(int col, int row)
{
	int i, j;

	// Salir de la función si las dimensiones no han cambiado
	if (term.col == col && term.row == row) {
		tfulldirt();
		return;
	}
	if (sel.alt)
		selremove();
	// Deslizar la pantalla hacia arriba si de otro modo el cursor saldría de la pantalla
	for (i = 0; i <= term.c.y - row; i++)
		free(term.line[i]);
	if (i > 0) {
		// Asegurarse que src y dst no son NULL
		memmove(term.line, term.line + i, row * sizeof(Line));
		term.c.y = row - 1;
	}
	for (i += row; i < term.row; i++)
		free(term.line[i]);
	// Re-dimensionar a la nueva altura
	term.line = xrealloc(term.line, row * sizeof(Line));
	// Re-dimensionar a la nueva anchura
	for (i = 0; i < MIN(row, term.row); i++) {
		term.line[i] = xrealloc(term.line[i], col * sizeof(Glyph));
		for (j = term.col; j < col; j++)
			tclearglyph(&term.line[i][j], 0);
	}
	// Alojar cualquier nueva fila
	for (/*i = MIN(row, term.row) */; i < row; i++) {
		term.line[i] = xmalloc(col * sizeof(Glyph));
		for (j = 0; j < col; j++)
			tclearglyph(&term.line[i][j], 0);
	}
	// Actualizar el curosr
	if (term.c.x >= col) {
		term.c.state &= ~CURSOR_WRAPNEXT;
		term.c.x = col - 1;
	} else {
		UPDATEWRAPNEXT(1, col);
	}
	// Actualizar el tamaño del terminal
	term.col = col, term.row = row;
	// Reiniciar la region de deslizado
	term.top = 0, term.bot = row - 1;
	// Marcar todas las lineas como sucias
	tfulldirt();
}

void
resettitle(void)
{
	xsettitle(NULL, 0);
}

void
drawregion(int x1, int y1, int x2, int y2)
{
	int y;

	for (y = y1; y < y2; y++) {
		if (!term.dirty[y])
			continue;

		term.dirty[y] = 0;
		xdrawline(TLINE(y), x1, y, x2);
	}
}

void
draw(void)
{
	int cx = term.c.x, ocx = term.ocx, ocy = term.ocy;

	if (!xstartdraw())
		return;

	// Ajustar la posición del cursor
	LIMIT(term.ocx, 0, term.col-1);
	LIMIT(term.ocy, 0, term.row-1);
	if (term.line[term.ocy][term.ocx].mode & ATTR_WDUMMY)
		term.ocx--;
	if (term.line[term.c.y][cx].mode & ATTR_WDUMMY)
		cx--;

	drawregion(0, 0, term.col, term.row);
	if (term.scr == 0)
		xdrawcursor(cx, term.c.y, term.line[term.c.y][cx],
				term.ocx, term.ocy, term.line[term.ocy][term.ocx]);
	term.ocx = cx;
	term.ocy = term.c.y;
	xfinishdraw();
	if (ocx != term.ocx || ocy != term.ocy)
		xximspot(term.ocx, term.ocy);
}

void
redraw(void)
{
	tfulldirt();
	draw();
}
