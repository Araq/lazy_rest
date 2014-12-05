import nake, os, times, osproc, md5, lazy_rest, sequtils, json, posix, strutils

type
  Failed_test = object of EAssertionFailed ## \
    ## Indicates something failed, with error output if `errors` is not nil.
    errors*: string


const
  name = "lazy_rest"
  badger = "lazy_rest_bager.nim"


template glob(pattern: string): expr =
  ## Shortcut to simplify getting lists of files.
  to_seq(walk_files(pattern))

let
  rst_files = concat(glob("*.rst"), glob("docs/*rst"))
  nim_files = concat(@[name & ".nim", "lazy_rest_c_api.nim"],
    glob("lazy_rest_pkg/*nim"))

iterator all_html_files(files: seq[string]): tuple[src, dest: string] =
  for filename in files:
    var r: tuple[src, dest: string]
    r.src = filename
    # Ignore files if they don't exist, babel version misses some.
    if not r.src.exists_file:
      echo "Ignoring missing ", r.src
      continue
    r.dest = filename.change_file_ext("html")
    yield r


proc test_shell(cmd: varargs[string, `$`]): bool {.discardable.} =
  ## Like dire_shell() but doesn't quit, rather raises an exception.
  let
    full_command = cmd.join(" ")
    (output, exit) = full_command.exec_cmd_ex
  result = 0 == exit
  if not result:
    var e = new_exception(Failed_test, "Error running " & full_command)
    e.errors = output
    raise e


proc rst_to_html(src, dest: string): bool =
  # Runs the unsafe rst generator, and if fails, uses the safe one.
  #
  # `src` will always be rendered, but true is only returned when there weren't
  # any errors.
  try:
    dest.write_file(rst_string_to_html(src.read_file, src))
    result = true
  except:
    dest.write_file(safe_rst_file_to_html(src))

proc doc(open_files = false) =
  # Generate html files from the rst docs.
  for rst_file, html_file in rst_files.all_html_files:
    if not html_file.needs_refresh(rst_file): continue
    if not rst_to_html(rst_file, html_file):
      quit("Could not generate html doc for " & rst_file)
    else:
      echo rst_file & " -> " & html_file
      if open_files: shell("open " & html_file)

  for nim_file, html_file in nim_files.all_html_files:
    if not html_file.needs_refresh(nim_file): continue
    if not shell("nimrod doc --verbosity:0", nim_file):
      quit("Could not generate HTML API doc for " & nim_file)
    if open_files: shell("open " & html_file)

  echo "All docs generated"


proc doco() = doc(true)


proc validate_doc() =
  for rst_file, html_file in rst_files.all_html_files():
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
  # Run the test suite.
  for test_file in walk_files("tests/*/test*nim"):
    let (dir, name, ext) = test_file.split_file
    with_dir test_file.parent_dir:
      try:
        echo "Testing ", name
        test_shell("nimrod c -r", name)
      except Failed_test:
        failed.add(test_file)

  # Add compilation of the badger binary.
  try:
    echo "Testing ", badger
    test_shell("nimrod c -r lazy_rest_badger.nim -v")
  except Failed_test:
    failed.add(badger)

  # Show results
  if failed.len > 0:
    echo "Uh oh, " & $failed.len & " tests failed running"
    for f in failed: echo "\t" & f
  else:
    echo "All tests run without errors."


proc web() =
  echo "Changing branches to render gh-pages…"
  let ourselves = read_file("nakefile")
  dire_shell "git checkout gh-pages"
  dire_shell "rm -R `git ls-files -o`"
  dire_shell "rm -Rf gh_docs"
  dire_shell "gh_nimrod_doc_pages -c ."
  write_file("nakefile", ourselves)
  dire_shell "chmod 775 nakefile"
  echo "All commands run, now check the output and commit to git."
  shell "open index.html"
  echo "Wen you are done come back with './nakefile postweb'."


proc postweb() =
  echo "Forcing changes back to master."
  dire_shell "git checkout -f @{-1}"
  echo "Updating submodules just in case."
  dire_shell "git submodule update"


proc copy_vagrant(target_dir: string) =
  ## Copies enough source files to `target_dir` to build a binary.
  ##
  ## This is done through an external python script which calls git submodule
  ## foreach and git archive.
  target_dir.remove_dir

  var files: seq[string] = @[]
  for pattern in ["*.nim", "lazy_rest_pkg"/"*.nim", "*cfg", "*.nimble",
      "resources"/"*", "external"/"badger_bits"/"*.nim"]:
    files.add(glob(pattern))
  for path in files:
    let
      dest = target_dir/path
      dir = dest.split_file.dir
    dir.create_dir
    echo "Creating ", dest
    path.copy_file_with_permissions(dest)


proc vagrant() =
  ## Takes care of running vagrant, copying files and packaging linux binaries.
  for variant in ["32bit", "64bit"]:
    let dir = "vagrant_linux"/variant/"lazy_rest/"
    copy_vagrant dir
    with_dir dir:
      dire_shell "vagrant up"
      dire_shell("vagrant ssh -c '" &
        "cd /vagrant/lazy_rest && " &
        "nimrod c -d:release lazy_rest_badger.nim &&" &
        "strip lazy_rest_badger.exe" &
        "'")
      dire_shell "vagrant halt"


task "clean", "Removes temporal files, mostly.": clean()
task "doc", "Generates HTML docs.": doc()
task "i", "Uses babel to force install package locally.": install_babel()
task "test", "Runs local generation tests.": run_tests()

if exists_file(".sybil_systems"):
  task "web", "Renders gh-pages, don't use unless you are gradha.": web()
  task "check_doc", "Validates rst format with python.": validate_doc()
  task "postweb", "Gradha uses this like portals, don't touch!": postweb()
  task "vagrant", "Runs vagrant to build linux binaries": vagrant()

when defined(macosx):
  task "doco", "Like 'doc' but also calls 'open' on generated HTML.": doco()
