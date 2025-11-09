# Utility function for golang-using packages to setup a go toolchain.
termux_setup_golang() {
	export GOPATH="${TERMUX_COMMON_CACHEDIR}/go-path" GOCACHE="${TERMUX_COMMON_CACHEDIR}/go-build"
	mkdir -p "$GOPATH" "$GOCACHE"
	if [ "$TERMUX_ON_DEVICE_BUILD" = "false" ]; then
		local TERMUX_GO_VERSION=go1.25.3
		local TERMUX_GO_SHA256=0335f314b6e7bfe08c3d0cfaa7c19db961b7b99fb20be62b0a826c992ad14e0f
		local TERMUX_GO_PLATFORM=linux-amd64

		local TERMUX_BUILDGO_FOLDER
		if [ "${TERMUX_PACKAGES_OFFLINE-false}" = "true" ]; then
			TERMUX_BUILDGO_FOLDER=${TERMUX_SCRIPTDIR}/build-tools/${TERMUX_GO_VERSION}
		else
			TERMUX_BUILDGO_FOLDER=${TERMUX_COMMON_CACHEDIR}/${TERMUX_GO_VERSION}
		fi

		TERMUX_BUILDGO_FOLDER+="-r1"

		export GOROOT=$TERMUX_BUILDGO_FOLDER
		export PATH=${GOROOT}/bin:${PATH}

		if [ -d "$TERMUX_BUILDGO_FOLDER" ]; then return; fi

		local TERMUX_BUILDGO_TAR=$TERMUX_COMMON_CACHEDIR/${TERMUX_GO_VERSION}.${TERMUX_GO_PLATFORM}.tar.gz
		rm -Rf "$TERMUX_COMMON_CACHEDIR/go" "$TERMUX_BUILDGO_FOLDER"
		termux_download https://go.dev/dl/${TERMUX_GO_VERSION}.${TERMUX_GO_PLATFORM}.tar.gz \
			"$TERMUX_BUILDGO_TAR" \
			"$TERMUX_GO_SHA256"

		local old_pwd=$PWD
		cd "$TERMUX_COMMON_CACHEDIR"
		tar xf "$TERMUX_BUILDGO_TAR"
		cd go
		local patch_file
		for patch_file in $TERMUX_SCRIPTDIR/packages/golang/*.patch; do
			patch -p1 < $patch_file
		done
		cd ..
		mv go "$TERMUX_BUILDGO_FOLDER"
		rm "$TERMUX_BUILDGO_TAR"
		cd "$old_pwd"
	else
		if [[ "$(dpkg-query -W -f '${db:Status-Status}\n' golang 2>/dev/null)" != "installed" ]]; then
			echo "Package 'golang' is not installed."
			echo "You can install it with"
			echo
			echo "  pkg install golang"
			echo
			echo "or build it from source with"
			echo
			echo "  ./build-package.sh golang"
			echo
			exit 1
		fi

		export GOROOT="$TERMUX__PREFIX__LIB_DIR/go"
	fi
}
