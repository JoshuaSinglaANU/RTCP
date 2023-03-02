

'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'STEAMPIPES/TESTS/WYE'
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
SP                        = require '../..'
{ $, $async, }            = SP
#...........................................................................................................
{ jr
  is_empty }              = CND
defer                     = setImmediate
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }



#-----------------------------------------------------------------------------------------------------------
@[ "1 leapfrog lookaround with groups" ] = ( T, done ) ->
  probes_and_matchers = [
    [ [ [ 1 .. 12 ], ( ( d ) -> ( d % 3 ) isnt 0 ), ], [1,2,4,5,[null,3,6],7,8,[3,6,9],10,11,[6,9,12],[9,12,null]],                           null, ]
    [ [ [ 1 .. 12 ], ( ( d ) -> ( d % 3 ) is   0 ), ], [[null,1,2],3,[1,2,4],[2,4,5],6,[4,5,7],[5,7,8],9,[7,8,10],[8,10,11],12,[10,11,null]], null, ]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    #.......................................................................................................
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      [ values
        tester ]  = probe
      collector   = []
      pipeline    = []
      pipeline.push SP.new_value_source values
      pipeline.push SP.leapfrog tester, SP.lookaround $ ( d3, send ) ->
        [ prv, d, nxt, ]  = d3
        send d3
      pipeline.push SP.$collect { collector, }
      pipeline.push SP.$drain -> resolve collector
      SP.pull pipeline...
      #.....................................................................................................
      return null
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "1 leapfrog lookaround with groups 2" ] = ( T, done ) ->
  probes_and_matchers = [
    [ [ [ 1 .. 12 ], ( ( d ) -> ( d % 3 ) isnt 0 ), ], [1,2,4,5,[null,3,6],7,8,[3,6,9],10,11,[6,9,12],[9,12,null]],                           null, ]
    [ [ [ 1 .. 12 ], ( ( d ) -> ( d % 3 ) is   0 ), ], [[null,1,2],3,[1,2,4],[2,4,5],6,[4,5,7],[5,7,8],9,[7,8,10],[8,10,11],12,[10,11,null]], null, ]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    #.......................................................................................................
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      [ values
        tester ]  = probe
      collector   = []
      pipeline    = []
      pipeline.push SP.new_value_source values
      # pipeline.push SP.$show { title: 'µ33421-1', }
      # pipeline.push SP.leapfrog tester, SP.lookaround $ ( d3, send ) ->
      pipeline.push SP.lookaround { leapfrog: tester, }, $ ( d3, send ) ->
        # debug 'µ43443', jr d3
        [ prv, d, nxt, ] = d3
        send d3
      # pipeline.push SP.$show { title: 'µ33421-2', }
      pipeline.push SP.$collect { collector, }
      pipeline.push SP.$drain -> resolve collector
      SP.pull pipeline...
      #.....................................................................................................
      return null
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
### TAINT ordering not preserved ###
@[ "_____________ 2 leapfrog lookaround ungrouped" ] = ( T, done ) ->
  probes_and_matchers = [
    [ [ [ 1 .. 12 ], ( ( d ) -> ( d % 3 ) isnt 0 ), ], [ 1 .. 12 ], null, ]
    [ [ [ 1 .. 12 ], ( ( d ) -> ( d % 3 ) is   0 ), ], [ 1 .. 12 ], null, ]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    #.......................................................................................................
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      [ values
        tester ]  = probe
      collector   = []
      pipeline    = []
      pipeline.push SP.new_value_source values
      pipeline.push SP.leapfrog tester, SP.lookaround $ ( d3, send ) ->
        help 'µ44333', jr d3
        [ prv, d, nxt, ]  = d3
        send d
      pipeline.push SP.$show()
      pipeline.push SP.$collect { collector, }
      pipeline.push SP.$drain -> resolve collector
      SP.pull pipeline...
      #.....................................................................................................
      return null
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "3 lookaround" ] = ( T, done ) ->
  probes_and_matchers = [
    [ [ [ 1 .. 12 ], ( ( d ) -> ( d % 3 ) isnt 0 ), ], [ 1 .. 12 ], null, ]
    [ [ [ 1 .. 12 ], ( ( d ) -> ( d % 3 ) is   0 ), ], [ 1 .. 12 ], null, ]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    #.......................................................................................................
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      [ values
        tester ]  = probe
      collector   = []
      pipeline    = []
      pipeline.push SP.new_value_source values
      pipeline.push SP.lookaround $ ( d3, send ) ->
        [ prv, d, nxt, ]  = d3
        send d
      pipeline.push SP.$collect { collector, }
      pipeline.push SP.$drain -> resolve collector
      SP.pull pipeline...
      #.....................................................................................................
      return null
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "4 leapfrog" ] = ( T, done ) ->
  probes_and_matchers = [
    [ [ [ 1 .. 12 ], ( ( d ) -> ( d % 3 ) isnt 0 ), ], [1,2,300,4,5,600,7,8,900,10,11,1200],         null, ]
    [ [ [ 1 .. 12 ], ( ( d ) -> ( d % 3 ) is   0 ), ], [100,200,3,400,500,6,700,800,9,1000,1100,12], null, ]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    #.......................................................................................................
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      [ values
        tester ]  = probe
      collector   = []
      pipeline    = []
      pipeline.push SP.new_value_source values
      pipeline.push SP.leapfrog tester, $ ( d, send ) -> send d * 100
      pipeline.push SP.$collect { collector, }
      pipeline.push SP.$drain -> resolve collector
      SP.pull pipeline...
      #.....................................................................................................
      return null
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
### TAINT ordering not preserved ###
@[ "_____________ 5 leapfrog window ungrouped" ] = ( T, done ) ->
  probes_and_matchers = [
    [ [ [ 1 .. 12 ], ( ( d ) -> ( d % 3 ) isnt 0 ), ], [ 1 .. 12 ], null, ]
    [ [ [ 1 .. 12 ], ( ( d ) -> ( d % 3 ) is   0 ), ], [ 1 .. 12 ], null, ]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    #.......................................................................................................
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      [ values
        tester ]  = probe
      collector   = []
      pipeline    = []
      pipeline.push SP.new_value_source values
      pipeline.push SP.leapfrog tester, SP.window $ ( d3, send ) ->
        help 'µ44333', jr d3
        [ prv, d, nxt, ]  = d3
        send d
      pipeline.push SP.$show()
      pipeline.push SP.$collect { collector, }
      pipeline.push SP.$drain -> resolve collector
      SP.pull pipeline...
      #.....................................................................................................
      return null
  #.........................................................................................................
  done()
  return null


############################################################################################################
unless module.parent?
  # test @
  # test @[ "1 leapfrog lookaround with groups" ]
  # test @[ "1 leapfrog lookaround with groups 2" ]
  # test @[ "2 leapfrog lookaround ungrouped" ]
  # test @[ "3 lookaround" ]
  test @[ "4 leapfrog" ]
  # test @[ "5 leapfrog window ungrouped" ]
