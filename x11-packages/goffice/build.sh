TERMUX_PKG_HOMEPAGE=https://gitlab.gnome.org/GNOME/goffice/
TERMUX_PKG_DESCRIPTION="A GLib/GTK+ set of document-centric objects and utilities"
TERMUX_PKG_LICENSE="GPL-2.0, GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="0.10.59"
TERMUX_PKG_REVISION=1
TERMUX_PKG_SRCURL=https://download.gnome.org/sources/goffice/${TERMUX_PKG_VERSION%.*}/goffice-${TERMUX_PKG_VERSION}.tar.xz
TERMUX_PKG_SHA256=b08f7173325594b71fbbea476a30b5b3120c3dadff5c0a26d140e4e524916622
TERMUX_PKG_DEPENDS="gdk-pixbuf, glib, gtk3, libcairo, libgsf, librsvg, libspectre, libxml2, libxslt, pango, zlib"
TERMUX_PKG_BUILD_DEPENDS="g-ir-scanner"
TERMUX_PKG_VERSIONED_GIR=false
TERMUX_PKG_DISABLE_GIR=false
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--enable-introspection=no
--with-lasem=no
--without-long-double
"

termux_step_pre_configure() {
	termux_setup_gir

	CPPFLAGS+=" -D__USE_GNU"
}

termux_step_post_configure() {
	touch ./goffice/g-ir-scanner
}
