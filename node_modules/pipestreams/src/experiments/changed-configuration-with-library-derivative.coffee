


'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/DERIVATIVE'
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
test                      = require 'guy-test'
eq                        = CND.equals
jr                        = JSON.stringify
#...........................................................................................................
PS_ORIGINAL               = require '../..'
#...........................................................................................................
{ jr
  copy
  is_empty
  assign }                = CND
create                    = Object.create
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }
defer                     = setImmediate

#-----------------------------------------------------------------------------------------------------------
new_pipestreams_library = ( end_symbol = null ) ->
  R = PS_ORIGINAL._copy_library()
  if end_symbol isnt null
    R.symbols.end = end_symbol
  return R

#-----------------------------------------------------------------------------------------------------------
@[ "pipeline using altered configuration" ] = ( T, done ) ->
  # through = require 'pull-through'
  probes_and_matchers = [
    [[false,[1,2,3,null,5]],[1,1,1,2,2,2,3,3,3,null,null,null,5,5,5],null]
    [[false,[1,2,3,42,5]],[1,1,1,2,2,2,3,3,3],null]
    # [[true,[1,2,3,null,5]],[1,1,1,2,2,2,3,3,3,null,null,null,5,5,5],null]
    # [[false,[1,2,3,null,"stop",25,30]],[1,1,1,2,2,2,3,3,3,null,null,null],null]
    # [[true,[1,2,3,null,"stop",25,30]],[1,1,1,2,2,2,3,3,3,null,null,null],null]
    # [[false,[1,2,3,undefined,"stop",25,30]],[1,1,1,2,2,2,3,3,3,undefined,undefined,undefined,],null]
    # [[true,[1,2,3,undefined,"stop",25,30]],[1,1,1,2,2,2,3,3,3,undefined,undefined,undefined,],null]
    # [[false,["stop",25,30]],[],null]
    # [[true,["stop",25,30]],[],null]
    ]
  #.........................................................................................................
  my_end_sym                = 42
  PS                        = new_pipestreams_library my_end_sym
  debug PS.symbols
  { $
    $async }                = PS.export()
  #.........................................................................................................
  aborting_map = ( use_defer, mapper ) ->
    react = ( handler, data ) ->
      if data is 'stop' then  handler true
      else                    handler null, mapper data
    # a sink function: accept a source...
    return ( read ) ->
      # ...but return another source!
      return ( abort, handler ) ->
        read abort, ( error, data ) ->
          # if the stream has ended, pass that on.
          return handler error if error
          if use_defer then  defer -> react handler, data
          else                        react handler, data
          return null
        return null
      return null
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
      pipeline.push PS.$map ( d ) -> info '22398-2', xrpr d; collector.push d; return d
      pipeline.push PS.$map ( d ) -> info '22398-3', xrpr d; collector.push d; return d
      pipeline.push PS.$map ( d ) -> info '22398-4', xrpr d; collector.push d; return d
      pipeline.push PS.$drain ->
        help '44998', xrpr collector
        resolve collector
      PS.pull pipeline...
  #.........................................................................................................
  done()
  return null



############################################################################################################
unless module.parent?
  null
  test @
  # test @[ "demo through with null" ]
  # test @[ "demo watch pipeline on abort 1" ]
  # test @[ "demo watch pipeline on abort 2" ]
