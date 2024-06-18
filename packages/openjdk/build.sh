TERMUX_PKG_HOMEPAGE=https://github.com/openjdk/jdk21u
TERMUX_PKG_DESCRIPTION="Java development kit and runtime"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=21.0.4+5
TERMUX_PKG_SRCURL=https://github.com/openjdk/jdk21u/archive/refs/tags/jdk-${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=7dce384597c955c199930c2c678bbac4cb744608603d31ef4aa0743dbb39ce7a
TERMUX_PKG_DEPENDS="libjpeg-turbo, zlib, libandroid-shmem"
TERMUX_PKG_BUILD_DEPENDS="cups, fontconfig, giflib, libpng, libx11, libxrender, libxext, libxtst, libxrandr"
TERMUX_PKG_RECOMMENDS="ca-certificates-java, resolv-conf"
TERMUX_PKG_SUGGESTS="cups"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_HAS_DEBUG=false
TERMUX_PKG_API_LEVEL=31

termux_step_pre_configure() {
	unset JAVA_HOME
}

termux_step_configure() {
	local jdk_ldflags="-L${TERMUX_PREFIX}/lib -Wl,-rpath=$TERMUX_PREFIX/lib/jvm/java-21-openjdk/lib -Wl,-rpath=${TERMUX_PREFIX}/lib -Wl,--enable-new-dtags"
	bash ./configure \
		--disable-precompiled-headers \
		--disable-warnings-as-errors \
		--enable-headless-only \
		--enable-option-checking=fatal \
		--openjdk-target=$TERMUX_HOST_PLATFORM \
		--with-cups-include="$TERMUX_PREFIX/include" \
		--with-debug-level=release \
		--with-extra-cflags="$CFLAGS $CPPFLAGS -DLE_STANDALONE -D__ANDROID__=1 -D__TERMUX__=1" \
		--with-extra-cxxflags="$CXXFLAGS $CPPFLAGS -DLE_STANDALONE -D__ANDROID__=1 -D__TERMUX__=1" \
		--with-extra-ldflags="${jdk_ldflags} -Wl,--as-needed -landroid-shmem" \
		--with-fontconfig-include="$TERMUX_PREFIX/include" \
		--with-freetype-include="$TERMUX_PREFIX/include/freetype2" \
		--with-freetype-lib="$TERMUX_PREFIX/lib" \
		--with-giflib=system \
		--with-jvm-variants=server \
		--with-libjpeg=system \
		--with-libpng=system \
		--with-toolchain-type=clang \
		--without-x \
		--with-zlib=system \
		--x-includes="$TERMUX_PREFIX/include/X11" \
		AR="$AR" \
		NM="$NM" \
		OBJCOPY="$OBJCOPY" \
		OBJDUMP="$OBJDUMP" \
		STRIP="$STRIP" \
		CXXFILT="llvm-cxxfilt" \
		BUILD_CC="/usr/bin/clang-16" \
		BUILD_CXX="/usr/bin/clang++-16" \
		BUILD_NM="/usr/bin/llvm-nm-16" \
		BUILD_AR="/usr/bin/llvm-ar-16" \
		BUILD_OBJCOPY="/usr/bin/llvm-objcopy-16" \
		BUILD_STRIP="/usr/bin/llvm-strip-16"
}

termux_step_make() {
	cd build/linux-${TERMUX_ARCH/i686/x86}-server-release
	make JOBS=1 images
}

termux_step_make_install() {
	mkdir -p $TERMUX_PREFIX/lib/jvm/java-21-openjdk
	cp -r build/linux-${TERMUX_ARCH/i686/x86}-server-release/images/jdk/* \
		$TERMUX_PREFIX/lib/jvm/java-21-openjdk/
	find $TERMUX_PREFIX/lib/jvm/java-21-openjdk/ -name "*.debuginfo" -delete

	# Dependent projects may need JAVA_HOME.
	mkdir -p $TERMUX_PREFIX/lib/jvm/java-21-openjdk/etc/profile.d
	echo "export JAVA_HOME=$TERMUX_PREFIX/lib/jvm/java-21-openjdk/" > \
		$TERMUX_PREFIX/lib/jvm/java-21-openjdk/etc/profile.d/java.sh
}

termux_step_post_make_install() {
	cd $TERMUX_PREFIX/lib/jvm/java-21-openjdk/man/man1
	for manpage in *.1; do
		gzip "$manpage"
	done

	local binaries="$(find $TERMUX_PREFIX/lib/jvm/java-21-openjdk/bin -executable -type f | xargs -I{} basename "{}" | xargs echo)"
	for tool in $binaries; do
		ln -sf $TERMUX_PREFIX/lib/jvm/java-21-openjdk/bin/$tool $TERMUX_PREFIX/bin/$tool
	done

	local manpages="$(find $TERMUX_PREFIX/lib/jvm/java-21-openjdk/man/man1 -name "*.1.gz" | xargs -I{} basename "{}" | xargs echo)"
	for manpage in $manpages; do
		ln -sf $TERMUX_PREFIX/lib/jvm/java-21-openjdk/man/man1/$manpage.gz $TERMUX_PREFIX/share/man/man1/$manpage.gz
	done
}
