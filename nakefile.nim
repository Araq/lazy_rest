import
  nake, os, times, osproc, md5, lazy_rest, sequtils, json, posix, strutils,
  external/badger_bits/bb_system

type
  Failed_test = object of EAssertionFailed ## \
    ## Indicates something failed, with error output if `errors` is not nil.
    errors*: string


const
  pkg_name = "lazy_rest"
  badger_name = "lazy_rest_badger"
  src_name = pkg_name & "-" & lazy_rest.version_str & "-source"
  bin_name = pkg_name & "-" & lazy_rest.version_str & "-binary"
  badger = "lazy_rest_bager.nim"
  zip_exe = "zip"
  dist_dir = "dist"


template glob(pattern: string): expr =
  ## Shortcut to simplify getting lists of files.
  to_seq(walk_files(pattern))

let
  rst_files = concat(glob("*.rst"), glob("docs/*rst"))
  nim_files = concat(@[pkg_name & ".nim", "lazy_rest_c_api.nim"],
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


proc cp(src, dest: string) =
  ## Verbose wrapper around copy_file_with_permissions.
  assert src.not_nil and dest.not_nil
  assert src != dest
  echo src & " -> " & dest
  src.copy_file_with_permissions(dest)


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
    test_shell("nimrod c -r " & badger_name & ".nim -v")
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


proc build_vagrant(dir: string) =
  ## Powers up the vagrant box, compilex the lazy badger and produces C files.
  ##
  ## The C files are left in the nimcache subdirectory, the exe is directly at
  ## the root. After all work has done the vagrant instance is halted. This
  ## doesn't do any provisioning, the vagrant instances are meant to be
  ## prepared beforehand.
  with_dir dir:
    dire_shell "vagrant up"
    dire_shell("vagrant ssh -c '" &
      "cd /vagrant/lazy_rest && " &
      "nimrod c -d:release " & badger_name & ".nim &&" &
      "strip " & badger_name & ".exe &&" &
      "rm -Rf nimcache &&" &
      "nimrod c --compile_only --header lazy_rest_c_api.nim &&" &
      "echo done'")
    dire_shell "vagrant halt"


proc zip_vagrant(vagrant_dir, zip_name: string) =
  ## Zips the source and binary files produced by build_vagrant().
  let
    tmp_dir = "tmp"
    dist_bin_dir = tmp_dir/bin_name & "-" & zip_name
    dist_src_dir = tmp_dir/src_name & "-" & zip_name
    exec_options = {poStdErrToStdOut, poUsePath, poEchoCmd}
    nimcache_dir = vagrant_dir/"nimcache"

  # Prepare directories.
  tmp_dir.remove_dir
  dist_bin_dir.create_dir
  create_dir(dist_src_dir/"src")
  cp(vagrant_dir/badger_name & ".exe", dist_bin_dir/badger_name & ".exe")
  for src_file in concat(glob(nimcache_dir/"*.c"), glob(nimcache_dir/"*.h")):
    cp(src_file, dist_src_dir/"src"/src_file.extract_filename)

  echo "TODO rst instructions for each binary package."

  # Create zip files.
  with_dir tmp_dir:
    for full_path in [dist_bin_dir, dist_src_dir]:
      let
        zip_dir = full_path.extract_filename
        zip_file = zip_dir & ".zip"
      discard exec_process(zip_exe, args = ["-9r", zip_file, zip_dir],
        options = exec_options)
      doAssert exists_file(zip_file)

  for zip_file in glob(tmp_dir/"*.zip"):
    cp(zip_file, dist_dir/zip_file.extract_filename)
  tmp_dir.remove_dir


proc build_dist_github_report() =
  ## Inspects files in zip and generates markdown for github.
  ##
  ## This will just pick the zip files and generate some md5 of them
  echo "TODO dist github!"


proc vagrant() =
  ## Takes care of running vagrant, copying files and packaging everything.
  dist_dir.remove_dir
  dist_dir.create_dir

  for vdir, zname in items([("32bit", "i386"), ("64bit", "i686")]):
    let dir = "vagrant_linux"/vdir/"lazy_rest/"
    copy_vagrant dir
    build_vagrant dir
    zip_vagrant(dir, zname)
  echo "TODO mac version"
  build_dist_github_report()


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
