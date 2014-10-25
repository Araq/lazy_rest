import lazy_rest, external/badger_bits/bb_system, strtabs

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
## then compile those into your C program.
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


type
  C_state = object
    error_rst_file_to_html: ref E_Base
    error_rst_string_to_html: ref E_Base
    errors_safe_rst_file_to_html: seq[string]
    errors_safe_rst_string_to_html: seq[string]
    ret_nim_file_to_html: string
    ret_parse_rst_options: PStringTable
    ret_rst_file_to_html: string
    ret_rst_string_to_html: string
    ret_safe_rst_file_to_html: string
    ret_safe_rst_string_to_html: string
    ret_set_normal_error_rst: seq[string]
    ret_set_safe_error_rst: seq[string]


var C: C_state


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
  ## Also, due to a limitation in Nimrod's exportc pragma, right now the
  ## ``PStringTable`` type will be exported to the C header like ``typedef
  ## struct tstringtable128812 tstringtable128812``, so it may be difficult or
  ## impossible to write crossplatform source code which calls this function,
  ## given that each platform's Nimrod compiler (or version) may generate a
  ## different symbol. Still, the function is here for completeness (and maybe
  ## you don't mind the weird ``typedef``).
  C.ret_parse_rst_options = parse_rst_options(options.nil_string)
  result = C.ret_parse_rst_options


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
  let
    filename = filename.nil_string
    content = content.nil_string
  C.ret_rst_string_to_html = nil
  C.error_rst_string_to_html = nil

  try:
    C.ret_rst_string_to_html = rst_string_to_html(content, filename, config)
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
  let filename = filename.nil_string
  C.ret_rst_file_to_html = nil
  C.error_rst_file_to_html = nil

  try:
    C.ret_rst_file_to_html = rst_file_to_html(filename, config)
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


proc lr_safe_rst_string_to_html*(filename, data: cstring,
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
  ## <#lr_safe_rst_string_to_html_error>`_ to retrieve their text.
  let
    filename = filename.nil_string
    data = data.nil_string
  C.errors_safe_rst_string_to_html = @[]

  C.ret_safe_rst_string_to_html = safe_rst_string_to_html(filename, data,
    C.errors_safe_rst_string_to_html.addr, config)

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
  ## `lr_safe_rst_string_to_html() <#lr_safe_rst_string_to_html>`_.
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
  ## <#lr_safe_rst_file_to_html_error>`_ to retrieve their text.
  let filename = filename.nil_string
  C.errors_safe_rst_file_to_html = @[]

  C.ret_safe_rst_file_to_html = safe_rst_file_to_html(filename,
    C.errors_safe_rst_file_to_html.addr, config)

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
  ## `lr_safe_rst_file_to_html() <#lr_safe_rst_file_to_html>`_.
  if C.errors_safe_rst_file_to_html.is_nil or pos < 0 or
      pos >= C.errors_safe_rst_file_to_html.len:
    return

  result = C.errors_safe_rst_file_to_html[pos].nil_cstring


proc lr_nim_file_to_html*(filename: cstring, number_lines: cint,
    config: PStringTable): cstring {.exportc, raises: [].} =
  ## Wraps `nim_file_to_html() <lazy_rest.html#nim_file_to_html>`_ for C.
  ##
  ## The Nimrod boolean parameter is replaced by an ``int`` (non zero ==
  ## ``true``). The memory of the returned ``cstring`` will be kept until the
  ## next call to this function, you may need to copy it somewhere.
  let
    filename = filename.nil_string
    number_lines = if number_lines != 0: true else: false
  C.ret_nim_file_to_html = nim_file_to_html(filename, number_lines, config)
  result = C.ret_nim_file_to_html.nil_cstring


proc lr_set_normal_error_rst*(input_rst: cstring): cint
    {.exportc, raises: [].} =
  ## Exports `set_normal_error_rst() <lazy_rest.html#set_normal_error_rst>`_
  ## for C.
  ##
  ## The C API returns the number of errors instead of the list of error
  ## messages. If you got a zero, this means success. Otherwise you can use
  ## `lr_set_normal_error_rst_error() <#lr_set_normal_error_rst_error>`_ in a
  ## loop to retrieve the individual error messages.
  let input_rst = input_rst.nil_string
  C.ret_set_normal_error_rst = set_normal_error_rst(input_rst)
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
  ## `lr_set_normal_error_rst() <#lr_set_normal_error_rst>`_.
  if C.ret_set_normal_error_rst.is_nil or pos < 0 or
      pos >= C.ret_set_normal_error_rst.len:
    return

  result = C.ret_set_normal_error_rst[pos].nil_cstring


proc lr_set_safe_error_rst*(input_rst: cstring): cint
    {.exportc, raises: [].} =
  ## Exports `set_safe_error_rst() <lazy_rest.html#set_safe_error_rst>`_ for C.
  ##
  ## The C API returns the number of errors instead of the list of error
  ## messages. If you got a zero, this means success. Otherwise you can use
  ## `lr_set_safe_error_rst_error() <#lr_set_safe_error_rst_error>`_ in a loop
  ## to retrieve the individual error messages.
  let input_rst = input_rst.nil_string
  C.ret_set_safe_error_rst = set_safe_error_rst(input_rst)
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
  ## `lr_set_safe_error_rst() <#lr_set_safe_error_rst>`_.
  if C.ret_set_safe_error_rst.is_nil or pos < 0 or
      pos >= C.ret_set_safe_error_rst.len:
    return

  result = C.ret_set_safe_error_rst[pos].nil_cstring
