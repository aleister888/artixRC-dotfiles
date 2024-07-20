# dmenu - dynamic menu
# Consulta el archivo LICENSE para los detalles de derechos de autor y licencia.

include config.mk

SRC = drw.c dmenu.c stest.c util.c
OBJ = ${SRC:.c=.o}

all: dmenu stest

.c.o:
	${CC} -c ${CFLAGS} $<

config.h:
	cp config.def.h $@

${OBJ}: arg.h config.h config.mk drw.h

dmenu: dmenu.o drw.o util.o
	${CC} -o $@ dmenu.o drw.o util.o ${LDFLAGS}

stest: stest.o
	${CC} -o $@ stest.o ${LDFLAGS}

clean:
	rm -f *.o dmenu stest font.h config.h

install: all
	mkdir -p ${DESTDIR}${PREFIX}/bin
	install -Dm 755 dmenu ${DESTDIR}${PREFIX}/bin
	install -Dm 755 dmenu_path ${DESTDIR}${PREFIX}/bin
	install -Dm 755 dmenu_run ${DESTDIR}${PREFIX}/bin
	install -Dm 755 stest ${DESTDIR}${PREFIX}/bin
	mkdir -p ${DESTDIR}${MANPREFIX}/man1
	sed "s/VERSION/${VERSION}/g" < dmenu.1 > ${DESTDIR}${MANPREFIX}/man1/dmenu.1
	sed "s/VERSION/${VERSION}/g" < stest.1 > ${DESTDIR}${MANPREFIX}/man1/stest.1
	chmod 644 ${DESTDIR}${MANPREFIX}/man1/dmenu.1
	chmod 644 ${DESTDIR}${MANPREFIX}/man1/stest.1

uninstall:
	rm -f ${DESTDIR}${PREFIX}/bin/dmenu \
		${DESTDIR}${PREFIX}/bin/dmenu_path \
		${DESTDIR}${PREFIX}/bin/dmenu_run \
		${DESTDIR}${PREFIX}/bin/stest \
		${DESTDIR}${MANPREFIX}/man1/dmenu.1 \
		${DESTDIR}${MANPREFIX}/man1/stest.1

.PHONY: all clean install uninstall
