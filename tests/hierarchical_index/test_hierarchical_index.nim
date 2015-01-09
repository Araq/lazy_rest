import lazy_rest, strutils, os, nake, lazy_rest_pkg/lrstgen, sequtils


proc mangle_idx(filename, prefix: string): string =
  ## Reads `filename` and returns it as a string with `prefix` applied.
  ##
  ## All the paths in the idx file will be prefixed with `prefix`. This is done
  ## adding the prefix to the second *column* which is meant to be the html
  ## file reference.
  result = ""
  for line in filename.lines:
    var cols = to_seq(line.split('\t'))
    if cols.len > 1: cols[1] = prefix/cols[1]
    result.add(cols.join("\t") & "\n")


proc collapse_idx(base_dir: string) =
  ## Walks `base_dir` recursively collapsing idx files.
  ##
  ## The files are collapsed to the base directory using the semi full relative
  ## path replacing path separators with underscores. The contents of the idx
  ## files are modified to contain the relative path.
  let
    base_dir = if base_dir.len < 1: "." else: base_dir
    filter = {pcFile, pcLinkToFile, pcDir, pcLinkToDir}
  for path in base_dir.walk_dir_rec(filter):
    let (dir, name, ext) = path.split_file
    # Ignore files which are not an index.
    if ext != ".idx": continue
    # Ignore files found in the base_dir.
    if dir.same_file(base_dir): continue
    # Ignore paths starting with a dot
    if name[0] == '.': continue
    # Extract the parent paths.
    let dest = base_dir/(name & ext)
    var relative_dir = dir[base_dir.len .. <dir.len]
    if relative_dir[0] == DirSep or relative_dir[0] == AltSep:
      relative_dir.delete(0, 0)
    assert(not relative_dir.is_absolute)

    echo "Flattening ", path, " to ", dest
    dest.write_file(mangle_idx(path, relative_dir))


proc build_index(directory: string): string {.discardable.} =
  result = ""
  let
    dest = directory/"theindex.html"
    dir = if directory.len < 1: "." else: directory
    data = merge_indexes(dir)

  assert data.len > 0
  dest.write_file("<html><body>" & data & "</body></html>")
  result = dest


proc test() =
  var config = new_rst_config()
  config[lrc_render_write_index_auto] = "true"

  for path in walk_dir_rec(".", {pcFile, pcDir}):
    let ext = path.split_file.ext.to_lower
    case ext
    of ".rst":
      let dest = path.change_file_ext("html")
      dest.write_file(safe_rst_file_to_html(path, user_config = config))
      echo "Parsed ", path
    of ".nim":
      let (dir, name, ext) = path.split_file
      var prev_dir = ""
      if dir.len > 0:
        prev_dir = get_current_dir()
        set_current_dir(dir)

      shell(nim_exe, "doc --verbosity:0 --hints:off --index:on", name & ext)
      echo "Parsed ", path
      if prev_dir.len > 0:
        set_current_dir(prev_dir)
    else:
      discard

  collapse_idx(".")
  build_index(".")
  echo "Test finished successfully"


task default_task, "Run test": test()
