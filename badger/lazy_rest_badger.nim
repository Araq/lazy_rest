import
  lazy_rest, strutils, os, argument_parser, tables, sequtils, sets,
  external/badger_bits/bb_system


const
  stdin_str = "STDIN"

  param_dir = @["-r", "--recursive-dir"]
  help_dir = "Specifies a directory to be processed recursively."

  param_extensions = @["-e", "--extensions"]
  help_extensions = "Colon separated list of extensions to process, 'rst' by default."

  param_help = @["-h", "--help"]
  help_help = "Displays commandline help and exits."

  param_version = @["-v", "--version"]
  help_version = "Displays the current version and exists."

  param_output = @["-o", "--output"]
  help_output = "When a single file is the input, sets its output filename."

  param_raw_directive = @["-R", "--parser-raw-directive"]
  help_raw_directive = "Allows raw directives to be processed."

  param_enable_smilies = @["-S", "--parser-enable-smilies"]
  help_enable_smilies = "Transforms text smileys into images."

  param_fenced_blocks = @["-F", "--parser-fenced-blocks"]
  help_fenced_blocks = "Allows triple quote fenced blocks, typical of GitHub."

  param_option_file = @["-O", "--parser-option-file"]
  help_option_file = "Specifies a file from which to read lazy_rest options."

  param_skip_pounds = @["-P", "--parser-skip-pounds"]
  help_skip_pounds = "Ignores the initial pound symbol of input lines."


type
  Global = object
    input_files: seq[string] ## List of input files to process.
    output_filename: string ## The name of the output, for single file usage.
    extensions: seq[string] ## List of extensions, by default rst.
    parse_option_file: string ## File to be loaded to process options.
    parse_raw_directive: bool
    parse_enable_smilies: bool
    parse_fenced_blocks: bool
    parse_skip_pounds: bool


var G: Global
# Set some defaults.
G.extensions = @["rst"]
G.input_files = @[]


proc find_rst_files(base_dir: string): seq[string] =
  ## Finds and returns all the rst files found in `base_dir`.
  ##
  ## You better have already filled G.extensions before calling this.
  assert G.extensions.len > 0
  # Build set of extensions.
  var VALID_EXT = init_set[string]()
  for ext in G.extensions: VALID_EXT.incl(ext)

  result = @[]
  for path in base_dir.walk_dir_rec({pcFile, pcLinkToFile, pcDir, pcLinkToDir}):
    let ext = path.split_file.ext.to_lower
    if ext.len > 2 and VALID_EXT.contains(ext[1 .. <ext.len]):
      result.add(path)


proc is_stdin(): bool =
  ## Returns ``true`` if the G.input_files contains a single STDIN entry.
  result = G.input_files.not_nil and G.input_files.len == 1 and
    G.input_files[0].to_upper == stdin_str


template abort(msg: string) =
  ## Aborts the command line parsing with a message.
  PARAMS.echo_help
  quit msg


proc process_commandline() =
  ## Parses the commandline, quits if something goes wrong.
  ##
  ## Successful results are stored in the global variable. If something goes
  ## wrong this proc will quit execution.
  var PARAMS: seq[Tparameter_specification] = @[]

  PARAMS.add(new_parameter_specification(PK_HELP,
    names = param_help, help_text = help_help))
  PARAMS.add(new_parameter_specification(names = param_version,
    help_text = help_version))

  PARAMS.add(new_parameter_specification(PK_STRING, names = param_extensions,
    help_text = help_extensions))
  PARAMS.add(new_parameter_specification(PK_STRING, names = param_dir,
    help_text = help_dir))
  PARAMS.add(new_parameter_specification(PK_STRING, names = param_output,
    help_text = help_output))
  PARAMS.add(new_parameter_specification(PK_STRING, names = param_option_file,
    help_text = help_option_file))
  PARAMS.add(new_parameter_specification(names = param_raw_directive,
    help_text = help_raw_directive))
  PARAMS.add(new_parameter_specification(names = param_enable_smilies,
    help_text = help_enable_smilies))
  PARAMS.add(new_parameter_specification(names = param_fenced_blocks,
    help_text = help_fenced_blocks))
  PARAMS.add(new_parameter_specification(names = param_skip_pounds,
    help_text = help_skip_pounds))

  let result = PARAMS.parse

  if result.options.has_key(param_version[0]):
    echo "lazy_rest_badger version " & lazy_rest.version_str
    quit()

  # Store the name of the options file.
  if result.options.has_key(param_option_file[0]):
    let path = result.options[param_option_file[0]].str_val
    if not path.exists_file:
      abort "The option file '" & path & "' doesn't seem to be valid."
    G.parse_option_file = path

  # Read what extensions are meant to be parsed.
  if result.options.has_key(param_extensions[0]):
    var VALUES = result.options[param_extensions[0]].str_val.split(':')
    VALUES = VALUES.filter_it(it.len > 0)
    if VALUES.len < 1:
      abort "Specify at least a single non zero length extension"
    G.extensions = VALUES

  # Add positional parameters unconditionally.
  for param in result.positional_parameters:
    G.input_files.add(param.str_val)

  # Add recursive directory.
  if result.options.has_key(param_dir[0]):
    let base_dir = result.options[param_dir[0]].str_val
    if not base_dir.exists_dir:
      abort "The specified directory '" & base_dir & "' is not valid."
    G.input_files.add(base_dir.find_rst_files)

  # Abort if there is no input.
  if G.input_files.len < 1:
    abort "Specify a file or directory to process (file can be STDIN)"

  # For inputs of single file allow specifying the output.
  if result.options.has_key(param_output[0]):
    let filename = result.options[param_output[0]].str_val
    if G.input_files.len != 1:
      abort "You can't specify an output filename with multiple inputs."
    # Ok, the input is single, but is it STDIN?
    if is_stdin():
      abort "You can't specify an output filename with STDIN, use redirects."
    G.output_filename = filename

  # Detect aditional parsing options.
  if result.options.has_key(param_raw_directive[0]):
    G.parse_raw_directive = true
  if result.options.has_key(param_enable_smilies[0]):
    G.parse_enable_smilies = true
  if result.options.has_key(param_fenced_blocks[0]):
    G.parse_fenced_blocks = true
  if result.options.has_key(param_skip_pounds[0]):
    G.parse_skip_pounds = true


proc main() =
  process_commandline()

when isMainModule: main()
