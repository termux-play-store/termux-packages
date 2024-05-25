TERMUX_PKG_HOMEPAGE=https://bellard.org/tinyemu
TERMUX_PKG_DESCRIPTION="A system emulator for the RISC-V and x86 architectures."
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_LICENSE_FILE="MIT-LICENSE.txt"
TERMUX_PKG_MAINTAINER="@Yonle"
_VERSION=2019-12-21
TERMUX_PKG_VERSION=${_VERSION//-/.}
TERMUX_PKG_REVISION=1
TERMUX_PKG_SRCURL=https://bellard.org/tinyemu/tinyemu-${_VERSION}.tar.gz
TERMUX_PKG_SHA256=be8351f2121819b3172fcedce5cb1826fa12c87da1b7ed98f269d3e802a05555
TERMUX_PKG_DEPENDS="libcurl, openssl, sdl"
TERMUX_PKG_BUILD_IN_SRC=true