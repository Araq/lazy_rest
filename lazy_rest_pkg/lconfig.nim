## `lazy_rest <https://github.com/gradha/lazy_rest>`_ submodule containing
## configuration constants used elsewhere.
##
## The constants with the ``lrc_`` prefix stand for lazy_rest configuration
## keys. These keys are used for the `PStringTable
## <http://nimrod-lang.org/strtabs.html#PStringTable>`_ types passed in the
## API.

type
  TRstParseOption* = enum     ## Options for the internal RST parser \
    ##
    ## These options are used as quick lookup enums while processing RST files,
    ## usually you will set values in the… TODO.
    ##
    roSkipPounds, ## \
    ## skip ``#`` at line beginning (documentation embedded in Nimrod comments)
    roSupportSmilies, ## make the RST parser support smilies like ``:)``
    roSupportRawDirective, ## \
    ## support the ``raw`` directive (don't support it for sandboxing)
    roSupportMarkdown ## support markdown triple quote fenced blocks

  TRstParseOptions* = set[TRstParseOption]

const
  lrc_doc_file* = "doc.file" ## \
  ## Key used to access the PStringTable storing the skeleton of the HTML rest
  ## render. This skeleton has to contain the ``$content`` string at least.
  lrc_split_item_toc* = "split.item_toc" ## \
  ## Key used to tweak the number of characters a table of content entry can
  ## have nefore being split. The splitting prevents the TOC from growing too
  ## wide and obscuring the main text. The default value is 20.
