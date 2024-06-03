TERMUX_PKG_HOMEPAGE=https://bellard.org/quickjs/
TERMUX_PKG_DESCRIPTION="QuickJS is a small and embeddable Javascript engine"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
_YEAR=2024
_MONTH=01
_DAY=13
TERMUX_PKG_VERSION=${_YEAR}${_MONTH}${_DAY}
TERMUX_PKG_SRCURL=https://bellard.org/quickjs/quickjs-${_YEAR}-${_MONTH}-${_DAY}.tar.xz
TERMUX_PKG_SHA256=3c4bf8f895bfa54beb486c8d1218112771ecfc5ac3be1036851ef41568212e03
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_NO_STATICSPLIT=true
TERMUX_PKG_EXTRA_MAKE_ARGS="
CROSS_PREFIX=${TERMUX_HOST_PLATFORM}-
CONFIG_CLANG=y
CONFIG_DEFAULT_AR=y
-W run-test262
-W run-test262-bn
prefix=$TERMUX_PREFIX
"
