import lazy_rest, strutils

const
  special_config = slurp("special.cfg")
  nearly_empty_config = slurp("nearly_empty.cfg")
  expected_title = "Hello Rst!"
  expected_string = "Crayon pop rules"
  filename = "hello.rst"


proc count_instances(text, substring: string): int =
  ## Returns the number of times `substring` appears in `text`.
  var pos = text.find(substring)
  while pos >= 0:
    result += 1
    pos = text.find(substring, start = pos + substring.len)


proc normal_test() =
  # Expects the normal thing to happen.
  let
    normal_text = rst_file_to_html(filename)
    normal_count = normal_text.count_instances(expected_title)
  doAssert normal_text.find(expected_string) < 0
  doAssert normal_count == 2


proc special_test() =
  # Generates the file with a different configuration.
  let
    special_text = rst_file_to_html(filename, special_config.parse_rst_options)
    special_count = special_text.count_instances(expected_title)
  doAssert special_text.find(expected_string) > 0
  doAssert special_count == 4


proc empty_test() =
  # Runs with a nearly empty file, to verify the embedded one works.
  let text = filename.rst_file_to_html(nearly_empty_config.parse_rst_options)
  write_file("nearly_empty.html", text)


proc test() =
  normal_test()
  special_test()
  normal_test()
  empty_test()


when isMainModule:
  test()
  echo "Test finished successfully"
