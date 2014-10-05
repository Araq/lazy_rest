================
Lazy reST readme
================

Lazy reST is a `Nimrod <http://nimrod-lang.org>`_ module providing a slightly
higher level API over `Nimrod's rstgen module
<http://nimrod-lang.org/rstgen.html>`_ with some extras. The actual rstgen
module and friends are duplicated here, which allows to use the stable Nimrod
compiler version with the latest features. Some additional features are
provided with regards to Nimrod's standard library version, like embedding of
`Prism <http://prismjs.com>`_ for code block syntax highlighting.

Unlike Nimrod's standard library, this module doesn't aim to support LaTeX
generation at all. The included LaTeX bits are inherited and not maintained.
Which doesn't mean patches aren't welcome, but you may have more success
sending them `upstream to Nimrod <https://github.com/Araq/Nimrod>`_ instead of
here.


Changes
=======

This is development version 0.1.0. For a list of changes see the
`docs/changes.rst <docs/changes.rst>`_ file.


License
=======

`MIT license <LICENSE.rst>`_.


Usage
=====

If you are a Nimrod programmer read the `Nimrod usage guide
<docs/nimrod_usage.rst>`_ which includes installation steps.

Information on how errors are handled is available in the separate `Lazy reST
error handling <docs/error_handling.rst>`_ document.

All documentation should be available online at
http://gradha.github.io/lazy_rest/.


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
