import lazy_rest

## Exported C API of `lazy_rest <https://github.com/gradha/lazy_rest>`_ a
## reStructuredText processing module for Nimrod.
##
## These are simple Nimrod wrappers around the main `lazy_rest.nim
## <../lazy_rest.html>`_ module. They just document and export to C the most
## interesting procs to be consumed by other C programs.

proc txt_to_rst*(input_filename: cstring): int {.exportc, raises: [].}=
  ## Converts the input filename.
  ##
  ## The conversion is stored in internal global variables. The proc returns
  ## the number of bytes required to store the generated HTML, which you can
  ## obtain using the global accessor `get_global_html() <#get_global_html>`_
  ## passing a pointer to the buffer.
  ##
  ## The returned value doesn't include the typical C null terminator. If there
  ## are problems, an internal error text may be returned so it can be
  ## displayed to the end user. As such, it is impossible to know the
  ## success/failure based on the returned value.
  ##
  ## This proc is mainly for the C api.
  assert input_filename.not_nil
  let filename = $input_filename
  case filename.splitFile.ext
  of ".nim":
    G.last_c_conversion = nim_file_to_html(filename)
  else:
    G.last_c_conversion = safe_rst_file_to_html(filename)
  result = G.last_c_conversion.len


proc get_global_html*(output_buffer: pointer) {.exportc, raises: [].} =
  ## Copies the result of txt_to_rst into output_buffer.
  ##
  ## If output_buffer doesn't contain the bytes returned by txt_to_rst, you
  ## will pay that dearly!
  ##
  ## This proc is mainly for the C api.
  if G.last_c_conversion.is_nil:
    quit("Uh oh, wrong API usage")
  copyMem(output_buffer, addr(G.last_c_conversion[0]), G.last_c_conversion.len)
