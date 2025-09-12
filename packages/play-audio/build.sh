TERMUX_PKG_HOMEPAGE=https://github.com/termux/play-audio
TERMUX_PKG_DESCRIPTION="Simple command line audio player for Android"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=0.6
TERMUX_PKG_REVISION=3
# TODO: Fix to released version after https://github.com/termux/play-audio/pull/14 is merged&released
TERMUX_PKG_SRCURL=https://github.com/fornwall/play-audio/archive/refs/heads/include-string-h.zip
TERMUX_PKG_SHA256=17fdf01431cf2d8809f115c5c906cfa2d04e457753575ab663a6d5a39ebc637b
TERMUX_PKG_DEPENDS="libc++"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=true
