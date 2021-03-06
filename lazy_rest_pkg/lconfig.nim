## `lazy_rest <https://github.com/gradha/lazy_rest>`_ submodule containing
## configuration constants used elsewhere.
##
## The constants with the ``lrc_`` prefix stand for lazy_rest configuration
## keys. These keys are used for the `PStringTable
## <http://nimrod-lang.org/strtabs.html#PStringTable>`_ types passed in the
## API. You can create these configuration objects with `new_rst_config()
## <#new_rst_config>`_.
##
## The constants with the ``lrk_`` prefix stand for lazy_rest render key
## substitution. They are the strings that you can use inside your
## `lrc_render_template <#lrc_render_template>`_ to specify different
## parametrized values.
##
## The constants with the ``lrd_`` prefix stand for lazy_rest default values,
## and are usually returned by `lrstgen.default_config()
## <lrstgen.html#default_config>`_.


when defined(lazy_rest_devel_log):
  import logging


import
  strtabs, bb_system, parsecfg, streams


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

  lrc_render_write_index_auto* = "render.write.index.auto" ## \
  ## Automatically writes an index file after generating the HTML.
  ##
  ## The value for this option has to be *true* according to the parsing of the
  ## `is_true() proc <#is_true>`_ to be enabled.
  ##
  ## When enabled, and only if you pass a filename to the rst processing procs,
  ## on success an ``.idx`` file will be generated based on the specified input
  ## path. Index files can later be merged together with
  ## `lrstgen.mergeIndexes() <lrstgen.html#mergeIndexes>`_. This is a
  ## semi-public option meant for other tools building upon this module which
  ## want to provide a similar feature to Nimrod's ``buildIndex`` compiler
  ## command. See the related `Nimrod docgen documentation
  ## <http://nim-lang.org/docgen.html#index-idx-file-format>`_.

  lrc_render_write_index_filename* = "render.write.index.filename" ## \
  ## Specific path to the ``.idx`` file to be generated along HTML output.
  ##
  ## If the `lrc_render_write_index_auto <#lrc_render_write_index_auto>`_
  ## option is not enough because maybe you can't depend on the current working
  ## directory to be the same as the input filename, use this option to set the
  ## full path to the output file.
  ##
  ## This option takes precedence over `lrc_render_write_index_auto
  ## <#lrc_render_write_index_auto>`_. And remember to set this to the empty
  ## string after each usage if you don't want to overwrite the file on the
  ## next run you do with the same configuration settings!

  lrc_parser_skip_pounds* = "parser.skip.pounds" ## \
  ## Modifies the rst parser to skip initial hash symbols (``#``).
  ##
  ## The value for this option has to be *true* according to the parsing of the
  ## `is_true() proc <#is_true>`_ to be enabled. When activated, lines starting
  ## with a single or double hash (``#`` or ``##``) will be treated as if the
  ## hash was not present. Note that the rest of the line **won't** be ignored.
  ## This means that your typical Nimrod comment block will be rendered as an
  ## indented text, because the hash pound will be ignored, and usually you
  ## separate the text from the hashes with a space, which will then be
  ## interpreted as rst indentation.
  ##
  ## To see the effect of this option look at the
  ## `tests/parser_options/parser_skip_pounds.rst
  ## <https://github.com/gradha/lazy_rest/blob/master/tests/parser_options/parser_skip_pounds.rst>`_
  ## file and the output files generated by the test in that directory.

  lrc_parser_enable_smilies* = "parser.enable.smilies" ## \
  ## Modifies the rst parser to enable smiley pattern replacement.
  ##
  ## Enabling this will transform several patterns (like ``:-D``) found in
  ## plain text with image references.  The value for this option has to be
  ## *true* according to the parsing of the `is_true() proc <#is_true>`_ to be
  ## enabled.
  lrc_parser_enable_raw_directive* = "parser.enable.raw.directive" ## \
  ## Modifies the rst parser to enable the raw directive.
  ##
  ## By default the raw directive is skipped by the parser.  The value for this
  ## option has to be *true* according to the parsing of the `is_true() proc
  ## <#is_true>`_ to be enabled.
  lrc_parser_enable_fended_blocks* = "parser.enable.fenced.blocks" ## \
  ## Modifies the rst parser to enable GitHub markdown style fenced blocks.
  ##
  ## Fenced blocks consist of three backticks ``(`)`` and optionally a language
  ## syntax option to initiate a source code block without indentation.  The
  ## value for this option has to be *true* according to the parsing of the
  ## `is_true() proc <#is_true>`_ to be enabled.

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
  ##
  ## This render key is only used by the success template, it won't do anything
  ## in error pages.

  lrk_render_prism_css* = "prism_css" ## \
  ## Replaced by the Prism CSS code required to style code highlighting.
  ##
  ## This is a `subexe <http://nimrod-lang.org/subexes.html>`_ replacement key
  ## used inside `lrc_render_template <#lrc_render_template>`_ content.  See
  ## the `Lazy reST error handling <../docs/error_handling.html>`_ document for
  ## more information.
  ##
  ## This render key is only used by the success template, it won't do anything
  ## in error pages.

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
  ##
  ## This render key is only used by the failure template, it won't do anything
  ## in success pages since they were rendered without errrors.

  lrd_render_date_format* = "yyyy-MM-dd" ## \
  ## `Default value <lrstgen.html#default_config>`_ for `lrc_render_date_format
  ## <#lrc_render_date_format>`_.

  lrd_render_time_format* = "HH:mm" ## \
  ## `Default value <lrstgen.html#default_config>`_ for `lrc_render_time_format
  ## <#lrc_render_time_format>`_.

  lrd_render_local_date_format* = "yyyy-MM-dd" ## \
  ## `Default value <lrstgen.html#default_config>`_ for
  ## `lrc_render_local_date_format <#lrc_render_local_date_format>`_.

  lrd_render_local_time_format* = "HH:mm" ## \
  ## `Default value <lrstgen.html#default_config>`_ for
  ## `lrc_render_local_time_format <#lrc_render_local_time_format>`_.

  lrd_render_split_item_toc* = "20" ## \
  ## `Default value <lrstgen.html#default_config>`_ for
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
  ## of that, the string value has to be the literal ``1``, ``t``, ``true``,
  ## ``y`` or ``yes``. Any other value will make this proc return ``false``.
  case t[key]
  of "1", "t", "true", "y", "yes":
    result = true
  else:
    discard
  return


proc new_rst_config*(): PStringTable =
  ## Convenience method to return a new empty ``PStringTable`` table.
  ##
  ## This essentially calls `strtabs.newStringTable()
  ## <http://nimrod-lang.org/strtabs.html#newStringTable,TStringTableMode>`_
  ## with the parameter `modeStyleInsensitive
  ## <http://nimrod-lang.org/strtabs.html#TStringTableMode>`_.
  ##
  ## After creating this table you will want to fill it with ``lrc_``
  ## configuration keys like `lrc_parser_skip_pounds
  ## <#lrc_parser_skip_pounds>`_ or `lrc_render_date_format
  ## <#lrc_render_date_format>`_. Example:
  ##
  ## .. code-block::
  ##
  ##   import lazy_rest_pkg/lconfig
  ##   var config = new_rst_config()
  ##   config[lrc_render_split_item_toc] = "30"
  result = newStringTable(modeStyleInsensitive)


proc load_rst_config(mem_string: string): PStringTable =
  ## Parses the configuration string and returns it as a PStringTable.
  ##
  ## If something goes wrong, will likely raise an exception or return nil.
  var
    f = newStringStream(mem_string)
    temp = newStringTable(modeStyleInsensitive)
  if f.is_nil: raise newException(EInvalidValue, "cannot stream string")

  var p: TCfgParser
  open(p, f, "static slurped config")
  while true:
    var e = next(p)
    case e.kind
    of cfgEof:
      break
    of cfgSectionStart:   ## a ``[section]`` has been parsed
      discard
    of cfgKeyValuePair:
      temp[e.key] = e.value
    of cfgOption:
      when defined(lazy_rest_devel_log):
        warn("command: " & e.key & ": " & e.value)
      else:
        discard
    of cfgError:
      when defined(lazy_rest_devel_log):
        error(e.msg)
      else:
        discard
      raise newException(EInvalidValue, e.msg)
  close(p)
  result = temp


proc parse_rst_options*(options: string): PStringTable {.raises: [].} =
  ## Parses the options string, returns ``nil`` if something goes wrong.
  ##
  ## You can safely pass the result of this proc to `rst_string_to_html()
  ## <../lazy_rest.html#rst_string_to_html>`_ or any other proc asking for
  ## configuration options since they will handle ``nil`` gracefully. Usually
  ## you will pass the contents of a file like `resources/embedded_nimdoc.cfg
  ## <https://github.com/gradha/lazy_rest/blob/master/resources/embedded_nimdoc.cfg>`_
  ## to configure the options for the parsing and rendering phases of the rst
  ## transformation.
  if options.is_nil or options.len < 1:
    return nil

  try:
    # Select the correct configuration.
    result = load_rst_config(options)
  except EInvalidValue, E_Base:
    try:
      when defined(lazy_rest_devel_log):
        error("Returning nil as parsed options")
      else:
        discard
    except: discard
