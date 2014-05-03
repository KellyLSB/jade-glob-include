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


# Array Unique
Array.prototype.uniq = ->
  cache = {}; for data, index in @
    if cache[data] then continue
    cache[data] = true
    data


# Array is all matching CB
Array.prototype.isAll = (cb) ->
  result = (!!cb(data) for data in @).uniq()
  if result.length == 1 then result.shift() else false


# String Repeat
String.prototype.repeat = (num, mult) ->
  if typeof mult is 'undefined' then mult = 1
  Array((num * mult) + 1).join(@)


# Setup the Jade Glob Include patcher class
class JadeGlobInclude
  @tmp_dir: nodePath.resolve('tmp')
  @tmp_file: nodePath.resolve(@tmp_dir, 'glob_tmp.jade')
  @log_indent: 0


  @log: (message, indent) ->
    indent = if ! indent then @log_indent

    prefix = if indent > 0 then '~'.repeat(indent)+'> ' else ''

    console.info prefix.cyan + message


  @tmpDir: (tmp) ->
    @tmp_dir = nodePath.resolve(tmp)
    @tmpFile(nodePath.basename(@tmp_file))
    return @


  @prepTmpDir: ->
    # Remove 'tmp' if it is a file
    if nodeFs.existsSync(@tmp_dir) && ! nodeFs.statSync(@tmp_dir).isDirectory()
      nodeFs.unlinkSync(@tmp_dir)

    # Create the 'tmp' directory
    if ! nodeFs.existsSync(@tmp_dir)
      @log "Preparing temporary directory '#{@tmp_dir}'....".cyan
      nodeFs.mkdirSync(@tmp_dir)


  @tmpFile: (file) ->
    @tmp_file = nodePath.resolve(@tmp_dir, nodePath.basename(file))
    return @


  @useTmpFile: (data, cb) ->
    # Bump log indent up
    @log_indent++

    # Enforce the use an an Array containing strings
    if ! data instanceof Array && typeof data is 'string' then data = [data]
    if ! data instanceof Array && ! typeof data is 'string'
      return @log 'Received non Array or String as argument in `JadeGlobInclude.useTmpFile()` ...'.red
    if data instanceof Array && ! data.isAll((d) -> typeof d is 'string')
      return @log 'Received non String in Array in `JadeGlobInclude.useTmpFile()` ...'.red

    # Add notice to the top if the file describing it.
    data.unshift "//- Generated On: #{Date()}.\n"
    data.unshift '//- Temporary Jade File For Globbed Includes.'

    # Write the temporary file
    @log "Creating temporary file '#{@tmp_file}'.".yellow
    nodeFs.writeFileSync @tmp_file, data.join("\n"), flags: 'w+'

    # Run callback
    captured_result = cb @tmp_file

    # Cleanup and remove temporary file
    if nodeFs.existsSync @tmp_file
      @log "Removing temporary file '#{@tmp_file}'.".yellow
      nodeFs.unlinkSync @tmp_file

    # Knock log indent down
    @log_indent--

    # Reuturn the result
    captured_result


  @patch: (jade) ->
    JadeParser = jade.Parser

    # Don't patch a second time
    # NOTE: Used for grunt-jade data hack.
    if JadeParser.prototype.glob_includer then return jade

    # Notice to user :D
    @log 'Initializing Jade Glob Include....'.cyan

    # Prepare temporary directory
    @prepTmpDir()

    # Notice to user :D
    @log 'Mokeypatching Jade Parser....'.cyan

    # Copy out original method so it may be monkeypatched.
    jadeParseInclude = JadeParser.prototype.parseInclude.toString()

    # Split at comment to grab the include token data
    # TODO: This will need to be continuously updated as Jade changes.
    jadeParseInclude = jadeParseInclude.split('// has-filter')

    # Dual Assignment of the array halves
    [jadeParsePrefix, jadeParseInclude] = jadeParseInclude

    # Notice to user :D
    @log 'Carefully placing modified original parser back into Jade....'.cyan

    # Create new Include Parser
    eval "JadeParser.prototype.jadeParseInclude = function(fs, tok, path) {\n#{jadeParseInclude}"

    # Make a var of self
    $ = @

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
        $.log "Including: '#{file}'.".yellow
        return @jadeParseInclude fs, tok, file

      # Prepare data for temporary file
      if files.length > 0
        $.log "Including #{files.length} files via '#{path}' match.".cyan

        # Prepare the include statements
        data = for file in files
          "include #{nodePath.relative($.tmp_dir, nodePath.resolve(file))}"

      # No data was found, in order to prevent error return empty array
      else
        $.log "Zero files matched '#{path}'; will continue with using an" +
        "empty temporary file in order to prevent error.".red, @log_indent + 1
        data = []

      $.useTmpFile data, (file) => @jadeParseInclude(fs, tok, file)

    # Mark as initialized
    JadeParser.prototype.glob_includer = true

    # Notice to console of initialization.
    @log "Oh my Glob! Jade Glob Includer is now initialized....".green

    # Return modified jade instance.
    # NOTE: also returned by reference; the original object is modified.
    jade


# Export the class
module.exports = JadeGlobInclude
