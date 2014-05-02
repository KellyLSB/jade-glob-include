# Title: Jade-Glob-Include
# Author: Kelly Becker <kbecker@kellybecker.me>
# Website: http://kellybecker.me
# Repository: http://github.com/KellyLSB/jade-glob-include

# Include node tools
nodePath = require('path')
nodeFs = require('fs')

# Console Text Coloring
colors = require('colors')

# Directory Globber
glob = require('glob')

# NOTE: Include jade utils; this is a REQUIRED module.
# While I am Hijacking Jade, the code still runs in the context of this file.
utils = require('jade/lib/utils')


# Patcher for the Jade parser.
module.exports.Patch = (jade) ->
  JadeParser = jade.Parser

  # Don't patch a second time
  # NOTE: Used for grunt-jade data hack.
  if JadeParser.prototype.glob_includer then return jade

  # Modify the original so it may be used.
  jadeParseInclude = JadeParser.prototype.parseInclude

  # Split at comment to grab the include token data
  # TODO: This will need to be continuously updated as Jade changes.
  jadeParseInclude = jadeParseInclude
    .toString().split('// has-filter')

  # Dual Assignment
  [jadeParsePrefix, jadeParseInclude] = jadeParseInclude

  # Create new Include Parser
  eval "jadeParseInclude = function(fs, tok, path) {\n#{jadeParseInclude}"

  # Reapply modified code
  JadeParser.prototype.jadeParseInclude = jadeParseInclude

  # Replace the parser
  JadeParser.prototype.parseInclude = ->
    # Include the tokenized data from Jade
    eval jadeParsePrefix.split("\n").splice(1).join("\n")

    # NOTE: Remove CWD from the path; for readability and that we
    # are adding it back in for path's that won't return with it....
    path = nodePath.normalize(path).replace("#{process.cwd()}/", '')

    # Get list of files to include
    files = glob.sync nodePath.normalize(path)

    # If there was only one file; process normally.
    if files.length == 1
      file = files.shift()
      if this.filename == temp_file
        console.info '~> '.cyan + "Jade Glob Includer: Including from Glob: '#{file}'.".yellow
      else
        console.info "Jade Glob Includer: Including normally: '#{file}'.".yellow
      return @jadeParseInclude fs, tok, file

    # Prepare the includes for the temporary files
    if files.length > 0
      console.info "Jade Glob Includer: Including #{files.length} files via '#{path}' match.".cyan

      # Prep the temporary file contents.
      temp_data = ("include ../#{file}" for file in files)

    # Notify of zero files globbed
    else
      console.info "Jade Glob Includer: Zero files matched '#{path}'".red
      console.info "~> Will continue with using a empty Temporary File.\n".red

    # Add notice to the top if the file describing it.
    temp_data.unshift("//- Generated On: #{Date()}.\n")
    temp_data.unshift('//- Temporary Jade File For Globbed Includes.')

    # Write the temporary file
    console.info '~> '.cyan + "Jade Glob Includer: Creating temporary file '#{temp_file}'.".yellow
    nodeFs.writeFileSync temp_file,
      temp_data.join("\n"),
      flags: 'w+'

    # Parse the temporary file.
    captured_output = @jadeParseInclude fs, tok, temp_file

    # Cleanup and remove the temporary file
    if nodeFs.existsSync(temp_file)
      console.info '~> '.cyan + "Jade Glob Includer: Removing temporary file '#{temp_file}'.".yellow
      nodeFs.unlinkSync(temp_file)

    # Return the captured output
    return captured_output

  # Mark as initialized
  JadeParser.prototype.glob_includer = true

  # Notice to console of initialization.
  console.info "Jade Glob Includer: Initialized.".green

  # Define location for temporary file
  temp_dir = nodePath.join(process.cwd(), 'tmp')
  temp_file = nodePath.join(temp_dir, 'jade_glob_include_tmp.jade')

  # Remove 'tmp' if it is a file
  if nodeFs.existsSync(temp_dir) && ! nodeFs.statSync(temp_dir).isDirectory()
    nodeFs.unlinkSync(temp_dir)

  # Create the 'tmp' directory
  if ! nodeFs.existsSync(temp_dir)
    console.info "Jade Glob Includer: Creating temporary directory '#{temp_dir}'.".yellow
    nodeFs.mkdirSync(temp_dir)

  # Return modified jade instance.
  # NOTE: also returned by reference; the original object is modified.
  return jade
