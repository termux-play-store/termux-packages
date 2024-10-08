TERMUX_PKG_HOMEPAGE=https://github.com/lxqt/libdbusmenu-lxqt
TERMUX_PKG_DESCRIPTION="A library that provides a Qt implementation of the DBusMenu protocol"
TERMUX_PKG_LICENSE="LGPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="0.1.0"
TERMUX_PKG_SRCURL="https://github.com/lxqt/libdbusmenu-lxqt/releases/download/${TERMUX_PKG_VERSION}/libdbusmenu-lxqt-${TERMUX_PKG_VERSION}.tar.xz"
TERMUX_PKG_SHA256=a82d77375034b0f27e6e08b5c7ad9c19ee88e8d7bb699ee0423a5a0e781fb291
TERMUX_PKG_DEPENDS="libc++, qt6-qtbase"
TERMUX_PKG_BUILD_DEPENDS="qt6-qtbase-cross-tools"
TERMUX_PKG_AUTO_UPDATE=true
