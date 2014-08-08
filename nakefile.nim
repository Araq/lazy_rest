import nake, os, times, osproc, md5, lazy_rest, sequtils, json, posix, strutils

type
  Failed_test = object of EAssertionFailed ## \
    ## Indicates something failed, with error output if `errors` is not nil.
    errors*: string

template glob_rst(basedir: string = nil): expr =
  ## Shortcut to simplify getting lists of files.
  ##
  ## Pass nil to iterate over rst files in the current directory. This avoids
  ## prefixing the paths with "./" unnecessarily.
  if baseDir.isNil:
    to_seq(walk_files("*.rst"))
  else:
    to_seq(walk_files(basedir/"*.rst"))

let
  rst_files = concat(glob_rst(), glob_rst("docs"))

iterator all_rst_files(): tuple[src, dest: string] =
  for rst_name in rst_files:
    var r: tuple[src, dest: string]
    r.src = rst_name
    # Ignore files if they don't exist, babel version misses some.
    if not r.src.existsFile:
      echo "Ignoring missing ", r.src
      continue
    r.dest = rst_name.change_file_ext("html")
    yield r


proc test_shell(cmd: varargs[string, `$`]): bool {.discardable.} =
  ## Like direShell() but doesn't quit, rather raises an exception.
  let
    full_command = cmd.join(" ")
    (output, exit) = full_command.exec_cmd_ex
  result = 0 == exit
  if not result:
    var e = new_exception(Failed_test, "Error running " & full_command)
    e.errors = output
    raise e


proc doc(open_files = false) =
  # Generate html files from the rst docs.
  for rst_file, html_file in all_rst_files():
    if not html_file.needs_refresh(rst_file): continue
    if not shell("nimrod rst2html --verbosity:0", rst_file):
      quit("Could not generate html doc for " & rst_file)
    else:
      echo rst_file & " -> " & html_file
      if open_files: shell("open " & html_file)

  echo "All docs generated"


proc doco() = doc(true)


proc validate_doc() =
  for rst_file, html_file in all_rst_files():
    echo "Testing ", rst_file
    let (output, exit) = execCmdEx("rst2html.py " & rst_file & " > /dev/null")
    if output.len > 0 or exit != 0:
      echo "Failed python processing of " & rst_file
      echo output

proc clean() =
  for path in walk_dir_rec("."):
    let ext = splitFile(path).ext
    if ext == ".html":
      echo "Removing ", path
      path.removeFile()
  echo "Temporary files cleaned"


proc install_babel() =
  direshell("babel install -y")
  echo "Installed"


proc run_tests() =
  var failed: seq[string] = @[]
  for test_file in walk_files("tests/*/test*nim"):
    let (dir, name, ext) = test_file.split_file
    with_dir test_file.parent_dir:
      try:
        echo "Testing ", name
        test_shell("nimrod c -r", name)
      except Failed_test:
        failed.add(test_file)
  if failed.len > 0:
    echo "Uh oh, " & $failed.len & " tests failed running"
    for f in failed: echo "\t" & failed
  else:
    echo "All tests run without errors."


task "check_doc", "Validates rst format with python.": validate_doc()
task "clean", "Removes temporal files, mostly.": clean()
task "doc", "Generates HTML docs.": doc()
task "doco", "Like 'doc' but also calls 'open' on generated HTML.": doco()
task "i", "Uses babel to force install package locally.": install_babel()
task "test", "Runs local generation tests.": run_tests()
