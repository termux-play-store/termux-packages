TERMUX_PKG_HOMEPAGE=https://libgit2.github.com/
TERMUX_PKG_DESCRIPTION="C library implementing Git core methods"
# License: GPL-2.0 with linking exception
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_LICENSE_FILE="COPYING"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.9.1"
TERMUX_PKG_SRCURL=https://github.com/libgit2/libgit2/archive/v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=14cab3014b2b7ad75970ff4548e83615f74d719afe00aa479b4a889c1e13fc00
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_DEPENDS="libssh2, openssl, pcre2, zlib"
TERMUX_PKG_BUILD_DEPENDS="libpcreposix"
TERMUX_PKG_BREAKS="libgit2-dev"
TERMUX_PKG_REPLACES="libgit2-dev"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DBUILD_TESTS=OFF
-DUSE_SSH=ON
-DREGEX_BACKEND=pcre2
"

termux_step_post_get_source() {
	# Do not forget to bump revision of reverse dependencies and rebuild them
	# after SOVERSION is changed.
	local _SOVERSION=1.9

	local v=$(echo ${TERMUX_PKG_VERSION#*:} | cut -d . -f 1-2)
	if [ "${v}" != "${_SOVERSION}" ]; then
		termux_error_exit "SOVERSION guard check failed."
	fi
}

termux_step_pre_configure() {
	find "$TERMUX_PKG_SRCDIR" -name CMakeLists.txt | xargs -n 1 \
		sed -i 's/\( PROPERTIES C_STANDARD\) 90/\1 99/g'
}
