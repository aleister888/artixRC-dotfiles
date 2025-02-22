# st - simple terminal
# See LICENSE file for copyright and license details.
.POSIX:

include config.mk

SRC = st.c x.c $(LIGATURES_C) $(SIXEL_C)
OBJ = $(SRC:.c=.o)

all: st

config.h:
	cp config.def.h config.h

.c.o:
	$(CC) $(STCFLAGS) -c $<

st.o: config.h st.h win.h
x.o: arg.h config.h st.h win.h $(LIGATURES_H)

$(OBJ): config.h config.mk

st: $(OBJ)
	$(CC) -o $@ $(OBJ) $(STLDFLAGS)

clean:
	rm -f *.o st config.h

install: all
	mkdir -p ${DESTDIR}${PREFIX}/bin
	install -Dm 755 st ${DESTDIR}${PREFIX}/bin
	mkdir -p ${DESTDIR}${MANPREFIX}/man1
	sed "s/VERSION/${VERSION}/g" < st.1 > ${DESTDIR}${MANPREFIX}/man1/st.1
	chmod 644 ${DESTDIR}${MANPREFIX}/man1/st.1
	tic -sx st.info
	@echo Please see the README file regarding the terminfo entry of st.
	test -d ${DESTDIR}${PREFIX}/share/applications || mkdir -p ${DESTDIR}${PREFIX}/share/applications
	test -f ${DESTDIR}${PREFIX}/share/applications/st.desktop || cp -n st.desktop $(DESTDIR)$(PREFIX)/share/applications/

uninstall:
	rm -f ${DESTDIR}${PREFIX}/bin/st \
		${DESTDIR}${MANPREFIX}/man1/st.1 \
		$(DESTDIR)$(PREFIX)/share/applications/st.desktop

.PHONY: all clean dist install uninstall
