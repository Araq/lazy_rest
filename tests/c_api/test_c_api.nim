import lazy_rest_c_api

## Test for the C API of lazy_rest.
##
## Don't be fooled, despite this being a Nimrod program, it actually contains
## little Nimrod code. The single proc of this test just emits lots of C code.
## The reason for testing C code through the emit pragma is that it leaves us a
## cross platform portable way of running and invoking C compilers leveraging
## the work that has already been done for Nimrod itself.
##
## Since writing all C code embedded inside the emit pragma is quite painful we
## use slurp the get real C code from an external file which allows our puny
## editors to syntax highlight it properly.

const c_source = slurp("test_c_api.c")

{.emit:c_source.}

proc run_tests() = {.emit:"""run_c_test();""".}

when isMainModule:
  run_tests()
  echo "Test finished successfully"
