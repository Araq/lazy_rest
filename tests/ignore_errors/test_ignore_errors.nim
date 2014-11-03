import lazy_rest, os, strutils


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
