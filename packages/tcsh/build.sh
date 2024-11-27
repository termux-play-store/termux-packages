TERMUX_PKG_HOMEPAGE=https://www.tcsh.org
TERMUX_PKG_DESCRIPTION="TENEX C Shell, an enhanced version of Berkeley csh"
TERMUX_PKG_LICENSE="BSD 3-Clause"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="6.24.14"
TERMUX_PKG_SRCURL=https://github.com/tcsh-org/tcsh/archive/TCSH${TERMUX_PKG_VERSION//./_}.tar.gz
TERMUX_PKG_SHA256=f406eedfb98715b0baed248b2e42d51f2c16f902337014e08aca5ef7e7f8c51b
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_UPDATE_METHOD=repology
TERMUX_PKG_BUILD_DEPENDS="libcrypt, ncurses"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="--enable-nls --disable-nls-catalogs"
