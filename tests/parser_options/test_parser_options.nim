import
  lazy_rest, strutils, lazy_rest_pkg/lconfig, os


const
  out_dir = "output"


proc process(filename: string) =
  # Runs the normal and special tests on the specified file.
  let
    content = filename.read_file
    (dir, name, ext) = filename.split_file
    config_option = name.replace('_', '.')
    dest_default = out_dir/name & "_default.html"
    dest_tweaked = out_dir/name & "_tweaked.html"
  # First generate the normal HTML, which may produce errors.
  echo dest_default
  dest_default.write_file(safe_rst_string_to_html(filename, content))

  # Now generate a default config with the option set to true.
  var config = new_rst_config()
  config[config_option] = "t"
  echo dest_tweaked
  dest_tweaked.write_file(safe_rst_string_to_html(filename,
    content, user_config = config))


proc test() =
  out_dir.create_dir
  for rst in walk_files("*.rst"):
    process(rst)


when isMainModule:
  test()
  echo "Test finished successfully"
