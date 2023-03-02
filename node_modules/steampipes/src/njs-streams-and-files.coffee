

'use strict'


############################################################################################################
CND                       = require 'cnd'
badge                     = 'STEAMPIPES/NJS-STREAMS-AND-FILES'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
FS                        = require 'fs'
# TO_PULL_STREAM            = require 'stream-to-pull-stream'
# TO_NODE_STREAM            = require '../deps/pull-stream-to-stream-patched'
# TO_NODE_STREAM            = require 'pull-stream-to-stream'
defer                     = setImmediate
{ jr }                    = CND
types                     = require './types'
{ isa
  validate
  type_of }               = types



#===========================================================================================================
# READ FROM, WRITE TO FILES, NODEJS STREAMS
#-----------------------------------------------------------------------------------------------------------
@read_from_file = ( path, byte_count = 65536 ) ->
  ### TAINT use settings object ###
  validate.positive_integer byte_count
  pfy           = ( require 'util' ).promisify
  source        = @new_push_source()
  #.........................................................................................................
  defer =>
    fd    = await ( pfy FS.open ) path, 'r'
    read  = pfy FS.read
    loop
      buffer      = Buffer.alloc byte_count
      bytes_read  = ( await read fd, buffer, 0, byte_count, null ).bytesRead
      break if bytes_read is 0
      source.send if bytes_read < byte_count then ( buffer.slice 0, bytes_read ) else buffer
    source.end()
    return null
  #.........................................................................................................
  return source

#-----------------------------------------------------------------------------------------------------------
@_KLUDGE_file_as_buffers = ( path, byte_count = 65536 ) -> new Promise ( resolve ) =>
  pipeline  = []
  pipeline.push @read_from_file path, byte_count
  pipeline.push @$pass()
  pipeline.push @$drain ( buffers ) => resolve buffers
  @pull pipeline...
  return null

#-----------------------------------------------------------------------------------------------------------
@$split = ( splitter = '\n', decode = true ) ->
  ### thx to https://github.com/maxogden/binary-split/blob/master/index.js ###
  validate.nonempty_text splitter
  validate.boolean decode
  is_buffer = Buffer.isBuffer
  matcher   = Buffer.from splitter
  buffered  = null
  last      = Symbol 'last'
  #.........................................................................................................
  find_first_match = ( buffer, offset ) ->
    return -1 if offset >= buffer.length
    for i in [ offset ... buffer.length ] by +1
      if buffer[ i ] is matcher[ 0 ]
        if matcher.length > 1
          fullMatch = true
          j = i
          k = 0
          while j < i + matcher.length
            if buffer[ j ] isnt matcher[ k ]
              fullMatch = false
              break
            j++
            k++
          return j - matcher.length if fullMatch
        else
          break
    return i + matcher.length - 1
  #.........................................................................................................
  return @$ { last, }, ( d, send ) ->
    if d is last
      if buffered?
        send if decode then ( buffered.toString 'utf-8' ) else buffered
      return
    throw new Error "µ23211 expected a buffer, got a #{type_of d}" unless is_buffer d
    offset    = 0
    lastMatch = 0
    if buffered?
      d         = Buffer.concat [ buffered, d, ]
      offset    = buffered.length
      buffered  = null
    loop
      idx = find_first_match d, offset - matcher.length + 1
      if idx >= 0 and idx < d.length
        e         = d.slice lastMatch, idx
        send if decode then ( e.toString 'utf-8' ) else e
        offset    = idx + matcher.length
        lastMatch = offset
      else
        buffered  = d.slice(lastMatch)
        break
    return null

#-----------------------------------------------------------------------------------------------------------
@tee_write_to_file = ( path, options ) ->
  ### TAINT consider to abandon all sinks except `$drain()` and use throughs with writers instead ###
  ### TAINT consider using https://pull-stream.github.io/#pull-write-file instead ###
  ### TAINT code duplication ###
  switch ( arity = arguments.length )
    when 1 then stream = FS.createWriteStream path
    when 2 then stream = FS.createWriteStream path, options
    else throw new Error "µ9983 expected 1 to 3 arguments, got #{arity}"
  return @tee_write_to_nodejs_stream stream

#-----------------------------------------------------------------------------------------------------------
@tee_write_to_file_sync = ( path, options ) ->
  return @$watch ( d ) -> FS.appendFileSync path, d

# #-----------------------------------------------------------------------------------------------------------
# @read_from_nodejs_stream = ( stream ) ->
#   switch ( arity = arguments.length )
#     when 1 then null
#     else throw new Error "µ9983 expected 1 argument, got #{arity}"
#   #.........................................................................................................
#   return TO_PULL_STREAM.source stream, ( error ) -> finish error

#-----------------------------------------------------------------------------------------------------------
@tee_write_to_nodejs_stream = ( stream ) ->
  ### TAINT code duplication ###
  # throw new Error "µ76644 method `tee_write_to_nodejs_stream()` not yet implemented"
  switch ( arity = arguments.length )
    when 1 then null
    else throw new Error "µ9983 expected 1 argument, got #{arity}"
  last = Symbol 'last'
  #.........................................................................................................
  stream.on 'close', -> debug 'µ55544', 'close'
  stream.on 'error', -> throw error
  #.........................................................................................................
  return @$ { last, }, ( d, send ) =>
    warn "µ87876 closing stream" if d is last
    return stream.close() if d is last
    warn "µ87876 writing", jr d
    stream.write d
    send d

# #-----------------------------------------------------------------------------------------------------------
# @tee_write_to_nodejs_stream = ( stream, on_end ) ->
#   ### TAINT code duplication ###
#   switch ( arity = arguments.length )
#     when 1, 2 then null
#     else throw new Error "µ9983 expected 1 or 2 arguments, got #{arity}"
#   validate.function on_end if on_end?
#   has_finished  = false
#   last          = Symbol 'last'
#   #.........................................................................................................
#   finish = ( error ) ->
#     if error?
#       has_finished = true
#       throw error if error?
#     if not has_finished
#       has_finished = true
#       on_end() if on_end?
#     return null
#   #.........................................................................................................
#   stream.on 'close', -> finish()
#   stream.on 'error', -> finish error
#   # description = { [@marks.isa_sink], type: 'tee_write_to_nodejs_stream', stream, on_end, }
#   #.........................................................................................................
#   pipeline = []
#   pipeline.push @$watch { last, }, ( d ) ->
#     return stream.close() if d is last
#     stream.write d
#   pipeline.push @$drain finish
#   #.........................................................................................................
#   return @pull pipeline...

# #-----------------------------------------------------------------------------------------------------------
# @node_stream_from_source = ( source ) -> TO_NODE_STREAM.source source

# #-----------------------------------------------------------------------------------------------------------
# @node_stream_from_sink = ( sink ) ->
#   ### TAINT consider to abandon all sinks except `$drain()` and use throughs with writers instead ###
#   R           = TO_NODE_STREAM.sink sink
#   description = { type: 'node_stream_from_sink', sink, }
#   return @mark_as_sink R, description





