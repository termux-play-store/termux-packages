TERMUX_PKG_HOMEPAGE=https://www.gnupg.org/related_software/libassuan/
TERMUX_PKG_DESCRIPTION="Library implementing the Assuan IPC protocol used between most newer GnuPG components"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="3.0.1"
TERMUX_PKG_REVISION=2
TERMUX_PKG_SRCURL=https://www.gnupg.org/ftp/gcrypt/libassuan/libassuan-${TERMUX_PKG_VERSION}.tar.bz2
TERMUX_PKG_SHA256=c8f0f42e6103dea4b1a6a483cb556654e97302c7465308f58363778f95f194b1
TERMUX_PKG_DEPENDS="libgpg-error"
TERMUX_PKG_BREAKS="libassuan-dev"
TERMUX_PKG_REPLACES="libassuan-dev"
TERMUX_PKG_BREAKS="gnupg (<< 2.4.5-7), gpgv (<< 2.4.5-7), gpgme (<< 1.23.2-3), pinentry (<< 1.3.1-1), pinentry-gtk (<< 1.3.1), profanity (<< 0.14.0-3)"
