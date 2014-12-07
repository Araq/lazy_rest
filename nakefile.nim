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
  src_name = "source"
  bin_name = pkg_name & "-" & lazy_rest.version_str & "-binary"
  badger = "lazy_rest_bager.nim"
  zip_exe = "zip"
  dist_dir = "dist"
  nimcache = "nimcache"
  sybil_witness = ".sybil_systems"
  nimbase_h = "nimbase.h"
  exec_options = {poStdErrToStdOut, poUsePath, poEchoCmd}


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


proc vagrant_dirs(): seq[string] =
  ## Returns the list of paths for the vagrant linux machines.
  result = @[]
  for vdir in ["32bit", "64bit"]:
    result.add("vagrant_linux"/vdir/"lazy_rest/")


proc cp(src, dest: string) =
  ## Verbose wrapper around copy_file_with_permissions.
  ##
  ## In addition to copying permissions this will create necessary destination
  ## directories. If `src` is a directory it will be copied recursively.
  assert src.not_nil and dest.not_nil
  assert src != dest
  echo src & " -> " & dest
  dest.split_file.dir.create_dir
  if src.exists_dir:
    src.copy_dir(dest)
  else:
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
    quit(QuitFailure)
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
  ## foreach and git archive. Also creates the sybil_witness to make the
  ## platform_dist nake task available.
  target_dir.remove_dir
  target_dir.create_dir
  write_file(target_dir/sybil_witness, "dominator")

  var files: seq[string] = @[]
  for pattern in ["*.nim", "lazy_rest_pkg"/"*.nim", "*cfg", "*.nimble",
      "resources"/"*", "external"/"badger_bits"/"*.nim", "tests"/"*"]:
    files.add(glob(pattern))
  for path in files:
    cp(path, target_dir/path)


proc build_vagrant(dir: string) =
  ## Powers up the vagrant box, compiles the lazy badger and produces C files.
  ##
  ## The compilation is done through the build_platform_dist() code invoking
  ## make *remotely*. The results will be put obvioulsy in the vagrant's dist
  ## subdirectory for collection.  After all work has done the vagrant instance
  ## is halted. This doesn't do any provisioning, the vagrant instances are
  ## meant to be prepared beforehand.
  with_dir dir:
    dire_shell "vagrant up"
    dire_shell("vagrant ssh -c '" &
      "cd /vagrant/lazy_rest && " &
      "nake test && " &
      "nake platform_dist && " &
      "echo done'")
    dire_shell "vagrant halt"


proc copy_nimcache(nimcache_dir, dest_dir: string) =
  ## Copies source files from `nimcache_dir` into `dest_dir`.
  let dest_dir = dest_dir
  for src_file in concat(glob(nimcache_dir/"*.c"), glob(nimcache_dir/"*.h")):
    cp(src_file, dest_dir/src_file.extract_filename)


proc copy_nimbase(dest_dir: string) =
  ## Looks for ``nimbase.h`` and copies it along to `dest_dir`.
  ##
  ## The ``nimbase.h`` file is found based on the lib relative directory from
  ## the nimrod compiler.
  let compiler = "nimrod".find_exe
  assert compiler.not_nil and compiler.len > 5
  let nimbase = compiler.split_file.dir / ".."/"lib"/nimbase_h
  cp(nimbase, dest_dir/nimbase_h)


proc build_dist_github_report() =
  ## Inspects files in zip and generates markdown for github.
  ##
  ## This will just pick the zip files and generate some md5 of them
  echo "TODO dist github!"


proc run_vagrant() =
  ## Takes care of running vagrant and running build_platform_dist *there*.
  for dir in vagrant_dirs():
    copy_vagrant dir
    build_vagrant dir


proc pack_dir(zip_dir: string, do_remove = true) =
  ## Creates a zip out of `zip_dir`, then optionally removes that dir.
  ##
  ## The zip will be created in the parent directory with the same name as the
  ## last directory plus the zip extension.
  assert zip_dir.exists_dir
  let base_dir = zip_dir.split_file.dir
  with_dir base_dir:
    let
      local_dir = zip_dir.extract_filename
      zip_file = local_dir & ".zip"
    discard exec_process(zip_exe, args = ["-9r", zip_file, local_dir],
      options = exec_options)
    doAssert exists_file(zip_file)
    if do_remove:
      local_dir.remove_dir


proc collect_vagrant() =
  ## Takes dist generated files from vagrant dirs and copies to our dist.
  ##
  ## This requires that both vagrant and current dist dirs exists. Also, once
  ## finished all the source files are put into a single zip.
  doAssert dist_dir.exists_dir
  for vagrant_base in vagrant_dirs():
    let dir = vagrant_base/dist_dir
    for path in glob(dir/"*"):
      cp(path, dist_dir/path.extract_filename)

  # Build mega-source pack.
  let src_final = dist_dir/pkg_name & "-" &
    lazy_rest.version_str & "-generated-C-sources"
  src_final.create_dir
  for src_dir in glob(dist_dir/"source*"):
    move_file(src_dir, src_final/src_dir.extract_filename)
  pack_dir(src_final)


proc build_platform_dist() =
  ## Runs some compilation tasks to produce the binary and source dists.
  ##
  ## This will generate files in the ``dist`` subdirectory but will not pack
  ## them. Presumably you are running this on different platforms to later
  ## *gather* the results together.
  nimcache.remove_dir
  dist_dir.remove_dir
  let
    platform = "-" & host_os & "-" & host_cpu
    dist_bin_dir = dist_dir/bin_name & platform

  # Build the binary.
  dire_shell "nimrod c -d:release " & badger_name & ".nim"
  dire_shell "strip " & badger_name & ".exe"
  cp(badger_name & ".exe", dist_bin_dir/badger_name & ".exe")

  # Zip the binary and remove the uncompressed files.
  pack_dir(dist_dir/bin_name & platform)

  # Build sources.
  for variant in ["debug", "release"]:
    nimcache.remove_dir
    dire_shell("nimrod c -d:" & variant, "--compile_only --header",
      "lazy_rest_c_api.nim")
    let dest = dist_dir/src_name & platform & "-" & variant
    copy_nimcache(nimcache, dest)
    copy_nimbase(dest)


proc build_dist() =
  ## Runs all the distribution tasks and collects everything for upload.
  run_vagrant()
  build_platform_dist()
  collect_vagrant()
  build_dist_github_report()


task "clean", "Removes temporal files, mostly.": clean()
task "doc", "Generates HTML docs.": doc()
task "i", "Uses babel to force install package locally.": install_babel()
task "test", "Runs local generation tests.": run_tests()

if sybil_witness.exists_file:
  task "web", "Renders gh-pages, don't use unless you are gradha.": web()
  task "check_doc", "Validates rst format with python.": validate_doc()
  task "postweb", "Gradha uses this like portals, don't touch!": postweb()
  task "vagrant", "Runs vagrant to build linux binaries": run_vagrant()
  task "platform_dist", "Build dist for current OS": build_platform_dist()
  task "dist", "Performs distribution tasks for all platforms": build_dist()

when defined(macosx):
  task "doco", "Like 'doc' but also calls 'open' on generated HTML.": doco()
