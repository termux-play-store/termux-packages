TERMUX_PKG_HOMEPAGE=https://gitlab.freedesktop.org/mstoeckl/waypipe
TERMUX_PKG_DESCRIPTION="A proxy for Wayland clients"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="0.9.0"
TERMUX_PKG_SRCURL=https://gitlab.freedesktop.org/mstoeckl/waypipe/-/archive/v${TERMUX_PKG_VERSION}/waypipe-v${TERMUX_PKG_VERSION}.tar.bz2
TERMUX_PKG_SHA256=79d5e8c534e190b0f076ae2e9cd711881d31efc58dbbd6326b477f3ed5a99807
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_DEPENDS="liblz4, zstd"
TERMUX_PKG_BUILD_DEPENDS="ffmpeg"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-Dwith_video=enabled
-Dwith_dmabuf=disabled
-Dwith_lz4=enabled
-Dwith_zstd=enabled
-Dwith_vaapi=disabled
-Dwith_systemtap=false
"
