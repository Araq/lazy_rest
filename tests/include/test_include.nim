import lazy_rest, os

const
  rst_files = [
    "simple_include_01", "recursion_base", "complex_recursion_a",
    "relative", "absolute_unix", "absolute_windows",
    ]
  flattened_files = ["flattened_includes"]


proc flattened_find_file(ignored, target_filename: string):
    string {.procvar, raises:[].} =
  let target = target_filename.extract_filename
  if target.exists_file:
    result = target


proc test() =
  # Normal includes.
  for name in rst_files:
    let
      src = name & ".rst"
      dest = name & ".html"
    dest.write_file(src.safe_rst_file_to_html)

  # Flattened ones.
  for name in flattened_files:
    let
      src = name & ".rst"
      dest = name & ".html"
    dest.write_file(src.safe_rst_file_to_html(find_file = flattened_find_file))


when isMainModule: test()
