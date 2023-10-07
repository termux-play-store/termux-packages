#!/usr/bin/env python3

import unittest
import tempfile
import os
import buildorder


def setup_test_packages():
    tmpdir = tempfile.mkdtemp()

    pkg_dir = f"{tmpdir}/firstpackage"
    os.mkdir(pkg_dir)
    with open(f"{tmpdir}/firstpackage/build.sh", "w") as f:
        f.write('TERMUX_PKG_DEPENDS="liba, libb"')

    return tmpdir


class BuildorderTest(unittest.TestCase):
    def test_parse_build_file_dependencies(self):
        tmpdir = setup_test_packages()
        pkg = buildorder.TermuxPackage(f"{tmpdir}/firstpackage")
        self.assertEqual(pkg.name, "firstpackage")
        self.assertEqual(pkg.deps, set(["liba", "libb"]))

    def test_lower(self):
        self.assertEqual("foo".upper(), "FOO")


if __name__ == "__main__":
    unittest.main()
