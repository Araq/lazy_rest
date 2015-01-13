================
Lazy reST readme
================

Lazy reST is a `Nimrod <http://nimrod-lang.org>`_ module providing a spin-off
higher level API over `Nimrod's rstgen module
<http://nimrod-lang.org/rstgen.html>`_. The main reasons for this spin-off are:

* Incompatible, but easier and safer to use API.
* Explicit C API support for embedding.
* Embeds `Prism <http://prismjs.com>`_ for code syntax highlighting of more
  languages.
* Drops explicit support for `LaTeX <http://latex-project.org>`_.
* All the latest features supported on the latest stable Nimrod compiler.

On top of the library code, the ``lazy_rest_badger.exe`` program shows how to
use the library and provides a simple practical rst to html command line tool.


Changes
=======

This is development version 0.2.3. For a list of changes see the
`docs/changes.rst <docs/changes.rst>`_ file.


License
=======

`MIT license <LICENSE.rst>`_.


Usage
=====

If you are a Nimrod programmer read the `Nimrod usage guide
<docs/nimrod_usage.rst>`_ which includes installation steps. C programmers can
read the `C usage guide <docs/c_usage.rst>`_ which unfortunately requires you
to read the Nimrod version too anyway.

Information on how errors are handled is available in the separate `Lazy reST
error handling <docs/error_handling.rst>`_ document.

All documentation should be available online at
http://gradha.github.io/lazy_rest/.

The ``lazy_rest_badger.exe`` binary has its own manual in
`docs/lazy_rest_badger_usage.rst <docs/lazy_rest_badger_usage.rst>`_, but
running the program with the ``--help`` switch should show enough help to get
you going.


Git branches
============

This project uses the `git-flow branching model
<https://github.com/nvie/gitflow>`_ with reversed defaults. Stable releases are
tracked in the ``stable`` branch. Development happens in the default ``master``
branch.


Feedback
========

You can send me feedback through `github's issue tracker
<https://github.com/gradha/lazy_rest/issues>`_. I also take a look
from time to time to `Nimrod's forums <http://forum.nimrod-lang.org>`_ where
you can talk to other nimrod programmers.
