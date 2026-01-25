TERMUX_PKG_HOMEPAGE=https://source.android.com/
TERMUX_PKG_DESCRIPTION="bionic libc, libicuuc, liblzma, zlib, and boringssl for package builder and termux-docker"
TERMUX_PKG_LICENSE="BSD 3-Clause, Apache-2.0, ZLIB, Public Domain, BSD 2-Clause, OpenSSL, MirOS, BSD"
TERMUX_PKG_LICENSE_FILE="
bionic/libc/NOTICE
external/zlib/LICENSE
external/lzma/NOTICE
external/icu/LICENSE
external/boringssl/NOTICE
external/mksh/NOTICE
external/toybox/LICENSE
external/iputils/NOTICE
"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="16.0.0_r4"
TERMUX_PKG_AUTO_UPDATE=false
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_SKIP_SRC_EXTRACT=true
# Should be handled by AOSP build system so disable it here.
TERMUX_PKG_UNDEF_SYMBOLS_FILES="all"
TERMUX_PKG_BREAKS="bionic-host"
TERMUX_PKG_REPLACES="bionic-host"

termux_step_get_source() {
	if $TERMUX_ON_DEVICE_BUILD; then
		termux_error_exit "Package '$TERMUX_PKG_NAME' is not safe for on-device builds."
	fi

	termux_download https://storage.googleapis.com/git-repo-downloads/repo "${TERMUX_PKG_CACHEDIR}/repo" SKIP_CHECKSUM
	chmod +x "${TERMUX_PKG_CACHEDIR}/repo"

	mkdir -p "${TERMUX_PKG_SRCDIR}"
	cd "${TERMUX_PKG_SRCDIR}" || termux_error_exit "Couldn't enter source code directory: ${TERMUX_PKG_SRCDIR}"

	# Repo requires us to have a Git user name and email set.
	# The GitHub workflow does this, but the local build container doesn't
	[[ "$(git config --get user.name)" != '' ]] || git config --global user.name "Termux Github Actions"
	[[ "$(git config --get user.email)" != '' ]] || git config --global user.email "contact@termux.dev"

	"${TERMUX_PKG_CACHEDIR}"/repo init \
		--partial-clone \
		--no-use-superproject \
		-b android-${TERMUX_PKG_VERSION} \
		-u https://android.googlesource.com/platform/manifest \
		<<< 'n'

	local _NUM_JOBS=4
	"${TERMUX_PKG_CACHEDIR}"/repo sync -c -j${_NUM_JOBS} ||
		"${TERMUX_PKG_CACHEDIR}"/repo sync -c -j${_NUM_JOBS} ||
		"${TERMUX_PKG_CACHEDIR}"/repo sync -c -j${_NUM_JOBS} ||
		termux_error_exit "Repo sync failed"
}

termux_step_make() {
	case "${TERMUX_ARCH}" in
		i686) _ARCH=x86 ;;
		aarch64) _ARCH=arm64 ;;
		*) _ARCH=${TERMUX_ARCH} ;;
	esac

	local _GO_CACHE_DIR="${TERMUX_PKG_TMPDIR}/gocache"

	env -i PATH="${PATH}" GOCACHE="${_GO_CACHE_DIR}" bash -c "
		set -e;
		cd ${TERMUX_PKG_SRCDIR}
		source build/envsetup.sh;
		lunch aosp_${_ARCH}-aosp_current-eng;
		export ALLOW_MISSING_DEPENDENCIES=true
		make linker libc libm libdl libdl_android debuggerd crash_dump
		make toybox sh mkshrc ping ping6 tracepath tracepath6 traceroute6 arping
	"
}

termux_step_make_install() {
	mkdir -p "${TERMUX_PREFIX}/opt/aosp/"
	cp -r "${TERMUX_PKG_SRCDIR}"/out/target/product/generic*/system "${TERMUX_PREFIX}/opt/aosp/system"
	cp -r "${TERMUX_PKG_SRCDIR}"/out/target/product/generic*/apex "${TERMUX_PREFIX}/opt/aosp/apex"
}
