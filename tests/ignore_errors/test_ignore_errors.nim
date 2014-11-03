import lazy_rest, os, strutils

## This test verifies that parsing of the document can happen despite a custom
## message handler not raising errors when they are encountered. The generated
## output also helps to see what would be produced in these cases.

proc setup() =
  copy_file_with_permissions(".."/"errors"/"evil_asterisks.rst",
    "evil_asterisks.rst")


proc custom_msg_handler(filename: string, line, col: int,
    msgkind: TMsgKind, arg: string) {.procvar, raises:[].} =
  let mc = msgkind.whichMsgClass
  var message = filename & "(" & $line & ", " & $col & ") " & $mc
  try:
    let reason = rst_messages[msgkind] % arg
    message.add(": " & reason)
  except EInvalidValue:
    discard

  if mc == mcError:
    echo "Ignoring ", message


proc run_tests() =
  setup()
  for rst_file in walk_files("*.rst"):
    let dest = rst_file.change_file_ext(".html")
    dest.write_file(rst_file.rst_file_to_html(msg_handler = custom_msg_handler))


when isMainModule:
  run_tests()
  echo "Test finished successfully"
