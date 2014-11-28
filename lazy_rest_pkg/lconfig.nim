## `lazy_rest <https://github.com/gradha/lazy_rest>`_ submodule containing
## configuration constants used elsewhere.
##
## The constants with the ``lrc_`` prefix stand for lazy_rest configuration
## keys. These keys are used for the `PStringTable
## <http://nimrod-lang.org/strtabs.html#PStringTable>`_ types passed in the
## API.
##
## The constants with the ``lrk_`` prefix stand for lazy_rest render key
## substitution. They are the strings that you can use inside your
## `lrc_render_template <#lrc_render_template>`_ to specify different
## parametrized values.
##
## The constants with the ``lrd_`` prefix stand for lazy_rest default values,
## and are usually returned by `lrstgen.defaultConfig()
## <lrstgen.html#defaultConfig>`_.


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
  lrc_render_template* = "render.template" ## \
  ## Key used to access the PStringTable storing the skeleton of the HTML rest
  ## render. This skeleton has to contain the `lrk_render_content
  ## <#lrk_render_content>`_ `substitution expression
  ## <http://nimrod-lang.org/subexes.html>`_ at least, but of course you can
  ## use more.

  lrc_render_date_format* = "render.date.format" ## \
  ## Key used to access the render GMT date format. See `times.format()
  ## <http://nimrod-lang.org/times.html#format>`_ for a list of valid format
  ## specifiers.

  lrc_render_time_format* = "render.time.format" ## \
  ## Key used to access the render GMT time format. See `times.format()
  ## <http://nimrod-lang.org/times.html#format>`_ for a list of valid format
  ## specifiers.

  lrc_render_local_date_format* = "render.local_date.format" ## \
  ## Key used to access the render local date format. See `times.format()
  ## <http://nimrod-lang.org/times.html#format>`_ for a list of valid format
  ## specifiers.

  lrc_render_local_time_format* = "render.local_time.format" ## \
  ## Key used to access the render local time format. See `times.format()
  ## <http://nimrod-lang.org/times.html#format>`_ for a list of valid format
  ## specifiers.

  lrc_render_failure_test* = "render.failure.test" ## \
  ## Special key used in lazy_rest unit testing to simulate serious errors.
  ##
  ## If you set this configuration key to the value `lrd_render_failure_test
  ## <#lrd_render_failure_test>`_ you will get the special last resort error
  ## page. See the `Lazy reST error handling <../docs/error_handling.html>`_
  ## document for more information.

  lrc_split_item_toc* = "split.item_toc" ## \
  ## Key used to tweak the number of characters a table of content entry can
  ## have nefore being split. The splitting prevents the TOC from growing too
  ## wide and obscuring the main text. The default value is 20.

  lrk_render_title* = "title"
  lrk_render_date* = "date"
  lrk_render_time* = "time"
  lrk_render_local_date* = "local_date"
  lrk_render_local_time* = "local_time"
  lrk_render_file_time* = "fileTime"
  lrk_render_prism_js* = "prism_js"
  lrk_render_prism_css* = "prism_css"
  lrk_render_content* = "content"

  lrd_render_date_format* = "yyyy-MM-dd"
  lrd_render_time_format* = "HH:mm"
  lrd_render_local_date_format* = "yyyy-MM-dd"
  lrd_render_local_time_format* = "HH:mm"
  lrd_split_item_toc* = "20"
  lrd_render_failure_test* =
    "Why do people suffer through video content lesser than 4k?" ## \
    ## Special value to set for `lrc_render_failure_test
    ## <#lrc_render_failure_test>`_.
