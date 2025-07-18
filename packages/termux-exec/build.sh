TERMUX_PKG_HOMEPAGE=https://github.com/termux-play-store/termux-exec/
TERMUX_PKG_DESCRIPTION="An execve() wrapper to make /bin and /usr/bin shebangs work"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=1.8
TERMUX_PKG_SRCURL=https://github.com/termux-play-store/termux-exec/archive/refs/tags/${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=d9330dc99794e05e0bfd5ba797acc85d3ba6cf2c3e3436eaa4f84ca58a631a48
TERMUX_PKG_ESSENTIAL=true
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_EXTRA_MAKE_ARGS="TERMUX_PREFIX=${TERMUX_PREFIX} TERMUX_BASE_DIR=${TERMUX_BASE_DIR}"
TERMUX_PKG_AUTO_UPDATE=true
