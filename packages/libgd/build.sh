TERMUX_PKG_HOMEPAGE=https://libgd.github.io/
TERMUX_PKG_DESCRIPTION="GD is an open source code library for the dynamic creation of images by programmers"
TERMUX_PKG_LICENSE="custom"
TERMUX_PKG_LICENSE_FILE="COPYING"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=2.3.3
TERMUX_PKG_REVISION=4
TERMUX_PKG_SRCURL=https://github.com/libgd/libgd/releases/download/gd-${TERMUX_PKG_VERSION}/libgd-${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=dd3f1f0bb016edcc0b2d082e8229c822ad1d02223511997c80461481759b1ed2
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_METHOD=repology
TERMUX_PKG_DEPENDS="fontconfig, freetype, libheif, libjpeg-turbo, libpng, libtiff, libwebp, zlib"

# Disable vpx support for now, look at https://github.com/gagern/libgd/commit/d41eb72cd4545c394578332e5c102dee69e02ee8
# for enabling:
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="--without-vpx --without-x"
