TERMUX_PKG_HOMEPAGE=https://gitlab.freedesktop.org/mstoeckl/waypipe
TERMUX_PKG_DESCRIPTION="A proxy for Wayland clients"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_LICENSE_FILE="LICENSE.MIT"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="0.10.4"
TERMUX_PKG_SRCURL=https://gitlab.freedesktop.org/mstoeckl/waypipe/-/archive/v${TERMUX_PKG_VERSION}/waypipe-v${TERMUX_PKG_VERSION}.tar.bz2
TERMUX_PKG_SHA256=4de622de39890912a0242e446b8d401f6fe385977985224f15353d40d6f7f0a3
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_DEPENDS="liblz4, libwayland, zstd"
TERMUX_PKG_BUILD_DEPENDS="libwayland-protocols, libwayland-cross-scanner, scdoc"
# confusing preprocessor feature matrix in waypipe:
# https://gitlab.freedesktop.org/mstoeckl/waypipe/-/blob/a04f6e3573f19ec7d7a7ef74b3fd1ee52400a2f7/src/video.c#L28-L77
# -Dwith_dmabuf=disabled appears to cause -Dwith_video=enabled to have no effect,
# preventing the compilation of any calls to FFmpeg API.
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-Dbuild_c=true
-Dbuild_rs=false
-Dman-pages=enabled
-Dtests=false
-Dwerror=false
-Dwith_video=disabled
-Dwith_dmabuf=disabled
-Dwith_lz4=enabled
-Dwith_zstd=enabled
-Dwith_vaapi=disabled
-Dwith_secctx=enabled
-Dwith_systemtap=false
"

termux_step_pre_configure() {
	termux_setup_wayland_cross_pkg_config_wrapper
}

termux_step_post_make_install() {
	# keep executable name same as previous
	mv -v "${TERMUX_PREFIX}"/bin/{waypipe-c,waypipe}
}
