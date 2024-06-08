TERMUX_PKG_HOMEPAGE=https://github.com/KhronosGroup/Vulkan-Loader
TERMUX_PKG_DESCRIPTION="Vulkan Loader"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.3.287"
TERMUX_PKG_SRCURL=https://github.com/KhronosGroup/Vulkan-Loader/archive/refs/tags/v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=8501325eb301c9cbd147acf439ad243dc6b4b417c08adc413cdeb4e188537fb0
TERMUX_PKG_BUILD_DEPENDS="vulkan-headers (=${TERMUX_PKG_VERSION})"
TERMUX_PKG_CONFLICTS="vulkan-loader-android"
TERMUX_PKG_PROVIDES="vulkan-loader-android"
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_TAG_TYPE="newest-tag"
TERMUX_PKG_UPDATE_VERSION_REGEXP="\d+.\d+.\d+"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DBUILD_TESTS=OFF
-DCMAKE_SYSTEM_NAME=Linux
-DENABLE_WERROR=OFF
-DVULKAN_HEADERS_INSTALL_DIR=$TERMUX_PREFIX
-DBUILD_WSI_XCB_SUPPORT=OFF
-DBUILD_WSI_XLIB_SUPPORT=OFF
-DBUILD_WSI_WAYLAND_SUPPORT=OFF
"

termux_step_pre_configure() {
	CPPFLAGS+=" -Wno-typedef-redefinition"
}

termux_step_post_make_install() {
	# Sanity check
	echo "INFO: ========== vulkan.pc =========="
	cat "$TERMUX_PREFIX/lib/pkgconfig/vulkan.pc"
	echo "INFO: ========== vulkan.pc =========="

	# Lots of apps will search libvulkan.so.1
	local e=0
	[ ! -e "$TERMUX_PREFIX"/lib/libvulkan.so ] && e=1
	[ ! -e "$TERMUX_PREFIX"/lib/libvulkan.so.1 ] && e=1
	if [[ "${e}" != 0 ]]; then
		termux_error_exit "
		Symlink check failed!
		$(file "$TERMUX_PREFIX"/lib/libvulkan.so)
		$(file "$TERMUX_PREFIX"/lib/libvulkan.so.1)
		"
	fi
}
