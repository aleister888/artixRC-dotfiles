#################################
# Perfil de Firejail para Steam #
#################################

# Directorios/archivos permitidos
noblacklist ${HOME}/.local/share/Steam
mkdir ${HOME}/.local/share/Steam
whitelist ${HOME}/.local/share/Steam

noblacklist ${HOME}/.local/share/vulkan
mkdir ${HOME}/.local/share/vulkan

noblacklist ${HOME}/.steam
mkdir ${HOME}/.steam

noblacklist ${HOME}/.steampath
mkfile ${HOME}/.steampath

noblacklist ${HOME}/.steampid
mkfile ${HOME}/.steampid

whitelist ${HOME}/.steam
whitelist ${HOME}/.steampath
whitelist ${HOME}/.steampid

# Necesario para que STEAM_RUNTIME_PREFER_HOST_LIBRARIES=1 funcione
noblacklist /sbin
noblacklist /usr/sbin

# Permitr java (Desactivado por disable-devel.inc)
include allow-java.inc
# Permitr python (Desactivado por disable-interpreters.inc)
include allow-python2.inc
include allow-python3.inc

include disable-common.inc
include disable-devel.inc
include disable-interpreters.inc
include disable-programs.inc

include whitelist-common.inc
include whitelist-var-common.inc

# Opciones de Firejail
caps.drop all
netfilter
nodvd
nogroups
nonewprivs
noroot
notv
nou2f
novideo
protocol unix,inet,inet6,netlink
# Seccomp ( Ignorando: mount, name_to_handle_at, pivot_root y umount2 [ Usados por Proton >= 5.13 ] )
seccomp !chroot,!mount,!name_to_handle_at,!pivot_root,!ptrace,!umount2
# Permitir "process_vm_readv", usado por GE-Proton7-18
seccomp.32 !process_vm_readv
# Tracelog (Hace no funcionar el navegador interno de Steam)
#tracelog

# Esta opción puede hacer que algunos juegos no funcionen
private-dev
private-etc alsa,alternatives,asound.conf,bumblebee,ca-certificates,crypto-policies,dbus-1,drirc,fonts,group,gtk-2.0,gtk-3.0,host.conf,hostname,hosts,ld.so.cache,ld.so.conf,ld.so.conf.d,ld.so.preload,localtime,lsb-release,machine-id,mime.types,nvidia,os-release,passwd,pki,pulse,resolv.conf,services,ssl,vulkan
private-tmp

#dbus-user none
#dbus-system none
