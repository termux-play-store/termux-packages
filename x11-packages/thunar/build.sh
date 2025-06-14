TERMUX_PKG_HOMEPAGE=https://docs.xfce.org/xfce/thunar/start
TERMUX_PKG_DESCRIPTION="Modern file manager for XFCE environment"
TERMUX_PKG_LICENSE="GPL-2.0, LGPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="4.20.3"
TERMUX_PKG_SRCURL=https://archive.xfce.org/src/xfce/thunar/${TERMUX_PKG_VERSION%.*}/thunar-${TERMUX_PKG_VERSION}.tar.bz2
TERMUX_PKG_SHA256=fe1908b396298e6515a90fa9ddaec0db8b684e4b3d7773118e21561baf8f9639
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_DEPENDS="atk, desktop-file-utils, exo, gdk-pixbuf, glib, gtk3, harfbuzz, libcairo, libexif, libice, libnotify, libsm, libx11, libxfce4ui, libxfce4util, pango, pcre2, shared-mime-info, xfce4-panel, xfconf, zlib"
TERMUX_PKG_BUILD_DEPENDS="g-ir-scanner, xfce4-dev-tools"
TERMUX_PKG_RECOMMENDS="gvfs, hicolor-icon-theme, thunar-archive-plugin, tumbler"
TERMUX_PKG_VERSIONED_GIR=false
TERMUX_PKG_DISABLE_GIR=false
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--disable-debug
--disable-static
--enable-gtk-doc-html=no
--enable-introspection=no
"

termux_step_pre_configure() {
	termux_setup_gir
}
