
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'STEAMPIPES/TESTS/SORT'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND
{ is_empty
  copy
  assign
  jr }                    = CND
#...........................................................................................................
test                      = require 'guy-test'
#...........................................................................................................
SP                        = require '../..'
{ $, $async, }            = SP


#-----------------------------------------------------------------------------------------------------------
sort = ( values ) -> new Promise ( resolve, reject ) =>
  ### TAINT should handle errors (?) ###
  pipeline  = []
  pipeline.push SP.new_value_source values
  pipeline.push SP.$sort()
  pipeline.push SP.$drain ( result ) -> resolve result
  SP.pull pipeline...
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "sort 1" ] = ( T, done ) ->
  # debug jr ( key for key of SP ).sort(); xxx
  probes_and_matchers = [
    [ [ 4, 9, 10, 3, 2 ], [ 2, 3, 4, 9, 10 ] ]
    [ [ 'a', 'z', 'foo' ], [ 'a', 'foo', 'z' ] ]
    ]
  count     = probes_and_matchers.length
  source    = SP.new_push_source()
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      resolve await sort probe
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "sort 2" ] = ( T, done ) ->
  # debug jr ( key for key of SP ).sort(); xxx
  probes_and_matchers = [
    [[4,9,10,3,2,null],[2,3,4,9,10],null]
    [[4,9,10,3,2,null],[2,3,4,9,10],null]
    [[4,9,10,"frob",3,2,null],null,"unable to compare a text to a float"]
    [["a",1,"z","foo"],null,"unable to compare a float to a text"]
    ]
  count     = probes_and_matchers.length
  source    = SP.new_push_source()
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      pipeline  = []
      pipeline.push SP.new_value_source probe
      pipeline.push SP.$sort()
      pipeline.push SP.$drain ( result ) -> resolve result
      SP.pull pipeline...
      # resolve await sort probe
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "sort with permissive mode" ] = ( T, done ) ->
  # debug jr ( key for key of SP ).sort(); xxx
  probes_and_matchers = [
    [[4,9,10,3,2,null],[2,3,4,9,10],null]
    [[4,9,10,3,2,null],[2,3,4,9,10],null]
    [[4,9,10,"frob",3,2,null],[2,4,9,10,"frob",3],null]
    [["a",1,"z","foo"],["a",1,"foo","z"],null]
    ]
  count     = probes_and_matchers.length
  source    = SP.new_push_source()
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      pipeline  = []
      pipeline.push SP.new_value_source probe
      pipeline.push SP.$sort { strict: false, }
      pipeline.push SP.$drain ( result ) -> resolve result
      SP.pull pipeline...
      # resolve await sort probe
  #.........................................................................................................
  done()
  return null


############################################################################################################
if module is require.main then do =>
  test @
  # test @[ "sort with permissive mode" ]
  # test @[ "sort 2" ]

