TERMUX_PKG_HOMEPAGE=https://xorg.freedesktop.org/
TERMUX_PKG_DESCRIPTION="Display information utility for X"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=1.3.4
TERMUX_PKG_SRCURL=https://xorg.freedesktop.org/archive/individual/app/xdpyinfo-${TERMUX_PKG_VERSION}.tar.xz
TERMUX_PKG_SHA256=a8ada581dbd7266440d7c3794fa89edf6b99b8857fc2e8c31042684f3af4822b
TERMUX_PKG_DEPENDS="libx11, libxcb, libxcomposite, libxext, libxi, libxinerama, libxrender, libxtst, libxxf86dga, libxxf86vm"
TERMUX_PKG_BUILD_DEPENDS="xorg-util-macros"