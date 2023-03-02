

'use strict'


############################################################################################################
CND                       = require 'cnd'
badge                     = 'PIPESTREAMS/NJS-STREAMS-AND-FILES'
FS                        = require 'fs'
TO_PULL_STREAM            = require 'stream-to-pull-stream'
TO_NODE_STREAM            = require '../deps/pull-stream-to-stream-patched'
# TO_NODE_STREAM            = require 'pull-stream-to-stream'
defer                     = setImmediate



#===========================================================================================================
# READ FROM, WRITE TO FILES, NODEJS STREAMS
#-----------------------------------------------------------------------------------------------------------
@read_from_file = ( path, options ) ->
  ### TAINT consider using https://pull-stream.github.io/#pull-file-reader instead ###
  switch ( arity = arguments.length )
    when 1 then null
    when 2
      if CND.isa_function options
        [ path, options, on_end, ] = [ path, null, options, ]
    else throw new Error "µ9983 expected 1 or 2 arguments, got #{arity}"
  #.........................................................................................................
  return @read_from_nodejs_stream ( FS.createReadStream path, options )

#-----------------------------------------------------------------------------------------------------------
@read_chunks_from_file = ( path, byte_count ) ->
  unless ( CND.isa_number byte_count ) and ( byte_count > 0 ) and ( byte_count is parseInt byte_count )
    throw new Error "expected positive integer number, got #{rpr byte_count}"
  pfy           = ( require 'util' ).promisify
  source        = @new_push_source()
  #.........................................................................................................
  defer =>
    fd    = await ( pfy FS.open ) path, 'r'
    read  = pfy FS.read
    loop
      buffer = Buffer.alloc byte_count
      await read fd, buffer, 0, byte_count, null
      source.send buffer
    return null
  #.........................................................................................................
  return source

#-----------------------------------------------------------------------------------------------------------
@write_to_file = ( path, options, on_end ) ->
  ### TAINT consider to abandon all sinks except `$drain()` and use throughs with writers instead ###
  ### TAINT consider using https://pull-stream.github.io/#pull-write-file instead ###
  ### TAINT code duplication ###
  switch ( arity = arguments.length )
    when 1 then null
    when 2
      if CND.isa_function options
        [ path, options, on_end, ] = [ path, null, options, ]
    when 3
    else throw new Error "µ9983 expected 1 to 3 arguments, got #{arity}"
  #.........................................................................................................
  R           = @write_to_nodejs_stream ( FS.createWriteStream path, options ), on_end
  description = { type: 'write_to_file', path, options, on_end, }
  return @mark_as_sink R, description

#-----------------------------------------------------------------------------------------------------------
@read_from_nodejs_stream = ( stream ) ->
  switch ( arity = arguments.length )
    when 1 then null
    else throw new Error "µ9983 expected 1 argument, got #{arity}"
  #.........................................................................................................
  return TO_PULL_STREAM.source stream, ( error ) -> finish error

#-----------------------------------------------------------------------------------------------------------
@write_to_nodejs_stream = ( stream, on_end ) ->
  ### TAINT consider to abandon all sinks except `$drain()` and use throughs with writers instead ###
  ### TAINT code duplication ###
  switch ( arity = arguments.length )
    when 1, 2 then null
    else throw new Error "µ9983 expected 1 or 2 arguments, got #{arity}"
  #.........................................................................................................
  if on_end? and ( ( type = CND.type_of on_end ) isnt 'function' )
    throw new Error "µ9383 expected a function, got a #{type}"
  #.........................................................................................................
  has_finished = false
  #.........................................................................................................
  finish = ( error ) ->
    ### In case there was an error, throw it: ###
    if error?
      has_finished = true
      throw error if error?
    #.......................................................................................................
    if not has_finished
      has_finished = true
      on_end() if on_end?
    #.......................................................................................................
    return null
  #.........................................................................................................
  stream.on 'close', -> finish()
  #.........................................................................................................
  R           = TO_PULL_STREAM.sink stream, ( error ) -> finish error
  description = { type: 'write_to_nodejs_stream', stream, on_end, }
  return @mark_as_sink R, description

#-----------------------------------------------------------------------------------------------------------
@node_stream_from_source = ( source ) -> TO_NODE_STREAM.source source

#-----------------------------------------------------------------------------------------------------------
@node_stream_from_sink = ( sink ) ->
  ### TAINT consider to abandon all sinks except `$drain()` and use throughs with writers instead ###
  R           = TO_NODE_STREAM.sink sink
  description = { type: 'node_stream_from_sink', sink, }
  return @mark_as_sink R, description





