import
  lazy_rest, strutils, os, sequtils


const
  out_dir = "output"
  special_index = out_dir/"special.index"


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
  config[lrc_render_write_index_auto] = "t"

  # First generate the normal HTML, which may produce errors.
  echo dest_default
  var ERRORS: seq[string] = @[]
  let default_html = content.safe_rst_string_to_html(filename,
    ERRORS.addr, config)
  dest_default.write_file(default_html)

  # Now generate a default config with the option set to true.
  config[config_option] = "t"
  config[lrc_render_write_index_auto] = "" # Disable automatic index…
  # …and if there were errors, force a specific filename index.
  if ERRORS.len > 0:
    config[lrc_render_write_index_filename] = special_index

  echo dest_tweaked
  let tweaked_html = content.safe_rst_string_to_html(filename,
    user_config = config)
  dest_tweaked.write_file(tweaked_html)

  # The output HTML should be different in all cases.
  assert tweaked_html != default_html


proc test() =
  out_dir.create_dir
  for rst in walk_files("*.rst"):
    process(rst)
  # Verify that we got three normal indices, one special.
  doAssert len(to_seq(walk_files("*.idx"))) == 3
  doAssert special_index.exists_file


when isMainModule:
  test()
  echo "Test finished successfully"
