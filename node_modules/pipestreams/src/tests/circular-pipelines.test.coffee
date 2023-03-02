
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
PS                        = require '../..'
{ $, $async, }            = PS.export()


#-----------------------------------------------------------------------------------------------------------
@[ "circular pipeline 1" ] = ( T, done ) ->
  probes_and_matchers = [
    [[true,3,4],[3,4,10,2,5,1,16,8,4,2,1],null]
    [[false,3,4],[3,4,10,2,5,1,16,8,4,2,1],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      #.....................................................................................................
      [ use_defer, values..., ] = probe
      refillable                = [ values..., ]
      mainsource                = PS.new_refillable_source refillable, { repeat: 2, show: true, }
      collector                 = []
      mainline                  = []
      mainline.push mainsource
      mainline.push PS.$defer() if use_defer
      mainline.push $ ( d, send ) ->
        if d > 1
          if d %% 2 is 0 then refillable.push d / 2
          else                refillable.push d * 3 + 1
        send d
      mainline.push PS.$collect { collector, }
      mainline.push PS.$drain ->
        help collector
        resolve collector
      PS.pull mainline...
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "circular pipeline 2" ] = ( T, done ) ->
  probes_and_matchers = [
    [[true,3,4],[3,4,10,2,5,1,],null]
    [[false,3,4],[3,4,10,2,5,1,],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      #.....................................................................................................
      [ use_defer, values..., ] = probe
      buffer                    = [ values..., ]
      mainsource                = PS.new_refillable_source buffer, { repeat: 1, }
      collector                 = []
      mainline                  = []
      mainline.push mainsource
      mainline.push PS.$defer() if use_defer
      mainline.push $ ( d, send ) ->
        return send.end() if d is 16
        if d > 1
          if d %% 2 is 0 then buffer.push d / 2
          else                buffer.push d * 3 + 1
        send d
      mainline.push PS.$collect { collector, }
      mainline.push PS.$drain ->
        help collector
        resolve collector
      PS.pull mainline...
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "circular pipeline 3" ] = ( T, done ) ->
  probes_and_matchers = [
    [[true,3,4],[3,4,10,2,5,1,],null]
    [[false,3,4],[3,4,10,2,5,1,],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      #.....................................................................................................
      [ use_defer, values..., ] = probe
      buffer                    = [ values..., ]
      mainsource                = PS.new_refillable_source buffer, { repeat: 1, }
      collector                 = []
      mainline                  = []
      mainline.push mainsource
      mainline.push PS.$defer() if use_defer
      mainline.push PS.$continue_if ( d ) -> d isnt 16
      mainline.push $ ( d, send ) ->
        if d > 1
          if d %% 2 is 0 then buffer.push d / 2
          else                buffer.push d * 3 + 1
        send d
      mainline.push PS.$collect { collector, }
      mainline.push PS.$drain ->
        help collector
        resolve collector
      PS.pull mainline...
  #.........................................................................................................
  done()
  return null



############################################################################################################
unless module.parent?
  test @
  # test @[ "circular pipeline 1" ]
  # test @[ "circular pipeline 2" ]
  # test @[ "generator as source 2" ]


