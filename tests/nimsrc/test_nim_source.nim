import lazy_rest, strutils, os

proc test() =
  var count = 0
  for path in walk_files("../../lazy_rest_pkg/*.nim"):
    let
      filename = path.extract_filename.change_file_ext("html")
      with_numbers = "numbers_" & filename
      without_numbers = "plain_" & filename

    with_numbers.write_file(path.nim_file_to_html(number_lines = true))
    without_numbers.write_file(path.nim_file_to_html(number_lines = false))
    count.inc

  echo "Did render ", count, " nim files."
  doAssert 6 == count, "Number of nim files didn't match, did you add some?"

when isMainModule:
  test()
  echo "Test finished successfully"
