# Firejail profile for steam
# Description: Valve's Steam digital software delivery system
# This file is overwritten after every install/update
# Persistent local customizations
include steam.local
# Persistent global definitions
include globals.local

noblacklist ${HOME}/.local/share/Steam
noblacklist ${HOME}/.local/share/vulkan
noblacklist ${HOME}/.steam
noblacklist ${HOME}/.steampath
noblacklist ${HOME}/.steampid
# needed for STEAM_RUNTIME_PREFER_HOST_LIBRARIES=1 to work
noblacklist /sbin
noblacklist /usr/sbin

# Allow java (blacklisted by disable-devel.inc)
include allow-java.inc

# Allow python (blacklisted by disable-interpreters.inc)
include allow-python2.inc
include allow-python3.inc

include disable-common.inc
include disable-devel.inc
include disable-interpreters.inc
include disable-programs.inc

mkdir ${HOME}/.local/share/Steam
mkdir ${HOME}/.local/share/vulkan
mkdir ${HOME}/.steam
mkfile ${HOME}/.steampath
mkfile ${HOME}/.steampid
whitelist ${HOME}/.local/share/Steam
whitelist ${HOME}/.steam
whitelist ${HOME}/.steampath
whitelist ${HOME}/.steampid
include whitelist-common.inc
include whitelist-var-common.inc

# NOTE: The following were intentionally left out as they are alternative
# (i.e.: unnecessary and/or legacy) paths whose existence may potentially
# clobber other paths (see #4225).  If you use any, either add the entry to
# steam.local or move the contents to a path listed above (or open an issue if
# it's missing above).
#mkdir ${HOME}/.config/RogueLegacyStorageContainer
#mkdir ${HOME}/.local/share/RogueLegacyStorageContainer

caps.drop all
#ipc-namespace
netfilter
nodvd
nogroups
nonewprivs
noroot
notv
nou2f
# For VR support add 'ignore novideo' to your steam.local.
novideo
protocol unix,inet,inet6,netlink
# seccomp sometimes causes issues (see #2951, #3267).
# Add 'ignore seccomp' to your steam.local if you experience this.
# mount, name_to_handle_at, pivot_root and umount2 are used by Proton >= 5.13
# (see #4366).
seccomp !chroot,!mount,!name_to_handle_at,!pivot_root,!ptrace,!umount2
# process_vm_readv is used by GE-Proton7-18 (see #5185).
seccomp.32 !process_vm_readv
# tracelog breaks integrated browser
#tracelog

# private-bin is disabled while in testing, but is known to work with multiple games.
# Add the next line to your steam.local to enable private-bin.
#private-bin awk,basename,bash,bsdtar,bzip2,cat,chmod,cksum,cmp,comm,compress,cp,curl,cut,date,dbus-launch,dbus-send,desktop-file-edit,desktop-file-install,desktop-file-validate,dirname,echo,env,expr,file,find,getopt,grep,gtar,gzip,head,hostname,id,lbzip2,ldconfig,ldd,ln,ls,lsb_release,lsof,lspci,lz4,lzip,lzma,lzop,md5sum,mkdir,mktemp,mv,netstat,ps,pulseaudio,python*,readlink,realpath,rm,sed,sh,sha1sum,sha256sum,sha512sum,sleep,sort,steam,steamdeps,steam-native,steam-runtime,sum,tail,tar,tclsh,test,touch,tr,umask,uname,update-desktop-database,wc,wget,wget2,which,whoami,xterm,xz,zenity
# Extra programs are available which might be needed for select games.
# Add the next line to your steam.local to enable support for these programs.
#private-bin java,java-config,mono
# To view screenshots add the next line to your steam.local.
#private-bin eog,eom,gthumb,pix,viewnior,xviewer

private-dev
# private-etc breaks a small selection of games on some systems. Add 'ignore private-etc'
# to your steam.local to support those.
private-etc alsa,alternatives,asound.conf,bumblebee,ca-certificates,crypto-policies,dbus-1,drirc,fonts,group,gtk-2.0,gtk-3.0,host.conf,hostname,hosts,ld.so.cache,ld.so.conf,ld.so.conf.d,ld.so.preload,localtime,lsb-release,machine-id,mime.types,nvidia,os-release,passwd,pki,pulse,resolv.conf,services,ssl,vulkan
private-tmp

#dbus-user none
#dbus-system none

read-only ${HOME}/.config/MangoHud
#restrict-namespaces
