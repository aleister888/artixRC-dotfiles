# Versión de dmenu
VERSION = 5.3

# Directorios
PREFIX = /usr/local
MANPREFIX = /usr/local/share/man
X11INC = /usr/X11R6/include
X11LIB = /usr/X11R6/lib

PKG_CONFIG = pkg-config

# Comenta estas lineas si no quieres usar Xinerama
XINERAMALIBS  = -lXinerama
XINERAMAFLAGS = -DXINERAMA

# Librerías e inclusiones
INCS = -I${X11INC} \
       `$(PKG_CONFIG) --cflags freetype2`
LIBS = -L${X11LIB} -lX11 -lfontconfig -lXft ${XINERAMALIBS} \
       `$(PKG_CONFIG) --libs fontconfig` \
       `$(PKG_CONFIG) --libs xft`

# Opciones de compilación
CPPFLAGS = -DVERSION=\"${VERSION}\" ${XINERAMAFLAGS} -D_GNU_SOURCE
CFLAGS = -march=x86-64-v3 -O3 -Os ${INCS} ${CPPFLAGS} \
	 -pipe -std=c99 -pedantic -Wall -Wno-deprecated-declarations
LDFLAGS  = ${LIBS}

# Compliador y enlazador
CC = cc
