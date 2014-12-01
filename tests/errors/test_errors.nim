import
  lazy_rest, strutils, os, strtabs

type Pair = tuple[src, dest: string]

const
  tests = ["unknown.rst", "rst_error.rst", "evil_asterisks.rst"]
  templates = [
    "default_error_html_template.rst", "safe_error_html_template.rst",
    "custom_default_error.rst", "custom_safe_error.rst"]
  out_dir = "output"


proc test_safe_procs(file_prefix: string, config: PStringTable) =
  # First test without error control.
  for src in tests:
    let dest = file_prefix & src.change_file_ext("html")
    dest.write_file(src.safe_rst_file_to_html(user_config = config))
    do_assert dest.exists_file

  # Now do some in memory checks.
  discard safe_rst_file_to_html(nil)
  discard safe_rst_file_to_html("")
  discard safe_rst_string_to_html(nil, "Or was it `single quotes?")
  discard safe_rst_string_to_html("<", "Or was < it `single quotes?")
  try: discard safe_rst_string_to_html(nil, nil)
  except EAssertionFailed: discard

  var errors: seq[string]
  # Repeat counting errors.
  for src in tests:
    let dest = file_prefix & src.change_file_ext("html")
    errors = @[]
    dest.write_file(src.safe_rst_file_to_html(errors.addr,
      user_config = config))
    do_assert dest.exists_file
    do_assert errors.len > 0
    echo "Ignore this: ", errors[0]

  # Now do some in memory checks.
  errors = @[]
  discard safe_rst_file_to_html(nil, errors.addr)
  do_assert errors.len > 0
  echo "Ignore this: ", errors[0]
  errors = @[]
  discard safe_rst_file_to_html("", errors.addr)
  do_assert errors.len > 0
  echo "Ignore this: ", errors[0]
  errors = @[]
  discard safe_rst_string_to_html(nil, "Or was it `single quotes?")
  do_assert errors.len < 1
  discard safe_rst_string_to_html("<", "Or was < it `single quotes?")
  do_assert errors.len < 1


proc docstrings() =
  ## Stuff demostrated in the embedded documentation.
  const rst = "hello `world"
  discard safe_rst_string_to_html(nil, rst)
  var errors: seq[string] = @[]
  let html = safe_rst_string_to_html(nil, rst, errors.addr)
  if errors.len > 0: discard
  else: discard

  const rst_filename = "invisible.rst"
  discard safe_rst_file_to_html(rst_filename)
  errors = @[]
  let html2 = safe_rst_file_to_html(rst_filename, errors.addr)
  do_assert errors.len > 0


proc build_template() =
  ## Generates the HTML for embedding as error template.
  for src in templates:
    let dest = src.change_file_ext("html")
    dest.write_file(src.safe_rst_file_to_html)
    do_assert dest.exists_file


proc render_errors(prefix: string) =
  test_safe_procs(prefix & "normal_subex_errors_", nil)
  var config = newStringTable(modeStyleInsensitive)
  config[lrc_render_failure_test] = lrd_render_failure_test
  test_safe_procs(prefix & "forced_subex_errors_", config)

proc run_tests() =
  out_dir.create_dir
  build_template()
  docstrings()

  # Set the error templates.
  var raw_config = new_rst_config()
  raw_config["parser.enable.raw.directive"] = "true"
  var errors = set_normal_error_rst(
    read_file("custom_default_error.rst"), raw_config)
  doAssert errors.len < 1
  errors = set_safe_error_rst(read_file("custom_safe_error.rst"), raw_config)
  doAssert errors.len < 1
  render_errors(out_dir/"custom_")

  errors = set_normal_error_rst("")
  doAssert errors.len < 1
  errors = set_safe_error_rst(nil)
  doAssert errors.len < 1
  render_errors(out_dir/"default_")


when isMainModule:
  run_tests()
  echo "Test finished successfully"
