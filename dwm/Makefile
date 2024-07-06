# dwm - dynamic window manager
# Consulta el archivo LICENSE para los detalles de derechos de autor y licencia.

include config.mk

SRC = drw.c dwm.c util.c
OBJ = ${SRC:.c=.o}

all: dwm

.c.o:
	${CC} -c ${CFLAGS} $<

${OBJ}: config.h config.mk resolution.h

config.h:
	cp config.def.h $@

resolution.h:
	cp 1080.h $@

dwm: ${OBJ}
	${CC} -o $@ ${OBJ} ${LDFLAGS}

1080:
	cp -f 1080.h resolution.h

2160:
	cp -f 2160.h resolution.h

clean:
	rm -f *.o dwm resolution.h config.h

install: all
	mkdir -p ${DESTDIR}${PREFIX}/bin
	install -m 755 dwm ${DESTDIR}${PREFIX}/bin
	install -m 755 layoutmenu.sh ${DESTDIR}${PREFIX}/bin
	mkdir -p ${DESTDIR}${MANPREFIX}/man1
	sed "s/VERSION/${VERSION}/g" < dwm.1 > ${DESTDIR}${MANPREFIX}/man1/dwm.1
	chmod 644 ${DESTDIR}${MANPREFIX}/man1/dwm.1

uninstall:
	rm -f ${DESTDIR}${PREFIX}/bin/dwm \
		${DESTDIR}${PREFIX}/bin/layoutmenu.sh \
		${DESTDIR}${MANPREFIX}/man1/dwm.1

.PHONY: all clean 1080 2160 install uninstall
