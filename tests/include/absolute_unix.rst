Absolute unix include
=====================

This file includes an absolute path to a typical Unix file. It might appear, or
it might fail. Let's see…

.. include:: /etc/passwd
    :literal:

What this means is that absolute paths are dangerous and if you are writing a
web server generating HTML from rst you need to sanitize include paths with a
custom file handler.
