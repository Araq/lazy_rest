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

const
  c_source = slurp("c_test.c")
  error_template = slurp("../errors/custom_default_error.rst")
  special_options = slurp("../runtime_change/special.cfg")

{.emit:c_source.}

proc run_tests*() =
  let
    e = error_template.cstring
    o = special_options.cstring
  {.emit:"""run_c_test(`e`, `o`);""".}
