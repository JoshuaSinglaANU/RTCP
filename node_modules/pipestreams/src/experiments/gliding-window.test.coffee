
'use strict'




############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'GLIDING-WINDOW'
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
PS                        = require '../..'
{ $, $async, }            = PS.export()


#-----------------------------------------------------------------------------------------------------------
@[ "gliding window: basic functionality" ] = ( T, done ) ->
  #.........................................................................................................
  pipeline      = []
  Ø             = ( x ) => pipeline.push x
  section_count = 0
  probes        = ( i for i in [ 0 .. 9 ] )
  width         = 3
  expect_count  = Math.max 0, probes.length - width + 1
  #.........................................................................................................
  Ø ( require 'pull-stream/sources/values' ) probes
  Ø PS.$gliding_window width, ( section ) ->
    section_count += +1
    urge section
  Ø PS.$collect()
  # Ø PS.$show()
  Ø $ 'null', ( data, send ) ->
    if data?
      T.ok section_count is expect_count
      send data
    else
      done()
      # send null
  Ø PS.$drain()
  #.........................................................................................................
  PS.pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@[ "gliding window: drop values" ] = ( T, done ) ->
  #.........................................................................................................
  pipeline      = []
  Ø             = ( x ) => pipeline.push x
  probes        = ( i for i in [ 0 .. 9 ] )
  width         = 3
  #.........................................................................................................
  Ø ( require 'pull-stream/sources/values' ) probes
  Ø PS.$gliding_window width, ( section ) ->
    [ d0, d1, d2, ] = section
    section[ 0 .. 2 ] = [ d0, d2, ] if d1 % 2 is 0
  Ø PS.$collect()
  # Ø PS.$show()
  Ø $ 'null', ( data, send ) ->
    if data?
      urge data
      T.ok CND.equals data, [ 0, 1, 3, 5, 7, 9 ]
      send data
    else
      done()
      # send null
  Ø PS.$drain()
  #.........................................................................................................
  PS.pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@[ "gliding window: insert values" ] = ( T, done ) ->
  #.........................................................................................................
  pipeline      = []
  Ø             = ( x ) => pipeline.push x
  probes        = ( i for i in [ 0 .. 9 ] )
  #.........................................................................................................
  Ø ( require 'pull-stream/sources/values' ) probes
  Ø PS.$gliding_window 1, ( section ) ->
    [ d0, ] = section
    section.push d0 * 2 if d0 % 2 is 1
  Ø PS.$collect()
  # Ø PS.$show()
  Ø $ 'null', ( data, send ) ->
    if data?
      urge data
      T.ok CND.equals data, [ 0, 1, 2, 2, 3, 6, 4, 5, 10, 6, 7, 14, 8, 9, 18 ]
      send data
    else
      done()
      # send null
  Ø PS.$drain()
  #.........................................................................................................
  PS.pull pipeline...


############################################################################################################
unless module.parent?
  test @



