import
  bb_nake, bb_os, times, osproc, md5, lazy_rest, sequtils, json, posix,
  strutils, bb_system


const
  pkg_name = "lazy_rest"
  badger_name = "lazy_rest_badger"
  src_name = "c-sources"
  bin_name = pkg_name & "-" & lazy_rest.version_str & "-binary"
  badger = "lazy_rest_bager.nim"
  nimcache = "nimcache"
  nimbase_h = "nimbase.h"


let
  rst_files = concat(glob("*.rst"), glob("docs"/"*rst"),
    glob("docs"/"dist"/"*rst"))
  nim_files = concat(@[pkg_name & ".nim", "lazy_rest_c_api.nim"],
    glob("lazy_rest_pkg/*nim"))

iterator all_html_files(files: seq[string]): tuple[src, dest: string] =
  for filename in files:
    var r: tuple[src, dest: string]
    r.src = filename
    # Ignore files if they don't exist, nimble version misses some.
    if not r.src.exists_file:
      echo "Ignoring missing ", r.src
      continue
    r.dest = filename.change_file_ext("html")
    yield r


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


proc doc(start_dir = ".", open_files = false) =
  ## Generate html files from the rst docs.
  ##
  ## Pass `start_dir` as the root where you want to place the generated files.
  ## If `open_files` is true the ``open`` command will be called for each
  ## generated HTML file.
  for rst_file, html_file in rst_files.all_html_files:
    let
      full_path = start_dir / html_file
      base_dir = full_path.split_file.dir
    base_dir.create_dir
    if not full_path.needs_refresh(rst_file): continue
    if not rst_to_html(rst_file, full_path):
      quit("Could not generate html doc for " & rst_file)
    else:
      echo rst_file & " -> " & full_path
      if open_files: shell("open " & full_path)

  for nim_file, html_file in nim_files.all_html_files:
    let
      full_path = start_dir / html_file
      base_dir = full_path.split_file.dir
    base_dir.create_dir
    if not full_path.needs_refresh(nim_file): continue
    if not shell(nim_exe, "doc --verbosity:0 -o:" & full_path, nim_file):
      quit("Could not generate HTML API doc for " & nim_file)
    if open_files: shell("open " & full_path)

  echo "All docs generated"


proc doco() = doc(open_files = true)


proc validate_doc() =
  for rst_file, html_file in rst_files.all_html_files():
    echo "Testing ", rst_file
    let (output, exit) = execCmdEx("rst2html.py " & rst_file & " > /dev/null")
    if output.len > 0 or exit != 0:
      echo "Failed python processing of " & rst_file
      echo output


proc clean() =
  for path in dot_walk_dir_rec("."):
    case splitFile(path).ext.to_lower
    of ".html", ".exe":
      echo "Removing ", path
      path.removeFile()
    else:
      discard
  echo "Temporary files cleaned"


proc install_nimble() =
  direshell("nimble install -y")
  echo "Installed"


proc run_tests() =
  run_test_subdirectories("tests")

  # Add compilation of the badger binary.
  try:
    echo "Testing ", badger_name
    test_shell(nim_exe, "c -r " & badger_name & ".nim -v")
    test_shell(nim_exe, "c -d:release -r " & badger_name & ".nim -v")
  except Shell_failure:
    quit("Could not compile " & badger_name)


proc web() = switch_to_gh_pages()
proc postweb() = switch_back_from_gh_pages()

proc copy_nimcache(nimcache_dir, dest_dir: string) =
  ## Copies source files from `nimcache_dir` into `dest_dir`.
  let dest_dir = dest_dir
  for src_file in concat(glob(nimcache_dir/"*.c"), glob(nimcache_dir/"*.h")):
    cp(src_file, dest_dir/src_file.extract_filename)


proc copy_nimbase(dest_dir: string) =
  ## Looks for ``nimbase.h`` and copies it along to `dest_dir`.
  ##
  ## The ``nimbase.h`` file is found based on the lib relative directory from
  ## the nim_exe.
  assert nim_exe.not_nil and nim_exe.len > 5
  let nimbase = nim_exe.split_file.dir / ".."/"lib"/nimbase_h
  cp(nimbase, dest_dir/nimbase_h)


proc md5() =
  ## Inspects files in zip and generates markdown for github.
  let templ = """
Add the following notes to the release info:

Compiled with Nimrod version https://github.com/Araq/Nimrod/commit/$$1 or https://github.com/Araq/Nimrod/tree/v0.9.6.

[See the changes log](https://github.com/gradha/lazy_rest/blob/v$1/docs/changes.rst).

Binary MD5 checksums:""" % [lazy_rest.version_str]
  show_md5_for_github(templ)


proc run_vagrant() =
  ## Takes care of running vagrant and running build_platform_dist *there*.
  run_vagrant("""
    nimble build
    nake test
    nake platform_dist
    """)


proc collect_vagrant_sources() =
  ## Takes dist generated files from vagrant dirs and copies to our dist.
  ##
  ## This requires that both vagrant and current dist dirs exists. Also, once
  ## finished all the source files are put into a single zip along with some
  ## documentation.

  # Build mega-source pack.
  let src_final = dist_dir/pkg_name & "-" &
    lazy_rest.version_str & "-generated-C-sources"
  src_final.create_dir
  for src_dir in glob(dist_dir/"c-source*"):
    move_file(src_dir, src_final/src_dir.extract_filename)

  let
    readme_rst = "docs"/"dist"/"c_sources.html"
    readme_html = src_final/"readme.html"
    doc_dir = src_final/"documentation"
    doc_dist_dir = doc_dir/"docs"/"dist"

  cp(readme_rst, readme_html)
  doc(start_dir = doc_dir)
  doc_dist_dir.remove_dir
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
    usage_rst = "docs"/"lazy_rest_badger_usage.rst"
    readme_rst = "docs"/"dist"/"lazy_rest_badger.rst"
    usage_html = dist_bin_dir/"lazy_rest_badger_usage.html"
    readme_html = dist_bin_dir/"readme.html"

  # Build the binary.
  dire_shell nim_exe & " c -d:release " & badger_name & ".nim"
  dire_shell "strip " & badger_name & ".exe"
  cp(badger_name & ".exe", dist_bin_dir/badger_name & ".exe")
  doAssert rst_to_html(usage_rst, usage_html)
  doAssert rst_to_html(readme_rst, readme_html)

  # Zip the binary and remove the uncompressed files.
  pack_dir(dist_dir/bin_name & platform)

  # Build sources.
  for variant in ["debug", "release"]:
    nimcache.remove_dir
    dire_shell(nim_exe, "c -d:" & variant, "--compileOnly --header --noMain",
      "lazy_rest_c_api.nim")
    let dest = dist_dir/src_name & platform & "-" & variant
    copy_nimcache(nimcache, dest)
    copy_nimbase(dest)


proc build_dist() =
  ## Runs all the distribution tasks and collects everything for upload.
  doc()
  build_platform_dist()
  run_vagrant()
  collect_vagrant_dist()
  collect_vagrant_sources()
  md5()


task "clean", "Removes temporal files, mostly.": clean()
task "doc", "Generates HTML docs.": doc()
task "i", "Uses nimble to force install package locally.": install_nimble()
task "test", "Runs local generation tests.": run_tests()

if sybil_witness.exists_file:
  task "web", "Renders gh-pages, don't use unless you are gradha.": web()
  task "check_doc", "Validates rst format with python.": validate_doc()
  task "postweb", "Gradha uses this like portals, don't touch!": postweb()
  task "vagrant", "Runs vagrant to build linux binaries": run_vagrant()
  task "platform_dist", "Build dist for current OS": build_platform_dist()
  task "dist", "Performs distribution tasks for all platforms": build_dist()
  task "md5", "Computes md5 of files found in dist subdirectory.": md5()

when defined(macosx):
  task "doco", "Like 'doc' but also calls 'open' on generated HTML.": doco()
