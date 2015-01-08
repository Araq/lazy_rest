============================
Lazy reST badger usage guide
============================

.. |rst| replace:: reStructuredText

This is the usage guide for the ``lazy_rest_badger.exe`` tool of `Lazy reSt
<https://github.com/gradha/lazy_rest>`_.  This tool demonstrates usage of the
``lazy_rest`` module and provides a convenient and easy to install program
which transforms |rst| files into HTML.  You can get this program compiling it
yourself from source or downloading binaries from GitHub.


Installation
============

Binaries
--------

Precompiled binaries for some platforms are provided through `GitHub releases
<https://github.com/gradha/lazy_rest/releases>`_. The binaries are statically
linked, so you can in theory put them anywhere on your system and have them
work fine.


Usage
=====

Lazy rest badger runs on files you specify explicitly on the command line or
recursively through a specific directory. It can also run in *filter* mode
reading input from standard input and piping results to standard output.


Switches
--------

Typical usage can be figured out using the ``--help`` switch. These are the
available switches:

-h, --help                              Displays command line help and exits.
-v, --version                           Displays the current version and exists.
-e, --extensions STRING                 Colon separated list of extensions to
    process, 'rst' by default. If you store |rst| content in files with
    ``.txt`` extension, or both, you could for instance pass the string
    ``txt:rst`` so that both kinds of files are scanned.
-r, --recursive-dir STRING              Specifies a directory to be processed
    recursively.  This directory will be searched for files ending in the
    extensions specified by ``--extensions``.
-o, --output STRING                     When a single file is the input, sets
    its output filename.  If you don't specify this option the generated
    filename will be the same as the source but with the extension changed to
    ``.html``. Files are always overwritten without remorse.
-s, --safe                              Always generate a *safe* HTML
    output, even if input is bad. By default *unsafe* rendering is used, which
    means that any error during parsing will throw an exception and execution
    will stop. However in safe mode you still get some HTML which attempts to
    display the contents of the |rst| file being rendered along with some
    information about the error.
-O, --parser-option-file STRING         Specifies a file from which to read
    lazy_rest options. Option files can contain many different parser and
    render tweaks (some of which are accessed as switches), but you will most
    likely use this to customize the output HTML template. For an example of
    option file go look at
    https://github.com/gradha/lazy_rest/blob/master/resources/embedded_nimdoc.cfg.
    The `Lazy reST error handling document <error_handling.rst>`_ (`see online
    <http://gradha.github.io/lazy_rest/gh_docs/master/docs/error_handling.html>`_)
    has some information on the replacement keys you can use in the template
    (both the success and failure versions).
-R, --parser-raw-directive              Allows raw directives to be processed.
    By default these are ignored since they allow you to bypass all HTML
    escaping safeties.
-S, --parser-enable-smilies             Transforms text smilies into images.
    Enabling this will transform several patterns (like ``:-D``) found in plain
    text with image references.
-F, --parser-fenced-blocks              Allows triple quote fenced blocks,
    typical of GitHub.  Fenced blocks consist of three backticks ``(`)`` and
    optionally a language syntax option to initiate a source code block without
    indentation.
-P, --parser-skip-pounds                Ignores the initial pound symbol of
    input lines.  When activated, lines starting with a single or double hash
    (``#`` or ``##``) will be treated as if the hash was not present. Note that
    the rest of the line **won't** be ignored.  This means that your typical
    Nimrod comment block will be rendered as an indented text, because the hash
    pound will be ignored, and usually you separate the text from the hashes
    with a space, which will then be interpreted as rst indentation.


Examples
--------

You want to convert all the files with the ``.txt`` extension in the current
subdirectory and don't want to recurse. These files use the |rst| raw
directive and you want to allow it::

    $ lazy_rest_badger.exe *.txt -R

You want to convert all the files in a specific directory with the ``.text``
extension recursively but not those with the extension ``.rst``. The files may
contain errors, but you would prefer if all the files generated some HTML
output at least::

    $ lazy_rest_badger.exe -r ../some/path/ -e text --safe

You have a program generating |rst| output and you would like to pipe it
through ``lazy_rest_badger.exe``, then redirect it somewhere else::

    $ foo | lazy_rest_badger.exe STDIN | bar > result.html

Remember that in all cases ``lazy_rest_badger.exe`` will overwrite the
destination file.
