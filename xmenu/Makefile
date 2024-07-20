# Nombre de la aplicación
PROG = xmenu

# Directorio
PREFIX      ?= /usr/local
MANPREFIX   ?= ${PREFIX}/share/man
LOCALINC    ?= /usr/local/include
LOCALLIB    ?= /usr/local/lib
X11INC      ?= /usr/X11R6/include
X11LIB      ?= /usr/X11R6/lib
FREETYPEINC ?= /usr/include/freetype2
# Des-comenta esta línea para compilar en OpenBSD
#FREETYPEINC = ${X11INC}/freetype2

# Librerías e inclusiones
INCS += -I${LOCALINC} -I${X11INC} -I${FREETYPEINC}
LIBS += -L${LOCALLIB} -L${X11LIB} -lfontconfig -lXft -lX11 -lXinerama -lImlib2

# Opciones de compilación
CFLAGS   += ${DEBUG} -Wall -Wextra ${INCS} ${CPPFLAGS}
LDFLAGS  += ${LIBS}

# Compliador y enlazador
CC = cc

bindir = ${DESTDIR}${PREFIX}
mandir = ${DESTDIR}${MANPREFIX}

SRCS = ${PROG}.c
OBJS = ${SRCS:.c=.o}

all: ${PROG}

${PROG}: ${OBJS}
	${CC} -o $@ ${OBJS} ${LDFLAGS}

${OBJS}: config.h

.c.o:
	${CC} ${CFLAGS} -c $<

clean:
	-rm ${OBJS} ${PROG}

install: all
	mkdir -p ${bindir}/bin
	install -Dm 755 ${PROG} ${bindir}/bin/${PROG}
	mkdir -p ${mandir}/man1
	install -Dm 644 ${PROG}.1 ${mandir}/man1/${PROG}.1

uninstall:
	rm -f ${bindir}/bin/${PROG}
	rm -f ${mandir}/man1/${PROG}.1

.PHONY: all clean install uninstall
