
'use strict'




############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'GENERATOR-AS-SOURCE'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
test                      = require 'guy-test'
#...........................................................................................................
SP                        = require '../..'
{ $, $async, }            = SP


#-----------------------------------------------------------------------------------------------------------
@[ "generator as source: random numbers" ] = ( T, done ) ->
  #.........................................................................................................
  pipeline      = []
  Ø             = ( x ) => pipeline.push x
  # expect_count  = Math.max 0, probes.length - width + 1
  #.........................................................................................................
  ### TAINT his isn't a generator in the technical sense, but the code from
  https://github.com/pull-stream/pull-stream/blob/master/sources/infinite.js expanded upon. ###
  $random = ( n, seed, delta ) ->
    rnd = CND.get_rnd n, seed, delta
    return ( end, callback ) ->
      return callback end   if end
      return callback true  if 0 > ( n += -1 )
      callback null, rnd()
  #.........................................................................................................
  Ø $random 10, 1, 1
  Ø SP.$show()
  Ø SP.$collect()
  Ø $ { last: null, }, ( data, send ) ->
    if data?
      # T.ok section_count is expect_count
      send data
    else
      done()
      # send null
  Ø SP.$drain()
  #.........................................................................................................
  SP.pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@[ "generator as source 2" ] = ( T, done ) ->
  count = 0
  #.........................................................................................................
  g = ( max ) ->
    loop
      break if count >= max
      yield ++count
    return null
  #.........................................................................................................
  await T.perform null, [1,2,3,4,null,6,7,8,9,10], ->
    return new Promise ( resolve ) ->
      pipeline = []
      pipeline.push SP.new_generator_source g 10
      pipeline.push $ ( d, send ) -> send if d is 5 then null else d
      pipeline.push SP.$show()
      pipeline.push SP.$collect()
      pipeline.push SP.$watch ( d ) ->
        debug '22920', d
        resolve d
      pipeline.push SP.$drain()
      SP.pull pipeline...
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "generator as source 3" ] = ( T, done ) ->
  count = 0
  #.........................................................................................................
  g = ->
    loop
      yield ++count
    return null
  #.........................................................................................................
  await T.perform null, [1,2,3,4,], -> return new Promise ( resolve ) ->
    pipeline = []
    pipeline.push SP.new_generator_source g()
    pipeline.push SP.$defer()
    pipeline.push SP.$end_if ( d ) -> d is 5
    pipeline.push SP.$show()
    pipeline.push SP.$collect()
    pipeline.push SP.$watch ( d ) ->
      debug '22920', d
      resolve d
    pipeline.push SP.$drain()
    SP.pull pipeline...
  done()
  return null


############################################################################################################
unless module.parent?
  test @

