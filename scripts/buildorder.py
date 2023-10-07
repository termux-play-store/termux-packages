#!/usr/bin/env python3
"Script to generate a build order respecting package dependencies."

import json
import os
import re
import sys
from itertools import filterfalse

termux_arch = os.getenv("TERMUX_ARCH") or "aarch64"
termux_pkg_library = os.getenv("TERMUX_PACKAGE_LIBRARY") or "bionic"


def die(msg):
    "Exit the process with an error message."
    sys.exit("ERROR: " + msg)


def parse_build_file_dependencies_with_vars(path, vars):
    "Extract the dependencies specified in the given variables of a build.sh or *.subpackage.sh file."
    dependencies = []

    with open(path, encoding="utf-8") as build_script:
        for line in build_script:
            if line.startswith(vars):
                dependencies_string = line.split("DEPENDS=")[1]
                for char in "\"'\n":
                    dependencies_string = dependencies_string.replace(char, "")

                # Split also on '|' to dependencies with '|', as in 'nodejs | nodejs-current':
                for dependency_value in re.split(",|\\|", dependencies_string):
                    # Replace parenthesis to ignore version qualifiers as in "gcc (>= 5.0)":
                    dependency_value = re.sub(r"\(.*?\)", "", dependency_value).strip()
                    arch = os.getenv("TERMUX_ARCH")
                    if arch is None:
                        arch = "aarch64"
                    if arch == "x86_64":
                        arch = "x86-64"
                    dependency_value = re.sub(
                        r"\${TERMUX_ARCH/_/-}", arch, dependency_value
                    )

                    dependencies.append(dependency_value)

    return set(dependencies)


def parse_build_file_dependencies(path):
    "Extract the dependencies of a build.sh or *.subpackage.sh file."
    return parse_build_file_dependencies_with_vars(
        path,
        (
            "TERMUX_PKG_DEPENDS",
            "TERMUX_PKG_BUILD_DEPENDS",
            "TERMUX_SUBPKG_DEPENDS",
            "TERMUX_PKG_DEVPACKAGE_DEPENDS",
        ),
    )


def parse_build_file_antidependencies(path):
    "Extract the antidependencies of a build.sh file."
    return parse_build_file_dependencies_with_vars(
        path, "TERMUX_PKG_ANTI_BUILD_DEPENDS"
    )


def parse_build_file_excluded_arches(path):
    "Extract the excluded arches specified in a build.sh or *.subpackage.sh file."
    arches = []

    with open(path, encoding="utf-8") as build_script:
        for line in build_script:
            if line.startswith(
                ("TERMUX_PKG_BLACKLISTED_ARCHES", "TERMUX_SUBPKG_EXCLUDED_ARCHES")
            ):
                arches_string = line.split("ARCHES=")[1]
                for char in "\"'\n":
                    arches_string = arches_string.replace(char, "")
                for arches_value in re.split(",", arches_string):
                    arches.append(arches_value.strip())

    return set(arches)


def parse_build_file_variable_bool(path, var):
    return parse_build_file_variable_str(path, var) == "true"


def parse_build_file_variable_str(path, var):
    # File might not exists, e.g. for virtual '-static' subpackages:
    if os.path.exists(path):
        with open(path, encoding="utf-8") as build_script:
            for line in build_script:
                if line.startswith(var):
                    return line.split("=")[-1].replace("\n", "").strip('"')
    return None


class TermuxPackage(object):
    "A main package definition represented by a directory with a build.sh file."

    def __init__(self, dir_path):
        self.dir = dir_path
        self.name = os.path.basename(self.dir)

        # search package build.sh
        build_sh_path = os.path.join(self.dir, "build.sh")
        if not os.path.isfile(build_sh_path):
            raise Exception("build.sh not found for package '" + self.name + "'")

        self.deps = parse_build_file_dependencies(build_sh_path)
        self.antideps = parse_build_file_antidependencies(build_sh_path)
        self.excluded_arches = parse_build_file_excluded_arches(build_sh_path)
        self.only_installing = parse_build_file_variable_bool(
            build_sh_path, "TERMUX_PKG_ONLY_INSTALLING"
        )
        self.separate_subdeps = parse_build_file_variable_bool(
            build_sh_path, "TERMUX_PKG_SEPARATE_SUB_DEPENDS"
        )
        self.platform_independent = parse_build_file_variable_bool(
            build_sh_path, "TERMUX_PKG_PLATFORM_INDEPENDENT"
        )

        if os.getenv("TERMUX_ON_DEVICE_BUILD") == "true":
            self.deps.add("libc++")

        # search subpackages
        self.subpkgs = []

        for filename in os.listdir(self.dir):
            if not filename.endswith(".subpackage.sh"):
                continue
            subpkg = TermuxSubPackage(self.dir + "/" + filename, self)
            if termux_arch in subpkg.excluded_arches:
                continue

            self.subpkgs.append(subpkg)

        subpkg = TermuxSubPackage(
            self.dir + "/" + self.name + "-static" + ".subpackage.sh",
            self,
            virtual=True,
        )
        self.subpkgs.append(subpkg)

        self.needed_by = set()  # Populated outside constructor, reverse of deps.

    def __repr__(self):
        return "<{} '{}'>".format(self.__class__.__name__, self.name)

    def __eq__(self, other):
        return self.name == other.name

    def __hash__(self):
        return hash(self.name)

    def recursive_dependencies(self, pkgs_map, include_subpackages, result):
        "All the dependencies of the package, both direct and indirect."
        if self in result:
            return
        result.add(self)

        orig_result = result.copy()

        for dependency_name in self.deps:
            dependency_package = pkgs_map[dependency_name]
            dependency_package.recursive_dependencies(
                pkgs_map, include_subpackages, result
            )
        if include_subpackages:
            for subpkg in self.subpkgs:
                subpkg.recursive_dependencies(pkgs_map, include_subpackages, result)

        # Remove antideps:
        all_added_now = result - orig_result
        # print("PKG: " + self.name + ", added_now = " + str(all_added_now))
        for added_now in all_added_now:
            if added_now.name in self.antideps and added_now not in orig_result:
                print(
                    "Removing "
                    + added_now.name
                    + " since it was added just now but is in antideps"
                )
                result.remove(added_now)

    def toplevel_package(self):
        return self


class TermuxSubPackage:
    "A sub-package represented by a ${PACKAGE_NAME}.subpackage.sh file."

    def __init__(self, subpackage_file_path, parent, virtual=False):
        if parent is None:
            raise Exception("SubPackages should have a parent")

        self.name = os.path.basename(subpackage_file_path).split(".subpackage.sh")[0]

        self.parent = parent
        self.platform_independent = parse_build_file_variable_bool(
            subpackage_file_path, "TERMUX_SUBPKG_PLATFORM_INDEPENDENT"
        )

        self.deps = set()
        depend_on_parent = parse_build_file_variable_str(
            subpackage_file_path, "TERMUX_SUBPKG_DEPEND_ON_PARENT"
        )
        if not depend_on_parent or depend_on_parent == "unversioned":
            self.deps.add(parent.name)
        elif depend_on_parent == "deps":
            self.deps.update(self.parent.deps)
        elif depend_on_parent != "no":
            die(
                f"Subpackage {self.name} has invalid TERMUX_SUBPKG_DEPEND_ON_PARENT: '{depend_on_parent}"
            )

        self.only_installing = parent.only_installing
        self.excluded_arches = set()
        if not virtual:
            self.deps |= parse_build_file_dependencies(subpackage_file_path)
            self.excluded_arches |= parse_build_file_excluded_arches(
                subpackage_file_path
            )
        self.dir = parent.dir

        self.needed_by = set()  # Populated outside constructor, reverse of deps.

    def __repr__(self):
        return "<{} '{}' parent='{}'>".format(
            self.__class__.__name__, self.name, self.parent
        )

    def __eq__(self, other):
        return self.name == other.name

    def __hash__(self):
        return hash(self.name)

    def recursive_dependencies(self, pkgs_map, include_subpackages, result):
        """All the dependencies of the subpackage, both direct and indirect.
        Only relevant when building in fast-build mode"""
        if self in result:
            return
        result.add(self)
        for dependency_name in self.deps:
            dependency_package = pkgs_map[dependency_name]
            if dependency_package not in result:
                dependency_package.recursive_dependencies(
                    pkgs_map, include_subpackages, result
                )

    def toplevel_package(self):
        return self.parent


def read_packages_from_directories(directories):
    """Construct a map from package name to TermuxPackage."""
    pkgs_map = {}

    for package_dir in directories:
        for pkgdir_name in sorted(os.listdir(package_dir)):
            dir_path = package_dir + "/" + pkgdir_name
            if os.path.isfile(dir_path + "/build.sh"):
                new_package = TermuxPackage(package_dir + "/" + pkgdir_name)

                if termux_arch in new_package.excluded_arches:
                    continue

                if new_package.name in pkgs_map:
                    die("Duplicated package: " + new_package.name)
                else:
                    pkgs_map[new_package.name] = new_package

                for subpkg in new_package.subpkgs:
                    if termux_arch in subpkg.excluded_arches:
                        continue
                    if subpkg.name in pkgs_map:
                        die("Duplicated package: " + subpkg.name)
                    else:
                        pkgs_map[subpkg.name] = subpkg

    for _name, pkg in pkgs_map.items():
        for dependency_name in pkg.deps:
            if dependency_name not in pkgs_map:
                die(
                    f'Package {pkg.name} depends on non-existing package "{dependency_name}'
                )
            dep_pkg = pkgs_map[dependency_name]
            dep_pkg.needed_by.add(pkg)

    return pkgs_map


def generate_build_order(pkgs_map, packages_to_build):
    "Generate a package order (for building or installation) for all packages in pkgs_map."
    build_order = []

    # Tracks non-visited deps for each package
    remaining_deps = {}

    for pkg in packages_to_build:
        if isinstance(pkg, TermuxPackage):
            remaining_deps[pkg] = {
                pkgs_map[dep].toplevel_package()
                for dep in pkg.deps
                if pkgs_map[dep].toplevel_package() != pkg
            }

            for subpkg in pkg.subpkgs:
                if subpkg.name in pkg.deps and pkg.name in subpkg.deps:
                    # A circular dependency between toplevel package and sub-package.
                    # Let gtk3<->gtk-update-icon-cache circular dependency through for now:
                    if (
                        subpkg.platform_independent == pkg.platform_independent
                        and pkg.name != "gtk3"
                    ):
                        die(
                            "Found pointless split between "
                            + pkg.name
                            + " and "
                            + subpkg.name
                        )

                if not remaining_deps[subpkg.toplevel_package()]:
                    remaining_deps[subpkg.toplevel_package()] = set()
                remaining_deps[pkg] |= {
                    pkgs_map[dep].toplevel_package()
                    for dep in subpkg.deps
                    if pkgs_map[dep].toplevel_package() != pkg
                }

    # List of all TermuxPackages without dependencies
    leaf_pkgs = [pkg for pkg, deps in remaining_deps.items() if not deps]

    if not leaf_pkgs:
        die("No package without dependencies - where to start?")

    # Sort alphabetically:
    pkg_queue = sorted(leaf_pkgs, key=lambda p: p.name)

    # Topological sorting
    visited = set()

    while pkg_queue:
        pkg = pkg_queue.pop(0)

        if pkg.name in visited:
            continue

        visited.add(pkg.name)
        build_order.append(pkg)

        other_to_consider = set([p.toplevel_package() for p in pkg.needed_by])
        for subpkg in pkg.subpkgs:
            other_to_consider |= set([p.toplevel_package() for p in subpkg.needed_by])

        for other_pkg in sorted(other_to_consider, key=lambda p: p.name):
            if other_pkg not in remaining_deps:
                # Other package outside of packages to build
                continue

            # Remove this pkg from deps
            remaining_deps[other_pkg].discard(pkg)

            if not remaining_deps[other_pkg]:
                pkg_to_perhaps_build = other_pkg

                if (
                    not pkg_to_perhaps_build.name in visited
                    and not pkg_to_perhaps_build in pkg_queue
                ):
                    pkg_queue.append(pkg_to_perhaps_build)

    pkgs_remaining = [pkg for pkg, deps in remaining_deps.items() if deps]
    if pkgs_remaining:
        die(f"Cycle detected - remaining packages: {pkgs_remaining}")

    return build_order


def main():
    "Generate the build order either for all packages or a specific one."
    import argparse

    parser = argparse.ArgumentParser(
        description="Generate order in which to build dependencies for a package. Generates"
    )
    parser.add_argument(
        "-i",
        default=False,
        action="store_true",
        help="Generate dependency list for fast-build mode. This includes subpackages in output since these can be downloaded.",
    )
    parser.add_argument(
        "package", nargs="?", help="Package to generate dependency list for."
    )
    parser.add_argument(
        "package_dirs",
        nargs="*",
        help='Directories with packages. Can for example point to "../community-packages/packages". Note that the packages suffix is no longer added automatically if not present.',
    )
    args = parser.parse_args()
    installation_instead_of_building = args.i
    target_package_path = args.package

    if target_package_path:
        packages_directories = args.package_dirs
        if target_package_path[-1] == "/":
            target_package_path = target_package_path[:-1]
        if not os.path.isdir(target_package_path):
            die("Not a directory: " + target_package_path)
        if (
            not os.path.relpath(os.path.dirname(target_package_path), ".")
            in packages_directories
        ):
            packages_directories.insert(0, os.path.dirname(target_package_path))

        if target_package_path.endswith("/"):
            target_package_path = target_package_path[:-1]
        target_package_name = os.path.basename(target_package_path)
    else:
        # Build all packages
        if installation_instead_of_building:
            die("-i mode does not work when building all packages")

        with open("repo.json") as f:
            data = json.load(f)
        packages_directories = []
        for d in data.keys():
            if d != "pkg_format":
                packages_directories.append(d)
        for path in packages_directories:
            if not os.path.isdir(path):
                die("Not a directory: " + path)

    pkgs_map = read_packages_from_directories(packages_directories)

    packages_to_output = []

    if installation_instead_of_building:
        # We should only install dependencies for a certain target package
        target_package = pkgs_map[target_package_name]

        # Only build the package itself and dependencies:
        packages_to_output = set()
        target_package.recursive_dependencies(pkgs_map, False, packages_to_output)
        for subpkg in target_package.subpkgs:
            subpkg.recursive_dependencies(pkgs_map, False, packages_to_output)

        # We don't need the packages we are going to build:
        packages_to_output.remove(target_package)
        for subpkg in target_package.subpkgs:
            if subpkg in packages_to_output:
                packages_to_output.remove(subpkg)
    else:
        if target_package_path:
            target_packages = set()
            pkgs_map[target_package_name].recursive_dependencies(
                pkgs_map, True, target_packages
            )
        else:
            target_packages = [pkg for _name, pkg in pkgs_map.items()]
        packages_to_output = generate_build_order(pkgs_map, target_packages)

    for pkg in packages_to_output:
        pkg_name = pkg.name
        print("%-30s %s" % (pkg_name, pkg.dir))


if __name__ == "__main__":
    main()
