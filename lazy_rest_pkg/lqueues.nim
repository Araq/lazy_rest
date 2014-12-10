## Multi processor aware API for `lazy_rest
## <https://github.com/gradha/lazy_rest>`_.
##
## **DO NOT USE THIS MODULE AT THE MOMENT**, it is incomplete and crashes bad.
##
## By default the main `lazy_rest <../lazy_rest.html>`_ module works in a
## single threaded way. Since no globals are used, rendering of rst files can
## be parallelized. This module builds on top of the main API providing a queue
## interface: you pass a list of `Rest_task <#Rest_task>`_ objects and they
## will be rendered in parallel using all available cores.
##
## **NOTE**: This will have to wait until
## https://github.com/gradha/lazy_rest/issues/5 is resolved in the future.
##
## **DO NOT USE THIS MODULE AT THE MOMENT**, it is incomplete and crashes bad.

import lazy_rest, bb_system, locks, strutils, bb_os, osproc

type
  Rest_task* = object ## Holds input/output data for each rendering job. \
    ##
    ## You can create any number of rest tasks and populate the fields, then
    ## feed them to render and check the output.
    input_filename*: string ## Full path to the input filename. \
      ##
      ## This field can be left nil if you are providing the rst data to render
      ## in the `input_data` field. However, this is needed for documents using
      ## the include directive or reporting errors to users. If this field is
      ## not nil, whatever you put in `input_data` will be erased.
    input_data*: string ## Contents of the input filename. \
      ##
      ## This field can be nil if you are providing a filename in the
      ## `input_filename` field. But if this field is not nil, no IO operation
      ## will be done for rendering as this data will be used directly.
    output_data*: string ## Stores render result data. \
      ##
      ## This value will be nil if the Rest_task object has not been processed
      ## or there was a serious error preventing any rendering. However, for
      ## proper error checking you should check the `errors` field.
    output_filename*: string ## Fill path to the output filename. \
      ##
      ## This field can be left nil, in which case only `output_data` will be
      ## filled. However, if you provide a non nil string, it will be created
      ## or overwritten with the contents from `output_data`.
    safe_render*: bool ## Set this to true if you need safe rendering. \
      ##
      ## When safe rendering is active, you will **always** get a valid HTML in
      ## the `output_data` field. However, this might be an HTML error message
      ## if something actually went wrong, which tells the user to report bugs
      ## in GigHub along with a raw listing of the input file.
      ##
      ## When `safe_render` is false, `output_data` will be filled only if
      ## there were no errors of any kind during rendering.
    errors*: seq[string] ## List of errors found. \
      ##
      ## The list of errors found will be not nil if any errors were found.
      ## Note that not all kind of errors are critical. For instance, if you
      ## set up rendering of rst files and the target output files can't be
      ## written, you still have the valid data in the `output_data` field, but
      ## `errors` will contain a text description of an IO error. Also if you
      ## set `safe_render` to true, any rendering error will be added to this
      ## sequence.

  Rest_thread = TThread[void] ## Shortcut for void thread.

  Global_communication = object ## \
    ## Holds all the communication global variables between threads.
    L: TLock ## Global lock, used to avoid concurrent calls to public API.
    DL: TLock ## Data lock, used by consumer threads to access the queue.
    threads: seq[Rest_thread] ## Pool of created threads.
    tasks: ptr seq[Rest_task] ## List of input/output tasks to process.
    pos: int ## Next `tasks` index to process by a Rest_thread.


var G: Global_communication
G.L.init_lock


const HTML_EXTENSION = "html"


proc `$`*(t: Rest_task): string =
  ## Convenience debug converter.
  let
    idata = if t.input_data.is_nil: "nil" else: $t.input_data.len
    odata = if t.output_data.is_nil: "nil" else: $t.output_data.len
    e = if t.errors.is_nil: "nil" else: t.errors.join(", ")

  result = "Rest_task {input_filename: " & t.input_filename.nil_echo &
    ", output_filename: " & t.output_filename.nil_echo & ", input_data: " &
    idata & ", output_data: " & odata & ", safe_render: " &
    $(t.safe_render) & ", errors: " & e & "}"


proc rst_file_task*(filename: string, safe_render = true): Rest_task =
  ## Helper proc to create file oriented tasks for a queue.
  ##
  ## The proc will return a valid `Rest_task <#Rest_task>`_ object which
  ## accepts the `filename` as input file and will fill `output_filename` with
  ## the input using the ``.html`` extension.
  ##
  ## Note that no checking is done about the file itself. The proc will crash
  ## if you pass a nil `filename`.
  assert filename.not_nil
  assert filename.len > 0, "You can't pass an empty input filename"
  result.input_filename = filename
  result.output_filename = filename.change_file_ext(HTML_EXTENSION)
  result.safe_render = safe_render


proc rst_string_task*(filename: string, safe_render = true): Rest_task =
  ## Helper proc to create string oriented tasks for a queue.
  ##
  ## Unlike `rst_file_task <#rst_file_task>`_ this proc will actually read the
  ## contents of `filename` and fill both the `input_filename` and `input_data`
  ## fields, but **will not** fill `output_filename`. Also, the proc may assert
  ## due to IO errors when reading the file, so you may need to check for that.
  assert filename.not_nil
  assert filename.len > 0, "You can't pass an empty input filename"
  result.input_filename = filename
  result.input_data = filename.read_file
  result.safe_render = safe_render


proc render_task() {.thread.} =
  while true:
    G.DL.acquire
    # Check if the tasks array was finished.
    if G.pos >= G.tasks[].len:
      G.DL.release
      return

    # Keep a copy of the position and release the lock to minimize contention.
    let pos = G.pos
    G.pos.inc
    G.DL.release

    # Step 1, read file if needed.
    if G.tasks[pos].input_filename.safe.len > 0:
      # TODO: Catch errors
      G.tasks[pos].input_data = G.tasks[pos].input_filename.read_file

    # Step 2, process file into output buffer.
    if G.tasks[pos].safe_render:
      G.tasks[pos].output_data = safe_rst_string_to_html(
        G.tasks[pos].input_filename.safe, G.tasks[pos].input_data)
    else:
      # TODO: Catch errors
      G.tasks[pos].output_data = rst_string_to_html(
        G.tasks[pos].input_filename.safe, G.tasks[pos].input_data)

    # Step 3, write to external file.
    if G.tasks[pos].output_filename.safe.len > 0:
      write_file(G.tasks[pos].output_filename, G.tasks[pos].output_data)


template critical_section(lock: var TLock, body: stmt) =
  ## Helper to make locking visible through source identation.
  lock.acquire
  try: body
  finally: lock.release


proc render*(tasks: var seq[Rest_task], abort_early = true,
    num_threads = count_processors()): int {.discardable.} =
  ## Renders the tasks in a parallel fashion.
  ##
  ## The `Rest_task <#Rest_task>`_ objects will be modified inplace. If
  ## `abort_early` is true, the first item giving any trouble will prevent
  ## processing remaining items. Since errors could come at any moment, you
  ## need to check all the `tasks` individually and look at their `errors`
  ## field.
  ##
  ## You can force the number of parallel rendering threads with `num_threads`
  ## if you don't want to use as many as processors on the machine.
  ## `num_threads` has to be greater than zero, otherwise debug builds will
  ## assert and release builds may crash.
  ##
  ## Returns the number of tasks processed. You may find this useful if
  ## `abort_early` is true, since `tasks` is processed sequentially, so the
  ## return value will be the highest `tasks` index you need to check for error
  ## reasons. If `abort_early` is false, the return value will always equal the
  ## length of `tasks`.
  assert num_threads > 0
  G.L.critical_section:
    G.tasks = addr(tasks)
    G.pos = 0
    G.threads = newSeq[Rest_thread](num_threads)
    for f in 0 .. <num_threads: create_thread[void](G.threads[f], render_task)
    G.threads.join_threads
    echo "Hey!"
