## Different parallelization performance tests.
##
## The fastest method is implemented with a public API. To test the module you
## need to create a ``nimrod_doc`` symlink to your Nimrod's ``doc`` directory
## so that the ``manual.txt`` file can be accessed. Copying just this file
## won't work due to further rst include directives.
##
## At the moment there are two tests, using actors and a manual thread pool
## with global sequence locking. The latter performs closer to the possible
## optimal performance scaling.
##
## Due to https://github.com/Araq/Nimrod/issues/1469 a ``really_release``
## symbol is used to detect debug vs release builds.

when defined(release):
  const num_files = 150
  const really_release = true
else:
  const num_files = 20
  const really_release = false

import lazy_rest, strutils, os, times, actors, osproc, locks

type
  Param_in = tuple[src, dest: string]

const manual_input = "nimrod_doc"/"manual.txt"
var manual_contents: string

proc process(p: Param_in) {.thread.} =
  # Converts the rst to html.
  # Dummy test
  #os.sleep(100)

  # This generates files so that they can be checked and compared.
  #p.dest.write_file(safe_rst_file_to_html(p.src))

  # This is just for in memory rendering testing to avoid IO measurements.
  var r = rst_string_to_html(manual_contents, p.src)


proc serial_test() =
  for i in 1 .. num_files:
    process((manual_input, "smanual" & $i & ".html"))


proc parallel_test() =
  let cpus = countProcessors()
  echo "Using cpu pool: ", cpus
  var params: seq[Param_in] = @[]
  for i in 1 .. num_files:
    params.add((manual_input, "pmanual" & $i & ".html"))

  var pool: TActorPool[Param_in, void]
  pool.createActorPool(cpus)
  for i in 1 .. num_files:
    pool.spawn(params[i - 1], process)
  pool.sync()


var
  threads: seq[TThread[void]]
  global_pos = 0
  success_conversions = 0
  input_params: seq[Param_in]
  L: TLock

L.initLock

proc render_input() {.thread.} =
  while true:
    L.acquire
    if global_pos >= input_params.len:
      L.release
      return

    var pos = global_pos
    global_pos.inc
    L.release

    #input_params[pos].dest.write_file(
    #  safe_rst_file_to_html(input_params[pos].src))
    discard rst_string_to_html(manual_contents, input_params[pos].src)
    success_conversions.atomicInc

proc thread_test() =
  let cpus = countProcessors()
  # Init globals.
  global_pos = 0
  input_params = newSeq[Param_in](num_files)
  for f in 0 .. <num_files:
    input_params[f] = (manual_input, "tmanual" & $f & ".html")
  # Create and start threads.
  threads = newSeq[TThread[void]](cpus)
  for f in 0 .. <cpus: createThread[void](threads[f], render_input)
  threads.join_threads
  assert success_conversions == num_files
  #L.deinitLock


proc test() =
  let t1 = epoch_time()
  serial_test()
  let t2 = epoch_time()
  parallel_test()
  let t3 = epoch_time()
  thread_test()
  let t4 = epoch_time()
  when really_release: echo "Running in release mode for ", num_files
  else: echo "Running in debug mode for ", num_files
  echo "Spent in serial queue ", $(t2 - t1)
  echo "Spent in parallel queue ", $(t3 - t2)
  echo "Spent in thread queue ", $(t4 - t3)
  echo "Using ", countProcessors(), " for ", num_files, " steps"
  let
    it = float(int(num_files / float(countProcessors()) + 1))
    serial_time = (t2 - t1) / float(num_files)
  echo "Optimal would be ", $(it * serial_time), "s"

proc check_setup() =
  if not manual_input.exists_file:
    quit("Sorry, couldn't find " & manual_input &", copy it from NIM_PATH/doc.")
  manual_contents = manual_input.read_file

when isMainModule:
  check_setup()
  test()
  echo "Test finished successfully"
