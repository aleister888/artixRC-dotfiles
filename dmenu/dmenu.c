// Consulta el archivo LICENSE para los detalles de derechos de autor y licencia.

#include <ctype.h>
#include <locale.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <time.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/prctl.h>
#include <sys/select.h>

#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <X11/Xutil.h>
#ifdef XINERAMA
#include <X11/extensions/Xinerama.h>
#endif
#include <X11/Xft/Xft.h>

#include "drw.h"
#include "util.h"

// Macros
#define INTERSECT(x,y,w,h,r)	(MAX(0, MIN((x)+(w),(r).x_org+(r).width)  - MAX((x),(r).x_org)) \
				* MAX(0, MIN((y)+(h),(r).y_org+(r).height) - MAX((y),(r).y_org)))
#define TEXTW(X)		(drw_fontset_getwidth(drw, (X)) + lrpad)
#define NUMBERSMAXDIGITS	100
#define NUMBERSBUFSIZE		(NUMBERSMAXDIGITS * 2) + 1

// Enums
enum { SchemeNorm, SchemeSel, SchemeOut, SchemeLast }; // Esquema de color

struct item {
	char *text;
	struct item *left, *right;
	int out;
};

static struct {
	pid_t pid;
	int enable, in[2], out[2];
	char buf[256];
} qalc;

static char numbers[NUMBERSBUFSIZE] = "";
static char text[BUFSIZ] = "";
static char *embed;
static int bh, mw, mh;
static int inputw = 0, promptw, passwd = 0;
static int lrpad; // Suma del espaciado izq. y derecho
static size_t cursor;
static struct item *items = NULL;
static struct item *matches, *matchend;
static struct item *prev, *curr, *next, *sel;
static int mon = -1, screen;

static Atom clip, utf8;
static Display *dpy;
static Window root, parentwin, win;
static XIC xic;

static Drw *drw;
static Clr *scheme[SchemeLast];

#include "config.h"

static char * cistrstr(const char *s, const char *sub);
static int (*fstrncmp)(const char *, const char *, size_t) = strncasecmp;
static char *(*fstrstr)(const char *, const char *) = cistrstr;

static unsigned int
textw_clamp(const char *str, unsigned int n)
{
	unsigned int w = drw_fontset_getwidth_clamp(drw, str, n) + lrpad;
	return MIN(w, n);
}

static void
appenditem(struct item *item, struct item **list, struct item **last)
{
	if (*last)
		(*last)->right = item;
	else
		*list = item;

	item->left = *last;
	item->right = NULL;
	*last = item;
}

static void
calcoffsets(void)
{
	int i, n;

	if (lines > 0)
		n = lines * bh;
	else
		n = mw - (promptw + inputw + TEXTW("<") + TEXTW(">") + TEXTW(numbers));
	// Calcular que items empiezan en la siguente/anterior página
	for (i = 0, next = curr; next; next = next->right)
		if ((i += (lines > 0) ? bh : textw_clamp(next->text, n)) > n)
			break;
	for (i = 0, prev = curr; prev && prev->left; prev = prev->left)
		if ((i += (lines > 0) ? bh : textw_clamp(prev->left->text, n)) > n)
			break;
}

static int
max_textw(void)
{
	int len = 0;
	for (struct item *item = items; item && item->text; item++)
		len = MAX(TEXTW(item->text), len);
	return len;
}

static void
cleanup(void)
{
	size_t i;

	XUngrabKey(dpy, AnyKey, AnyModifier, root);
	for (i = 0; i < SchemeLast; i++)
		free(scheme[i]);
	for (i = 0; items && items[i].text; ++i)
		free(items[i].text);
	free(items);
	drw_free(drw);
	XSync(dpy, False);
	XCloseDisplay(dpy);
}

static char *
cistrstr(const char *h, const char *n)
{
	size_t i;

	if (!n[0])
		return (char *)h;

	for (; *h; ++h) {
		for (i = 0; n[i] && tolower((unsigned char)n[i]) ==
			tolower((unsigned char)h[i]); ++i)
			;
		if (n[i] == '\0')
			return (char *)h;
	}
	return NULL;
}

static int
drawitem(struct item *item, int x, int y, int w)
{
	if (item == sel)
		drw_setscheme(drw, scheme[SchemeSel]);
	else if (item->out)
		drw_setscheme(drw, scheme[SchemeOut]);
	else
		drw_setscheme(drw, scheme[SchemeNorm]);

	return drw_text(drw, x, y, w, bh, lrpad / 2, item->text, 0);
}

static void
recalculatenumbers()
{
	unsigned int numer = 0, denom = 0;
	struct item *item;
	if (matchend) {
		numer++;
		for (item = matchend; item && item->left; item = item->left)
			numer++;
	}
	for (item = items; item && item->text; item++)
		denom++;
	snprintf(numbers, NUMBERSBUFSIZE, "%d/%d", numer, denom);
}

static void
drawmenu(void)
{
	unsigned int curpos;
	struct item *item;
	int x = 0, y = 0, w;
	char *censort;

	drw_setscheme(drw, scheme[SchemeNorm]);
	drw_rect(drw, 0, 0, mw, mh, 1, 1);

	if (prompt && *prompt) {
		drw_setscheme(drw, scheme[SchemeSel]);
		x = drw_text(drw, x, 0, promptw, bh, lrpad / 2, prompt, 0);
	}
	// Dibujar campo de entrada
	w = (lines > 0 || !matches) ? mw - x : inputw;
	drw_setscheme(drw, scheme[SchemeNorm]);
	if (passwd) {
		censort = ecalloc(1, sizeof(text));
		memset(censort, '-', strlen(text));
		drw_text(drw, x, 0, w, bh, lrpad / 2, censort, 0);
		free(censort);
	} else drw_text(drw, x, 0, w, bh, lrpad / 2, text, 0);

	curpos = TEXTW(text) - TEXTW(&text[cursor]);
	if ((curpos += lrpad / 2 - 1) < w) {
		drw_setscheme(drw, scheme[SchemeNorm]);
		drw_rect(drw, x + curpos, 2, 2, bh - 4, 1, 0);
	}

	recalculatenumbers();
	if (lines > 0) {
		// Dibujar lista vertical
		for (item = curr; item != next; item = item->right)
			drawitem(item, x, y += bh, mw - x);
	} else if (matches) {
		// Dibujar lista horizontal
		x += inputw;
		w = TEXTW("<");
		if (curr->left) {
			drw_setscheme(drw, scheme[SchemeNorm]);
			drw_text(drw, x, 0, w, bh, lrpad / 2, "<", 0);
		}
		x += w;
		for (item = curr; item != next; item = item->right)
			x = drawitem(item, x, 0, textw_clamp(item->text, mw - x - TEXTW(">") - TEXTW(numbers)));
		if (next) {
			w = TEXTW(">");
			drw_setscheme(drw, scheme[SchemeNorm]);
			drw_text(drw, mw - w - TEXTW(numbers), 0, w, bh, lrpad / 2, ">", 0);
		}
	}
	drw_setscheme(drw, scheme[SchemeNorm]);
	drw_text(drw, mw - TEXTW(numbers), 0, TEXTW(numbers), bh, lrpad / 2, numbers, 0);
	drw_map(drw, win, 0, 0, mw, mh);
}

static void
grabfocus(void)
{
	struct timespec ts = { .tv_sec = 0, .tv_nsec = 10000000  };
	Window focuswin;
	int i, revertwin;

	for (i = 0; i < 100; ++i) {
		XGetInputFocus(dpy, &focuswin, &revertwin);
		if (focuswin == win)
			return;
		XSetInputFocus(dpy, win, RevertToParent, CurrentTime);
		nanosleep(&ts, NULL);
	}
	die("cannot grab focus");
}

static void
grabkeyboard(void)
{
	struct timespec ts = { .tv_sec = 0, .tv_nsec = 1000000  };
	int i;

	if (embed)
		return;
	// Intenta acaparar el teclado, es posible que sea necesario esperar a que otro proceso deje de usarlo
	for (i = 0; i < 1000; i++) {
		if (XGrabKeyboard(dpy, DefaultRootWindow(dpy), True, GrabModeAsync,
			GrabModeAsync, CurrentTime) == GrabSuccess)
			return;
		nanosleep(&ts, NULL);
	}
	die("cannot grab keyboard");
}

static void
init_qalc(void)
{
	pipe(qalc.in);
	pipe2(qalc.out, O_NONBLOCK);
	qalc.pid = fork();
	if (qalc.pid == -1)
		die("failed to fork for qalc");
	if (qalc.pid == 0) {
		dup2(qalc.in[0], STDIN_FILENO);
		dup2(qalc.out[1], STDOUT_FILENO);
		close(qalc.in[1]);
		close(qalc.out[0]);
		prctl(PR_SET_PDEATHSIG, SIGTERM);
		execl("/usr/bin/qalc", "qalc", "-c0", "-t", NULL);
		die ("execl qalc failed");
	} else { // Proceso padre
		close(qalc.in[0]);
		close(qalc.out[1]);
		items = malloc(sizeof(struct item)*2);
		items[0].text = malloc(LENGTH(qalc.buf));
		strcpy(items[0].text, "no result");
		items[1].out = 0;
		items[1].text = NULL;
	}
}

static void
recv_qalc(void)
{
	ssize_t r = read(qalc.out[0], qalc.buf, LENGTH(qalc.buf));

	if (r < 0)
		die("error reading qalc.out");

	if (qalc.buf[0] == '\n') {
		int i;
		for (i = 3; i < LENGTH(qalc.buf) && qalc.buf[i] != '\n'; ++i)
		items[0].text[i-3] = qalc.buf[i];
			items[0].text[i-3] = 0;
		if (r != LENGTH(qalc.buf))
			return;
	}

	while (read(qalc.out[0], qalc.buf, LENGTH(qalc.buf)) != -1)
	; // Vaciar re-direccionamiento
	if (errno != EAGAIN && errno != EWOULDBLOCK)
	die("error emptying qalc.out");
}

static void
send_qalc(void)
{
	int s = strlen(text);
	text[s] = '\n';
	write(qalc.in[1], text, s+1);
	text[s] = 0;
}

static void
match_qalc(void)
{
	matches = matchend = NULL;
	appenditem(items, &matches, &matchend);
	curr = sel = matches;
	calcoffsets();
}

static void
match(void)
{
	if (qalc.enable) {
		match_qalc();
		return;
	}

	static char **tokv = NULL;
	static int tokn = 0;

	char buf[sizeof text], *s;
	int i, tokc = 0;
	size_t len, textsize;
	struct item *item, *lprefix, *lsubstr, *prefixend, *substrend;

	strcpy(buf, text);
	// Separar el texto de entrada en tokens para ser emparejados individualmente
	for (s = strtok(buf, " "); s; tokv[tokc - 1] = s, s = strtok(NULL, " "))
		if (++tokc > tokn && !(tokv = realloc(tokv, ++tokn * sizeof *tokv)))
			die("cannot realloc %zu bytes:", tokn * sizeof *tokv);
	len = tokc ? strlen(tokv[0]) : 0;

	matches = lprefix = lsubstr = matchend = prefixend = substrend = NULL;
	textsize = strlen(text) + 1;
	for (item = items; item && item->text; item++) {
		for (i = 0; i < tokc; i++)
			if (!fstrstr(item->text, tokv[i]))
				break;
		if (i != tokc) // No todos los tokens coinciden
			continue;
		// Las coincidencias exactas van primero, luego los prefijos y después las subcadenas
		if (!tokc || !fstrncmp(text, item->text, textsize))
			appenditem(item, &matches, &matchend);
		else if (!fstrncmp(tokv[0], item->text, len))
			appenditem(item, &lprefix, &prefixend);
		else
			appenditem(item, &lsubstr, &substrend);
	}
	if (lprefix) {
		if (matches) {
			matchend->right = lprefix;
			lprefix->left = matchend;
		} else
			matches = lprefix;
		matchend = prefixend;
	}
	if (lsubstr) {
		if (matches) {
			matchend->right = lsubstr;
			lsubstr->left = matchend;
		} else
			matches = lsubstr;
		matchend = substrend;
	}
	curr = sel = matches;
	calcoffsets();
}

static void
insert(const char *str, ssize_t n)
{
	if (strlen(text) + n > sizeof text - 1)
		return;
	// Desplazar el texto existente, insertar el nuevo y actualizar el cursor
	memmove(&text[cursor + n], &text[cursor], sizeof text - cursor - MAX(n, 0));
	if (n > 0)
		memcpy(&text[cursor], str, n);
	cursor += n;
	match();
}

static size_t
nextrune(int inc)
{
	ssize_t n;
	// Devuelve la ubicación de la siguiente runa utf8 en la dirección dada (+1 o -1)
	for (n = cursor + inc; n + inc >= 0 && (text[n] & 0xc0) == 0x80; n += inc)
		;
	return n;
}

static void
movewordedge(int dir)
{
	if (dir < 0) { // Mueve el cursor al principio de la palabra
		while (cursor > 0 && strchr(worddelimiters, text[nextrune(-1)]))
			cursor = nextrune(-1);
		while (cursor > 0 && !strchr(worddelimiters, text[nextrune(-1)]))
			cursor = nextrune(-1);
	} else { // Mueve el cursor al final de la palabra
		while (text[cursor] && strchr(worddelimiters, text[cursor]))
			cursor = nextrune(+1);
		while (text[cursor] && !strchr(worddelimiters, text[cursor]))
			cursor = nextrune(+1);
	}
}

static void
keypress(XKeyEvent *ev)
{
	char buf[64];
	int len;
	KeySym ksym = NoSymbol;
	Status status;

	len = XmbLookupString(xic, ev, buf, sizeof buf, &ksym, &status);
	switch (status) {
	default: // XLookupNone, XBufferOverflow
		return;
	case XLookupChars: // Cadena compuesta a partir del método de entrada
		goto insert;
	case XLookupKeySym:
	case XLookupBoth: // Si se devuelven un KeySym y una cadena: Usar KeySym
		break;
	}

	if (ev->state & ControlMask) {
		switch(ksym) {
		case XK_a: ksym = XK_Home;      break;
		case XK_b: ksym = XK_Left;      break;
		case XK_c: ksym = XK_Escape;    break;
		case XK_d: ksym = XK_Delete;    break;
		case XK_e: ksym = XK_End;       break;
		case XK_f: ksym = XK_Right;     break;
		case XK_g: ksym = XK_Escape;    break;
		case XK_h: ksym = XK_BackSpace; break;
		case XK_i: ksym = XK_Tab;       break;
		case XK_j: // A través
		case XK_J: // A través
		case XK_m: // A través
		case XK_M: ksym = XK_Return; ev->state &= ~ControlMask; break;
		case XK_n: ksym = XK_Down;      break;
		case XK_p: ksym = XK_Up;        break;

		case XK_k: // Borrar hacia la derecha
			text[cursor] = '\0';
			match();
			break;
		case XK_u: // Borrar hacia la izquierda
			insert(NULL, 0 - cursor);
			break;
		case XK_w: // Borrar palabra
			while (cursor > 0 && strchr(worddelimiters, text[nextrune(-1)]))
				insert(NULL, nextrune(-1) - cursor);
			while (cursor > 0 && !strchr(worddelimiters, text[nextrune(-1)]))
				insert(NULL, nextrune(-1) - cursor);
			break;
		case XK_y: // Pegar selección
		case XK_Y:
			XConvertSelection(dpy, (ev->state & ShiftMask) ? clip : XA_PRIMARY,
				utf8, utf8, win, CurrentTime);
			return;
		case XK_Left:
		case XK_KP_Left:
			movewordedge(-1);
			goto draw;
		case XK_Right:
		case XK_KP_Right:
			movewordedge(+1);
			goto draw;
		case XK_Return:
		case XK_KP_Enter:
			break;
		case XK_bracketleft:
			cleanup();
			exit(1);
		default:
			return;
		}
	} else if (ev->state & Mod1Mask) {
		switch(ksym) {
		case XK_b:
			movewordedge(-1);
			goto draw;
		case XK_f:
			movewordedge(+1);
			goto draw;
		case XK_g: ksym = XK_Home;  break;
		case XK_G: ksym = XK_End;   break;
		case XK_h: ksym = XK_Up;    break;
		case XK_j: ksym = XK_Next;  break;
		case XK_k: ksym = XK_Prior; break;
		case XK_l: ksym = XK_Down;  break;
		default:
			return;
		}
	}

	switch(ksym) {
	default:
insert:
		if (!iscntrl((unsigned char)*buf))
			insert(buf, len);
		break;
	case XK_Delete:
	case XK_KP_Delete:
		if (text[cursor] == '\0')
			return;
		cursor = nextrune(+1);
		// A través
	case XK_BackSpace:
		if (cursor == 0)
			return;
		insert(NULL, nextrune(-1) - cursor);
		break;
	case XK_End:
	case XK_KP_End:
		if (text[cursor] != '\0') {
			cursor = strlen(text);
			break;
		}
		if (next) {
			// Saltar al final de la lista y posicionar los elementos en sentido inverso
			curr = matchend;
			calcoffsets();
			curr = prev;
			calcoffsets();
			while (next && (curr = curr->right))
				calcoffsets();
		}
		sel = matchend;
		break;
	case XK_Escape:
		cleanup();
		exit(1);
	case XK_Home:
	case XK_KP_Home:
		if (sel == matches) {
			cursor = 0;
			break;
		}
		sel = curr = matches;
		calcoffsets();
		break;
	case XK_Left:
	case XK_KP_Left:
		if (cursor > 0 && (!sel || !sel->left || lines > 0)) {
			cursor = nextrune(-1);
			break;
		}
		if (lines > 0)
			return;
		// A través
	case XK_Up:
	case XK_KP_Up:
		if (sel && sel->left && (sel = sel->left)->right == curr) {
			curr = prev;
			calcoffsets();
		}
		break;
	case XK_Next:
	case XK_KP_Next:
		if (!next)
			return;
		sel = curr = next;
		calcoffsets();
		break;
	case XK_Prior:
	case XK_KP_Prior:
		if (!prev)
			return;
		sel = curr = prev;
		calcoffsets();
		break;
	case XK_Return:
	case XK_KP_Enter:
		puts((sel && !(ev->state & ShiftMask)) ? sel->text : text);
		if (!(ev->state & ControlMask)) {
			cleanup();
			exit(0);
		}
		if (sel)
			sel->out = 1;
		break;
	case XK_Right:
	case XK_KP_Right:
		if (text[cursor] != '\0') {
			cursor = nextrune(+1);
			break;
		}
		if (lines > 0)
			return;
		// A través
	case XK_Down:
	case XK_KP_Down:
		if (sel && sel->right && (sel = sel->right) == next) {
			curr = next;
			calcoffsets();
		}
		break;
	case XK_Tab:
		if (!sel)
			return;
		cursor = strnlen(sel->text, sizeof text - 1);
		memcpy(text, sel->text, cursor);
		text[cursor] = '\0';
		match();
		break;
	}

	if (qalc.enable)
		send_qalc();

draw:
	drawmenu();
}

static void
paste(void)
{
	char *p, *q;
	int di;
	unsigned long dl;
	Atom da;

	// Se nos ha dado la selección actual, ahora insértala en la entrada
	if (XGetWindowProperty(dpy, win, utf8, 0, (sizeof text / 4) + 1, False,
		utf8, &da, &di, &dl, &dl, (unsigned char **)&p)
	== Success && p) {
		insert(p, (q = strchr(p, '\n')) ? q - p : (ssize_t)strlen(p));
		XFree(p);
	}
	drawmenu();
}

static void
readstdin(void)
{
	char *line = NULL;
	size_t i, itemsiz = 0, linesiz = 0;
	ssize_t len;

	// Leer cada línea de stdin y añadirla a la lista de elementos
	for (i = 0; (len = getline(&line, &linesiz, stdin)) != -1; i++) {
		if (i + 1 >= itemsiz) {
			itemsiz += 256;
			if (!(items = realloc(items, itemsiz * sizeof(*items))))
				die("cannot realloc %zu bytes:", itemsiz * sizeof(*items));
		}
		if (line[len - 1] == '\n')
			line[len - 1] = '\0';
		if (!(items[i].text = strdup(line)))
			die("strdup:");

		items[i].out = 0;
	}
	free(line);
	if (items)
		items[i].text = NULL;
	lines = MIN(lines, i);
}

static void
run(void)
{
	XEvent ev;

	fd_set rfds;
	int xfd = ConnectionNumber(dpy);

	for (;;) {
		FD_ZERO(&rfds);
		FD_SET(xfd, &rfds);
		FD_SET(qalc.out[0], &rfds);

		if (select(MAX(xfd, qalc.out[0])+1, &rfds, NULL, NULL, NULL) > 0) {
			if (qalc.enable && FD_ISSET(qalc.out[0], &rfds)) {
				recv_qalc();
				drawmenu();
			}
			while (XPending(dpy) && !XNextEvent(dpy, &ev)) {
				if (XFilterEvent(&ev, win))
					continue;
				switch(ev.type) {
					case DestroyNotify:
						if (ev.xdestroywindow.window != win)
							break;
						cleanup();
						exit(1);
					case Expose:
						if (ev.xexpose.count == 0)
							drw_map(drw, win, 0, 0, mw, mh);
						break;
					case FocusIn:
						// Recuperar el foco de la ventana principal
						if (ev.xfocus.window != win)
							grabfocus();
						break;
					case KeyPress:
						keypress(&ev.xkey);
						break;
					case SelectionNotify:
						if (ev.xselection.property == utf8)
							paste();
						break;
					case VisibilityNotify:
						if (ev.xvisibility.state != VisibilityUnobscured)
							XRaiseWindow(dpy, win);
						break;
				}
			}
		}
	}
}

static void
setup(void)
{
	int x, y, i, j;
	unsigned int du;
	XSetWindowAttributes swa;
	XIM xim;
	Window w, dw, *dws;
	XWindowAttributes wa;
	XClassHint ch = {"dmenu", "dmenu"};
#ifdef XINERAMA
	XineramaScreenInfo *info;
	Window pw;
	int a, di, n, area = 0;
#endif
	// Apariencia inicial
	for (j = 0; j < SchemeLast; j++)
		scheme[j] = drw_scm_create(drw, colors[j], 2);

	clip = XInternAtom(dpy, "CLIPBOARD",   False);
	utf8 = XInternAtom(dpy, "UTF8_STRING", False);

	// Calcular las dimensiones del menú
	bh = drw->fonts->h;
	bh = user_bh ? bh + user_bh : bh + 2;
	lines = MAX(lines, 0);
	mh = (lines + 1) * bh;
	promptw = (prompt && *prompt) ? TEXTW(prompt) - lrpad / 4 : 0;
#ifdef XINERAMA
	i = 0;
	if (parentwin == root && (info = XineramaQueryScreens(dpy, &n))) {
		XGetInputFocus(dpy, &w, &di);
		if (mon >= 0 && mon < n)
			i = mon;
		else if (w != root && w != PointerRoot && w != None) {
			// Encuentra la ventana de nivel superior que contiene el foco de entrada actual
			do {
				if (XQueryTree(dpy, (pw = w), &dw, &w, &dws, &du) && dws)
					XFree(dws);
			} while (w != root && w != pw);
			// Encontrar la pantalla xinerama con la que más se cruza la ventana
			if (XGetWindowAttributes(dpy, pw, &wa))
				for (j = 0; j < n; j++)
					if ((a = INTERSECT(wa.x, wa.y, wa.width, wa.height, info[j])) > area) {
						area = a;
						i = j;
					}
		}
		// No hay ventana activa en la pantalla, así que usa la localización del puntero
		if (mon < 0 && !area && XQueryPointer(dpy, root, &dw, &dw, &x, &y, &di, &di, &du))
			for (i = 0; i < n; i++)
				if (INTERSECT(x, y, 1, 1, info[i]) != 0)
					break;

		if (centered) {
			mw = MIN(MAX(max_textw() + promptw, min_width), info[i].width);
			x = info[i].x_org + ((info[i].width  - mw) / 2);
			y = info[i].y_org + ((info[i].height - mh) / 2);
		} else {
			x = info[i].x_org;
			y = info[i].y_org + (topbar ? 0 : info[i].height - mh);
			mw = info[i].width;
		}

		XFree(info);
	} else
#endif
	{
		if (!XGetWindowAttributes(dpy, parentwin, &wa))
			die("could not get embedding window attributes: 0x%lx",
				parentwin);

		if (centered) {
			mw = MIN(MAX(max_textw() + promptw, min_width), wa.width);
			x = (wa.width  - mw) / 2;
			y = (wa.height - mh) / 2;
		} else {
			x = 0;
			y = topbar ? 0 : wa.height - mh;
			mw = wa.width;
		}
	}
	promptw = (prompt && *prompt) ? TEXTW(prompt) - lrpad / 4 : 0;
	inputw = mw / 3; // Anchura de la entrada: ~33% de la anchura del monitor
	match();

	// Crear la ventana del menú
	swa.override_redirect = True;
	swa.background_pixel = scheme[SchemeNorm][ColBg].pixel;
	swa.event_mask = ExposureMask | KeyPressMask | VisibilityChangeMask;
	win = XCreateWindow(dpy, root, x, y, mw, mh, border_width,
		CopyFromParent, CopyFromParent, CopyFromParent,
		CWOverrideRedirect | CWBackPixel | CWEventMask, &swa);
	if (border_width)
		XSetWindowBorder(dpy, win, scheme[SchemeSel][ColBg].pixel);
	XSetClassHint(dpy, win, &ch);


	// Métodos de entrada
	if ((xim = XOpenIM(dpy, NULL, NULL, NULL)) == NULL)
		die("XOpenIM failed: could not open input device");

	xic = XCreateIC(xim, XNInputStyle, XIMPreeditNothing | XIMStatusNothing,
		XNClientWindow, win, XNFocusWindow, win, NULL);

	XMapRaised(dpy, win);
	if (embed) {
		XReparentWindow(dpy, win, parentwin, x, y);
		XSelectInput(dpy, parentwin, FocusChangeMask | SubstructureNotifyMask);
		if (XQueryTree(dpy, parentwin, &dw, &w, &dws, &du) && dws) {
			for (i = 0; i < du && dws[i] != win; ++i)
				XSelectInput(dpy, dws[i], FocusChangeMask);
			XFree(dws);
		}
		grabfocus();
	}
	drw_resize(drw, mw, mh);
	drawmenu();
}

static void
usage(void)
{
	die("usage:	dmenu [-bCPfv] [-l lines] [-p prompt] [-fn font] [-m monitor]\n"
		"	[-nb color] [-nf color] [-sb color] [-sf color] [-w windowid]");
}

int
main(int argc, char *argv[])
{
	XWindowAttributes wa;
	int i, fast = 0;

	for (i = 1; i < argc; i++)
		// Opciones que no necesitan de argumentos
		if (!strcmp(argv[i], "-v")) { // Imprime la versión del programa
			puts("dmenu-"VERSION);
			exit(0);
		} else if (!strcmp(argv[i], "-b")) // Aparecer en la parte inferior de la pantalla
			topbar = 0;
		else if (!strcmp(argv[i], "-C")) // Apropiarse del teclado antes de leer stdin
			qalc.enable = 1;
		else if (!strcmp(argv[i], "-f")) // Apropiarse del teclado antes de leer stdin
			fast = 1;
		else if (!strcmp(argv[i], "-c")) // Centrar dmenu en la pantalla
			centered = 1;
		else if (!strcmp(argv[i], "-s")) { // Fijarse en las mayúsculas
			fstrncmp = strncmp;
			fstrstr = strstr;
		} else if (!strcmp(argv[i], "-P")) // La entrada es una contraseña
			passwd = 1;
		else if (i + 1 == argc)
			usage();
		// Opciones que si necesitan un argumento
		else if (!strcmp(argv[i], "-l")) // Número de lineas en las listas verticales
			lines = atoi(argv[++i]);
		else if (!strcmp(argv[i], "-m"))
			mon = atoi(argv[++i]);
		else if (!strcmp(argv[i], "-p")) // Añadir texto en el cuadro de entrada
			prompt = argv[++i];
		else if (!strcmp(argv[i], "-fn")) // Fuente
			fonts[0] = argv[++i];
		else if (!strcmp(argv[i], "-nb")) // Color del fondo (normal)
			colors[SchemeNorm][ColBg] = argv[++i];
		else if (!strcmp(argv[i], "-nf")) // Color de la fuente (normal)
			colors[SchemeNorm][ColFg] = argv[++i];
		else if (!strcmp(argv[i], "-sb")) // Color del fondo (entrada seleccionada)
			colors[SchemeSel][ColBg] = argv[++i];
		else if (!strcmp(argv[i], "-sf")) // Color de la fuente (entrada seleccionada)
			colors[SchemeSel][ColFg] = argv[++i];
		else if (!strcmp(argv[i], "-w")) // Incrustar el ID de la ventana
			embed = argv[++i];
		else if (!strcmp(argv[i], "-bw"))
			border_width = atoi(argv[++i]); // Tamaño del borde
		else
			usage();

	if (!setlocale(LC_CTYPE, "") || !XSupportsLocale())
		fputs("warning: no locale support\n", stderr);
	if (!(dpy = XOpenDisplay(NULL)))
		die("cannot open display");
	screen = DefaultScreen(dpy);
	root = RootWindow(dpy, screen);
	if (!embed || !(parentwin = strtol(embed, NULL, 0)))
		parentwin = root;
	if (!XGetWindowAttributes(dpy, parentwin, &wa))
		die("could not get embedding window attributes: 0x%lx",
			parentwin);
	drw = drw_create(dpy, screen, root, wa.width, wa.height);
	if (!drw_fontset_create(drw, fonts, LENGTH(fonts)))
		die("no fonts could be loaded.");
	lrpad = drw->fonts->h;

#ifdef __OpenBSD__
	if (pledge("stdio rpath", NULL) == -1)
		die("pledge");
#endif

	if (qalc.enable) {
		init_qalc();
		grabkeyboard();
	} else if (fast && !isatty(0)) {
		grabkeyboard();
		readstdin();
	} else {
		readstdin();
		grabkeyboard();
	}
	setup();
	run();

	return 1; // Inalcanzable
}
