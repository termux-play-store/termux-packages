TERMUX_PKG_HOMEPAGE="https://www.freedesktop.org/wiki/Distributions/AppStream/"
TERMUX_PKG_DESCRIPTION="Provides a standard for creating app stores across distributions"
TERMUX_PKG_LICENSE="LGPL-2.1"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.0.5"
TERMUX_PKG_SRCURL=https://github.com/ximion/appstream/archive/refs/tags/v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=dd33b1375ba4221ffee060e2778c478e8150d7b1108c6309148f5fb1ca6e90c0
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_TAG_TYPE="newest-tag"
TERMUX_PKG_DEPENDS="curl, glib, libxml2, libxmlb, libyaml, zstd"
TERMUX_PKG_BUILD_DEPENDS="g-ir-scanner, glib-cross, valac"
TERMUX_PKG_VERSIONED_GIR=false
TERMUX_PKG_DISABLE_GIR=false
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-Dapidocs=false
-Ddocs=false
-Dgir=false
-Dstemming=false
-Dsystemd=false
-Dvapi=true
"

termux_step_pre_configure() {
	termux_setup_gir
	termux_setup_glib_cross_pkg_config_wrapper
}
