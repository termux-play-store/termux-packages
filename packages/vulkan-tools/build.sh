TERMUX_PKG_HOMEPAGE=https://github.com/KhronosGroup/Vulkan-Tools
TERMUX_PKG_DESCRIPTION="Vulkan Tools and Utilities"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.4.321"
TERMUX_PKG_SRCURL=https://github.com/KhronosGroup/Vulkan-Tools/archive/refs/tags/v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=f5f75413d21d1508b746a3d0594961d64c7155ee5f4f28245b9547c1b4697d8d
TERMUX_PKG_DEPENDS="libc++, libwayland, libx11, libxcb, vulkan-loader"
TERMUX_PKG_BUILD_DEPENDS="libwayland-protocols, vulkan-headers (=${TERMUX_PKG_VERSION}), vulkan-volk"
TERMUX_PKG_ANTI_BUILD_DEPENDS="vulkan-loader"
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_TAG_TYPE="newest-tag"
TERMUX_PKG_UPDATE_VERSION_REGEXP="\d+.\d+.\d+"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DCMAKE_SYSTEM_NAME=Linux
-DBUILD_CUBE=OFF
-DBUILD_ICD=OFF
-DBUILD_WSI_WAYLAND_SUPPORT=ON
-DBUILD_WSI_XCB_SUPPORT=ON
-DBUILD_WSI_XLIB_SUPPORT=ON
-DVULKAN_HEADERS_INSTALL_DIR=${TERMUX_PREFIX}
"

termux_step_pre_configure() {
	termux_setup_wayland_cross_pkg_config_wrapper
}
