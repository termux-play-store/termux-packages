TERMUX_PKG_HOMEPAGE=https://android.googlesource.com/platform/bionic/+/refs/heads/master/libm/upstream-netbsd/lib/libm/complex
TERMUX_PKG_DESCRIPTION="Symlink to libm for compatibility"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_VERSION="0.3"
TERMUX_PKG_REVISION=1
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_SKIP_SRC_EXTRACT=true

termux_step_make() {
	cd "$TERMUX_PREFIX/lib"
	ln -f -s "/system/lib${TERMUX_ARCH_BITS}/libm.so" libandroid-complex-math.so
}
