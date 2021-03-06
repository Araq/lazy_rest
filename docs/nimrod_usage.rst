============================
Lazy reST Nimrod usage guide
============================

.. |rst| replace:: reStructuredText

This is the Nimrod usage guide for `Lazy reSt
<https://github.com/gradha/lazy_rest>`_.  See the `README <../README.rst>`_.


Installation
============

Development version
-------------------

Install the `Nimrod compiler <http://nimrod-lang.org>`_. Then use `Nimrod's
Nimble package manager <https://github.com/nim-lang/nimble>`_ to install
locally the GitHub checkout::

    $ nimble update
    $ git clone https://github.com/gradha/lazy_rest.git
    $ cd lazy_rest
    $ nimble install -y

If you don't mind downloading the git repository every time, you can also tell
Nimble to install the latest development version directly from git::

    $ nimble update
    $ nimble install -y lazy_rest@#head

Stable version
--------------

Install the `Nimrod compiler <http://nimrod-lang.org>`_. Then use `Nimrod's
Nimble package manager <https://github.com/nim-lang/nimble>`_ to install
the latest stable package::

    $ nimble update
    $ nimble install lazy_rest


Documentation
=============

Documentation comes as `embedded docstrings <../lazy_rest.html>`_ in the
`lazy_rest.nim file <../lazy_rest.nim>`_. If you have `nake
<https://github.com/fowlmouth/nake>`_ installed, you can run the following
command to build all the |rst| files into HTML and the ``lazy_rest.nim`` module
into HTML::

    $ nake doc

This is essentially a wrapper around ``nimrod doc lazy_rest.nim``. You can also
read the pre generated HTML documentation at http://gradha.github.io/lazy_rest/
for all released versions and the current ``master`` git development branch.
Here is a minimal Nimrod usage example:

.. code:: Nimrod
    :number-lines:

    import lazy_rest, os
    
    proc test() =
      let
        src = "readme.rst"
        dest = src.change_file_ext(".html")
      dest.write_file(safe_rst_file_to_html(src))

    when isMainModule: test()


Extensions
==========

If you are rendering a |rst| file which contains a code block, and the code
block specifies a syntax highlight language not supported by `Nimrod's highlite
module <http://nimrod-lang.org/highlite.html>`_, then `Prism
<http://prismjs.com>`_ will be embedded in an attempt to prettify the code
block.

The footer of the generated files includes JavaScript code which updates a
relative timer to the last modification time of the rendered file, which might
be easier to parse than the default full date.
