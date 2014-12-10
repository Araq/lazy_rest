[Package]
name          = "lazy_rest"
version       = "0.2.1"
author        = "Grzegorz Adam Hankiewicz"
description   = """Simple rst (reStructuredText) HTML generation from Nimrod or C with some extras"""
license       = "MIT"
bin = "lazy_rest_badger.exe"

installDirs = """

docs
lazy_rest_pkg
resources

"""

InstallFiles = """

LICENSE.rst
README.rst
lazy_rest.nim
lazy_rest_badger.nim
lazy_rest_badger.nimrod.cfg
lazy_rest_c_api.nim
nakefile.nim

"""

[Deps]
Requires: "nake >= 1.2,argument_parser >= 0.2, https://github.com/gradha/badger_bits.git"
