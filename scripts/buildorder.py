#!/usr/bin/env python3
"Script to generate a build order respecting package dependencies."

import json, os, re, sys

from itertools import filterfalse

from typing import Set

termux_arch = os.getenv('TERMUX_ARCH') or 'aarch64'

def unique_everseen(iterable, key=None):
    """List unique elements, preserving order. Remember all elements ever seen.
    See https://docs.python.org/3/library/itertools.html#itertools-recipes
    Examples:
    unique_everseen('AAAABBBCCDAABBB') --> A B C D
    unique_everseen('ABBCcAD', str.lower) --> A B C D"""
    seen = set()
    seen_add = seen.add
    if key is None:
        for element in filterfalse(seen.__contains__, iterable):
            seen_add(element)
            yield element
    else:
        for element in iterable:
            k = key(element)
            if k not in seen:
                seen_add(k)
                yield element

def die(msg):
    "Exit the process with an error message."
    sys.exit('ERROR: ' + msg)

def parse_build_file_dependencies_with_vars(path, vars, parent_pkg=None):
    "Extract the dependencies specified in the given variables of a build.sh or *.subpackage.sh file."
    dependencies = []

    subpkg_depend_on_parent = None

    with open(path, encoding="utf-8") as build_script:
        for line in build_script:
            if line.startswith('TERMUX_SUBPKG_DEPEND_ON_PARENT='):
                subpkg_depend_on_parent = line[len('TERMUX_SUBPKG_DEPEND_ON_PARENT='):].strip()
            if line.startswith(vars):
                dependencies_string = line.split('DEPENDS=')[1]
                for char in "\"'\n":
                    dependencies_string = dependencies_string.replace(char, '')

                # Split also on '|' to dependencies with '|', as in 'nodejs | nodejs-current':
                for dependency_value in re.split(',|\\|', dependencies_string):
                    # Replace parenthesis to ignore version qualifiers as in "gcc (>= 5.0)":
                    dependency_value = re.sub(r'\(.*?\)', '', dependency_value).strip()
                    arch = os.getenv('TERMUX_ARCH')
                    if arch is None:
                        arch = 'aarch64'
                    if arch == "x86_64":
                        arch = "x86-64"
                    dependency_value = re.sub(r'\${TERMUX_ARCH/_/-}', arch, dependency_value)

                    dependencies.append(dependency_value)

    is_subpackage = 'subpackage.sh' in path
    if is_subpackage:
        if subpkg_depend_on_parent == 'no' or subpkg_depend_on_parent == '"no"':
            pass
        elif subpkg_depend_on_parent == 'deps':
            assert parent_pkg
            for dep in parent_pkg.deps:
                if not dep in dependencies:
                    dependencies.append(dep)
        else:
            package_name = os.path.basename(os.path.dirname(path))
            # print(f"Adding parent {package_name} to " + path)
            if not package_name in dependencies:
                dependencies.append(package_name)

    return set(dependencies)

def parse_build_file_dependencies(path, parent_pkg=None):
    "Extract the dependencies of a build.sh or *.subpackage.sh file."
    return parse_build_file_dependencies_with_vars(path, ('TERMUX_PKG_DEPENDS', 'TERMUX_PKG_BUILD_DEPENDS', 'TERMUX_SUBPKG_DEPENDS', 'TERMUX_PKG_DEVPACKAGE_DEPENDS'), parent_pkg=parent_pkg)

def parse_build_file_antidependencies(path):
    "Extract the antidependencies of a build.sh file."
    return parse_build_file_dependencies_with_vars(path, 'TERMUX_PKG_ANTI_BUILD_DEPENDS')

def parse_build_file_excluded_arches(path):
    "Extract the excluded arches specified in a build.sh or *.subpackage.sh file."
    arches = []

    with open(path, encoding="utf-8") as build_script:
        for line in build_script:
            if line.startswith(('TERMUX_PKG_EXCLUDED_ARCHES', 'TERMUX_SUBPKG_EXCLUDED_ARCHES')):
                arches_string = line.split('ARCHES=')[1]
                for char in "\"'\n":
                    arches_string = arches_string.replace(char, '')
                for arches_value in re.split(',', arches_string):
                    arches.append(arches_value.strip())

    return set(arches)

def parse_build_file_variable_bool(path, var):
    value = 'false'

    with open(path, encoding="utf-8") as build_script:
        for line in build_script:
            if line.startswith(var):
                value = line.split('=')[-1].replace('\n', '')
                break

    return value == 'true'

class TermuxPackage(object):
    deps: Set[str]
    # subpkgs: [TermuxSubPackage]

    "A main package definition represented by a directory with a build.sh file."
    def __init__(self, dir_path):
        self.dir = dir_path
        self.name = os.path.basename(self.dir)
        self.pkgs_cache = []

        # search package build.sh
        build_sh_path = os.path.join(self.dir, 'build.sh')
        if not os.path.isfile(build_sh_path):
            raise Exception("build.sh not found for package '" + self.name + "'")

        self.deps = parse_build_file_dependencies(build_sh_path)
        self.antideps = parse_build_file_antidependencies(build_sh_path)
        self.excluded_arches = parse_build_file_excluded_arches(build_sh_path)

        if os.getenv('TERMUX_ON_DEVICE_BUILD') == "true":
            always_deps = ['libc++']
            for dependency_name in always_deps:
                if dependency_name not in self.deps and self.name not in always_deps:
                    self.deps.add(dependency_name)

        # search subpackages
        self.subpkgs = []
        for filename in os.listdir(self.dir):
            if not filename.endswith('.subpackage.sh'):
                continue
            subpkg = TermuxSubPackage(self.dir + '/' + filename, self)
            if termux_arch in subpkg.excluded_arches:
                continue

            self.subpkgs.append(subpkg)

        subpkg = TermuxSubPackage(self.dir + '/' + self.name + '-static' + '.subpackage.sh', self, virtual=True)
        self.subpkgs.append(subpkg)

        self.needed_by = set()  # Populated outside constructor, reverse of deps.

    def __repr__(self):
        return "<{} '{}'>".format(self.__class__.__name__, self.name)

    def recursive_dependencies(self, pkgs_map, is_root=False):
        "All the dependencies of the package, both direct and indirect."
        result = []

        for subpkg in self.subpkgs:
            if f"{self.name}-static" != subpkg.name:
                # self.deps.add(subpkg.name)
                self.deps |= subpkg.deps

        self.deps -= self.antideps
        self.deps.discard(self.name)

        if is_root:
            # XXX: Do what buildorder.py effectively does in termux/termux-packages:
            for dep_name in list(self.deps):
                dep_pkg = pkgs_map[dep_name]
                if isinstance(dep_pkg, TermuxPackage):
                    for dep_subpkg in dep_pkg.subpkgs:
                        if not dep_subpkg.name.endswith('-static'):
                            self.deps.add(dep_subpkg.name)

        for dependency_name in sorted(self.deps):
            if dependency_name not in self.pkgs_cache:
                self.pkgs_cache.append(dependency_name)
                dependency_package = pkgs_map[dependency_name]
                result += [dependency_package]
                result += dependency_package.recursive_dependencies(pkgs_map)

        return unique_everseen(result)

class TermuxSubPackage:
    "A sub-package represented by a ${PACKAGE_NAME}.subpackage.sh file."
    def __init__(self, subpackage_file_path, parent, virtual=False):
        if parent is None:
            raise Exception("SubPackages should have a parent")

        self.name = os.path.basename(subpackage_file_path).split('.subpackage.sh')[0]
        self.parent = parent
        self.deps = set([parent.name]) if virtual else set()
        self.excluded_arches = set()
        if not virtual:
            self.deps |= parse_build_file_dependencies(subpackage_file_path, parent_pkg=parent)
            self.excluded_arches |= parse_build_file_excluded_arches(subpackage_file_path)
        self.dir = parent.dir

        self.needed_by = set()  # Populated outside constructor, reverse of deps.

    def __repr__(self):
        return "<{} '{}' parent='{}'>".format(self.__class__.__name__, self.name, self.parent)

    def recursive_dependencies(self, pkgs_map):
        """All the dependencies of the subpackage, both direct and indirect.
        Only relevant when building in fast-build mode"""
        result = []
        for dependency_name in sorted(self.deps):
            if dependency_name == self.parent.name:
                self.parent.deps.discard(self.name)
            dependency_package = pkgs_map[dependency_name]
            if dependency_package not in self.parent.subpkgs:
                result += dependency_package.recursive_dependencies(pkgs_map)
            result += [dependency_package]
        return unique_everseen(result)

def read_packages_from_directories(directories, full_buildmode):
    """Construct a map from package name to TermuxPackage."""
    pkgs_map = {}
    all_packages = []
    subpkg_name_to_parent_package: dict[str, TermuxPackage] = {}

    if full_buildmode:
        # Ignore directories and get all folders from repo.json file
        with open ('repo.json') as f:
            data = json.load(f)
        directories = []
        # for d in data.keys():
            # if d != "pkg_format":
                # directories.append(d)
        directories.append('packages')

    for package_dir in directories:
        for pkgdir_name in sorted(os.listdir(package_dir)):
            dir_path = package_dir + '/' + pkgdir_name
            if os.path.isfile(dir_path + '/build.sh'):
                new_package = TermuxPackage(package_dir + '/' + pkgdir_name)

                if termux_arch in new_package.excluded_arches:
                    continue

                if new_package.name in pkgs_map:
                    die('Duplicated package: ' + new_package.name)
                else:
                    pkgs_map[new_package.name] = new_package
                all_packages.append(new_package)

                for subpkg in new_package.subpkgs:
                    if termux_arch in subpkg.excluded_arches:
                        continue

                    if subpkg.name in pkgs_map:
                        die('Duplicated package: ' + subpkg.name)

                    if full_buildmode:
                        # When determining full build order subpackages are not relevant
                        # as they cannot be built. Instead add dependencies of subpackages.
                        subpkg_name_to_parent_package[subpkg.name] = new_package
                        for dep in subpkg.deps:
                            if dep != new_package.name:
                                new_package.deps.add(dep)
                    else:
                        all_packages.append(subpkg)
                        pkgs_map[subpkg.name] = subpkg

    for pkg in all_packages:
        for dependency_name in pkg.deps.copy():
            dep_pkg = None
            if full_buildmode:
                dep_parent_package = subpkg_name_to_parent_package.get(dependency_name)
                if dep_parent_package:
                    # This is a subpackage - do not depend on it:
                    pkg.deps.remove(dependency_name)
                    # Instead depend on parent package (if this is not the current package):
                    if dep_parent_package != pkg:
                        pkg.deps.add(dep_parent_package.name)
                    dep_pkg = dep_parent_package

            if not dep_pkg:
                if dependency_name not in pkgs_map:
                    die('Package %s depends on non-existing package "%s"' % (pkg.name, dependency_name))

                dep_pkg = pkgs_map[dependency_name]

            if dep_pkg != pkg:
                dep_pkg.needed_by.add(pkg)
    return pkgs_map

def generate_full_buildorder(pkgs_map):
    "Generate a build order for building all packages."
    build_order = []

    # Without subpackages removed:
    full_pkgs_map = pkgs_map.copy()

    # Merge all subpackages into parents - for generating build order
    # subpackages are not relevant, as they cannot be built in isolation.
    for _, pkg in full_pkgs_map.items():
        if isinstance(pkg, TermuxSubPackage):
            # pkg is readline
            for needed_by_pkg in pkg.needed_by:
                # needed_by = cmake-gui (depends on ncurses-ui-libs)
                # mark ncurses as needed cmake-gui
                if isinstance(needed_by_pkg, TermuxSubPackage):
                    pkg.parent.needed_by.add(needed_by_pkg.parent)
                else:
                    pkg.parent.needed_by.add(needed_by_pkg)
                needed_by_pkg.deps.remove(pkg.name)
                needed_by_pkg.deps.add(pkg.parent.name)

            del pkgs_map[pkg.name]
            # print("Removing subpackage: " + pkg.name + ", deps = " + str(pkg.deps) + ", parent = " + pkg.parent.name, file=sys.stderr)
            pkg.parent.deps |= pkg.deps
            # Avoid parent package depending on itself:
            if pkg.parent.name in pkg.parent.deps:
                pkg.parent.deps.remove(pkg.parent.name)
    # Remove dependencies from parent package to own subpackage:
    for _, pkg in pkgs_map.items():
        for dep in pkg.deps.copy():
            dep_pkg = full_pkgs_map[dep]
            if isinstance(dep_pkg, TermuxSubPackage) and dep_pkg.parent == dep:
                del pkg.deps[dep]

    # List of all TermuxPackages without dependencies
    leaf_pkgs = [pkg for pkg in pkgs_map.values() if not pkg.deps]

    if not leaf_pkgs:
        for pkg in pkgs_map.values():
            print(pkg.name + " -> " + str(pkg.deps), file=sys.stderr)
        die('No package without dependencies - where to start?')

    # Sort alphabetically:
    pkg_queue = sorted(leaf_pkgs, key=lambda p: p.name)

    # Topological sorting
    visited = set()

    # Tracks non-visited deps for each package
    remaining_deps = {}
    for name, pkg in pkgs_map.items():
        remaining_deps[name] = set(pkg.deps)
        if isinstance(pkg, TermuxPackage):
            for subpkg in pkg.subpkgs:
                remaining_deps[subpkg.name] = set(subpkg.deps)

    while pkg_queue:
        pkg = pkg_queue.pop(0)
        if pkg.name in visited:
            continue

        visited.add(pkg.name)
        build_order.append(pkg)

        for other_pkg in sorted(pkg.needed_by, key=lambda p: p.name):
            # Remove this pkg from deps
            remaining_deps[other_pkg.name].discard(pkg.name)

            if isinstance(pkg, TermuxPackage):
                # ... and all its subpackages
                remaining_deps[other_pkg.name].difference_update(
                    [subpkg.name for subpkg in pkg.subpkgs]
                )

            if not remaining_deps[other_pkg.name]:  # all deps were already appended?
                pkg_queue.append(other_pkg)  # should be processed

    if set(pkgs_map.values()) != set(build_order):
        print("ERROR: Cycle exists. Remaining: ", file=sys.stderr)
        for name, pkg in pkgs_map.items():
            if pkg not in build_order:
                print(name, remaining_deps[name], file=sys.stderr)

        # Print cycles so we have some idea where to start fixing this.
        def find_cycles(deps, pkg, path):
            """Yield every dependency path containing a cycle."""
            if pkg in path:
                yield path + [pkg]
            else:
                for dep in deps[pkg]:
                    yield from find_cycles(deps, dep, path + [pkg])

        cycles = set()
        for pkg in remaining_deps:
            for path_with_cycle in find_cycles(remaining_deps, pkg, []):
                # Cut the path down to just the cycle.
                cycle_start = path_with_cycle.index(path_with_cycle[-1])
                cycles.add(tuple(path_with_cycle[cycle_start:]))
        for cycle in sorted(cycles):
            print(f"cycle: {' -> '.join(cycle)}", file=sys.stderr)

        sys.exit(1)

    return build_order

def generate_target_buildorder(target_path, pkgs_map):
    "Generate a build order for building the dependencies of the specified package."
    if target_path.endswith('/'):
        target_path = target_path[:-1]

    package_name = os.path.basename(target_path)
    package = pkgs_map[package_name]
    # Do not depend on any sub package
    package.deps.difference_update([subpkg.name for subpkg in package.subpkgs])
    return package.recursive_dependencies(pkgs_map, is_root=True)

def main():
    "Generate the build order either for all packages or a specific one."
    import argparse

    parser = argparse.ArgumentParser(description='Generate order in which to build dependencies for a package. Generates')
    parser.add_argument('package', nargs='?',
                        help='Package to generate dependency list for.')
    parser.add_argument('package_dirs', nargs='*',
                        help='Directories with packages. Can for example point to "../community-packages/packages". Note that the packages suffix is no longer added automatically if not present.')
    args = parser.parse_args()
    package = args.package
    packages_directories = args.package_dirs

    if not package:
        full_buildorder = True
    else:
        full_buildorder = False

    if not full_buildorder:
        for path in packages_directories:
            if not os.path.isdir(path):
                die('Not a directory: ' + path)

    if package:
        if package[-1] == "/":
            package = package[:-1]
        if not os.path.isdir(package):
            die('Not a directory: ' + package)
        if not os.path.relpath(os.path.dirname(package), '.') in packages_directories:
            packages_directories.insert(0, os.path.dirname(package))
    pkgs_map = read_packages_from_directories(packages_directories, full_buildorder)

    if full_buildorder:
        build_order = generate_full_buildorder(pkgs_map)
    else:
        build_order = generate_target_buildorder(package, pkgs_map)

    for pkg in build_order:
        pkg_name = pkg.name
        print("%-30s %s" % (pkg_name, pkg.dir))

if __name__ == '__main__':
    main()
