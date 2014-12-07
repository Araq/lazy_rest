=======================
Lazy reST C usage guide
=======================

.. |rst| replace:: reStructuredText

This is the C usage guide for `Lazy reSt
<https://github.com/gradha/lazy_rest>`_.


Installation
============

The C API for Lazy reST is distributed actually as a Nimrod source file (see
`the lazy_rest_c_api.nim file <../lazy_rest_c_api.nim>`_ which you are meant to
compile with Nimrod using the `--header command line switch
<http://nimrod-lang.org/backends.html#backend-code-calling-nimrod>`_ to produce
``.c`` files along with a usable ``.h`` header.

What this means is that you need a working Nimrod compiler and follow the
`Nimrod installation steps <nimrod_usage.rst>`_ before doing anything else.

Once you have the Nimrod compiler and source (or Babel package) installed, you
can either compile the ``lazy_rest_c_api.nim`` file with the ``--header``
option (plus any other useful switches, e.g. ``--noMain`` and
``--compileOnly``) or create a dummy nimrod source file and use that to
compile. Usage example::

    $ echo "import lazy_rest_c_api " > dummy.nim
    $ nimrod --header --noMain --compileOnly \
        -d:release --nimcache:out_dir c dummy.nim
    $ cat out_dir/dummy.h
    # Add generated sources to your project.



Documentation
=============

Documentation comes as `embedded docstrings <../lazy_rest_c_api.html>`_ in the
`lazy_rest_c_api.nim file <../lazy_rest_c_api.nim>`_. If you have `nake
<https://github.com/fowlmouth/nake>`_ installed, you can run the following
command to build all the |rst| files into HTML and the ``lazy_rest_c_api.nim``
module into HTML::

    $ nake doc

This is essentially a wrapper around ``nimrod doc lazy_rest_c_api.nim``. You
can also read the pre generated HTML documentation at
http://gradha.github.io/lazy_rest/ for all released versions and the current
``master`` git development branch.


Practical example
=================

In the ``tests/c_api`` subdirectory you can find a `test_c_api.nim wrapper
<../tests/c_api/test_c_api.nim>`_ around a `c_test.c
<../tests/c_api/c_test.c>`_ file which makes use of the C API. That plus the
public API documentation should be enough.
