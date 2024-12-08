TERMUX_PKG_HOMEPAGE=https://docs.xfce.org/panel-plugins/xfce4-pulseaudio-plugin/start
TERMUX_PKG_DESCRIPTION="Pulseaudio plugin for the Xfce4 panel"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="0.4.9"
TERMUX_PKG_SRCURL=https://archive.xfce.org/src/panel-plugins/xfce4-pulseaudio-plugin/${TERMUX_PKG_VERSION%.*}/xfce4-pulseaudio-plugin-${TERMUX_PKG_VERSION}.tar.bz2
TERMUX_PKG_SHA256=a0807615fb2848d0361b7e4568a44f26d189fda48011c7ba074986c8bfddc99a
TERMUX_PKG_DEPENDS="libnotify, libcanberra, pulseaudio, xfce4-panel, pavucontrol"
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_BUILD_IN_SRC=true
