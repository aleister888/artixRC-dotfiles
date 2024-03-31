/* See LICENSE file for copyright and license details. */
/* Default settings; can be overriden by command line. */

static int topbar         = 1;    /* -b  option; if 0, dmenu appears at bottom     */
static int centered       = 0;    /* -c option; centers dmenu on screen */
static int min_width      = 500;  /* minimum width when centered */
static const int user_bh  = 0;    /* add an defined amount of pixels to the bar height */
static const char *prompt = NULL; /* -p  option; prompt to the left of input field */
static const char *colors[SchemeLast][2] = {
	[SchemeNorm] = { "#EBDBB2", "#1D2021" },
	[SchemeSel] = { "#EBDBB2", "#282828" },
	[SchemeOut] = { "#000000", "#00ffff" },
};
/* -l option; if nonzero, dmenu uses vertical list with given number of lines */
static unsigned int lines      = 0;

/*
 * Characters not considered part of a word while deleting words
 * for example: " /?\"&[]"
 */
static const char worddelimiters[] = " ";