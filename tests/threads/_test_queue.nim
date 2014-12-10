import lazy_rest, lazy_rest_pkg/lqueues, sequtils, bb_os

const
  input_files = ["nimrod_doc"/"manual.txt"]

proc test() =
  var
    file_test = input_files.map_it(Rest_task, it.rst_file_task)
    string_test = input_files.map_it(Rest_task, it.rst_string_task)
  echo file_test
  echo string_test
  # TODO: Remove dummy call to force log creation.
  discard rst_string_to_html("", "")
  file_test.render
  string_test.render

when isMainModule:
  test()
  echo "Test finished successfully"
