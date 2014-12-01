import
  lazy_rest, os, strutils


proc docstring_rst_string_to_html() =
  # Modify the configuration template to render embeddable HTML.
  var config = new_rst_config()
  config[lrc_render_template] = "$" & lrk_render_content
  let
    input_rst = "*Hello* **world**!"
    html = input_rst.rst_string_to_html(user_config = config)
  #echo html
  assert html == "<em>Hello</em> <strong>world</strong>!"
  # --> "<em>Hello</em> <strong>world</strong>!"


proc docstring_rst_file_to_html() =
  # Modify the configuration template to render embeddable HTML.
  let filename = ".."/"code_blocks"/"anon.rst"
  let html = filename.rst_file_to_html
  assert html.find("<p>Let's see how") > 0


proc docstring_safe_rst_string_to_html() =
  let
    rst = "*Hello* **world**!"
    name = "something.rst"
  #echo safe_rst_string_to_html(nil, rst)
  # --> dumps HTML saying something bad happened.
  var ERRORS: seq[string] = @[]
  let html = safe_rst_string_to_html(name, rst, ERRORS.addr)
  if ERRORS.len > 0:
    # We got HTML, but it won't be nice.
    for error in ERRORS: echo error
    discard
  else:
    # Yay, use `html` without worries.


proc docstring_safe_rst_file_to_html() =
  let filename = ".."/"code_blocks"/"anon.rst"
  #echo safe_rst_file_to_html(nil)
  # --> dumps HTML saying something bad happened.
  var ERRORS: seq[string] = @[]
  let html = safe_rst_file_to_html(filename, ERRORS.addr)
  if ERRORS.len > 0:
    # We got HTML, but it it won't be nice.
    for error in ERRORS: echo error
    discard
  else:
    filename.change_file_ext("html").write_file(html)


proc docstring_source_string_to_html() =
  let c_source = """#include <stdio.h>
    int main(void) { printf("Hello test!\n"); }"""
  write_file("hello.html",
    c_source.source_string_to_html("hello.c"))


proc docstring_source_file_to_html() =
  let filename = "hello.c"
  write_file("hello.html", filename.source_file_to_html)


proc test() =
  docstring_rst_string_to_html()
  docstring_rst_file_to_html()
  docstring_safe_rst_string_to_html()
  docstring_safe_rst_file_to_html()
  docstring_source_string_to_html()
  docstring_source_file_to_html()


when isMainModule:
  test()
  echo "Test finished successfully"
