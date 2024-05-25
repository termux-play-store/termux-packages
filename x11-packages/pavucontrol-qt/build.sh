TERMUX_PKG_HOMEPAGE=https://lxqt.github.io
TERMUX_PKG_DESCRIPTION="Qt port of volume control of sound server PulseAudio"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.4.0"
TERMUX_PKG_SRCURL="https://github.com/lxqt/pavucontrol-qt/releases/download/${TERMUX_PKG_VERSION}/pavucontrol-qt-${TERMUX_PKG_VERSION}.tar.xz"
TERMUX_PKG_SHA256=0d7ced3b9d215bcfae8fd5df5429aa07b0517984925cfa1cd020a9505749a994
TERMUX_PKG_DEPENDS="libc++, qt5-qtbase, kwindowsystem, liblxqt, pulseaudio-glib"
TERMUX_PKG_BUILD_DEPENDS="lxqt-build-tools, qt5-qtbase-cross-tools, qt5-qttools-cross-tools"
TERMUX_PKG_AUTO_UPDATE=true