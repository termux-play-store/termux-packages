TERMUX_PKG_HOMEPAGE=https://www.qt.io/
TERMUX_PKG_DESCRIPTION="Provides APIs for Wayland"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="6.9.1"
TERMUX_PKG_SRCURL="https://download.qt.io/official_releases/qt/${TERMUX_PKG_VERSION%.*}/${TERMUX_PKG_VERSION}/submodules/qtwayland-everywhere-src-${TERMUX_PKG_VERSION}.tar.xz"
TERMUX_PKG_SHA256=7d21ea0e687180ebb19b9a1f86ae9cfa7a25b4f02d5db05ec834164409932e3e
TERMUX_PKG_DEPENDS="libc++, libglvnd, libwayland, libxkbcommon, qt6-qtbase (>= ${TERMUX_PKG_VERSION}), qt6-qtdeclarative (>= ${TERMUX_PKG_VERSION}), qt6-qtsvg (>= ${TERMUX_PKG_VERSION})"
TERMUX_PKG_HOSTBUILD=true
TERMUX_PKG_NO_STATICSPLIT=true
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DCMAKE_MESSAGE_LOG_LEVEL=STATUS
-DCMAKE_SYSTEM_NAME=Linux
"

termux_step_host_build() {
	termux_setup_cmake
	termux_setup_ninja

	cmake \
		-G Ninja \
		-S ${TERMUX_PKG_SRCDIR} \
		-DCMAKE_BUILD_TYPE=MinSizeRel \
		-DCMAKE_INSTALL_PREFIX=${TERMUX_PREFIX}/opt/qt6/cross \
		-DCMAKE_MESSAGE_LOG_LEVEL=STATUS
	ninja \
		-j ${TERMUX_PKG_MAKE_PROCESSES} \
		install
}

termux_step_pre_configure() {
	termux_setup_cmake
	termux_setup_ninja
}

termux_step_make_install() {
	cmake \
		--install "${TERMUX_PKG_BUILDDIR}" \
		--prefix "${TERMUX_PREFIX}" \
		--verbose

	rm -Rf $TERMUX_PKG_HOSTBUILD_DIR
}
