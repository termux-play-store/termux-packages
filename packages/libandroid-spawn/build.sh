TERMUX_PKG_HOMEPAGE=https://man7.org/linux/man-pages/man3/posix_spawn.3.html
TERMUX_PKG_DESCRIPTION="Symlink to libc for compatibility"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_VERSION=0.4
TERMUX_PKG_REVISION=1
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_SKIP_SRC_EXTRACT=true

termux_step_make() {
	cd "$TERMUX_PREFIX/lib"
	ln -f -s "/system/lib${TERMUX_ARCH_BITS}/libc.so" libandroid-spawn.so
}
