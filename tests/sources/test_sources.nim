import lazy_rest, strutils, os

const
  out_dir = "output"

proc render_nim_files() =
  var count = 0
  for path in walk_files("../../lazy_rest_pkg/*.nim"):
    let
      name = path.split_file.name
      with_numbers = out_dir/name & "_numbers.html"
      without_numbers = out_dir/name & "_plain.html"

    with_numbers.write_file(path.source_file_to_html(number_lines = true))
    without_numbers.write_file(path.source_file_to_html(number_lines = false))
    count.inc

  echo "Did render ", count, " nim files."
  doAssert 6 == count, "Number of nim files didn't match, did you add some?"


proc render_misc_files() =
  var count = 0
  for path in walk_files("source.*"):
    var ext = path.split_file.ext
    ext.delete(0, 0)
    let
      with_numbers = out_dir/"source_" & ext & "_numbers.html"
      without_numbers = out_dir/"source_" & ext & "_plain.html"

    with_numbers.write_file(path.source_file_to_html(number_lines = true))
    without_numbers.write_file(path.source_file_to_html(number_lines = false))
    count.inc

  echo "Did render ", count, " misc files."


proc test() =
  out_dir.create_dir
  render_nim_files()
  render_misc_files()


when isMainModule:
  test()
  echo "Test finished successfully"
