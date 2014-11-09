## Submodule containing configuration constants used elsewhere.

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
  ## render. This skeleton has to contain the ``$content`` string.
