

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
@[ "demo watch pipeline on abort 2" ] = ( T, done ) ->
  # through = require 'pull-through'
  probes_and_matchers = [
    [[false,[1,2,3,null,5]],[1,1,1,2,2,2,3,3,3,null,null,null,5,5,5],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      #.....................................................................................................
      [ use_defer
        values ]  = probe
      source      = PS.new_value_source values
      collector   = []
      pipeline    = []
      pipeline.push source
      pipeline.push aborting_map use_defer, ( d ) -> info '22398-1', xrpr d; return d
      pipeline.push PS.$ ( d, send ) -> info '22398-2', xrpr d; collector.push d; send d
      pipeline.push PS.$ ( d, send ) -> info '22398-3', xrpr d; collector.push d; send d
      pipeline.push PS.$ ( d, send ) -> info '22398-4', xrpr d; collector.push d; send d
      # pipeline.push PS.$map ( d ) -> info '22398-2', xrpr d; collector.push d; return d
      # pipeline.push PS.$map ( d ) -> info '22398-3', xrpr d; collector.push d; return d
      # pipeline.push PS.$map ( d ) -> info '22398-4', xrpr d; collector.push d; return d
      pipeline.push PS.$drain ->
        help '44998', xrpr collector
        resolve collector
      pull pipeline...
  #.........................................................................................................
  done()
  return null

############################################################################################################
unless module.parent?
  # include = []
  # @_prune()
  # @_main()
  test @
  # test @[ "remit with end detection 1" ]
  # test @[ "remit with end detection 2" ]
  # test @[ "$surround async" ]
  # test @[ "end push source (1)" ]
  # test @[ "end push source (2)" ]
  # test @[ "end push source (3)" ]
  # test @[ "end push source (4)" ]
  # test @[ "end random async source" ]
  # test @[ "watch with end detection 1" ]
  # test @[ "watch with end detection 2" ]
  # test @[ "demo watch pipeline on abort 2" ]






