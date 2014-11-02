import lazy_rest

const rst_files = [
  "simple_include_01", "recursion_base", "complex_recursion_a",
  "relative", "absolute_unix", "absolute_windows",
  ]

proc test() =
  for name in rst_files:
    let
      src = name & ".rst"
      dest = name & ".html"
    dest.writeFile(src.safe_rst_file_to_html)

when isMainModule: test()
