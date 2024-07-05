// Consulta el archivo LICENSE para los detalles de derechos de autor y licencia.

#include <sys/stat.h>

#include <dirent.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "arg.h"
char *argv0;

#define FLAG(x)  (flag[(x)-'a'])

static void test(const char *, const char *);
static void usage(void);

static int match = 0;
static int flag[26];
static struct stat old, new;

// Función para probar las condiciones especificadas en los flags
static void
test(const char *path, const char *name)
{
	struct stat st, ln;

	// Condiciones de prueba según los flags establecidos
	if ((!stat(path, &st) && (FLAG('a') || name[0] != '.')        // Archivos ocultos
	&& (!FLAG('b') || S_ISBLK(st.st_mode))                        // Dispositivo de bloques
	&& (!FLAG('c') || S_ISCHR(st.st_mode))                        // Dispositivo de caracteres
	&& (!FLAG('d') || S_ISDIR(st.st_mode))                        // Directorio
	&& (!FLAG('e') || access(path, F_OK) == 0)                    // Existe
	&& (!FLAG('f') || S_ISREG(st.st_mode))                        // Archivo regular
	&& (!FLAG('g') || st.st_mode & S_ISGID)                       // set-group-id flag
	&& (!FLAG('h') || (!lstat(path, &ln) && S_ISLNK(ln.st_mode))) // Enlace simbólico
	&& (!FLAG('n') || st.st_mtime > new.st_mtime)                 // Más nuevo que el archivo
	&& (!FLAG('o') || st.st_mtime < old.st_mtime)                 // Más viejo que el archivo
	&& (!FLAG('p') || S_ISFIFO(st.st_mode))                       // Tubería con nombre
	&& (!FLAG('r') || access(path, R_OK) == 0)                    // Legible
	&& (!FLAG('s') || st.st_size > 0)                             // No vacío
	&& (!FLAG('u') || st.st_mode & S_ISUID)                       // set-user-id flag
	&& (!FLAG('w') || access(path, W_OK) == 0)                    // Escribible
	&& (!FLAG('x') || access(path, X_OK) == 0)) != FLAG('v')) {   // Ejecutable
		if (FLAG('q'))
			exit(0);
		match = 1;
		puts(name);
	}
}

// Función para mostrar el uso correcto del programa
static void
usage(void)
{
	fprintf(stderr, "uso: %s [-abcdefghlpqrsuvwx] "
	        "[-n archivo] [-o archivo] [archivo...]\n", argv0);
	exit(2); // Como test(1), devuelve > 1 en caso de error
}

int
main(int argc, char *argv[])
{
	struct dirent *d;
	char path[PATH_MAX], *line = NULL, *file;
	size_t linesiz = 0;
	ssize_t n;
	DIR *dir;
	int r;

	ARGBEGIN {
	case 'n': // Más nuevo que el archivo
	case 'o': // Más viejo que el archivo
		file = EARGF(usage());
		if (!(FLAG(ARGC()) = !stat(file, (ARGC() == 'n' ? &new : &old))))
			perror(file);
		break;
	default:
		// Operadores misceláneos
		if (strchr("abcdefghlpqrsuvwx", ARGC()))
			FLAG(ARGC()) = 1;
		else
			usage(); // Flag desconocido
	} ARGEND;

	if (!argc) {
		// Leer lista desde stdin
		while ((n = getline(&line, &linesiz, stdin)) > 0) {
			if (line[n - 1] == '\n')
				line[n - 1] = '\0';
			test(line, line);
		}
		free(line);
	} else {
		for (; argc; argc--, argv++) {
			if (FLAG('l') && (dir = opendir(*argv))) {
				// Comprobar los contenido del directorio
				while ((d = readdir(dir))) {
					r = snprintf(path, sizeof path, "%s/%s",
					             *argv, d->d_name);
					if (r >= 0 && (size_t)r < sizeof path)
						test(path, d->d_name);
				}
				closedir(dir);
			} else {
				test(*argv, *argv);
			}
		}
	}
	return match ? 0 : 1;
}

