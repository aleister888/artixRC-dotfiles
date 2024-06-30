# Perfil de Steam para Firejail

include steam.local
include globals.local

noblacklist ${HOME}/.local/share/Steam
noblacklist ${HOME}/.local/share/vulkan
noblacklist ${HOME}/.steam
noblacklist ${HOME}/.steampath
noblacklist ${HOME}/.steampid
# Necesario para que funcione STEAM_RUNTIME_PREFER_HOST_LIBRARIES=1
noblacklist /sbin
noblacklist /usr/sbin

# Permitir java (en lista negra por disable-devel.inc)
include allow-java.inc

# Permitir python (en lista negra por disable-interpreters.inc)
include allow-python2.inc
include allow-python3.inc

include disable-common.inc
include disable-devel.inc
include disable-interpreters.inc
include disable-programs.inc

mkdir ${HOME}/.local/share/Steam
mkdir ${HOME}/.steam
mkfile ${HOME}/.steampath
mkfile ${HOME}/.steampid
whitelist ${HOME}/.local/share/Steam
whitelist ${HOME}/.local/share/vulkan
whitelist ${HOME}/.steam
whitelist ${HOME}/.steampath
whitelist ${HOME}/.steampid
include whitelist-common.inc
include whitelist-var-common.inc

caps.drop all
#ipc-namespace
netfilter
nodvd
nogroups
nonewprivs
noroot
notv
nou2f
# Para soporte de VR, añade 'ignore novideo' a tu steam.local.
novideo
protocol unix,inet,inet6,netlink
# Seccomp a veces causa problemas (ver #2951, #3267).
# Agrega 'ignore seccomp' a tu steam.local si experimentas esto.
# mount, name_to_handle_at, pivot_root y umount2 son utilizados por Proton >= 5.13
# (ver #4366).
seccomp !chroot,!mount,!name_to_handle_at,!pivot_root,!ptrace,!umount2
# process_vm_readv es utilizado por GE-Proton7-18 (ver #5185).
seccomp.32 !process_vm_readv
# tracelog rompe el navegador integrado
#tracelog

private-dev
# private-etc rompe una pequeña selección de juegos en algunos sistemas. Agrega 'ignore private-etc'
# a tu steam.local para soportar esos juegos.
private-etc alsa,alternatives,asound.conf,bumblebee,ca-certificates,crypto-policies,dbus-1,drirc,fonts,group,gtk-2.0,gtk-3.0,host.conf,hostname,hosts,ld.so.cache,ld.so.conf,ld.so.conf.d,ld.so.preload,localtime,lsb-release,machine-id,mime.types,nvidia,os-release,passwd,pki,pulse,resolv.conf,services,ssl,vulkan
private-tmp

#dbus-user none
#dbus-system none

read-only ${HOME}/.config/MangoHud
#restrict-namespaces
