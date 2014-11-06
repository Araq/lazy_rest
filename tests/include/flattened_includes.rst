Flattened include test
======================

This file includes other rst files from the same directory but it does so using
weird relative pathnames. The ``test_include.nim`` example will use a custom
flattening find file proc which uses just the base filename. This means that
the HTML generated through ``test_include.nim`` will look good, but this file
processed with any other generic rst parser will fail the includes.

.. include:: weird/path/recursion_base.rst
    :literal:

.. include:: /another/weird/path/simple_include_02.rst
    :literal:

Did it work?
