import
  lazy_rest, os, strutils


proc docstring_rst_string_to_html() =
  # Modify the configuration template to render embeddable HTML.
  var config = new_rst_config()
  config[lrc_render_template] = "$" & lrk_render_content
  let
    input_rst = "*Hello* **world**!"
    html = input_rst.rst_string_to_html(user_config = config)
  echo html
  assert html == "<em>Hello</em> <strong>world</strong>!"
  # --> "<em>Hello</em> <strong>world</strong>!"


proc docstring_rst_file_to_html() =
  # Modify the configuration template to render embeddable HTML.
  let filename = ".."/"code_blocks"/"anon.rst"
  let html = filename.rst_file_to_html
  assert html.find("<p>Let's see how") > 0


proc test() =
  docstring_rst_string_to_html()
  docstring_rst_file_to_html()


when isMainModule:
  test()
  echo "Test finished successfully"
