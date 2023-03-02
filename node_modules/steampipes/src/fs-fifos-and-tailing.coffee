

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


#-----------------------------------------------------------------------------------------------------------
@new_unix_fifo_source = ( path ) ->
  throw new Error "^344^ currently not usable because of buffering issues"
  # thx to https://stackoverflow.com/a/52622889/7568091
  validate.nonempty_text path
  FS      = require 'fs'
  NET     = require 'net'
  R       = @new_push_source()
  flags   = FS.constants.O_RDONLY | FS.constants.O_NONBLOCK
  fd      = FS.openSync path, flags
  pipe    = new NET.Socket { fd, readable: true, }
  pipe.setNoDelay true
  pipe.on 'data', ( data )    => debug '^6556576^', pipe.bytesRead, data; R.send data
  pipe.on 'end',              => debug '^3338^', "ended: #{path}"; R.end()
  # pipe.on 'close',            => debug '^3338^', "closed: #{path}"; R.end()
  pipe.on 'error', ( error )  => throw error
  return R

#-----------------------------------------------------------------------------------------------------------
@new_stdin_source = ->
  R             = @new_push_source()
  input_stream  = process.stdin
  input_stream.on 'data', ( data ) => R.send data
  input_stream.on 'close', => R.end()
  return R




