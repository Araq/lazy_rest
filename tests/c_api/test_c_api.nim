import lazy_rest_c_api, c_test, lazy_rest

proc ignore_msg_handler*(filename: string, line, col: int,
    msgkind: TMsgKind, arg: string): string {.procvar, raises: [], exportc.} =
  ## Custom handler to ignore all errors, used in the C source code.
  discard

when isMainModule:
  run_tests()
  echo "Test finished successfully"
