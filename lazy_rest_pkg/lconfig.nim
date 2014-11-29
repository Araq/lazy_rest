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


import
  strtabs, external/badger_bits/bb_system


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

  lrc_render_split_item_toc* = "render.split.item.toc" ## \
  ## Key used to tweak the number of characters a table of content entry can
  ## have nefore being split. The splitting prevents the TOC from growing too
  ## wide and obscuring the main text. The default value is
  ## `lrd_render_split_item_toc <#lrd_render_split_item_toc>`_.

  lrc_parser_skip_pounds* = "parser.skip.pounds"
  lrc_parser_enable_smilies* = "parser.enable.smilies"
  lrc_parser_enable_raw_directive* = "parser.enable.raw.directive"
  lrc_parser_enable_fended_blocks* = "parser.enable.fenced.blocks"

  lrk_render_title* = "title" ## \
  ## Replaced by the title of the input file if anything was extracted.
  ##
  ## This is a `subexe <http://nimrod-lang.org/subexes.html>`_ replacement key
  ## used inside `lrc_render_template <#lrc_render_template>`_ content.  See
  ## the `Lazy reST error handling <../docs/error_handling.html>`_ document for
  ## more information.

  lrk_render_date* = "date" ## \
  ## Input file last modification GMT date in `lrd_render_date_format
  ## <#lrd_render_date_format>`_ format.
  ##
  ## This is a `subexe <http://nimrod-lang.org/subexes.html>`_ replacement key
  ## used inside `lrc_render_template <#lrc_render_template>`_ content.  See
  ## the `Lazy reST error handling <../docs/error_handling.html>`_ document for
  ## more information.

  lrk_render_time* = "time" ## \
  ## Input file last modification GMT time in `lrd_render_time_format
  ## <#lrd_render_time_format>`_ format.
  ##
  ## This is a `subexe <http://nimrod-lang.org/subexes.html>`_ replacement key
  ## used inside `lrc_render_template <#lrc_render_template>`_ content.  See
  ## the `Lazy reST error handling <../docs/error_handling.html>`_ document for
  ## more information.

  lrk_render_local_date* = "local_date" ## \
  ## Input file last modification local date in `lrd_render_local_date_format
  ## <#lrd_render_local_date_format>`_ format.
  ##
  ## This is a `subexe <http://nimrod-lang.org/subexes.html>`_ replacement key
  ## used inside `lrc_render_template <#lrc_render_template>`_ content.  See
  ## the `Lazy reST error handling <../docs/error_handling.html>`_ document for
  ## more information.

  lrk_render_local_time* = "local_time" ## \
  ## Input file last modification local time in `lrd_render_local_time_format
  ## <#lrd_render_local_time_format>`_ format.
  ##
  ## This is a `subexe <http://nimrod-lang.org/subexes.html>`_ replacement key
  ## used inside `lrc_render_template <#lrc_render_template>`_ content.  See
  ## the `Lazy reST error handling <../docs/error_handling.html>`_ document for
  ## more information.

  lrk_render_file_time* = "fileTime" ## \
  ## Last modification timestamp as Unix epoch but in milliseconds instead of
  ## seconds.
  ##
  ## This is a `subexe <http://nimrod-lang.org/subexes.html>`_ replacement key
  ## used inside `lrc_render_template <#lrc_render_template>`_ content.  See
  ## the `Lazy reST error handling <../docs/error_handling.html>`_ document for
  ## more information.

  lrk_render_prism_js* = "prism_js" ## \
  ## Replaced by the Prism JavaScript snippet when external highlighting is
  ## used.
  ##
  ## This is a `subexe <http://nimrod-lang.org/subexes.html>`_ replacement key
  ## used inside `lrc_render_template <#lrc_render_template>`_ content.
  ## See the `Lazy reST error handling <../docs/error_handling.html>`_ document
  ## for more information.

  lrk_render_prism_css* = "prism_css" ## \
  ## Replaced by the Prism CSS code required to style code highlighting.
  ##
  ## This is a `subexe <http://nimrod-lang.org/subexes.html>`_ replacement key
  ## used inside `lrc_render_template <#lrc_render_template>`_ content.  See
  ## the `Lazy reST error handling <../docs/error_handling.html>`_ document for
  ## more information.

  lrk_render_content* = "content" ## \
  ## Replaced by the input reStructuredText rendered as HTML.
  ##
  ## This is a `subexe <http://nimrod-lang.org/subexes.html>`_ replacement key
  ## used inside `lrc_render_template <#lrc_render_template>`_ content.  See
  ## the `Lazy reST error handling <../docs/error_handling.html>`_ document for
  ## more information.

  lrk_render_version_str* = "version_str" ## \
  ## Replaced by the current version string number.
  ##
  ## This is a `subexe <http://nimrod-lang.org/subexes.html>`_ replacement key
  ## used inside `lrc_render_template <#lrc_render_template>`_ content.  See
  ## the `Lazy reST error handling <../docs/error_handling.html>`_ document for
  ## more information.

  lrk_render_error_table* = "errors" ## \
  ## Replaced by an HTML table with the list of accumulated errors.
  ##
  ## This is a `subexe <http://nimrod-lang.org/subexes.html>`_ replacement key
  ## used inside `lrc_render_template <#lrc_render_template>`_ content.  See
  ## the `Lazy reST error handling <../docs/error_handling.html>`_ document for
  ## more information.

  lrd_render_date_format* = "yyyy-MM-dd" ## \
  ## `Default value <lrstgen.html#defaultConfig>`_ for `lrc_render_date_format
  ## <#lrc_render_date_format>`_.

  lrd_render_time_format* = "HH:mm" ## \
  ## `Default value <lrstgen.html#defaultConfig>`_ for `lrc_render_time_format
  ## <#lrc_render_time_format>`_.

  lrd_render_local_date_format* = "yyyy-MM-dd" ## \
  ## `Default value <lrstgen.html#defaultConfig>`_ for
  ## `lrc_render_local_date_format <#lrc_render_local_date_format>`_.

  lrd_render_local_time_format* = "HH:mm" ## \
  ## `Default value <lrstgen.html#defaultConfig>`_ for
  ## `lrc_render_local_time_format <#lrc_render_local_time_format>`_.

  lrd_render_split_item_toc* = "20" ## \
  ## `Default value <lrstgen.html#defaultConfig>`_ for
  ## `lrc_render_split_item_toc <#lrc_render_split_item_toc>`_.

  lrd_render_failure_test* =
    "Why do people suffer through video content lesser than 4k?" ## \
    ## Special value to set for `lrc_render_failure_test
    ## <#lrc_render_failure_test>`_.


type
  TLayeredConf* = object of TObject ## \
    ## Holds both a custom and default configurations.
    ##
    ## The user configuration can be nil, but the default can't be.
    user*, default*: PStringTable


proc `[]`*(t: TLayeredConf, key: string): string =
  ## Returns the key from the user configuration or the default configuration.
  ##
  ## If the key is not found, the empty string is returned.
  assert t.default.not_nil
  if t.user.not_nil and t.user.has_key(key):
    result = t.user[key]
  else:
    result = t.default[key]


proc is_true*(t: TLayeredConf, key: string): bool =
  ## Returns ``true`` if `t` contains the value `key` and it is of true nature.
  ##
  ## This proc internally looks for the value associated with the `key`. On top
  ## of that, the string value has to be ``1``, ``t``, ``true``, ``y`` or
  ## ``yes``. Any other value will make this proc return ``false``.
  case t[key]
  of "1", "t", "true", "y", "yes":
    result = true
  else:
    discard
  return
