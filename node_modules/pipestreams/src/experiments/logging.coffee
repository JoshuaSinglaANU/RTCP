

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/EXPERIMENTS/PULL-STREAM-EXAMPLES-PULL'
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
after                     = ( dts, f ) -> setTimeout  f, dts * 1000
every                     = ( dts, f ) -> setInterval f, dts * 1000
defer                     = setImmediate
{ jr
  is_empty }              = CND
#...........................................................................................................
PS                        = require '../..'
{ $, $async, }            = PS.export()
test                      = require 'guy-test'
assign                    = Object.assign
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }


#-----------------------------------------------------------------------------------------------------------
@[ "demo through with null" ] = ( T, done ) ->
  probes_and_matchers = [
    # [[ 5, 15, 20, undefined, 25, 30, ], [ 10, 30, 40, undefined, 50, 60 ]]
    [[1,2,3,null,4,5],[2,6,4,6,null,null,12,8,10],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      is_odd    = ( d ) -> ( d %% 2 ) isnt 0
      bylog     = PS.get_logger 'b', 'red'
      mainlog   = PS.get_logger 'm', 'gold'
      #.....................................................................................................
      # source    = PS.new_value_source probe
      source    = PS.new_random_async_value_source probe
      collector = []
      byline    = []
      byline.push bylog PS.$pass()
      byline.push PS.$filter ( d ) -> d %% 2 is 0
      byline.push $ ( d, send ) -> send if d? then d * 3 else d
      # byline.push PS.$watch ( d ) -> info xrpr d
      byline.push bylog PS.$pass()
      byline.push PS.$collect { collector, }
      byline.push bylog PS.$pass()
      byline.push PS.$drain()
      bystream  = PS.pull byline...
      mainline  = []
      mainline.push source
      # mainline.push log PS.$watch ( d ) -> info '--->', d
      mainline.push mainlog PS.$tee bystream
      mainline.push mainlog PS.$defer()
      mainline.push mainlog $ ( d, send ) -> send if d? then d * 2 else d
      # mainline.push mainlog PS.$tee is_odd, PS.pull byline...
      mainline.push mainlog PS.$collect { collector, }
      mainline.push mainlog PS.$drain ->
        help collector
        resolve collector
      PS.pull mainline...
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "circular pipeline 1" ] = ( T, done ) ->
  # through = require 'pull-through'
  probes_and_matchers = [
    # [[ 5, 15, 20, undefined, 25, 30, ], [ 10, 30, 40, undefined, 50, 60 ]]
    # [[1,2,3,4,5],[2,6,4,6,null,null,12,8,10],null]
    [[3,4],[3,4,10,2,5,1,16,8,4,2,1],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      #-----------------------------------------------------------------------------------------------------
      bylog                   = PS.get_logger 'b', 'red'
      mainlog                 = PS.get_logger 'm', 'gold'
      #.....................................................................................................
      use_defer               = true
      buffer                  = [ probe..., ]
      mainsource              = PS.new_refillable_source buffer, { repeat: 1, }
      collector               = []
      mainline                = []
      mainline.push mainsource
      mainline.push mainlog PS.$defer() if use_defer
      mainline.push mainlog $ ( d, send ) ->
        if d > 1
          if d %% 2 is 0 then buffer.push d / 2
          else                buffer.push d * 3 + 1
        send d
        # send PS.symbols.end if d is 1
      mainline.push mainlog PS.$collect { collector, }
      mainline.push mainlog PS.$drain ->
        help collector
        resolve collector
      PS.pull mainline...
      # mainsource.send 3
      # mainsource.end()
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "circular pipeline 2" ] = ( T, done ) ->
  # through = require 'pull-through'
  probes_and_matchers = [
    [[true,3,4],[30,32,34,10,12,14,20,22,24,94,100,34,40,64,70],null]
    [[false,3,4],[10,30,12,32,14,34,20,22,24,34,94,40,100,64,70],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      upperlog                  = PS.get_logger 'U', 'gold'
      lowerlog                  = PS.get_logger 'L', 'red'
      #.....................................................................................................
      [ use_defer, values..., ] = probe
      collector                 = []
      upperline                 = []
      lowerline                 = []
      refillable                = [ 20 .. 24 ]
      #.....................................................................................................
      source_1                  = PS.new_value_source [ 10 .. 14 ]
      source_2                  = PS.new_refillable_source refillable, { repeat: 1, show: true, }
      source_3                  = PS.new_value_source [ 30 .. 34 ]
      #.....................................................................................................
      upperline.push PS.new_merged_source source_1, source_2
      upperline.push upperlog PS.$defer() if use_defer
      upperline.push PS.$watch ( d ) -> echo 'U', xrpr d
      upperstream = PS.pull upperline...
      #.....................................................................................................
      lowerline.push PS.new_merged_source upperstream, source_3
      lowerline.push PS.$watch ( d ) -> echo 'L', xrpr d
      lowerline.push lowerlog $ ( d, send ) ->
        if d %% 2 is 0
          send d
        else
          refillable.push d * 3 + 1
      lowerline.push PS.$collect { collector, }
      lowerline.push PS.$drain ->
        help collector
        resolve collector
      PS.pull lowerline...
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "duplex" ] = ( T, done ) ->
  # through = require 'pull-through'
  probes_and_matchers = [
    [[1,2,3,4,5],[11,12,13,14,15],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      bylog         = PS.get_logger 'b', 'red'
      mainlog       = PS.get_logger 'm', 'gold'
      mainsource    = PS.new_value_source probe
      collector     = []
      mainline      = []
      # duplexsource = PS.new_push_source()
      stream_a = PS.pull ( bylog $ ( d, send ) -> send d * 3 )
      stream_b = PS.pull ( bylog $ ( d, send ) -> send d * 2 )
      stream_c = { source: stream_a, sink: stream_b, }
      #.....................................................................................................
      mainline.push mainsource
      mainline.push mainlog stream_c
      # mainline.push mainlog stream_c
      # # mainline.push mainlog PS.$defer()
      # mainline.push mainlog PS.$pass()
      # mainline.push mainlog $ ( d, send ) -> send d + 10
      # # mainline.push mainlog $async ( d, send, done ) -> send d + 10; done()
      mainline.push mainlog PS.$watch ( d ) -> collector.push d
      mainline.push mainlog PS.$drain ->
        help collector
        resolve collector
      PS.pull mainline...
  #.........................................................................................................
  done()
  return null


############################################################################################################
unless module.parent?
  null
  # test @
  # test @[ "circular pipeline 1" ], { timeout: 5000, }
  test @[ "circular pipeline 2" ], { timeout: 5000, }
  # test @[ "duplex" ]
  # @[ "_duplex 1" ]()
  # @[ "_duplex 2" ]()

