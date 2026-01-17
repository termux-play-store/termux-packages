termux_step_get_dependencies() {
	if [ "$TERMUX_PKG_METAPACKAGE" = true ]; then
		return 0
	fi

	if [ "$TERMUX_INSTALL_DEPS" = true ]; then
		# Download repo files
		termux_download_repo_file
	fi

	local DEBS_TO_INSTALL=()

	while read PKG PKG_DIR; do
		if [ -z $PKG ]; then
			continue
		elif [ "$PKG" = "ERROR" ]; then
			termux_error_exit "Obtaining buildorder failed"
		fi

		# llvm doesn't build if ndk-sysroot is installed:
		if [ "$PKG" = "ndk-sysroot" ]; then continue; fi

		read DEP_ARCH DEP_VERSION UNUSED UNUSED <<< $(termux_extract_dep_info $PKG "${PKG_DIR}")

		local can_build_locally=true
		if [ "$TERMUX_ON_DEVICE_BUILD" = "true" ] && ! termux_package__is_package_on_device_build_supported "$PKG_DIR"; then
			echo "Building dependency $PKG on device is not supported. It will be downloaded..."
			can_build_locally=false
		fi

		local DEB_FILE_TO_INSTALL

		local build_dependency=false
		if [ "$can_build_locally" = "true" ] && [ "$TERMUX_INSTALL_DEPS" = "false" ]; then
			build_dependency=true
		else
			DEB_FILE_TO_INSTALL="${TERMUX_COMMON_CACHEDIR}-${DEP_ARCH}/${PKG}_${DEP_VERSION}_${DEP_ARCH}.deb"
			if ! termux_download_deb_pac $PKG $DEP_ARCH $DEP_VERSION "$DEB_FILE_TO_INSTALL"; then
				if [ "$can_build_locally" = "false" ]; then
					termux_error_exit "Cannot build nor download $PKG@$DEP_VERSION"
				fi
				echo "Download of $PKG@$DEP_VERSION from $TERMUX_REPO_URL failed, building instead"
				build_dependency=true
			fi
		fi

		if $build_dependency; then
			DEB_FILE_TO_INSTALL=$TERMUX_OUTPUT_DIR/${PKG}_${DEP_VERSION}_${DEP_ARCH}.deb
			if [ -f "$DEB_FILE_TO_INSTALL" ]; then
				echo "Using already built $DEB_FILE_TO_INSTALL ..."
			else
				[ ! "$TERMUX_QUIET_BUILD" = true ] && echo "Building dependency $PKG instead of downloading..."
				termux_run_build-package
			fi
		fi

		DEBS_TO_INSTALL+=( "$DEB_FILE_TO_INSTALL" )

	done<<<$(./scripts/buildorder.py -i "$TERMUX_PKG_BUILDER_DIR" $TERMUX_PACKAGES_DIRECTORIES || echo "ERROR")

	local deb_file
	for deb_file in "${DEBS_TO_INSTALL[@]}"; do
		[ ! "$TERMUX_QUIET_BUILD" = true ] && echo "Extracting $deb_file ..."
		cd $TERMUX_COMMON_CACHEDIR-$DEP_ARCH
		ar x $deb_file data.tar.xz
		if tar -tf data.tar.xz|grep "^./$">/dev/null; then
			# Strip prefixed ./, to avoid possible
			# permission errors from tar
			tar -xf data.tar.xz --strip-components=1 \
				--no-overwrite-dir -C /
		else
			tar -xf data.tar.xz --no-overwrite-dir -C /
		fi
	done

	for lib in complex-math glob spawn support utimes; do
		# Make "-landroid-*" work when building for compatibility.
		if [ -L "$TERMUX_PREFIX/lib/libandroid-${lib}.so" ]; then
			rm "$TERMUX_PREFIX/lib/libandroid-${lib}.so"
			echo "" > "$TERMUX_PREFIX/lib/libandroid-${lib}.so"
			# Avoid the file being included in the package:
			touch -d "2 hours ago" "$TERMUX_PREFIX/lib/libandroid-${lib}.so"
		fi
	done
}

termux_run_build-package() {
	TERMUX_BUILD_IGNORE_LOCK=true ./build-package.sh \
		$(test "${TERMUX_INSTALL_DEPS}" = "true" && echo "-i") \
		"${PKG_DIR}"
}

termux_download_repo_file() {
	termux_get_repo_files

	# When doing build on device, ensure that apt lists are up-to-date.
	if [ "$TERMUX_ON_DEVICE_BUILD" = "true" ]; then
		apt update
	fi
}
