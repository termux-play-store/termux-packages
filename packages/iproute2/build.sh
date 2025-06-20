TERMUX_PKG_HOMEPAGE=https://wiki.linuxfoundation.org/networking/iproute2
TERMUX_PKG_DESCRIPTION="Utilities for controlling networking"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="6.15.0"
TERMUX_PKG_SRCURL=https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-${TERMUX_PKG_VERSION}.tar.xz
TERMUX_PKG_SHA256=8041854a882583ad5263466736c9c8c68c74b1a35754ab770d23343f947528fb
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
	CFLAGS+=" -fPIC"
	}
