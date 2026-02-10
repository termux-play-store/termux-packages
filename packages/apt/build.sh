TERMUX_PKG_HOMEPAGE=https://packages.debian.org/apt
TERMUX_PKG_DESCRIPTION="Front-end for the dpkg package manager"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="3.1.15"
TERMUX_PKG_SRCURL=https://deb.debian.org/debian/pool/main/a/apt/apt_${TERMUX_PKG_VERSION}.tar.xz
TERMUX_PKG_SHA256=208d58ff5bf6d9ebb93da0d77d480ef87b4618b0210dc88cb977aadd88d1c1c6
# apt-key requires utilities from coreutils, findutils, gpgv, grep, sed.
TERMUX_PKG_DEPENDS="coreutils, dpkg, findutils, gpgv, grep, libc++, openssl, liblzma, sed, termux-keyring, termux-licenses, xxhash"
TERMUX_PKG_BUILD_DEPENDS="docbook-xsl"
TERMUX_PKG_CONFLICTS="apt-transport-https, libapt-pkg, unstable-repo, game-repo, science-repo"
TERMUX_PKG_REPLACES="apt-transport-https, libapt-pkg, unstable-repo, game-repo, science-repo"
TERMUX_PKG_PROVIDES="unstable-repo, game-repo, science-repo"
TERMUX_PKG_SUGGESTS="gnupg"
TERMUX_PKG_ESSENTIAL=true

TERMUX_PKG_CONFFILES="
etc/apt/sources.list.d/termux.sources
"

TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DCMAKE_POLICY_VERSION_MINIMUM=3.5
-DPERL_EXECUTABLE=$(command -v perl)
-DCMAKE_DISABLE_FIND_PACKAGE_ZLIB=TRUE
-DCMAKE_DISABLE_FIND_PACKAGE_BZip2=TRUE
-DCMAKE_DISABLE_FIND_PACKAGE_ZIP=TRUE
-DCMAKE_DISABLE_FIND_PACKAGE_ZSTD=TRUE
-DCMAKE_DISABLE_FIND_PACKAGE_LZ4=TRUE
-DCMAKE_INSTALL_FULL_LOCALSTATEDIR=$TERMUX_PREFIX
-DCACHE_DIR=${TERMUX_CACHE_DIR}/apt
-DCOMMON_ARCH=$TERMUX_ARCH
-DDEFAULT_PAGER=less
-DDPKG_DATADIR=$TERMUX_PREFIX/share/dpkg
-DUSE_NLS=OFF
-DWITH_DOC=OFF
-DWITH_DOC_MANPAGES=ON
"

# ubuntu uses instead $PREFIX/lib instead of $PREFIX/libexec to
# "Work around bug in GNUInstallDirs" (from apt 1.4.8 CMakeLists.txt).
# Archlinux uses $PREFIX/libexec though, so let's force libexec->lib to
# get same build result on ubuntu and archlinux.
TERMUX_PKG_EXTRA_CONFIGURE_ARGS+="-DCMAKE_INSTALL_LIBEXECDIR=lib"

TERMUX_PKG_RM_AFTER_INSTALL="
bin/apt-cdrom
bin/apt-extracttemplates
bin/apt-sortpkgs
etc/apt/apt.conf.d
lib/apt/methods/cdrom
lib/apt/methods/mirror*
lib/apt/methods/rred
lib/apt/planners/
lib/apt/solvers/
lib/dpkg/
share/man/man1/apt-extracttemplates.1
share/man/man1/apt-sortpkgs.1
share/man/man1/apt-transport-mirror.1
share/man/man8/apt-cdrom.8
"

termux_step_pre_configure() {
	# Certain packages are not safe to build on device because their
	# build.sh script deletes specific files in $TERMUX_PREFIX.
	if $TERMUX_ON_DEVICE_BUILD; then
		termux_error_exit "Package '$TERMUX_PKG_NAME' is not safe for on-device builds."
	fi

	# Fix i686 builds.
	CXXFLAGS+=" -Wno-c++11-narrowing"

	# for manpage build
	local docbook_xsl_version=$(. $TERMUX_SCRIPTDIR/packages/docbook-xsl/build.sh; echo $TERMUX_PKG_VERSION)
	TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DDOCBOOK_XSL=$TERMUX_PREFIX/share/xml/docbook/xsl-stylesheets-$docbook_xsl_version-nons"
}

termux_step_post_make_install() {
	mkdir -p "$TERMUX_PREFIX"/etc/apt/sources.list.d
	{
		echo "# The main termux repository"
		echo "Components: main"
		echo "Signed-By: $TERMUX_PREFIX/etc/apt/trusted.gpg.d/termux-packages.gpg"
		echo "Suites: stable"
		echo "Types: deb"
		echo "URIs: https://termux.net"
	} > $TERMUX_PREFIX/etc/apt/sources.list.d/termux.sources

	# apt-transport-tor
	ln -sfr $TERMUX_PREFIX/lib/apt/methods/http $TERMUX_PREFIX/lib/apt/methods/tor
	ln -sfr $TERMUX_PREFIX/lib/apt/methods/http $TERMUX_PREFIX/lib/apt/methods/tor+http
	ln -sfr $TERMUX_PREFIX/lib/apt/methods/https $TERMUX_PREFIX/lib/apt/methods/tor+https
	# Workaround for "empty" subpackage:
	local dir=$TERMUX_PREFIX/share/apt-transport-tor
	mkdir -p $dir
	touch $dir/.placeholder
}

termux_step_create_debscripts() {
	cat <<- EOF > ./postinst
	#!$TERMUX_PREFIX/bin/sh
	rm -Rf $TERMUX_PREFIX/etc/apt/sources.list
	exit 0
	EOF
}
