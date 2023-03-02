
'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'STEAMPIPES/TESTS/MODIFIERS'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND
#...........................................................................................................
PATH                      = require 'path'
FS                        = require 'fs'
OS                        = require 'os'
test                      = require 'guy-test'
#...........................................................................................................
# SP                        = require '../..'
# { $
#   $async
#   $watch
#   $show  }                = SP.export()
#...........................................................................................................
types                     = require '../types'
{ isa
  validate
  type_of }               = types
#...........................................................................................................
read                      = ( path ) -> FS.readFileSync path, { encoding: 'utf-8', }
defer                     = setImmediate
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }
jr                        = JSON.stringify


#-----------------------------------------------------------------------------------------------------------
@[ "modifiers ($once_before_first)" ] = ( T, done ) ->
  SP = require '../..'
  #.........................................................................................................
  { $
    $async
    $drain
    $once_before_first
    $show } = SP.export()
  #.........................................................................................................
  $transform = =>
    return $once_before_first ( send ) ->
      debug '^12287^'
      send "may I introduce"
  #.........................................................................................................
  do =>
    source    = "Behind the Looking-Glass".split /\s+/
    matcher   = ["may I introduce","Behind","the","Looking-Glass"]
    pipeline  = []
    pipeline.push source
    pipeline.push $transform()
    pipeline.push $show()
    pipeline.push $drain ( result ) =>
      help jr result
      T.eq result, matcher
      done()
    SP.pull pipeline...
    return null
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "modifiers ($once_with_first)" ] = ( T, done ) ->
  SP = require '../..'
  #.........................................................................................................
  { $
    $async
    $drain
    $once_with_first
    $show } = SP.export()
  #.........................................................................................................
  do =>
    source    = "Behind the Looking-Glass".split /\s+/
    matcher   = ["Behold!—Behind","the","Looking-Glass"]
    pipeline  = []
    pipeline.push source
    pipeline.push $once_with_first ( d, send ) -> send "Behold!—" + d
    pipeline.push $show()
    pipeline.push $drain ( result ) =>
      help jr result
      T.eq result, matcher
      done()
    SP.pull pipeline...
    return null
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "modifiers ($once_after_last)" ] = ( T, done ) ->
  SP = require '../..'
  #.........................................................................................................
  { $
    $async
    $drain
    $once_after_last
    $show } = SP.export()
  #.........................................................................................................
  $transform = =>
    return $once_after_last ( send ) ->
      debug '^12287^'
      send "is an interesting book"
  #.........................................................................................................
  do =>
    source    = "Behind the Looking-Glass".split /\s+/
    matcher   = ["Behind","the","Looking-Glass","is an interesting book"]
    pipeline  = []
    pipeline.push source
    pipeline.push $transform()
    pipeline.push $show()
    pipeline.push $drain ( result ) =>
      help jr result
      T.eq result, matcher
      done()
    SP.pull pipeline...
    return null
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "modifiers ($once_async_before_first)" ] = ( T, done ) ->
  SP = require '../..'
  #.........................................................................................................
  { $
    $async
    $drain
    $once_async_before_first
    $show } = SP.export()
  #.........................................................................................................
  $transform = =>
    return $once_async_before_first ( send, done ) ->
      debug '^12287^'
      defer ->
        send "may I introduce"
        done()
      return null
  #.........................................................................................................
  do =>
    source    = "Behind the Looking-Glass".split /\s+/
    matcher   = ["may I introduce","Behind","the","Looking-Glass"]
    pipeline  = []
    pipeline.push source
    pipeline.push $transform()
    pipeline.push $show()
    pipeline.push $drain ( result ) =>
      help jr result
      T.eq result, matcher
      done()
    SP.pull pipeline...
    return null
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "modifiers ($once_async_after_last)" ] = ( T, done ) ->
  SP = require '../..'
  #.........................................................................................................
  { $
    $async
    $drain
    $once_async_after_last
    $show } = SP.export()
  #.........................................................................................................
  $transform = =>
    return $once_async_after_last ( send, done ) ->
      debug '^12287^'
      defer ->
        send "is an interesting book"
        done()
      return null
  #.........................................................................................................
  do =>
    source    = "Behind the Looking-Glass".split /\s+/
    matcher   = ["Behind","the","Looking-Glass","is an interesting book"]
    pipeline  = []
    pipeline.push source
    pipeline.push $transform()
    pipeline.push $show()
    pipeline.push $drain ( result ) =>
      help jr result
      T.eq result, matcher
      done()
    SP.pull pipeline...
    return null
  #.........................................................................................................
  return null


############################################################################################################
unless module.parent?
  test @
  # test @[ "modifiers ($once_before_first)" ]
  # test @[ "modifiers ($once_after_last)" ]
  # test @[ "modifiers ($once_async_before_first)" ]
  # test @[ "modifiers ($once_async_after_last)" ]







