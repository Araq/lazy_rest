import
  lazy_rest, strutils, os, argument_parser, tables

const
  PARAM_DIR = @["-r", "--recursive-dir"]
  HELP_DIR = "Specifies a directory to be processed recursively."

  PARAM_EXTENSIONS = @["-e", "--extensions"]
  HELP_EXTENSIONS = "Colon separated list of extensions to process, 'rst' by default."

  PARAM_HELP = @["-h", "--help"]
  HELP_HELP = "Displays commandline help and exits."

  PARAM_VERSION = @["-v", "--version"]
  HELP_VERSION = "Displays the current version and exists."

  PARAM_OUTPUT = @["-o", "--output"]
  HELP_OUTPUT = "When a single file is the input, sets its output filename."

  PARAM_RAW_DIRECTIVE = @["-R", "--parser-raw-directive"]
  HELP_RAW_DIRECTIVE = "Allows raw directives to be processed."

  PARAM_ENABLE_SMILIES = @["-S", "--parser-enable-smilies"]
  HELP_ENABLE_SMILIES = "Transforms text smileys into images."

  PARAM_FENCED_BLOCKS = @["-F", "--parser-fenced-blocks"]
  HELP_FENCED_BLOCKS = "Allows triple quote fenced blocks, typical of GitHub."

  PARAM_OPTION_FILE = @["-O", "--parser-option-file"]
  HELP_OPTION_FILE = "Specifies a file from which to read lazy_rest options."

  PARAM_SKIP_POUNDS = @["-P", "--parser-skip-pounds"]
  HELP_SKIP_POUNDS = "Ignores the initial pound symbol of input lines."


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


proc process_commandline() =
  ## Parses the commandline, quits if something goes wrong.
  ##
  ## Successful results are stored in the global variable. If something goes
  ## wrong this proc will quit execution.
  var params: seq[Tparameter_specification] = @[]

  params.add(new_parameter_specification(PK_HELP,
    names = PARAM_HELP, help_text = HELP_HELP))
  params.add(new_parameter_specification(names = PARAM_VERSION,
    help_text = HELP_VERSION))

  params.add(new_parameter_specification(PK_STRING, names = PARAM_EXTENSIONS,
    help_text = HELP_EXTENSIONS))
  params.add(new_parameter_specification(PK_STRING, names = PARAM_DIR,
    help_text = HELP_DIR))
  params.add(new_parameter_specification(PK_STRING, names = PARAM_OUTPUT,
    help_text = HELP_OUTPUT))
  params.add(new_parameter_specification(PK_STRING, names = PARAM_OPTION_FILE,
    help_text = HELP_OPTION_FILE))
  params.add(new_parameter_specification(names = PARAM_RAW_DIRECTIVE,
    help_text = HELP_RAW_DIRECTIVE))
  params.add(new_parameter_specification(names = PARAM_ENABLE_SMILIES,
    help_text = HELP_ENABLE_SMILIES))
  params.add(new_parameter_specification(names = PARAM_FENCED_BLOCKS,
    help_text = HELP_FENCED_BLOCKS))
  params.add(new_parameter_specification(names = PARAM_SKIP_POUNDS,
    help_text = HELP_SKIP_POUNDS))

  let result = parse(params)

  if result.options.hasKey(PARAM_VERSION[0]):
    echo "lazy_rest_badger version " & lazy_rest.version_str
    quit()

  #if result.positional_parameters.len < 1:
  #  echo "Missing URL(s) to download"
  #  echo_help(params)
  #  quit()

  #if result.options.hasKey(PARAM_OUTPUT[0]):
  #  if result.positional_parameters.len > 1:
  #    echo "Error: can't use $1 option with multiple URLs" % [PARAM_OUTPUT[0]]
  #    echo_help(params)
  #    quit()
  #  echo "Will download to $1" % [result.options[PARAM_OUTPUT[0]].str_val]

  #if result.options.hasKey(PARAM_PROGRESS):
  #  echo "Will use progress type $1" % [result.options[PARAM_PROGRESS].str_val]


proc main() =
  process_commandline()

when isMainModule: main()
