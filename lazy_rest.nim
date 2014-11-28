import
  lazy_rest_pkg/lrstgen, os, lazy_rest_pkg/lrst, strutils, parsecfg, subexes,
  strtabs, streams, times, cgi, logging, external/badger_bits/bb_system,
  lazy_rest_pkg/lconfig

export Find_file_handler
export TMsgClass
export TMsgHandler
export TMsgKind
export nil_find_file_handler
export nil_msg_handler
export rst_messages
export whichMsgClass

## Main API of `lazy_rest <https://github.com/gradha/lazy_rest>`_ a
## reStructuredText processing module for Nimrod.
##
## For more information regarding Nimrod usage see the `Nimrod usage guide
## <docs/nimrod_usage.rst>`_.
##
## If you are looking for the C API documentation, go to the
## `lazy_rest_c_api.nim <lazy_rest_c_api.html>`_ file.

# THIS BLOCK IS PENDING https://github.com/gradha/lazy_rest/issues/5
# If you want to use the multi processor aware queues, which are able to
# render rst files using all the cores of your CPU, import
# `lazy_rest_pkg/lqueues.nim <lazy_rest_pkg/lqueues.html>`_ and use the
# objects and procs it provides.

proc tuple_to_version(x: expr): string {.compileTime.} =
  ## Transforms an arbitrary int tuple into a dot separated string.
  result = ""
  for name, value in x.fieldPairs: result.add("." & $value)
  if result.len > 0: result.delete(0, 0)

proc load_config(mem_string: string): PStringTable


const
  rest_default_config = slurp("resources"/"embedded_nimdoc.cfg")
  error_template = slurp("resources"/"error_html.template") ##
  ## The default error template which uses the subexes module for string
  ## replacements.
  safe_error_start = slurp("resources"/"safe_error_start.template") ##
  ## Alternative to `error_template` if something goes wrong. This uses simple
  ## concatenation, so it should be safe.
  safe_error_end = slurp("resources"/"safe_error_end.template") ##
  ## Required pair to `safe_error_start`. Content is sandwiched between.
  prism_js = "<script>" & slurp("resources"/"prism.js") & "</script>"
  prism_css = slurp("resources"/"prism.css")
  version_int* = (major: 0, minor: 1, maintenance: 0) ## \
  ## Module version as an integer tuple.
  ##
  ## Major versions changes mean a break in API backwards compatibility, either
  ## through removal of symbols or modification of their purpose.
  ##
  ## Minor version changes can add procs (and maybe default parameters). Minor
  ## odd versions are development/git/unstable versions. Minor even versions
  ## are public stable releases.
  ##
  ## Maintenance version changes mean I'm not perfect yet despite all the kpop
  ## I watch.
  version_str* = tuple_to_version(version_int) ## \
    ## Module version as a string. Something like ``1.9.2``.

type
  Global_state = object
    default_config: PStringTable ## HTML rendering configuration, never nil.
    last_c_conversion: string ## Modified by the exported C API procs.
    did_start_logger: bool ## Internal debugging witness.
    user_normal_error: string ## \
    ## Not nil if the user called `set_normal_error_rst()
    ## <#set_normal_error_rst>`_ previously.
    user_safe_error_start: string ## \
    ## Not nil if the user called `set_safe_error_rst() <#set_safe_error_rst>`_
    ## previously.
    user_safe_error_end: string ## \
    ## Not nil if the user called `set_safe_error_rst() <#set_safe_error_rst>`_
    ## previously.


var G: Global_state
# Load default configuration.
G.default_config = load_config(rest_default_config)


proc stdout_msg_handler*(filename: string, line, col: int,
    msgkind: TMsgKind, arg: string): string {.procvar, raises: [],
    exportc:"lr_stdout_msg_handler".} =
  ## Default handler to report warnings/errors.
  ##
  ## This implementation shows the warning or error through ``stdout``. In the
  ## case of error the message is returned so that the ``EParseError``
  ## exception can be raised to avoid continuing. This procvar conforms to the
  ## `TMsgHandler type specification <lazy_rest_pkg/lrst.html#TMsgHandler>`_.
  let mc = msgkind.whichMsgClass
  var message = filename & "(" & $line & ", " & $col & ") " & $mc
  try:
    let reason = rst_messages[msgkind] % arg
    message.add(": " & reason)
  except EInvalidValue:
    discard

  if mc == mcError:
    result = message
  else:
    try: writeln(stdout, message)
    except EIO: discard


proc unrestricted_find_file_handler*(current_filename,
    target_filename: string): string {.procvar,
    exportc:"lr_unrestricted_find_file_handler", raises: [].} =
  ## Default handler to resolve file path navigation.
  ##
  ## This proc is called according to the `Find_file_handler type specification
  ## <lazy_rest_pkg/lrst.html#Find_file_handler>`_. The includes are always
  ## resolved, hence the *unrestricted*. You might want to provide your own
  ## security aware version which restricts absolute paths. Or disable file
  ## access altogether passing the `lrst.nil_find_file_handler()
  ## <lazy_rest_pkg/lrst.html#nil_find_file_handler>`_ proc where appropriate.
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##
  ##   if trusted_source:
  ##     buf = safe_rst_file_to_html(filename,
  ##       find_file = unrestricted_find_file_handler)
  ##   else:
  ##     buf = safe_rst_file_to_html(filename,
  ##       find_file = nil_find_file_handler)
  assert current_filename.not_nil and current_filename.len > 0
  assert target_filename.not_nil and target_filename.len > 0
  #debug("Asking for '" & target_filename & "'")
  #debug("from '" & current_filename & "'")
  result = ""
  if target_filename.is_absolute:
    if target_filename.exists_file:
      result = target_filename
  else:
    let path = current_filename.parent_dir / target_filename
    if path.exists_file:
      result = path
  #debug("\tReturning '" & result & "'")


proc load_config(mem_string: string): PStringTable =
  ## Parses the configuration and returns it as a PStringTable.
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
      warn("command: " & e.key & ": " & e.value)
    of cfgError:
      error(e.msg)
      raise newException(EInvalidValue, e.msg)
  close(p)
  result = temp


proc parse_rst_options*(options: string): PStringTable {.raises: [].} =
  ## Parses the options, returns nil if something goes wrong.
  ##
  ## You can safely pass the result of this proc to `rst_string_to_html()
  ## <#rst_string_to_html>`_ or any other proc asking for configuration options
  ## since they will handle nil gracefully.
  if options.is_nil or options.len < 1:
    return nil

  try:
    # Select the correct configuration.
    result = load_config(options)
  except EInvalidValue, E_Base:
    try: error("Returning nil as parsed options")
    except: discard


proc rst_string_to_html*(content, filename: string,
    user_config: PStringTable = nil,
    find_file: Find_file_handler = unrestricted_find_file_handler,
    msg_handler: TMsgHandler = stdout_msg_handler): string =
  ## Converts a content named filename into a string with HTML tags.
  ##
  ## If there is any problem with the parsing, an exception could be thrown.
  ##
  ## You can pass nil as `user_config` if you want to use the default HTML
  ## rendering templates embedded in the module. Or you can load a
  ## configuration file with `parse_rst_options <#parse_rst_options>`_ or
  ## `load_config <#load_config>`_.  The value for the `user_config` parameter
  ## is explained in `lazy_rest/lrstgen.initRstGenerator()
  ## <lazy_rest_pkg/lrstgen.html#initRstGenerator>`_.
  ##
  ## By default the `find_file` parameter will be the
  ## `unrestricted_find_file_handler() <#unrestricted_find_file_handler>`_
  ## proc. If you pass ``nil`` the `lrst.nil_find_file_handler()
  ## <lazy_rest_pkg/lrst.html#nil_find_file_handler>`_ proc will be used
  ## instead.
  assert content.not_nil
  assert G.default_config.not_nil
  let
    parse_options = {roSupportRawDirective}
    config = if user_config.not_nil: user_config else: G.default_config
  var
    filename = filename
    GENERATOR: TRstGenerator
    HAS_TOC: bool
  assert config.not_nil
  if filename.is_nil:
    filename = "(no filename)"

  # Was the debug logger started?
  if not G.did_start_logger:
    when not defined(release):
      var F = newFileLogger("/tmp/rester.log", fmtStr = verboseFmtStr)
      handlers.add(newConsoleLogger())
      handlers.add(F)
      info("Initiating global log for debugging")
    G.did_start_logger = true

  GENERATOR.initRstGenerator(outHtml, filename, parse_options,
    config, find_file, msg_handler)

  # Parse the result.
  var RST = rstParse(content, filename, 1, 1, HAS_TOC,
    parse_options, find_file, msg_handler)
  RESULT = newStringOfCap(30_000)

  # Render document into HTML chunk.
  var MOD_DESC = newStringOfCap(30_000)
  GENERATOR.renderRstToOut(RST, MOD_DESC)
  #GENERATOR.modDesc = toRope(MOD_DESC)

  var
    last_mod = epoch_time().from_seconds
    title = GENERATOR.meta[metaTitle]
  # Try to get filename modification, might not be possible with string data!
  if filename.not_nil:
    try: last_mod = filename.getLastModificationTime
    except: discard
  let
    last_mod_local = last_mod.getLocalTime
    last_mod_gmt = last_mod.getGMTime
    render_date_format = GENERATOR.config[lrc_render_date_format]
    render_time_format = GENERATOR.config[lrc_render_time_format]
    render_local_date_format = GENERATOR.config[lrc_render_local_date_format]
    render_local_time_format = GENERATOR.config[lrc_render_local_time_format]
  #if title.len < 1: title = filename.split_path.tail

  # Now finish by adding header, CSS and stuff.
  result = subex(GENERATOR.config[lrc_render_template]) % [
    lrk_render_title, title,
    lrk_render_date, last_mod_gmt.format(render_date_format),
    lrk_render_time, last_mod_gmt.format(render_time_format),
    lrk_render_local_date, last_mod_local.format(render_local_date_format),
    lrk_render_local_time, last_mod_local.format(render_local_time_format),
    lrk_render_file_time, $(int(last_mod_local.timeInfoToTime) * 1000),
    lrk_render_prism_js, if GENERATOR.unknownLangs: prism_js else: "",
    lrk_render_prism_css, if GENERATOR.unknownLangs: prism_css else: "",
    lrk_render_content, MOD_DESC]


proc rst_file_to_html*(filename: string, user_config: PStringTable = nil,
    find_file: Find_file_handler = unrestricted_find_file_handler,
    msg_handler: TMsgHandler = stdout_msg_handler): string =
  ## Converts a filename with rest content into a string with HTML tags.
  ##
  ## If there is any problem with the parsing, an exception could be thrown.
  ##
  ## By default the `find_file` parameter will be the
  ## `unrestricted_find_file_handler() <#unrestricted_find_file_handler>`_
  ## proc. If you pass ``nil`` the `lrst.nil_find_file_handler()
  ## <lazy_rest_pkg/lrst.html#nil_find_file_handler>`_ proc will be used
  ## instead.
  const msg = "filename parameter can't be nil!"
  rassert filename.not_nil, msg:
    raise new_exception(EInvalidValue, msg)

  result = rst_string_to_html(readFile(filename), filename, user_config,
    find_file, msg_handler)


proc add_pre_number_lines(content: string): string =
  ## Takes all the content and prefixes with number lines.
  ##
  ## The prefixing is done with plain text characters, right aligned, so this
  ## presumes the text will be formated with monospaced font inside some <pre>
  ## tag.
  let
    max_lines = 1 + content.count_lines
    width = len($max_lines)
  result = new_string_of_cap(content.len + width * max_lines)
  var
    I = 0
    LINE = 1
  result.add(align($LINE, width))
  result.add(" ")

  while I < content.len - 1:
    result.add(content[I])
    case content[I]
    of new_lines:
      if content[I] == '\c' and content[I+1] == '\l': inc I
      LINE.inc
      result.add(align($LINE, width))
      result.add(" ")
    else: discard
    inc I

  # Last character.
  if content[<content.len] in new_lines:
    discard
  else:
    result.add(content[<content.len])


proc build_error_table(ERRORS: ptr seq[string]): string {.raises: [].} =
  ## Returns a string with HTML to display the list of errors as a table.
  ##
  ## If there is any problem with the `ERRORS` variable an empty string is
  ## returned.
  RESULT = ""
  if ERRORS.not_nil and ERRORS[].not_nil and ERRORS[].len > 0:
    RESULT.add("<table CELLPADDING=\"5pt\" border=\"1\">")
    for line in ERRORS[]:
      RESULT.add("<tr><td>" & line.xml_encode & "</td></tr>")
    RESULT.add("</table>\n")


proc append(ERRORS: ptr seq[string], e: ref E_Base)
    {.raises: [].} =
  ## Helper to append the current exception to `ERRORS`.
  ##
  ## `ERRORS` can be nil, in which case this doesn't do anything. The exception
  ## will be added to the list as a basic text message.
  assert ERRORS.not_nil, "`ERRORS` ptr should never be nil, bad programmer!"
  assert ERRORS[].not_nil, "`ERRORS[]` should never be nil, bad programmer!"
  assert e.not_nil, "`e` ref should never be nil, bad programmer!"
  if ERRORS.is_nil or e.is_nil or ERRORS[].is_nil: return
  # Figure out the name of the exception.
  var E_NAME: string
  if e of EOS: E_NAME = "EOS"
  elif e of EIO: E_NAME = "EIO"
  elif e of EOutOfMemory: E_NAME = "EOutOfMemory"
  elif e of EInvalidSubex: E_NAME = "EInvalidSubex"
  elif e of EInvalidIndex: E_NAME = "EInvalidIndex"
  elif e of EInvalidValue: E_NAME = "EInvalidValue"
  elif e of EOutOfRange: E_NAME = "EOutOfRange"
  else:
    E_NAME = "E_Base(" & repr(e) & ")"
  ERRORS[].add(E_NAME & ", " & e.msg.safe)


template append_error_to_list(): stmt =
  ## Template to be used in exception blocks of procs using errors pattern.
  ##
  ## The template will expand to create a default errors variable which shadows
  ## the parameter. If the parameter has the default nil value, the local
  ## shadowed version will create local storage to be able to catch and process
  ## exceptions.
  ##
  ## This template should be used at the highest possible caller level, so that
  ## all its children are able to use the parent's error sequence rather than
  ## creating their own copy which goes nowhere.
  var
    ERRORS {.inject.} = ERRORS
    local {.inject.}: seq[string]
  if ERRORS.is_nil:
    local = @[]
    ERRORS = local.addr
  let e = get_current_exception()
  if e.not_nil:
    ERRORS.append(e)


proc build_error_html(filename, data: string, ERRORS: ptr seq[string],
    config: PStringTable): string {.raises: [].} =
  ## Helper which builds an error HTML from the input data and collected errors.
  ##
  ## This proc always returns a valid HTML. All the input parameters are
  ## optional, the proc will figure what to do if they aren't present.
  ##
  ## The `config` parameter is only used to force special error testing. If the
  ## config table contains the key ``lazy.rst.failure.test`` with the value
  ## ``Why do people suffer through video content lesser than 4k?`` the
  ## internal subex replacement will be forced to fail so as to test the
  ## *static* version of the error HTML page. In general the subex replacement
  ## will work, so you shouldn't worry too much about this. Unless you do, in
  ## which case you should look at the output from the errors test suite.
  result = ""
  var
    TIME_STR: array[4, string] # String representations, date, then time.
    ERROR_TITLE = "Error processing "
  # Force initialization to empty strings for time representations.
  for f in 0 .. high(TIME_STR):
    TIME_STR[f] = ""

  # Detect if we are forcing simulated error tests.
  var simulate_subex_failure = false
  if config.not_nil and config["lazy.rst.failure.test"] ==
      "Why do people suffer through video content lesser than 4k?":
    simulate_subex_failure = true

  # Fixup title page as much as we can.
  var last_mod: TTime
  if filename.is_nil:
    if data.is_nil:
      ERROR_TITLE.add("rst input")
    else:
      ERROR_TITLE.add($data.len & " bytes of rst input")
  else:
    ERROR_TITLE.add(filename.xml_encode)
    # See if we can get the filename time?
    try: last_mod = filename.getLastModificationTime
    except: discard
  let
    last_mod_local = last_mod.getLocalTime
    last_mod_gmt = last_mod.getGMTime

  # Recover current time and store in text for string replacement.
  try:
    for f, value in [get_time().get_gm_time, get_time().get_local_time]:
      TIME_STR[f * 2] = value.format("yyyy-MM-dd")
      TIME_STR[f * 2 + 1] = value.format("HH:mm")
  except EInvalidValue:
    discard

  # Generate content for the error HTML page.
  var CONTENT = ""
  if data.not_nil and data.len > 0:
    CONTENT = "<p><pre>" &
      data.xml_encode.add_pre_number_lines.replace("\n", "<br>") &
      "</pre></p>"

  # Attempt the replacement.
  try:
    if simulate_subex_failure:
      raise new_exception(EInvalidValue, "We heard you like errors, so we " &
        "put an error inside your error so you can check while you check.")

    let html_template =
      if G.user_normal_error.is_nil: error_template else: G.user_normal_error
    result = subex(html_template) % ["title", ERROR_TITLE,
      "local_date", TIME_STR[2], "local_time", TIME_STR[3],
      "fileTime", $(int(last_mod_local.timeInfoToTime) * 1000),
      "version_str", version_str, "errors", ERRORS.build_error_table,
      "content", CONTENT]
  except:
    ERRORS.append(get_current_exception())

  if result.len < 1:
    # Oops, something went really wrong and we don't have yet the HTML. Build
    # it from simple string concatenation.
    if G.user_safe_error_start.not_nil and G.user_safe_error_end.not_nil:
      result = G.user_safe_error_start & ERRORS.build_error_table & "<br>" &
        CONTENT & G.user_safe_error_end
    else:
      result = safe_error_start & ERRORS.build_error_table & "<br>" &
        CONTENT & safe_error_end


proc safe_rst_string_to_html*(filename, data: string,
    ERRORS: ptr seq[string] = nil, user_config: PStringTable = nil,
    find_file: Find_file_handler = unrestricted_find_file_handler,
    msg_handler: TMsgHandler = stdout_msg_handler): string {.raises: [].} =
  ## Wrapper over `rst_string_to_html <#rst_string_to_html>`_ to catch
  ## exceptions.
  ##
  ## Returns always a valid HTML. If something bad happens, it tries to show
  ## the error for debugging but still returns valid HTML, though it may be
  ## quite different from what you expect. The `filename` parameter is only
  ## used for error reporting, you can pass nil or the empty string.
  ##
  ## This proc always returns without raising any exceptions, but if you want
  ## to know about errors you can pass the address of an initialized sequence
  ## of string as the `ERRORS` parameter to figure out why something fails and
  ## report it to the user. Any problems found during rendering will be added
  ## to the existing list.
  ##
  ## The value for the `user_config` parameter is explained in
  ## `lazy_rest/lrstgen.initRstGenerator()
  ## <lazy_rest_pkg/lrstgen.html#initRstGenerator>`_.
  ##
  ## Usage example:
  ##
  ## .. code-block:: nimrod
  ##
  ##   echo safe_rst_string_to_html(nil, rst)
  ##   # --> dumps HTML saying something bad happened.
  ##   var ERRORS: seq[string] = @[]
  ##   let html = safe_rst_string_to_html(name, rst, ERRORS.addr)
  ##   if ERRORS.len > 0:
  ##     # We got HTML, but it it won't be nice.
  ##     for error in ERRORS: echo error
  ##     ...
  ##   else:
  ##     # Yay, use `html` without worries.
  const msg = "data parameter can't be nil"
  rassert data.not_nil, msg:
    append_error_to_list()
    ERRORS.append(new_exception(EInvalidValue, msg))
    result = build_error_html(filename, data, ERRORS, user_config)
    return

  try:
    result = rst_string_to_html(data, filename,
      user_config, find_file, msg_handler)
  except:
    append_error_to_list()
    result = build_error_html(filename, data, ERRORS, user_config)


proc safe_rst_file_to_html*(filename: string, ERRORS: ptr seq[string] = nil,
    user_config: PStringTable = nil,
    find_file: Find_file_handler = unrestricted_find_file_handler,
    msg_handler: TMsgHandler = stdout_msg_handler): string {.raises: [].} =
  ## Wrapper over `rst_file_to_html <#rst_file_to_html>`_ to catch exceptions.
  ##
  ## Returns always a valid HTML. If something bad happens, it tries to show
  ## the error for debugging but still returns valid HTML, though it may be
  ## quite different from what you expect.
  ##
  ## This proc always returns without raising any exceptions, but if you want
  ## to know about errors you can pass the address of an initialized sequence
  ## of string as the `ERRORS` parameter to figure out why something fails and
  ## report it to the user. Any problems found during rendering will be added
  ## to the existing list.
  ##
  ## The value for the `user_config` parameter is explained in
  ## `lazy_rest/lrstgen.initRstGenerator()
  ## <lazy_rest_pkg/lrstgen.html#initRstGenerator>`_.
  ##
  ## Usage example:
  ##
  ## .. code-block:: nimrod
  ##
  ##   import os
  ##
  ##   echo safe_rst_file_to_html(nil)
  ##   # --> dumps HTML saying something bad happened.
  ##   var ERRORS: seq[string] = @[]
  ##   let html = safe_rst_file_to_html(filename, ERRORS.addr)
  ##   if ERRORS.len > 0:
  ##     # We got HTML, but it it won't be nice.
  ##     for error in ERRORS: echo error
  ##     ...
  ##   else:
  ##     filename.change_file_ext("html").write_file(html)
  try:
    result = rst_file_to_html(filename, user_config, find_file, msg_handler)
  except:
    append_error_to_list()
    var CONTENT: string
    try:
      if filename.not_nil:
        CONTENT = filename.read_file
    except:
      CONTENT = "Could not read " & filename & " for display!!!"
    result = build_error_html(filename, CONTENT, ERRORS, user_config)


proc nim_file_to_html*(filename: string, number_lines = true,
    user_config: PStringTable = nil): string {.raises: [].} =
  ## Puts the contents of `filename` in a code block to render as rest.
  ##
  ## Returns a string with the rendered HTML. The `number_lines` parameter
  ## controls if the rendered source will have a column to the left of the
  ## source with line numbers. By default source lines will be numbered.
  ##
  ## This proc always works, since even empty code blocks should render (as
  ## empty HTML), and there should be no content escaping problems. In the case
  ## of failure, the error itself will be rendered in the final HTML.
  const
    with_numbers = "\n.. code-block:: nimrod\n   :number-lines:\n\n  "
    without_numbers = "\n.. code-block:: nimrod\n  "
  try:
    let
      name = filename.splitFile.name
      title_symbols = repeatChar(name.len, '=')
      length = 1000 + int(filename.getFileSize)
    var SOURCE = newStringOfCap(length)
    SOURCE = title_symbols & "\n" & name & "\n" & title_symbols &
      (if number_lines: with_numbers else: without_numbers)
    SOURCE.add(readFile(filename).replace("\n", "\n  "))
    result = rst_string_to_html(SOURCE, filename, user_config,
      find_file = nil_find_file_handler)
  except E_Base:
    result = "<html><body><h1>Error for " & filename & "</h1></body></html>"
  except EOS:
    result = "<html><body><h1>OS error for " & filename & "</h1></body></html>"
  except EIO:
    result = "<html><body><h1>I/O error for " & filename & "</h1></body></html>"
  except EOutOfMemory:
    result = """<html><body><h1>Out of memory!</h1></body></html>"""


proc set_normal_error_rst*(input_rst: string):
    seq[string] {.discardable, raises: [].} =
  ## Changes the default error page for ``safe_*`` function errors.
  ##
  ## Use this proc to customize the look of error HTML generated by procs like
  ## `safe_rst_file_to_html() <#safe_rst_file_to_html>`_ when they encounter
  ## minor errors like parsing problems which can be handled. You need to pass
  ## a valid reStructuredText input. Pass ``nil`` or the empty string if you
  ## want to recover the default embedded template. You might also want to call
  ## `set_safe_error_rst() <#set_safe_error_rst>`_.
  ##
  ## See the document `Lazy reST error handling <docs/error_handling.rst>`_ for
  ## more information on what your ``input_rst`` variable can contain. The only
  ## requirement is that it is valid reStructuredText.
  ##
  ## Returns an empty string on success or a list of error messages indicating
  ## problems with ``input_rst``.
  result = @[]
  if input_rst.is_nil or input_rst.len < 1:
    G.user_normal_error = nil
    return

  var
    ERRORS = result.addr
  try:
    G.user_normal_error = rst_string_to_html(input_rst,
      "set_normal_error_rst.input_rst", find_file = nil_find_file_handler,
      msg_handler = nil_msg_handler)
  except:
    append_error_to_list()


proc set_safe_error_rst*(input_rst: string):
    seq[string] {.discardable, raises: [].} =
  ## Changes the safe error page for ``safe_*`` function errors.
  ##
  ## Use this proc to customize the look of error HTML generated by procs like
  ## `safe_rst_file_to_html() <#safe_rst_file_to_html>`_ when they encounter a
  ## fatal error which can't be handled in any way (these should be very rare)
  ## and the error HTML has to be concatenated without interpolation. You need
  ## to pass a valid reStructuredText input. Pass ``nil`` or the empty string
  ## if you want to recover the default embedded template. You might also want
  ## to call `set_safe_error_rst() <#set_safe_error_rst>`_.
  ##
  ## See the document `Lazy reST error handling <docs/error_handling.rst>`_ for
  ## more information on what your ``input_rst`` variable needs to contain.
  ## Unlike `set_normal_error_rst() <#set_normal_error_rst>`_ your
  ## ``input_rst`` is required to produce a ``$content`` string somewhere to be
  ## a valid replacement for the embedded default.
  ##
  ## Returns an empty string on success or a list of error messages indicating
  ## problems with ``input_rst``.
  result = @[]
  if input_rst.is_nil or input_rst.len < 1:
    G.user_safe_error_start = nil
    G.user_safe_error_end = nil
    return

  var
    html: string
    ERRORS = result.addr
  try:
    html = rst_string_to_html(input_rst, "set_normal_error_rst.input_rst",
      find_file = nil_find_file_handler, msg_handler = nil_msg_handler)
  except:
    append_error_to_list()
    return

  # Success rendering, check to see if we have other required attributes.
  const required_string = "$content"
  let content_pos = html.find(required_string)

  if content_pos < 0:
    ERRORS.append(new_exception(EInvalidValue,
      "Did not find $content in final HTML, it is needed to split the page"))
    return

  let
    p1 = max(0, content_pos - 1)
    p2 = content_pos + required_string.len
  G.user_safe_error_start = html[0 .. p1]
  G.user_safe_error_end = html[p2 .. html.high]
