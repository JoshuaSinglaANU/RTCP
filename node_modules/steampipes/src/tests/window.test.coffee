
'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr.bind CND
badge                     = 'STEAMPIPES/TESTS/WINDOW'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
praise                    = CND.get_logger 'praise',    badge
echo                      = CND.echo.bind CND
#...........................................................................................................
test                      = require 'guy-test'
SP                        = require '../..'
{ $
  $async }                = SP

#-----------------------------------------------------------------------------------------------------------
@[ "WINDOWING $window" ] = ( T, done ) ->
  #.........................................................................................................
  probes_and_matchers = [
    [[[1,2,3,4],1,null],[[1],[2],[3],[4]],null]
    [[[1,2,3,4],2,null],[[null,1],[1,2],[2,3],[3,4],[4,null]],null]
    [[[1,2,3,4],3,null],[[null,null,1],[null,1,2],[1,2,3],[2,3,4],[3,4,null],[4,null,null]],null]
    [[[1,2,3,4],4,null],[[null,null,null,1],[null,null,1,2],[null,1,2,3],[1,2,3,4],[2,3,4,null],[3,4,null,null],[4,null,null,null]],null]
    [[[1,2,3,4],5,null],[[null,null,null,null,1],[null,null,null,1,2],[null,null,1,2,3],[null,1,2,3,4],[1,2,3,4,null],[2,3,4,null,null],[3,4,null,null,null],[4,null,null,null,null]],null]
    [[[1],1,null],[[1]],null]
    [[[1],2,null],[[null,1],[1,null]],null]
    [[[1],3,null],[[null,null,1],[null,1,null],[1,null,null]],null]
    [[[1],4,null],[[null,null,null,1],[null,null,1,null],[null,1,null,null],[1,null,null,null]],null]
    [[[],1,null],[],null]
    [[[],2,null],[],null]
    [[[],3,null],[],null]
    [[[],4,null],[],null]
    [[[1,2,3],0,null],[],'not a valid pipestreams_\\$window_settings']
    [[[1],2,'novalue'],[['novalue',1],[1,'novalue']],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      [ values
        width
        fallback ]  = probe
      source        = SP.new_value_source values
      pipeline      = []
      pipeline.push source
      pipeline.push SP.$window { width, fallback, }
      pipeline.push SP.$show()
      pipeline.push SP.$drain ( result ) -> resolve result
      SP.pull pipeline...
      return null
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "WINDOWING $window(), window() (2)" ] = ( T, done ) ->
  #.........................................................................................................
  probes_and_matchers = [
    [ { values: 'AABXXDXEFG', width: 2, }, 'ABXDXEFG' ]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      { values
        width     } = probe
      fallback      = Symbol 'fallback'
      source        = SP.new_value_source values
      pipeline      = []
      pipeline.push source
      pipeline.push SP.window { width, fallback, }, $ ( dx, send ) ->
        [ first_d, second_d, ] = dx
        return send second_d  if first_d  is fallback
        return                if second_d is fallback
        send second_d unless ( second_d is first_d )
      # pipeline.push SP.$window { width, }
      pipeline.push SP.$show()
      pipeline.push SP.$drain ( result ) -> resolve result.join ''
      # pipeline.push SP.$drain ( result ) -> resolve undefined
      SP.pull pipeline...
      return null
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "WINDOWING window with leapfrogging" ] = ( T, done ) ->
  #.........................................................................................................
  probes_and_matchers = [
    [[[1,2,3,4],1,null],[1,[2],3,[4]],"leapfrogging with windowing not yet implemented"]
    # [[[1,2,3,4],1,null],[1,[2],3,[4]],null]
    # [[[1,2,3,4],2,null],[1,[null,2],3,[2,4],[4,null]],null]
    # [[[1,2,3,4],3,null],[1,[null,null,2],3,[null,2,4],[2,4,null],[4,null,null]],null]
    # [[[1,2,3,4],4,null],[1,[null,null,null,2],3,[null,null,2,4],[null,2,4,null],[2,4,null,null],[4,null,null,null]],null]
    # [[[1,2,3,4],5,null],[1,[null,null,null,null,2],3,[null,null,null,2,4],[null,null,2,4,null],[null,2,4,null,null],[2,4,null,null,null],[4,null,null,null,null]],null]
    # [[[1],1,null],[1],null]
    # [[[1],2,null],[1],null]
    # [[[1],3,null],[1],null]
    # [[[1],4,null],[1],null]
    # [[[],1,null],[],null]
    # [[[],2,null],[],null]
    # [[[],3,null],[],null]
    # [[[],4,null],[],null]
    # [[[1,2,3],0,null],null,"not a valid pipestreams_\\$window_settings"]
    # [[[1],2,"novalue"],[1],null]
    # [[[2],2,"novalue"],[["novalue",2],[2,"novalue"]],null]
    # [[[1,2],2,"novalue"],[1,["novalue",2],[2,"novalue"]],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      [ values
        width
        fallback ]  = probe
      source        = SP.new_value_source values
      pipeline      = []
      leapfrog      = ( d ) -> d %% 2 is 1
      pipeline.push source
      pipeline.push SP.window { width, fallback, leapfrog, }, $ ( dx, send ) ->
        debug 'µ44772', dx
        send dx
      pipeline.push SP.$show()
      pipeline.push SP.$drain ( result ) -> resolve result
      SP.pull pipeline...
      return null
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "WINDOWING $lookaround" ] = ( T, done ) ->
  #.........................................................................................................
  probes_and_matchers = [
    [[[1,2,3,4],0,null],[[1],[2],[3],[4]],null]
    [[[1,2,3,4],1,null],[[null,1,2],[1,2,3],[2,3,4],[3,4,null]],null]
    [[[1,2,3,4],2,null],[[null,null,1,2,3],[null,1,2,3,4],[1,2,3,4,null],[2,3,4,null,null]],null]
    [[[1],1,null],[[null,1,null]],null]
    [[[],1,null],[],null]
    [[[],2,null],[],null]
    [[[],3,null],[],null]
    [[[],4,null],[],null]
    [[[1,2,3],-1],[],'not a valid pipestreams_\\$lookaround_settings']
    [[[1],1,42],[[42,1,42]],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      [ values
        delta
        fallback ]  = probe
      source        = SP.new_value_source values
      pipeline      = []
      pipeline.push source
      pipeline.push SP.$lookaround { delta, fallback, }
      pipeline.push SP.$show()
      pipeline.push SP.$drain ( result ) -> resolve result
      SP.pull pipeline...
      return null
  done()
  return null




############################################################################################################
unless module.parent?
  test @
  # test @[ "WINDOWING $window(), window() (2)" ]
  # test @[ "WINDOWING window with leapfrogging" ]


