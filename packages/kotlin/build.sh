TERMUX_PKG_HOMEPAGE=https://kotlinlang.org/
TERMUX_PKG_DESCRIPTION="The Kotlin Programming Language"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="2.2.21"
TERMUX_PKG_SRCURL=https://github.com/JetBrains/kotlin/releases/download/v${TERMUX_PKG_VERSION}/kotlin-compiler-${TERMUX_PKG_VERSION}.zip
TERMUX_PKG_SHA256=a623871f1cd9c938946948b70ef9170879f0758043885bbd30c32f024e511714
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_DEPENDS="openjdk-21"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_PLATFORM_INDEPENDENT=true

termux_step_make_install() {
	rm -f ./bin/*.bat
	rm -rf $TERMUX_PREFIX/opt/kotlin
	mkdir -p $TERMUX_PREFIX/opt/kotlin
	cp -r ./* $TERMUX_PREFIX/opt/kotlin/

	# Avoid the below error due to trying to load a libc version of libjansi:
	# Failed to load native library:jansi-2.4.0-629e7b7df22258e7-libjansi.so. osinfo: Linux/arm64
	# java.lang.UnsatisfiedLinkError: /data/data/com.termux/files/usr/tmp/jansi-2.4.0-629e7b7df22258e7-libjansi.so:
	# dlopen failed: library "libc.so.6" not found:
	# needed by /data/data/com.termux/files/usr/tmp/jansi-2.4.0-629e7b7df22258e7-libjansi.so in namespace (default)
	sed -i '$ i\JAVA_OPTS="$JAVA_OPTS -Dkotlin.colors.enabled=false"' $TERMUX_PREFIX/opt/kotlin/bin/kotlinc

	for i in $TERMUX_PREFIX/opt/kotlin/bin/*; do
		if [ ! -f "$i" ]; then
			continue
		fi
		ln -sfr $i $TERMUX_PREFIX/bin/$(basename $i)
	done
}
