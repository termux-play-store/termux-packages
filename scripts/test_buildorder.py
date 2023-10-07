#!/usr/bin/env python3

import unittest
import tempfile
import os
import buildorder


class BuildorderTest(unittest.TestCase):
    def test_parse_build_file_dependencies(self):
        tmpdir = tempfile.mkdtemp()
        pkg_dir = f"{tmpdir}/mypackage"
        os.mkdir(pkg_dir)
        with open(f"{tmpdir}/mypackage/build.sh", "w") as f:
            f.write('TERMUX_PKG_DEPENDS="liba, libb"')
        pkg = buildorder.TermuxPackage(pkg_dir)
        self.assertEqual(pkg.name, "mypackage")
        self.assertEqual(pkg.deps, set(["liba", "libb"]))

    def test_lower(self):
        self.assertEqual("foo".upper(), "FOO")


if __name__ == "__main__":
    unittest.main()
