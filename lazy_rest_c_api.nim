import lazy_rest, external/badger_bits/bb_system, strtabs, strutils

## Exported C API of `lazy_rest <https://github.com/gradha/lazy_rest>`_ a
## reStructuredText processing module for Nimrod.
##
## These are simple Nimrod wrappers around the main `lazy_rest.nim
## <lazy_rest.html>`_ module. They just document and export for C the most
## interesting procs to be consumed by other C programs. Usually you will
## compile this module using the `--header command line switch
## <http://nimrod-lang.org/backends.html#backend-code-calling-nimrod>`_ which
## generates the appropriate ``.c`` and ``.h`` files inside the `nimcache
## directory <http://nimrod-lang.org/backends.html#nimcache-naming-logic>`_,
## then compile those into your C program. For more information see the `C
## usage guide <docs/c_usage.rst>`_.
##
## Due to the differences between Nimrod and C, most of the wrapper procs will
## assign the return values to Nimrod global variables so that their memory is
## not freed while *other* Nimrod code executes (potentially triggering garbage
## collections). This means the C API is not thread safe nor reentrant.  You
## should also always call these procs from the main thread UI due to the
## garbage collector not being thread aware either.
##
## When passing ``cstring`` types back and forth, consider all of them to be
## ``char*`` strings encoded in UTF8. This means that you are not able to pass
## embedded ``NULLs`` in text since they will be treated as string terminators.
## In practice this should not be a problem given the nature of text
## processing.
##
## There is a limitation with regards to passing configuration options from C
## (see `lr_parse_rst_options() <#lr_parse_rst_options>`_) so the convenience
## `lr_set_global_rst_options() <#lr_set_global_rst_options>`_ is provided
## instead. The public API will remain having configuration options as
## parameters for the future though.


type
  lr_c_msg_handler* {.exportc.} =
    proc(filename: cstring, line, col: cint,
      msgkind: char, arg: cstring): cstring {.raises: [].} ## \
    ## Defines a C callback for message handlers.
    ##
    ## This callback works exactly the same like `TMsgHandler
    ## <lazy_rest_pkg/lrst.html#TMsgHandler>`_ but for C code. These callbacks
    ## are set globally through the `lr_set_c_msg_handler()
    ## <#lr_set_c_msg_handler>`_ proc.

  lr_c_find_file_handler* {.exportc.} =
    proc(current_filename, target_filename, out_path: cstring,
      max_length: cint) {.raises: [].} ## \
    ## Defines a C callback for resolving file paths.
    ##
    ## This callback works nearly the same like `Find_file_handler
    ## <lazy_rest_pkg/lrst.html#Find_file_handler>`_ but for C code. These
    ## callbacks are set globally through the `lr_set_c_find_file_handler()
    ## <#lr_set_c_find_file_handler>`_ proc.
    ##
    ## The main difference with regards to the Nimrod version is that the C
    ## version doesn't return any string due to memory management issues. The C
    ## version should write the result of the file path operation to the pre
    ## allocated `out_path`. The length of the buffer `out_path` is passed in
    ## as the parameter `max_length`, your string must fit into this size
    ## (including its NULL terminator!).
    ##
    ## By default `max_length` will be 255, but you can change this value with
    ## `lr_set_find_file_buffer_size <#lr_set_find_file_buffer_size>`_.
    ## Remember that paths are always UTF-8.

  C_state = object
    error_rst_file_to_html: ref E_Base
    error_rst_string_to_html: ref E_Base
    errors_safe_rst_file_to_html: seq[string]
    errors_safe_rst_string_to_html: seq[string]
    ret_source_string_to_html: string
    ret_source_file_to_html: string
    ret_parse_rst_options: PStringTable
    ret_rst_file_to_html: string
    ret_rst_string_to_html: string
    ret_safe_rst_file_to_html: string
    ret_safe_rst_string_to_html: string
    ret_set_normal_error_rst: seq[string]
    ret_set_safe_error_rst: seq[string]
    global_options: PStringTable
    msg_handler: tuple[nim: TMsgHandler, c: lr_c_msg_handler] # \
    # The C message handler takes precedence over the nim version.
    find_file_handler: tuple[nim: Find_file_handler,
      c: lr_c_find_file_handler] # \
    # The C find file handler takes precedence over the nim version.
    find_file_buffer_size: cint


const min_c_file_buffer = 255


var C: C_state
# Set some global defaults which can't be nil.
C.msg_handler.nim = stdout_msg_handler
C.find_file_handler.nim = unrestricted_find_file_handler
C.find_file_buffer_size = min_c_file_buffer


template override_config() =
  let config {.inject.} = if config == nil: C.global_options else: config


proc msg_callback_wrapper(filename: string, line, col: int,
    msgkind: TMsgKind, arg: string): string {.procvar, raises: [].} =
  ## Wraps the C callback.
  assert C.msg_handler.c.not_nil
  assert len($msgKind) > 1

  var reason = arg
  try: reason = rst_messages[msgkind] % arg
  except EInvalidValue: discard

  let
    filename = filename.nil_cstring
    kind = ($msgKind)[1]
    msg = C.msg_handler.c(filename, line.cint, col.cint, kind, reason)

  if msg.not_nil:
    result = $msg


proc find_file_callback_wrapper(current_filename,
    target_filename: string): string {.raises: [].} =
  ## Wraps the C callback.
  assert C.find_file_handler.c.not_nil
  var out_path = new_string_of_cap(C.find_file_buffer_size)
  out_path[0] = '\0'
  let
    current_filename = current_filename.nil_cstring
    target_filename = target_filename.nil_cstring
  C.find_file_handler.c(current_filename, target_filename, out_path[0].addr,
    C.find_file_buffer_size.cint)
  result = $cstring(out_path[0].addr)


template global_msg_handler(): TMsgHandler =
  ## Helper to choose the C or Nimrod message handlers as callbacks.
  ##
  ## Returns the appropriate TMsgHandler depending on previous calls to
  ## `lr_set_nim_msg_handler() <#lr_set_nim_msg_handler>`_ and
  ## `lr_set_c_msg_handler() <#lr_set_c_msg_handler>`_. The C version will use
  ## the special Nimrod callback wrapper.
  if C.msg_handler.c.not_nil: msg_callback_wrapper
  else: C.msg_handler.nim


template global_find_file_handler(): Find_file_handler =
  ## Helper to choose the C or Nimrod file handlers as callbacks.
  ##
  ## Returns the appropriate Find_file_handler depending on previous calls to
  ## `lr_set_nim_find_file_handler() <#lr_set_nim_find_file_handler>`_ and
  ## `lr_set_c_find_file_handler() <#lr_set_c_find_file_handler>`_. The C
  ## version will use the special Nimrod callback wrapper.
  if C.find_file_handler.c.not_nil: find_file_callback_wrapper
  else: C.find_file_handler.nim


proc lr_version_int*(major, minor, maintenance: ptr cint)
    {.exportc, cdecl, raises: [].} =
  ## Wraps `version_int <lazy_rest.html#version_int>`_ for C.
  ##
  ## Pass pointers to whatever version values you are interested it and they
  ## will be filled. Example:
  ##
  ## .. code-block:: c
  ##    int major = 6, minor = 6, maintenance = 6;
  ##    lr_version_int(&major, &minor, &maintenance);
  ##    printf("Using lazy_rest: %d-%d-%d.\n",
  ##       major, minor, maintenance);
  ##    // --> Using lazy_rest: 0-1-0.
  if major.not_nil: major[] = version_int.major.cint
  if minor.not_nil: minor[] = version_int.minor.cint
  if maintenance.not_nil: maintenance[] = version_int.maintenance.cint


proc lr_version_str*(): cstring {.exportc, raises: [].} =
  ## Wraps `version_str <lazy_rest.html#version_str>`_ for C.
  ##
  ## Always returns the same pointer to a valid ``cstring``. Example:
  ##
  ## .. code-block:: c
  ##    printf("Using lazy_rest %s.\n", lr_version_str());
  ##    // --> Using lazy_rest 0.1.0.
  result = version_str.cstring


proc lr_parse_rst_options*(options: cstring): PStringTable
    {.exportc, raises: [].} =
  ## Wraps `parse_rst_options() <lazy_rest.html#parse_rst_options>`_ for C.
  ##
  ## The return value is stored in a global variable so future calls to this
  ## function will mangle the returned value. It is unlikely you will need to
  ## call this more than once though.
  ##
  ## Also, due to a `limitation <https://github.com/Araq/Nimrod/issues/1579>`_
  ## in Nimrod's exportc pragma, right now the ``PStringTable`` type will be
  ## exported to the C header like ``typedef struct tstringtable128812
  ## tstringtable128812``, so it may be difficult or impossible to write
  ## crossplatform source code which calls this function, given that each
  ## platform's Nimrod compiler (or version) may generate a different symbol.
  ## Still, the function is here for completeness (and maybe you don't mind the
  ## weird ``typedef``). You can use `lr_set_global_rst_options()
  ## <#lr_set_global_rst_options>`_ to work around this issue.
  C.ret_parse_rst_options = parse_rst_options(options.nil_string)
  result = C.ret_parse_rst_options


proc lr_set_global_rst_options*(options: cstring): cint
    {.discardable, exportc, raises: [].} =
  ## Works around `lr_parse_rst_options() <#lr_parse_rst_options>`_ limitations.
  ##
  ## Since in C you can't get a hold of the type of a ``PStringTable``
  ## conveniently, this will call `lr_parse_rst_options()
  ## <#lr_parse_rst_options>`_ and store the result in a special global
  ## variable. From this moment on, every call to the public API which accepts
  ## a ``PStringTable``, if you pass ``null`` the global variable stored by
  ## this function will be used instead.
  ##
  ## At some point in the future this function will disappear (obviously when
  ## ``PStringTable`` can be exported properly).
  ##
  ## Returns zero if `lr_parse_rst_options() <#lr_parse_rst_options>`_ returned
  ## ``nil``, non zero otherwise.
  C.global_options = options.lr_parse_rst_options
  result = if C.global_options.is_nil: 0 else: 1


proc lr_set_nim_msg_handler*(func: TMsgHandler) {.exportc.} =
  ## Specifies the Nimrod message handler to use for rst processing.
  ##
  ## Since the C API doesn't provide explicit callback parameters, you can use
  ## this function to specify which of the built in Nimrod callbacks you want
  ## to use. The available callbacks are:
  ##
  ## * `lr_stdout_msg_handler <lazy_rest.html#stdout_msg_handler>`_.
  ## * `lr_nil_msg_handler <lazy_rest_pkg/lrst.html#nil_msg_handler>`_.
  ##
  ## If instead of built in Nimrod procs you would prefer to provide your own C
  ## function, use `lr_set_c_msg_handler() <#lr_set_c_msg_handler>`_. Passing
  ## ``NULL`` to this function is equal to passing `lr_nil_msg_handler
  ## <lazy_rest_pkg/lrst.html#nil_msg_handler>`_. Calling this function does
  ## **not** override whatever C callback you might have previously set with
  ## `lr_set_c_msg_handler() <#lr_set_c_msg_handler>`_, which takes precedence
  ## over the Nimrod version.
  ##
  ## If you don't call this proc, the default value is `lr_stdout_msg_handler
  ## <lazy_rest.html#stdout_msg_handler>`_ like in the `Nimrod API
  ## <lazy_rest.html>`_.
  if func.is_nil:
    C.msg_handler.nim = nil_msg_handler
  else:
    C.msg_handler.nim = func


proc lr_set_c_msg_handler*(func: lr_c_msg_handler) {.exportc.} =
  ## Specifies the C message handler to use for rst processing.
  ##
  ## This is like `lr_set_nim_msg_handler() <#lr_set_nim_msg_handler>`_
  ## but allows you to set a custom C callback. Callbacks passed in to this
  ## function take precedence over the Nimrod callback. Passing ``NULL`` will
  ## disable the C callback (which implicitly activates the failsafe Nimrod
  ## one).
  C.msg_handler.c = func


proc lr_set_nim_find_file_handler*(func: Find_file_handler) {.exportc.} =
  ## Specifies the Nimrod file handler to use for rst processing.
  ##
  ## Since the C API doesn't provide explicit callback parameters, you can use
  ## this function to specify which of the built in Nimrod callbacks you want
  ## to use. The available callbacks are:
  ##
  ## * `lr_unrestricted_find_file_handler()
  ##   <lazy_rest.html#unrestricted_find_file_handler>`_.
  ## * `lr_nil_find_file_handler()
  ##   <lazy_rest_pkg/lrst.html#nil_find_file_handler>`_.
  ##
  ## If instead of built in Nimrod procs you would prefer to provide your own C
  ## function, use `lr_set_c_find_file_handler()
  ## <#lr_set_c_find_file_handler>`_. Passing ``NULL`` to this function is
  ## equal to passing `lr_nil_find_file_handler
  ## <lazy_rest_pkg/lrst.html#nil_find_file_handler>`_. Calling this function
  ## does **not** override whatever C callback you might have previously set
  ## with `lr_set_c_find_file_handler() <#lr_set_c_find_file_handler>`_, which
  ## take precedence over the Nimrod version.
  ##
  ## If you don't call this proc, the default value is
  ## `lr_unrestricted_find_file_handler()
  ## <lazy_rest.html#unrestricted_find_file_handler>`_ like in the `Nimrod API
  ## <lazy_rest.html>`_.
  if func.is_nil:
    C.find_file_handler.nim = nil_find_file_handler
  else:
    C.find_file_handler.nim = func


proc lr_set_c_find_file_handler*(func: lr_c_find_file_handler) {.exportc.} =
  ## Specifies the C file handler to use for rst processing.
  ##
  ## This is like `lr_set_nim_find_file_handler()
  ## <#lr_set_nim_find_file_handler>`_ but allows you to set a custom C
  ## callback. Callbacks passed in to this function take precedence over the
  ## Nimrod callback. Passing ``NULL`` will disable the C callback (which
  ## implicitly activates the failsafe Nimrod one).
  C.find_file_handler.c = func


proc lr_set_find_file_buffer_size*(s: cint): cint {.exportc.} =
  ## Sets and returns the size for future find file handler buffer sizes.
  ##
  ## The size of the output buffer for `lr_c_find_file_handler()
  ## <#lr_c_find_file_handler>`_ callback functions can be changed by this
  ## function. If you pass a negative value **or** a value which is too small
  ## (less than 255), the current value won't change. You can use this feature
  ## (passing a negative value) to query the current value.
  ##
  ## What this means is that you can set buffer sizes equal or greater than
  ## 255, but never smaller.
  if s >= min_c_file_buffer:
    C.find_file_buffer_size = s
  result = C.find_file_buffer_size


proc lr_rst_string_to_html*(content, filename: cstring,
    config: PStringTable): cstring {.exportc, raises: [].} =
  ## Wraps `rst_string_to_html() <lazy_rest.html#rst_string_to_html>`_ for C.
  ##
  ## Returns a ``cstring`` with HTML or a ``null`` pointer if there were
  ## errors.  In case of errors you can call `lr_rst_string_to_html_error()
  ## <#lr_rst_string_to_html_error>`_ to retrieve the description, which will
  ## be the text of the Nimrod exception.
  ##
  ## The memory of the returned ``cstring`` will be kept until the next call to
  ## this function, you may need to copy it somewhere. Example:
  ##
  ## .. code-block:: c
  ##    char *s = lr_rst_string_to_html(valid_rst_string,
  ##       "<string>", 0);
  ##    if (s) {
  ##       // Success!
  ##    } else {
  ##       // Handle error.
  ##    }
  override_config()
  let
    filename = filename.nil_string
    content = content.nil_string
  C.ret_rst_string_to_html = nil
  C.error_rst_string_to_html = nil

  try:
    C.ret_rst_string_to_html = rst_string_to_html(content, filename, config,
      global_find_file_handler(), global_msg_handler())
    result = C.ret_rst_string_to_html.nil_cstring
  except:
    C.error_rst_string_to_html = get_current_exception()


proc lr_rst_string_to_html_error*(): cstring {.exportc, raises: [].} =
  ## Returns the error string for `lr_rst_string_to_html()
  ## <#lr_rst_string_to_html>`_.
  ##
  ## If a previous call to `lr_rst_string_to_html() <#lr_rst_string_to_html>`_
  ## returned ``null`` you can call this function to retrieve a textual reason
  ## for the failure.
  ##
  ## Returns the error string or ``null`` if there was no previous error. You
  ## may need to copy the returned error string, since its memory could be
  ## freed by the next call to `lr_rst_string_to_html()
  ## <#lr_rst_string_to_html>`_. Example:
  ##
  ## .. code-block:: c
  ##    char *s = lr_rst_string_to_html(bad_rst_string,
  ##       "<string>", 0);
  ##    if (!s) {
  ##       // Handle error.
  ##       printf("Error processing string: %s\n",
  ##          lr_rst_string_to_html_error());
  ##    }
  if C.error_rst_string_to_html.not_nil:
    result = C.error_rst_string_to_html.msg.nil_cstring


proc lr_rst_file_to_html*(filename: cstring, config: PStringTable):
    cstring {.exportc, raises: [].} =
  ## Wraps `rst_file_to_html() <lazy_rest.html#rst_file_to_html>`_ for C.
  ##
  ## Returns a ``cstring`` with HTML or a ``null`` pointer if there were
  ## errors.  In case of errors you can call `lr_rst_file_to_html_error()
  ## <#lr_rst_file_to_html_error>`_ to retrieve the description, which will be
  ## the text of the Nimrod exception.
  ##
  ## The memory of the returned ``cstring`` will be kept until the next call to
  ## this function, you may need to copy it somewhere. Example:
  ##
  ## .. code-block:: c
  ##    char *s = lr_rst_file_to_html(valid_rst_filename, 0);
  ##    if (s) {
  ##       // Success!
  ##    } else {
  ##       // Handle error.
  ##    }
  override_config()
  let filename = filename.nil_string
  C.ret_rst_file_to_html = nil
  C.error_rst_file_to_html = nil

  try:
    C.ret_rst_file_to_html = rst_file_to_html(filename, config,
      global_find_file_handler(), global_msg_handler())
    result = C.ret_rst_file_to_html.nil_cstring
  except:
    C.error_rst_file_to_html = get_current_exception()


proc lr_rst_file_to_html_error*(): cstring {.exportc, raises: [].} =
  ## Returns the error string for `lr_rst_file_to_html()
  ## <#lr_rst_file_to_html>`_.
  ##
  ## If a previous call to `lr_rst_file_to_html() <#lr_rst_file_to_html>`_
  ## returned ``null`` you can call this function to retrieve a textual reason
  ## for the failure.
  ##
  ## Returns the error string or ``null`` if there was no previous error. You
  ## may need to copy the returned error string, since its memory could be
  ## freed by the next call to `lr_rst_file_to_html() <#lr_rst_file_to_html>`_.
  ## Example:
  ##
  ## .. code-block:: c
  ##    char *s = lr_rst_file_to_html(bad_rst_filename, 0);
  ##    if (!s) {
  ##       // Handle error.
  ##       printf("Error processing file: %s\n",
  ##          lr_rst_file_to_html_error());
  ##    }
  if C.error_rst_file_to_html.not_nil:
    result = C.error_rst_file_to_html.msg.nil_cstring


proc lr_safe_rst_string_to_html*(data, filename: cstring,
    ERRORS: ptr cint, config: PStringTable):
    cstring {.exportc, raises: [].} =
  ## Wraps `safe_rst_string_to_html()
  ## <lazy_rest.html#safe_rst_string_to_html>`_ for C.
  ##
  ## Returns always a valid ``cstring`` with HTML. The memory of the returned
  ## ``cstring`` will be kept until the next call to this function, you may
  ## need to copy it somewhere.
  ##
  ## If `ERRORS` is not ``null``, it will store the number of errors found
  ## during the processing of the file. If this number is greater than zero,
  ## you can use `lr_safe_rst_string_to_html_error()
  ## <#lr_safe_rst_string_to_html_error>`_ to retrieve their text. Example:
  ##
  ## .. code-block:: c
  ##   char *s = lr_safe_rst_string_to_html(
  ##      valid_rst_string, "<filename>", 0, 0);
  ##   assert(s);
  ##   // Do here something with `s`.
  override_config()
  let
    filename = filename.nil_string
    data = data.nil_string
  C.errors_safe_rst_string_to_html = @[]

  C.ret_safe_rst_string_to_html = data.safe_rst_string_to_html(filename,
    C.errors_safe_rst_string_to_html.addr, config,
    global_find_file_handler(), global_msg_handler())

  result = C.ret_safe_rst_string_to_html.nil_cstring
  if ERRORS.not_nil:
    ERRORS[] = C.errors_safe_rst_string_to_html.len.cint


proc lr_safe_rst_string_to_html_error*(pos: cint): cstring
    {.exportc, raises: [].} =
  ## Returns error strings for `lr_safe_rst_string_to_html()
  ## <#lr_safe_rst_string_to_html>`_.
  ##
  ## If a previous call to `lr_safe_rst_string_to_html()
  ## <#lr_safe_rst_string_to_html>`_ produced errors and you captured them
  ## through the `ERRORS` parameter, you can call this function in a loop up to
  ## the returned value -1 to figure out the reasons.
  ##
  ## Returns the string for the specified error position or null if there was
  ## any error (eg. `pos` is an invalid index). You may need to copy the
  ## returned error string, since its memory could be freed by the next call to
  ## `lr_safe_rst_string_to_html() <#lr_safe_rst_string_to_html>`_. Example:
  ##
  ## .. code-block:: c
  ##   int errors = 666;
  ##   char *s = lr_safe_rst_string_to_html(
  ##      "<filename>", bad_rst_string, &errors, 0);
  ##   assert(s);
  ##   if (errors) {
  ##      printf("RST error stack trace:\n");
  ##      while (errors) {
  ##         printf("\t%s\n",
  ##            lr_safe_rst_string_to_html_error(--errors));
  ##      }
  ##   }
  ##   // Still, do here something with `s`.
  if C.errors_safe_rst_string_to_html.is_nil or pos < 0 or
      pos >= C.errors_safe_rst_string_to_html.len:
    return

  result = C.errors_safe_rst_string_to_html[pos].nil_cstring


proc lr_safe_rst_file_to_html*(filename: cstring, ERRORS: ptr cint,
    config: PStringTable): cstring {.exportc, raises: [].} =
  ## Wraps `safe_rst_file_to_html() <lazy_rest.html#safe_rst_file_to_html>`_
  ## for C.
  ##
  ## Returns always a valid ``cstring`` with HTML. The memory of the returned
  ## ``cstring`` will be kept until the next call to this function, you may
  ## need to copy it somewhere.
  ##
  ## If `ERRORS` is not ``null``, it will store the number of errors found
  ## during the processing of the file. If this number is greater than zero,
  ## you can use `lr_safe_rst_file_to_html_error()
  ## <#lr_safe_rst_file_to_html_error>`_ to retrieve their text. Example:
  ##
  ## .. code-block:: c
  ##   char *s = lr_safe_rst_file_to_html(
  ##      valid_rst_filename, 0, 0);
  ##   assert(s);
  ##   // Do here something with `s`.
  override_config()
  let filename = filename.nil_string
  C.errors_safe_rst_file_to_html = @[]

  C.ret_safe_rst_file_to_html = safe_rst_file_to_html(filename,
    C.errors_safe_rst_file_to_html.addr, config,
    global_find_file_handler(), global_msg_handler())

  result = C.ret_safe_rst_file_to_html.nil_cstring
  if ERRORS.not_nil:
    ERRORS[] = C.errors_safe_rst_file_to_html.len.cint


proc lr_safe_rst_file_to_html_error*(pos: cint): cstring
    {.exportc, raises: [].} =
  ## Returns error strings for `lr_safe_rst_file_to_html()
  ## <#lr_safe_rst_file_to_html>`_.
  ##
  ## If a previous call to `lr_safe_rst_file_to_html()
  ## <#lr_safe_rst_file_to_html>`_ produced errors and you captured them
  ## through the `ERRORS` parameter, you can call this function in a loop up to
  ## the returned value -1 to figure out the reasons.
  ##
  ## Returns the string for the specified error position or null if there was
  ## any error (eg. `pos` is an invalid index). You may need to copy the
  ## returned error string, since its memory could be freed by the next call to
  ## `lr_safe_rst_file_to_html() <#lr_safe_rst_file_to_html>`_. Example:
  ##
  ## .. code-block:: c
  ##   int errors = 666;
  ##   char *s = lr_safe_rst_file_to_html(
  ##      bad_rst_filename, &errors, 0);
  ##   assert(s);
  ##   if (errors) {
  ##      printf("RST error stack trace:\n");
  ##      while (errors) {
  ##         printf("\t%s\n",
  ##            lr_safe_rst_string_to_html_error(--errors));
  ##      }
  ##   }
  ##   // Still, do here something with `s`.
  ##
  if C.errors_safe_rst_file_to_html.is_nil or pos < 0 or
      pos >= C.errors_safe_rst_file_to_html.len:
    return

  result = C.errors_safe_rst_file_to_html[pos].nil_cstring


proc lr_source_string_to_html*(content, filename, language: cstring,
    number_lines: cint, config: PStringTable): cstring {.exportc, raises: [].} =
  ## Wraps `source_string_to_html() <lazy_rest.html#source_string_to_html>`_
  ## for C.
  ##
  ## The Nimrod boolean parameter is replaced by an ``int`` (non zero ==
  ## ``true``). The memory of the returned ``cstring`` will be kept until the
  ## next call to this function, you may need to copy it somewhere. Example:
  ##
  ## .. code-block:: c
  ##   char *s = lr_source_string_to_html(buf, "file.nim", 0, 1, 0);
  ##   // Do here something useful with `s`.
  override_config()
  let
    content = content.nil_string
    filename = filename.nil_string
    language = language.nil_string
    number_lines = if number_lines != 0: true else: false
  C.ret_source_string_to_html = source_string_to_html(content, filename,
    language, number_lines, config)
  result = C.ret_source_string_to_html.nil_cstring


proc lr_source_file_to_html*(filename: cstring, language: cstring,
    number_lines: cint, config: PStringTable): cstring {.exportc, raises: [].} =
  ## Wraps `source_file_to_html() <lazy_rest.html#source_file_to_html>`_ for C.
  ##
  ## The Nimrod boolean parameter is replaced by an ``int`` (non zero ==
  ## ``true``). The memory of the returned ``cstring`` will be kept until the
  ## next call to this function, you may need to copy it somewhere. Example:
  ##
  ## .. code-block:: c
  ##   char *s = lr_source_file_to_html("file.nim", 0, 1, 0);
  ##   // Do here something useful with `s`.
  override_config()
  let
    filename = filename.nil_string
    language = language.nil_string
    number_lines = if number_lines != 0: true else: false
  C.ret_source_file_to_html = source_file_to_html(filename,
    language, number_lines, config)
  result = C.ret_source_file_to_html.nil_cstring


proc lr_set_normal_error_rst*(input_rst: cstring, config: PStringTable): cint
    {.exportc, raises: [].} =
  ## Exports `set_normal_error_rst() <lazy_rest.html#set_normal_error_rst>`_
  ## for C.
  ##
  ## The C API returns the number of errors instead of the list of error
  ## messages. If you got a zero, this means success. Otherwise you can use
  ## `lr_set_normal_error_rst_error() <#lr_set_normal_error_rst_error>`_ in a
  ## loop to retrieve the individual error messages. Example:
  ##
  ## .. code-block:: c
  ##   lr_set_normal_error_rst(normal_error_rst);
  override_config()
  let input_rst = input_rst.nil_string
  C.ret_set_normal_error_rst = set_normal_error_rst(input_rst, config)
  result = C.ret_set_normal_error_rst.len.cint


proc lr_set_normal_error_rst_error*(pos: cint): cstring
    {.exportc, raises: [].} =
  ## Returns error strings for `lr_set_normal_error_rst()
  ## <#lr_set_normal_error_rst>`_.
  ##
  ## If a previous call to `lr_set_normal_error_rst()
  ## <#lr_set_normal_error_rst>`_ did return non zero, you can call this
  ## function in a loop up to the returned value -1 to figure out the reasons.
  ##
  ## Returns the string for the specified error position or null if there was
  ## any error (eg. `pos` is an invalid index). You may need to copy the
  ## returned error string, since its memory could be freed by the next call to
  ## `lr_set_normal_error_rst() <#lr_set_normal_error_rst>`_. Example:
  ##
  ## .. code-block:: c
  ##   int errors = lr_set_normal_error_rst(bad_rst_string);
  ##   if (errors) {
  ##      printf("Could not set normal error rst!\n");
  ##      while (errors) {
  ##         printf("\t%s\n",
  ##            lr_set_normal_error_rst_error(--errors));
  ##      }
  ##   }
  if C.ret_set_normal_error_rst.is_nil or pos < 0 or
      pos >= C.ret_set_normal_error_rst.len:
    return

  result = C.ret_set_normal_error_rst[pos].nil_cstring


proc lr_set_safe_error_rst*(input_rst: cstring, config: PStringTable): cint
    {.exportc, raises: [].} =
  ## Exports `set_safe_error_rst() <lazy_rest.html#set_safe_error_rst>`_ for C.
  ##
  ## The C API returns the number of errors instead of the list of error
  ## messages. If you got a zero, this means success. Otherwise you can use
  ## `lr_set_safe_error_rst_error() <#lr_set_safe_error_rst_error>`_ in a loop
  ## to retrieve the individual error messages. Example:
  ##
  ## .. code-block:: c
  ##   lr_set_safe_error_rst(safe_error_rst);
  override_config()
  let input_rst = input_rst.nil_string
  C.ret_set_safe_error_rst = set_safe_error_rst(input_rst, config)
  result = C.ret_set_safe_error_rst.len.cint


proc lr_set_safe_error_rst_error*(pos: cint): cstring
    {.exportc, raises: [].} =
  ## Returns error strings for `lr_set_safe_error_rst()
  ## <#lr_set_safe_error_rst>`_.
  ##
  ## If a previous call to `lr_set_safe_error_rst() <#lr_set_safe_error_rst>`_
  ## did return non zero, you can call this function in a loop up to the
  ## returned value -1 to figure out the reasons.
  ##
  ## Returns the string for the specified error position or null if there was
  ## any error (eg. `pos` is an invalid index). You may need to copy the
  ## returned error string, since its memory could be freed by the next call to
  ## `lr_set_safe_error_rst() <#lr_set_safe_error_rst>`_. Example:
  ##
  ## .. code-block:: c
  ##   int errors = lr_set_safe_error_rst(bad_rst_string);
  ##   if (errors) {
  ##      printf("Could not set safe error rst!\n");
  ##      while (errors) {
  ##         printf("\t%s\n",
  ##            lr_set_safe_error_rst_error(--errors));
  ##      }
  ##   }
  if C.ret_set_safe_error_rst.is_nil or pos < 0 or
      pos >= C.ret_set_safe_error_rst.len:
    return

  result = C.ret_set_safe_error_rst[pos].nil_cstring
