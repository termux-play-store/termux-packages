#!/usr/bin/env bash
##
##  Script for generating bootstrap archives.
##

set -e

export TERMUX_SCRIPTDIR=$(realpath "$(dirname "$(realpath "$0")")/../")
. $(dirname "$(realpath "$0")")/properties.sh
BOOTSTRAP_TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/bootstrap-tmp.XXXXXXXX")
trap 'rm -rf $BOOTSTRAP_TMPDIR' EXIT

# By default, bootstrap archives will be built for all architectures
# supported by Termux application.
# Override with option '--architectures'.
TERMUX_ARCHITECTURES=("arm" "aarch64" "x86_64")

# The supported termux package managers.
TERMUX_PACKAGE_MANAGERS=("apt")

# The repository base urls mapping for package managers.
declare -A REPO_BASE_URLS=(
	["apt"]="https://termux.net"
)

# The package manager that will be installed in bootstrap.
# The default is 'apt'. Can be changed by using the '--pm' option.
TERMUX_PACKAGE_MANAGER="apt"

# The repository base url for package manager.
# Can be changed by using the '--repository' option.
REPO_BASE_URL="${REPO_BASE_URLS[${TERMUX_PACKAGE_MANAGER}]}"

# A list of non-essential packages. By default it is empty, but can
# be filled with option '--add'.
declare -a ADDITIONAL_PACKAGES

# Check for some important utilities that may not be available for
# some reason.
for cmd in ar awk curl grep gzip find sed tar xargs xz zip jq; do
	if [ -z "$(command -v $cmd)" ]; then
		echo "[!] Utility '$cmd' is not available in PATH."
		exit 1
	fi
done

TERMUX_BUILD_BOOTSTRAPS=false

# Download package lists from remote repository.
read_package_list_deb() {
	local architecture
	for architecture in "$1"; do
		if [ ! -e "${BOOTSTRAP_TMPDIR}/packages.${architecture}" ]; then
			echo "[*] Downloading package list for architecture '${architecture}'..."
			curl --fail --location \
				--output "${BOOTSTRAP_TMPDIR}/packages.${architecture}" \
				"${REPO_BASE_URL}/dists/stable/main/binary-${architecture}/Packages"
			echo >> "${BOOTSTRAP_TMPDIR}/packages.${architecture}"
		fi

		echo "[*] Reading package list for '${architecture}'..."
		while read -r -d $'\xFF' package; do
			if [ -n "$package" ]; then
				local package_name
				package_name=$(echo "$package" | grep -i "^Package:" | awk '{ print $2 }')

				if [ -z "${PACKAGE_METADATA["$package_name"]}" ]; then
					PACKAGE_METADATA["$package_name"]="$package"
				else
					local prev_package_ver cur_package_ver
					cur_package_ver=$(echo "$package" | grep -i "^Version:" | awk '{ print $2 }')
					prev_package_ver=$(echo "${PACKAGE_METADATA["$package_name"]}" | grep -i "^Version:" | awk '{ print $2 }')

					# If package has multiple versions, make sure that our metadata
					# contains the latest one.
					if [ "$(echo -e "${prev_package_ver}\n${cur_package_ver}" | sort -rV | head -n1)" = "${cur_package_ver}" ]; then
						PACKAGE_METADATA["$package_name"]="$package"
					fi
				fi
			fi
		done < <(sed -e "s/^$/\xFF/g" "${BOOTSTRAP_TMPDIR}/packages.${architecture}")
	done
}

download_db_packages_pac() {
	if [ ! -e "${PATH_DB_PACKAGES}" ]; then
		echo "[*] Downloading package list for architecture '${package_arch}'..."
		curl --fail --location \
			--output "${PATH_DB_PACKAGES}" \
			"${REPO_BASE_URL}/${package_arch}/main.json"
	fi
}

read_db_packages_pac() {
	jq -r '."'${package_name}'"."'${1}'" | if type == "array" then .[] else . end' "${PATH_DB_PACKAGES}"
}

print_desc_package_pac() {
	echo -e "%${1}%\n${2}\n"
}

# Download specified package, its dependencies and then extract *.deb files to
# the bootstrap root.
pull_package() {
	local package_name=$1
	local package_tmpdir="${BOOTSTRAP_PKGDIR}/${package_name}"
	mkdir -p "$package_tmpdir"

	local built_package_deb=""

	if [ ${TERMUX_PACKAGE_MANAGER} = "apt" ]; then
		if [ "${TERMUX_BUILD_BOOTSTRAPS}" = true ]; then
			if [ ! -d packages/$package_name ]; then
				local parent_package_path=$(find . -name $package_name.subpackage.sh)
				local package_to_build=$(basename $(dirname $parent_package_path))
				echo "INFO: Package $package_name was a subpackage, building parent package $package_to_build"
			else
				local package_to_build="$package_name"
			fi

			if [[ -v "PACKAGE_METADATA[$package_to_build]" ]]; then
				echo "INFO: Package $package_to_build is already built"
			else
				./build-package.sh -a "$package_arch" "$package_to_build"
			fi

			# Scan through built .deb files:
			local f
			for f in output/*.deb; do
				local control=$(ar p $f control.tar.xz | tar xJOf - ./control)
				local deb_package_name=$(echo $control | grep 'Package: ' | cut -d ' ' -f 2)
				PACKAGE_METADATA["$deb_package_name"]="$control"
				if [ "$package_name" = "$deb_package_name" ]; then
					built_package_deb="$f"
				fi
			done
			if [ -z "$built_package_deb" ]; then
				echo "ERROR: Could not find built package for $package_name"
				exit 1
			fi
		fi

		local package_url
		package_url="$REPO_BASE_URL/$(echo "${PACKAGE_METADATA[${package_name}]}" | grep -i "^Filename:" | awk '{ print $2 }')"
		if [ "${TERMUX_BUILD_BOOTSTRAPS}" != true ]; then
			if [ "${package_url}" = "$REPO_BASE_URL" ] || [ "${package_url}" = "${REPO_BASE_URL}/" ]; then
				echo "[!] Failed to determine URL for package '$package_name'."
				exit 1
			fi
		fi

		local package_dependencies
		package_dependencies=$(
			while read -r token; do
				echo "$token" | cut -d'|' -f1 | sed -E 's@\(.*\)@@'
			done < <(echo "${PACKAGE_METADATA[${package_name}]}" | grep -i "^Depends:" | sed -E 's@^[Dd]epends:@@' | tr ',' '\n')
		)

		# Recursively handle dependencies.
		if [ -n "$package_dependencies" ]; then
			local dep
			for dep in $package_dependencies; do
				if [ ! -e "${BOOTSTRAP_PKGDIR}/${dep}" ]; then
					pull_package "$dep"
				fi
			done
			unset dep
		fi

		if [ ! -e "$package_tmpdir/package.deb" ]; then
			if [ "$TERMUX_BUILD_BOOTSTRAPS" = true ]; then
				echo "[*] Putting '$package_name' deb into place..."
				cp "$built_package_deb" "$package_tmpdir/package.deb"
			else
				echo "[*] Downloading '$package_name'..."
				curl --fail --location --output "$package_tmpdir/package.deb" "$package_url"
			fi

			echo "[*] Extracting '$package_name'..."
			(cd "$package_tmpdir"
				ar x package.deb

				# data.tar may have extension different from .xz
				if [ -f "./data.tar.xz" ]; then
					data_archive="data.tar.xz"
				elif [ -f "./data.tar.gz" ]; then
					data_archive="data.tar.gz"
				else
					echo "No data.tar.* found in '$package_name'."
					exit 1
				fi

				# Do same for control.tar.
				if [ -f "./control.tar.xz" ]; then
					control_archive="control.tar.xz"
				elif [ -f "./control.tar.gz" ]; then
					control_archive="control.tar.gz"
				else
					echo "No control.tar.* found in '$package_name'."
					exit 1
				fi

				# Extract files.
				tar xf "$data_archive" -C "$BOOTSTRAP_ROOTFS"

				# Register extracted files.
				tar tf "$data_archive" | sed -E -e 's@^\./@/@' -e 's@^/$@/.@' -e 's@^([^./])@/\1@' > "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/lib/dpkg/info/${package_name}.list"

				# Generate checksums (md5).
				tar xf "$data_archive"
				find data -type f -print0 | xargs -0 -r md5sum | sed 's@^\.$@@g' > "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/lib/dpkg/info/${package_name}.md5sums"

				# Extract metadata.
				tar xf "$control_archive"
				{
					cat control
					echo "Status: install ok installed"
					echo
				} >> "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/lib/dpkg/status"

				# Additional data: conffiles & scripts
				for file in conffiles postinst postrm preinst prerm; do
					if [ -f "${PWD}/${file}" ]; then
						cp "$file" "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/lib/dpkg/info/${package_name}.${file}"
					fi
				done
			)
		fi
	else
		local package_dependencies=$(read_db_packages_pac "DEPENDS" | sed 's/<.*$//g; s/>.*$//g; s/=.*$//g')

		if [ "$package_dependencies" != "null" ]; then
			local dep
			for dep in $package_dependencies; do
				if [ ! -e "${BOOTSTRAP_PKGDIR}/${dep}" ]; then
					pull_package "$dep"
				fi
			done
			unset dep
		fi

		if [ ! -e "$package_tmpdir/package.pkg.tar.xz" ]; then
			echo "[*] Downloading '$package_name'..."
			local package_filename=$(read_db_packages_pac "FILENAME")
			curl --fail --location --output "$package_tmpdir/package.pkg.tar.xz" "${REPO_BASE_URL}/${package_arch}/${package_filename}"

			echo "[*] Extracting '$package_name'..."
			(cd "$package_tmpdir"
				local package_desc="${package_name}-$(read_db_packages_pac VERSION)"
				mkdir -p "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/lib/pacman/local/${package_desc}"
				{
					echo "%FILES%"
					tar xvf package.pkg.tar.xz -C "$BOOTSTRAP_ROOTFS" .INSTALL .MTREE data 2> /dev/null | grep '^data/' || true
				} >> "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/lib/pacman/local/${package_desc}/files"
				mv "${BOOTSTRAP_ROOTFS}/.MTREE" "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/lib/pacman/local/${package_desc}/mtree"
				if [ -f "${BOOTSTRAP_ROOTFS}/.INSTALL" ]; then
					mv "${BOOTSTRAP_ROOTFS}/.INSTALL" "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/lib/pacman/local/${package_desc}/install"
				fi
				{
					local keys_desc="VERSION BASE DESC URL ARCH BUILDDATE PACKAGER ISIZE GROUPS LICENSE REPLACES DEPENDS OPTDEPENDS CONFLICTS PROVIDES"
					for i in "NAME ${package_name}" \
						"INSTALLDATE $(date +%s)" \
						"VALIDATION $(test $(read_db_packages_pac PGPSIG) != 'null' && echo 'pgp' || echo 'sha256')"; do
						print_desc_package_pac ${i}
					done
					jq -r -j '."'${package_name}'" | to_entries | .[] | select(.key | contains('$(sed 's/^/"/; s/ /","/g; s/$/"/' <<< ${keys_desc})')) | "%",(if .key == "ISIZE" then "SIZE" else .key end),"%\n",.value,"\n\n" | if type == "array" then (.| join("\n")) else . end' \
						"${PATH_DB_PACKAGES}"
				} >> "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/lib/pacman/local/${package_desc}/desc"
			)
		fi
	fi
}

# Final stage: generate bootstrap archive and place it to current
# working directory.
# Information about symlinks is stored in file SYMLINKS.txt.
create_bootstrap_archive() {
	echo "[*] Creating 'bootstrap-${1}.zip'..."
	(cd "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}"
		# Do not store symlinks in bootstrap archive.
		# Instead, put all information to SYMLINKS.txt
		while read -r -d '' link; do
			echo "$(readlink "$link")←${link}" >> SYMLINKS.txt
			rm -f "$link"
		done < <(find . -type l -print0)

		zip -r9 "${BOOTSTRAP_TMPDIR}/bootstrap-${1}.zip" ./*
	)

	mv -f "${BOOTSTRAP_TMPDIR}/bootstrap-${1}.zip" ./
	echo "[*] Finished successfully (${1})."
}

show_usage() {
	echo
	echo "Usage: generate-bootstraps.sh [options]"
	echo
	echo "Generate bootstrap archives for Termux application."
	echo
	echo "Options:"
	echo
	echo " -h, --help                  Show this help."
	echo
	echo " -a, --add PKG_LIST          Specify one or more additional packages"
	echo "                             to include into bootstrap archive."
	echo "                             Multiple packages should be passed as"
	echo "                             comma-separated list."
	echo
	echo " -b, --build                 Build packages from source instead instead"
	echo "                             of downloading them from the repository."
	echo
	echo " --pm MANAGER                Set up a package manager in bootstrap."
	echo "                             It can only be apt."
	echo
	echo " --architectures ARCH_LIST   Override default list of architectures"
	echo "                             for which bootstrap archives will be"
	echo "                             created."
	echo "                             Multiple architectures should be passed"
	echo "                             as comma-separated list."
	echo
	echo " -r, --repository URL        Specify URL for APT repository from"
	echo "                             which packages will be downloaded."
	echo "                             This must be passed after '--pm' option."
	echo
	echo "Architectures: ${TERMUX_ARCHITECTURES[*]}"
	echo "Repository Base Url: ${REPO_BASE_URL}"
	echo "Prefix: ${TERMUX_PREFIX}"
        echo "Package manager: ${TERMUX_PACKAGE_MANAGER}"
	echo
}

while (($# > 0)); do
	case "$1" in
		-h|--help)
			show_usage
			exit 0
			;;
		-a|--add)
			if [ $# -gt 1 ] && [ -n "$2" ] && [[ $2 != -* ]]; then
				for pkg in $(echo "$2" | tr ',' ' '); do
					ADDITIONAL_PACKAGES+=("$pkg")
				done
				unset pkg
				shift 1
			else
				echo "[!] Option '--add' requires an argument."
				show_usage
				exit 1
			fi
			;;
		-b|--build)
			TERMUX_BUILD_BOOTSTRAPS=true
			;;
		--pm)
			if [ $# -gt 1 ] && [ -n "$2" ] && [[ $2 != -* ]]; then
				TERMUX_PACKAGE_MANAGER="$2"
				REPO_BASE_URL="${REPO_BASE_URLS[${TERMUX_PACKAGE_MANAGER}]}"
				shift 1
			else
				echo "[!] Option '--pm' requires an argument." 1>&2
				show_usage
				exit 1
			fi
			;;
		--architectures)
			if [ $# -gt 1 ] && [ -n "$2" ] && [[ $2 != -* ]]; then
				TERMUX_ARCHITECTURES=()
				for arch in $(echo "$2" | tr ',' ' '); do
					TERMUX_ARCHITECTURES+=("$arch")
				done
				unset arch
				shift 1
			else
				echo "[!] Option '--architectures' requires an argument."
				show_usage
				exit 1
			fi
			;;
		-r|--repository)
			if [ $# -gt 1 ] && [ -n "$2" ] && [[ $2 != -* ]]; then
				REPO_BASE_URL="$2"
				shift 1
			else
				echo "[!] Option '--repository' requires an argument."
				show_usage
				exit 1
			fi
			;;
		*)
			echo "[!] Got unknown option '$1'"
			show_usage
			exit 1
			;;
	esac
	shift 1
done

if [[ "$TERMUX_PACKAGE_MANAGER" == *" "* ]] || [[ " ${TERMUX_PACKAGE_MANAGERS[*]} " != *" $TERMUX_PACKAGE_MANAGER "* ]]; then
	echo "[!] Invalid package manager '$TERMUX_PACKAGE_MANAGER'" 1>&2
	echo "Supported package managers: '${TERMUX_PACKAGE_MANAGERS[*]}'" 1>&2
	exit 1
fi

if [ -z "$REPO_BASE_URL" ]; then
	echo "[!] The repository base url is not set." 1>&2
	exit 1
fi

for package_arch in "${TERMUX_ARCHITECTURES[@]}"; do
	# Ensure newly built packages:
	if [ "$TERMUX_BUILD_BOOTSTRAPS" = true ]; then
		rm -Rf output/
	fi

	PATH_DB_PACKAGES="$BOOTSTRAP_TMPDIR/main_${package_arch}.json"
	BOOTSTRAP_ROOTFS="$BOOTSTRAP_TMPDIR/rootfs-${package_arch}"
	BOOTSTRAP_PKGDIR="$BOOTSTRAP_TMPDIR/packages-${package_arch}"

	mkdir -p "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/etc/apt/apt.conf.d"
	mkdir -p "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/etc/apt/preferences.d"
	mkdir -p "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/share/man/man1"
	mkdir -p "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/lib/dpkg/info"
	mkdir -p "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/lib/dpkg/triggers"
	mkdir -p "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/lib/dpkg/updates"
	mkdir -p "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/log/apt"
	touch "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/lib/dpkg/available"
	touch "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/lib/dpkg/status"

	# Setup nano alternative:
	mkdir -p "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/etc/alternatives/" \
		 "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/bin/" \
		 "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/lib/dpkg/alternatives/"
	ln -s "${TERMUX_PREFIX}/bin/nano" "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/etc/alternatives/editor"
	ln -s "${TERMUX_PREFIX}/etc/alternatives/editor" "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/bin/editor"
	ln -s "${TERMUX_PREFIX}/share/man/man1/nano.1.gz" "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/etc/alternatives/editor.1.gz"
	ln -s "${TERMUX_PREFIX}/etc/alternatives/editor.1.gz" "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/share/man/man1/editor.1.gz"
	cat << EOF > "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/lib/dpkg/alternatives/editor"
auto
${TERMUX_PREFIX}/bin/editor
editor.1.gz
${TERMUX_PREFIX}/share/man/man1/editor.1.gz

${TERMUX_PREFIX}/bin/nano
50
${TERMUX_PREFIX}/share/man/man1/nano.1.gz

EOF

	# Setup less alternative:
	ln -s "${TERMUX_PREFIX}/bin/less" "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/etc/alternatives/pager"
	ln -s "${TERMUX_PREFIX}/etc/alternatives/pager" "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/bin/pager"
	ln -s "${TERMUX_PREFIX}/share/man/man1/less.1.gz" "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/etc/alternatives/pager.1.gz"
	ln -s "${TERMUX_PREFIX}/etc/alternatives/pager.1.gz" "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/share/man/man1/pager.1.gz"
	cat << EOF > "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/var/lib/dpkg/alternatives/pager"
auto
${TERMUX_PREFIX}/bin/pager
pager.1.gz
${TERMUX_PREFIX}/share/man/man1/pager.1.gz

${TERMUX_PREFIX}/bin/less
50
${TERMUX_PREFIX}/share/man/man1/less.1.gz

EOF

	mkdir -p "${BOOTSTRAP_ROOTFS}/${TERMUX_PREFIX}/tmp"

	# Read package metadata.
	unset PACKAGE_METADATA
	declare -A PACKAGE_METADATA
	if [ ${TERMUX_PACKAGE_MANAGER} = "apt" ]; then
		if [ "${TERMUX_BUILD_BOOTSTRAPS}" != true ]; then
			read_package_list_deb "$package_arch"
		fi
	else
		download_db_packages_pac
	fi

	# Package manager.
	pull_package ${TERMUX_PACKAGE_MANAGER}

	# Core utilities.
	pull_package bash # Used by `termux-bootstrap-second-stage.sh`
	pull_package command-not-found
	pull_package curl
	pull_package dash
	pull_package findutils
	pull_package gawk
	pull_package procps
	pull_package psmisc
	pull_package tar
	pull_package termux-exec
	pull_package termux-tools
	pull_package util-linux

	# Additional.
	pull_package ed
	pull_package debianutils
	pull_package dos2unix
	pull_package inetutils
	pull_package nano
	pull_package net-tools
	pull_package patch
	pull_package unzip

	# Handle additional packages.
	for add_pkg in "${ADDITIONAL_PACKAGES[@]}"; do
		pull_package "$add_pkg"
	done
	unset add_pkg

	# Create bootstrap archive.
	create_bootstrap_archive "$package_arch"
done
