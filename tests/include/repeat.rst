Repeated include tests
----------------------

This test verifies that multiple include directives can be used with the same
parameters repeatedly and these won't *pollute* the *seen* cache.

One
-----

.. include:: simple_include_01.rst

Two
-----

.. include:: simple_include_01.rst

Three
-----

.. include:: simple_include_01.rst
