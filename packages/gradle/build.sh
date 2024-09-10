TERMUX_PKG_HOMEPAGE=https://gradle.org/
TERMUX_PKG_DESCRIPTION="Powerful build system for the JVM"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="8.10.1"
TERMUX_PKG_SRCURL=https://services.gradle.org/distributions/gradle-${TERMUX_PKG_VERSION}-bin.zip
TERMUX_PKG_SHA256=1541fa36599e12857140465f3c91a97409b4512501c26f9631fb113e392c5bd1
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_DEPENDS="openjdk"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_PLATFORM_INDEPENDENT=true

termux_step_make_install() {
	rm -f ./bin/*.bat
	rm -rf $TERMUX_PREFIX/opt/gradle
	mkdir -p $TERMUX_PREFIX/opt/gradle
	cp -r ./* $TERMUX_PREFIX/opt/gradle/
	for i in $TERMUX_PREFIX/opt/gradle/bin/*; do
		if [ ! -f "$i" ]; then
			continue
		fi
		ln -sfr $i $TERMUX_PREFIX/bin/$(basename $i)
	done
}
