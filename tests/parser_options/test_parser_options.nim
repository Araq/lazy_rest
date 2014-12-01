import
  lazy_rest, strutils, os


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
  # Build a default config which disables time stamps to avoid unit testing
  # spurious errors due to tests running in different seconds.
  var config = new_rst_config()
  config[lrc_render_date_format] = ""
  config[lrc_render_time_format] = ""
  config[lrc_render_local_date_format] = ""
  config[lrc_render_local_time_format] = ""

  # First generate the normal HTML, which may produce errors.
  echo dest_default
  let default_html = safe_rst_string_to_html(filename,
    content, user_config = config)
  dest_default.write_file(default_html)

  # Now generate a default config with the option set to true.
  config[config_option] = "t"
  echo dest_tweaked
  let tweaked_html = safe_rst_string_to_html(filename,
    content, user_config = config)
  dest_tweaked.write_file(tweaked_html)

  # The output HTML should be different in all cases.
  assert tweaked_html != default_html


proc test() =
  out_dir.create_dir
  for rst in walk_files("*.rst"):
    process(rst)


when isMainModule:
  test()
  echo "Test finished successfully"
