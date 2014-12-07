=======================
Lazy reST C usage guide
=======================

.. |rst| replace:: reStructuredText

This is the C usage guide for `Lazy reSt
<https://github.com/gradha/lazy_rest>`_.


Installation
============

Development version from Nimrod source
--------------------------------------

The C API for Lazy reST is distributed actually as a Nimrod source file (see
`the lazy_rest_c_api.nim file <../lazy_rest_c_api.nim>`_ which you are meant to
compile with Nimrod using the `--header command line switch
<http://nimrod-lang.org/backends.html#backend-code-calling-nimrod>`_ to produce
``.c`` files along with a usable ``.h`` header.

What this means is that you need a working Nimrod compiler and follow the
`Nimrod installation steps <nimrod_usage.rst>`_ before doing anything else.

Once you have the Nimrod compiler and source (or Nimble package) installed, you
can either compile the ``lazy_rest_c_api.nim`` file with the ``--header``
option (plus any other useful switches, e.g. ``--noMain`` and
``--compileOnly``) or create a dummy nimrod source file and use that to
compile. Usage example::

    $ echo "import lazy_rest_c_api " > dummy.nim
    $ nimrod --header --noMain --compileOnly \
        -d:release --nimcache:out_dir c dummy.nim
    $ cat out_dir/dummy.h
    # Add generated sources to your project.


Pre built C source packages
---------------------------

Stable releases provide pre built C source zip files which you can download
from https://github.com/gradha/lazy_rest/releases. These contain the C sources
you would normally generate yourself for your platform. Using these avoids all
the hassle of installing/compiling Nimrod code.


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
``master`` git development branch. The pre built C source packages contain a
``documentation`` directory with all the HTML documentation.


Practical example
=================

In the ``tests/c_api`` subdirectory (`see at GitHub
<https://github.com/gradha/lazy_rest/tree/master/tests/c_api>`_) you can find a
`test_c_api.nim wrapper <../tests/c_api/test_c_api.nim>`_ around a `c_test.c
<../tests/c_api/c_test.c>`_ file which makes use of the C API.

However, the most simple C example you can build is the following:

.. code:: c
    :number-lines:

    #include "lazy_rest_c_api.h"

    int main(void)
    {
        NimMain();
        printf("%s\n",
            lr_safe_rst_file_to_html("README.rst", 0, 0));
        return 0;
    }

Presuming that this C source is saved into a ``test.c`` file in the directory
where you unpack the pre built C sources, you could compile it like this with
GCC::

    $ gcc -o test *.c

Note that unlike the test suite example which uses an embedded C file, a
standalone C program is required to call ``NimMain()`` (line 5) once before any
other API function. The ``NimMain()`` function initialises Nimrod's garbage
collection and other internal values.  Since the garbage collection is tied to
the stack, you can't call any API code from a thread different than the one you
called ``NimMain()``.
