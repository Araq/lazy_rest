import lazy_rest, external/badger_bits/bb_system, strtabs

## Exported C API of `lazy_rest <https://github.com/gradha/lazy_rest>`_ a
## reStructuredText processing module for Nimrod.
##
## These are simple Nimrod wrappers around the main `lazy_rest.nim
## <lazy_rest.html>`_ module. They just document and export for C the most
## interesting procs to be consumed by other C programs.
##
## TODO: mention threading issues, and maybe NimMain initialisation.

type
  C_state = object
    last_c_conversion: string ## Modified by the exported C API procs.
    ret_set_normal_error_rst: seq[string] ## Last result of the proc \
    ## wrapped by lazy_rest_set_normal_error_rst.
    ret_set_safe_error_rst: seq[string] ## Last result of the proc \
    ## wrapped by lazy_rest_set_safe_error_rst.
    ret_nim_file_to_html: string ## Last result of the proc wrapped by \
    ## lazy_rest_nim_file_to_html.
    ret_safe_rst_file_to_html: string ## Last result of the proc wrapped by \
    ## lazy_rest_safe_rst_file_to_html.
    errors_safe_rst_file_to_html: seq[string] ## Last errors of the proc \
    ## wrapped by lazy_rest_safe_rst_file_to_html.
    ret_safe_rst_string_to_html: string ## Last result of the proc wrapped by \
    ## lazy_rest_safe_rst_string_to_html.
    errors_safe_rst_string_to_html: seq[string] ## Last errors of the proc \
    ## wrapped by lazy_rest_safe_rst_string_to_html.
    ret_rst_file_to_html: string ## Last result of the proc wrapped by \
    ## lazy_rest_rst_file_to_html.
    error_rst_file_to_html: ref E_Base ## Last error of the proc \
    ## wrapped by lazy_rest_rst_file_to_html.
    ret_rst_string_to_html: string ## Last result of the proc wrapped by \
    ## lazy_rest_rst_string_to_html.
    error_rst_string_to_html: ref E_Base ## Last error of the proc \
    ## wrapped by lazy_rest_rst_string_to_html.


var C: C_state


proc lazy_rest_rst_string_to_html*(content, filename: cstring,
    config: PStringTable): cstring {.exportc, raises: [].} =
  ## Wraps `rst_string_to_html() <lazy_rest.html#rst_string_to_html>`_ for C.
  ##
  ## Returns a ``cstring`` with HTML or a ``null`` pointer if there were
  ## errors.  In case of errors you can call
  ## `lazy_rest_rst_string_to_html_error()
  ## <#lazy_rest_rst_string_to_html_error>`_ to retrieve the description, which
  ## will be the text of the Nimrod exception.
  ##
  ## The memory of the returned ``cstring`` will be kept until the next call to
  ## this function, you may need to copy it somewhere.
  let
    filename = filename.nil_string
    content = content.nil_string
  C.ret_rst_string_to_html = nil

  try:
    C.ret_rst_string_to_html = rst_string_to_html(content, filename, config)
    result = C.ret_rst_string_to_html.nil_cstring
  except:
    C.error_rst_string_to_html = get_current_exception()


proc lazy_rest_rst_string_to_html_error*(): cstring {.exportc, raises: [].} =
  ## Returns the error string for `lazy_rest_rst_string_to_html()
  ## <#lazy_rest_rst_string_to_html>`_.
  ##
  ## If a previous call to `lazy_rest_rst_string_to_html()
  ## <#lazy_rest_rst_string_to_html>`_ returned ``null`` you can call this
  ## function to retrieve a textual reason for the failure.
  ##
  ## Returns the error string or ``null`` if there was no previous error. You
  ## may need to copy the returned error string, since its memory could be
  ## freed by the next call to `lazy_rest_rst_string_to_html()
  ## <#lazy_rest_rst_string_to_html>`_.
  if C.error_rst_string_to_html.not_nil:
    result = C.error_rst_string_to_html.msg.nil_cstring


proc lazy_rest_rst_file_to_html*(filename: cstring, config: PStringTable):
    cstring {.exportc, raises: [].} =
  ## Wraps `rst_file_to_html() <lazy_rest.html#rst_file_to_html>`_ for C.
  ##
  ## Returns a ``cstring`` with HTML or a ``null`` pointer if there were
  ## errors.  In case of errors you can call
  ## `lazy_rest_rst_file_to_html_error() <#lazy_rest_rst_file_to_html_error>`_
  ## to retrieve the description, which will be the text of the Nimrod
  ## exception.
  ##
  ## The memory of the returned ``cstring`` will be kept until the next call to
  ## this function, you may need to copy it somewhere.
  let filename = filename.nil_string
  C.ret_rst_file_to_html = nil

  try:
    C.ret_rst_file_to_html = rst_file_to_html(filename, config)
    result = C.ret_rst_file_to_html.nil_cstring
  except:
    C.error_rst_file_to_html = get_current_exception()


proc lazy_rest_rst_file_to_html_error*(): cstring {.exportc, raises: [].} =
  ## Returns the error string for `lazy_rest_rst_file_to_html()
  ## <#lazy_rest_rst_file_to_html>`_.
  ##
  ## If a previous call to `lazy_rest_rst_file_to_html()
  ## <#lazy_rest_rst_file_to_html>`_ returned ``null`` you can call this
  ## function to retrieve a textual reason for the failure.
  ##
  ## Returns the error string or ``null`` if there was no previous error. You
  ## may need to copy the returned error string, since its memory could be
  ## freed by the next call to `lazy_rest_rst_file_to_html()
  ## <#lazy_rest_rst_file_to_html>`_.
  if C.error_rst_file_to_html.not_nil:
    result = C.error_rst_file_to_html.msg.nil_cstring


proc lazy_rest_safe_rst_string_to_html*(filename, data: cstring,
    ERRORS: ptr int, config: PStringTable):
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
  ## you can use `lazy_rest_safe_rst_string_to_html_error()
  ## <#lazy_rest_safe_rst_string_to_html_error>`_ to retrieve their text.
  let
    filename = filename.nil_string
    data = data.nil_string
  C.errors_safe_rst_string_to_html = @[]

  C.ret_safe_rst_string_to_html = safe_rst_string_to_html(filename, data,
    C.errors_safe_rst_string_to_html.addr, config)

  result = C.ret_safe_rst_string_to_html.nil_cstring
  if ERRORS.not_nil:
    ERRORS[] = C.errors_safe_rst_string_to_html.len


proc lazy_rest_safe_rst_string_to_html_error*(pos: int): cstring
    {.exportc, raises: [].} =
  ## Returns error strings for `lazy_rest_safe_rst_string_to_html()
  ## <#lazy_rest_safe_rst_string_to_html>`_.
  ##
  ## If a previous call to `lazy_rest_safe_rst_string_to_html()
  ## <#lazy_rest_safe_string_to_html>`_ produced errors and you captured them
  ## through the `ERRORS` parameter, you can call this function in a loop up to
  ## the returned value -1 to figure out the reasons.
  ##
  ## Returns the string for the specified error position or null if there was
  ## any error (eg. `pos` is an invalid index). You may need to copy the
  ## returned error string, since its memory could be freed by the next call to
  ## `lazy_rest_safe_rst_string_to_html()
  ## <#lazy_rest_safe_rst_string_to_html>`_.
  if C.errors_safe_rst_string_to_html.is_nil or pos < 0 or
      pos >= C.errors_safe_rst_string_to_html.len:
    return

  result = C.errors_safe_rst_string_to_html[pos].nil_cstring


proc lazy_rest_safe_rst_file_to_html*(filename: cstring, ERRORS: ptr int,
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
  ## you can use `lazy_rest_safe_rst_file_to_html_error()
  ## <#lazy_rest_safe_rst_file_to_html_error>`_ to retrieve their text.
  let filename = filename.nil_string
  C.errors_safe_rst_file_to_html = @[]

  C.ret_safe_rst_file_to_html = safe_rst_file_to_html(filename,
    C.errors_safe_rst_file_to_html.addr, config)

  result = C.ret_safe_rst_file_to_html.nil_cstring
  if ERRORS.not_nil:
    ERRORS[] = C.errors_safe_rst_file_to_html.len


proc lazy_rest_safe_rst_file_to_html_error*(pos: int): cstring
    {.exportc, raises: [].} =
  ## Returns error strings for `lazy_rest_safe_rst_file_to_html()
  ## <#lazy_rest_safe_rst_file_to_html>`_.
  ##
  ## If a previous call to `lazy_rest_safe_rst_file_to_html()
  ## <#lazy_rest_safe_rst_file_to_html>`_ produced errors and you captured them
  ## through the `ERRORS` parameter, you can call this function in a loop up to
  ## the returned value -1 to figure out the reasons.
  ##
  ## Returns the string for the specified error position or null if there was
  ## any error (eg. `pos` is an invalid index). You may need to copy the
  ## returned error string, since its memory could be freed by the next call to
  ## `lazy_rest_safe_rst_file_to_html() <#lazy_rest_safe_rst_file_to_html>`_.
  if C.errors_safe_rst_file_to_html.is_nil or pos < 0 or
      pos >= C.errors_safe_rst_file_to_html.len:
    return

  result = C.errors_safe_rst_file_to_html[pos].nil_cstring


proc lazy_rest_nim_file_to_html*(filename: cstring, number_lines: int,
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


proc lazy_rest_set_normal_error_rst*(input_rst: cstring): int
    {.exportc, raises: [].} =
  ## Exports `set_normal_error_rst() <lazy_rest.html#set_normal_error_rst>`_
  ## for C.
  ##
  ## The C API returns the number of errors instead of the list of error
  ## messages. If you got a zero, this means success. Otherwise you can use
  ## `lazy_rest_set_normal_error_rst_error()
  ## <#lazy_rest_set_normal_error_rst_error>`_ in a loop to retrieve the
  ## individual error messages.
  let input_rst = input_rst.nil_string
  C.ret_set_normal_error_rst = set_normal_error_rst(input_rst)
  result = C.ret_set_normal_error_rst.len


proc lazy_rest_set_normal_error_rst_error*(pos: int): cstring
    {.exportc, raises: [].} =
  ## Returns error strings for `lazy_rest_set_normal_error_rst()
  ## <#lazy_rest_set_normal_error_rst>`_.
  ##
  ## If a previous call to `lazy_rest_set_normal_error_rst()
  ## <#lazy_rest_set_normal_error_rst>`_ did return non zero, you can call this
  ## function in a loop up to the returned value -1 to figure out the reasons.
  ##
  ## Returns the string for the specified error position or null if there was
  ## any error (eg. `pos` is an invalid index). You may need to copy the
  ## returned error string, since its memory could be freed by the next call to
  ## `lazy_rest_set_normal_error_rst() <#lazy_rest_set_normal_error_rst>`_.
  if C.ret_set_normal_error_rst.is_nil or pos < 0 or
      pos >= C.ret_set_normal_error_rst.len:
    return

  result = C.ret_set_normal_error_rst[pos].nil_cstring


proc lazy_rest_set_safe_error_rst*(input_rst: cstring): int
    {.exportc, raises: [].} =
  ## Exports `set_safe_error_rst() <lazy_rest.html#set_safe_error_rst>`_ for C.
  ##
  ## The C API returns the number of errors instead of the list of error
  ## messages. If you got a zero, this means success. Otherwise you can use
  ## `lazy_rest_set_safe_error_rst_error()
  ## <#lazy_rest_set_safe_error_rst_error>`_ in a loop to retrieve the
  ## individual error messages.
  let input_rst = input_rst.nil_string
  C.ret_set_safe_error_rst = set_safe_error_rst(input_rst)
  result = C.ret_set_safe_error_rst.len


proc lazy_rest_set_safe_error_rst_error*(pos: int): cstring
    {.exportc, raises: [].} =
  ## Returns error strings for `lazy_rest_set_safe_error_rst()
  ## <#lazy_rest_set_safe_error_rst>`_.
  ##
  ## If a previous call to `lazy_rest_set_safe_error_rst()
  ## <#lazy_rest_set_safe_error_rst>`_ did return non zero, you can call this
  ## function in a loop up to the returned value -1 to figure out the reasons.
  ##
  ## Returns the string for the specified error position or null if there was
  ## any error (eg. `pos` is an invalid index). You may need to copy the
  ## returned error string, since its memory could be freed by the next call to
  ## `lazy_rest_set_safe_error_rst() <#lazy_rest_set_safe_error_rst>`_.
  if C.ret_set_safe_error_rst.is_nil or pos < 0 or
      pos >= C.ret_set_safe_error_rst.len:
    return

  result = C.ret_set_safe_error_rst[pos].nil_cstring


#proc txt_to_rst*(input_filename: cstring): int {.exportc, raises: [].}=
#  ## Converts the input filename.
#  ##
#  ## The conversion is stored in internal global variables. The proc returns
#  ## the number of bytes required to store the generated HTML, which you can
#  ## obtain using the global accessor `get_global_html() <#get_global_html>`_
#  ## passing a pointer to the buffer.
#  ##
#  ## The returned value doesn't include the typical C null terminator. If there
#  ## are problems, an internal error text may be returned so it can be
#  ## displayed to the end user. As such, it is impossible to know the
#  ## success/failure based on the returned value.
#  ##
#  ## This proc is mainly for the C api.
#  assert input_filename.not_nil
#  let filename = $input_filename
#  case filename.splitFile.ext
#  of ".nim":
#    G.last_c_conversion = nim_file_to_html(filename)
#  else:
#    G.last_c_conversion = safe_rst_file_to_html(filename)
#  result = G.last_c_conversion.len
#
#
#proc get_global_html*(output_buffer: pointer) {.exportc, raises: [].} =
#  ## Copies the result of txt_to_rst into output_buffer.
#  ##
#  ## If output_buffer doesn't contain the bytes returned by txt_to_rst, you
#  ## will pay that dearly!
#  ##
#  ## This proc is mainly for the C api.
#  if G.last_c_conversion.is_nil:
#    quit("Uh oh, wrong API usage")
#  copyMem(output_buffer, addr(G.last_c_conversion[0]), G.last_c_conversion.len)
