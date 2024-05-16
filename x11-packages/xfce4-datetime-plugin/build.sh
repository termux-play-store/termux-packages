TERMUX_PKG_HOMEPAGE=https://docs.xfce.org/panel-plugins/xfce4-datetime-plugin/start
TERMUX_PKG_DESCRIPTION="xfce4-datetime-plugin shows the date and time in the panel; when left-clicked, a popup calendar appears."
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
_MAJOR_VERSION=0.8
TERMUX_PKG_VERSION=${_MAJOR_VERSION}.3
TERMUX_PKG_SRCURL=https://archive.xfce.org/src/panel-plugins/xfce4-datetime-plugin/${_MAJOR_VERSION}/xfce4-datetime-plugin-$TERMUX_PKG_VERSION.tar.bz2
TERMUX_PKG_SHA256=6b2eeb79fb586868737426cbd2a4cd43c7f8c58507d8a2f578e0150187cc00b0
TERMUX_PKG_DEPENDS="atk, gdk-pixbuf, glib, gtk3, harfbuzz, libcairo, libxfce4ui, libxfce4util, pango, xfce4-panel, zlib"