# Versión de st
VERSION = 0.9.2

# Directorios
PREFIX = /usr/local
APPPREFIX = $(PREFIX)/share/applications
MANPREFIX = $(PREFIX)/share/man
X11INC = /usr/X11R6/include
X11LIB = /usr/X11R6/lib

PKG_CONFIG = pkg-config

# Librerías e inclusiones
INCS = -I$(X11INC) \
	`$(PKG_CONFIG) --cflags fontconfig` \
	`$(PKG_CONFIG) --cflags freetype2`
LIBS = -L$(X11LIB) -lX11 -lutil -lXft \
	`$(PKG_CONFIG) --libs fontconfig` \
	`$(PKG_CONFIG) --libs freetype2`

# Opciones de compilación
STCPPFLAGS = -DVERSION=\"$(VERSION)\" -D_GNU_SOURCE
CFLAGS = -march=x86-64-v3 -O3 -Os ${INCS} ${CPPFLAGS} \
	-pipe -std=c99 -pedantic -Wall -Wno-deprecated-declarations -Wno-maybe-uninitialized
STCFLAGS = $(INCS) $(STCPPFLAGS) $(CPPFLAGS) $(CFLAGS)
STLDFLAGS = $(LIBS) $(LDFLAGS)

# Descomenta estas lineas para compilar en OpenBSD
#CPPFLAGS = -DVERSION=\"$(VERSION)\" -D_XOPEN_SOURCE=600 -D_BSD_SOURCE -Wno-cpp
#LIBS = -L$(X11LIB) -lm -lX11 -lutil -lXft \
#	`$(PKG_CONFIG) --libs fontconfig` \
#	`$(PKG_CONFIG) --libs freetype2`
#MANPREFIX = ${PREFIX}/man

# Compliador y enlazador
CC = cc
