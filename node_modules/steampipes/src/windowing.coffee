

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'STEAMPIPES/WINDOWING'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
{ jr }                    = CND
assign                    = Object.assign
#...........................................................................................................
types                     = require './types'
{ isa
  validate
  type_of }               = types
misfit                    = Symbol 'misfit'

#-----------------------------------------------------------------------------------------------------------
types.declare 'pipestreams_$window_settings',
  tests:
    "x is an object":                         ( x ) -> @isa.object x
    "x.width is a positive":                  ( x ) -> @isa.positive x.width

#-----------------------------------------------------------------------------------------------------------
types.declare 'pipestreams_$lookaround_settings',
  tests:
    "x is an object":                         ( x ) -> @isa.object x
    "x.delta is a cardinal":                  ( x ) -> @isa.cardinal x.delta

#-----------------------------------------------------------------------------------------------------------
@$window = ( settings ) ->
  ### Moving window over data items in stream. Turns stream of values into stream of
  lists each `width` elements long. ###
  defaults                = { width: 3, fallback: null, }
  settings                = assign {}, defaults, settings
  validate.pipestreams_$window_settings settings
  #.........................................................................................................
  if settings.leapfrog?
    throw new Error "µ77871 setting 'leapfrog' only valid for PS.window(), not PS.$window()"
  #.........................................................................................................
  if settings.width is 1
    return @$ ( d, send ) => send [ d, ]
  #.........................................................................................................
  last                    = Symbol 'last'
  had_value               = false
  fallback                = settings.fallback
  buffer                  = ( fallback for _ in [ 1 .. settings.width ] )
  #.........................................................................................................
  return @$ { last, }, ( d, send ) =>
    if d is last
      if had_value
        for _ in [ 1 ... settings.width ]
          buffer.shift()
          buffer.push fallback
          send buffer[ .. ]
      return null
    had_value = true
    buffer.shift()
    buffer.push d
    send buffer[ .. ]
    return null

#-----------------------------------------------------------------------------------------------------------
@$lookaround = ( settings ) ->
  ### Turns stream of values into stream of lists of values, each `( 2 * delta ) + 1` elements long;
  unlike `$window()`, will send exactly as many lists as there are values in the stream. Default
  is `delta: 1`, i.e. you get to see lists `[ prv, d, nxt, ]` where `prv` is the previous value
  (or the fallback which itself defaults to `null`), `d` is the current value, and `nxt` is the
  upcoming value (or `fallback` in case the stream will end after this value). ###
  defaults  = { delta: 1, fallback: null, }
  settings  = assign {}, defaults, settings
  validate.pipestreams_$lookaround_settings settings
  #.........................................................................................................
  if settings.leapfrog?
    throw new Error "µ77872 setting 'leapfrog' only valid for PS.lookaround(), not PS.$lookaround()"
  #.........................................................................................................
  if settings.delta is 0
    return @$ ( d, send ) => send [ d, ]
  #.........................................................................................................
  fallback  = settings.fallback
  delta     = center = settings.delta
  pipeline  = []
  pipeline.push @$window { width: ( 2 * delta + 1 ), fallback: misfit, }
  pipeline.push @$ ( d, send ) =>
    # debug 'µ11121', rpr d
    # debug 'µ11121', rpr ( ( if x is misfit then fallback else x ) for x in d )
    return null if d[ center ] is misfit
    send ( ( if x is misfit then fallback else x ) for x in d )
    return null
  return @pull pipeline...
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@window = ( settings, transform ) ->
  switch arity = arguments.length
    when 1
      [ settings, transform, ] = [ null, settings, ]
    when 2 then null
    else throw new Error "µ23111 expected 1 or 2 arguments, got #{arity}"
  #.........................................................................................................
  if ( leapfrog = settings?.leapfrog )?
    throw new Error "µ65532 leapfrogging with windowing not yet implemented"
    delete settings.leapfrog
  #.........................................................................................................
  pipeline = []
  pipeline.push @$window settings
  pipeline.push transform
  R = @pull pipeline...
  #.........................................................................................................
  # if leapfrog?
  #   return @leapfrog leapfrog, R
  # #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@lookaround = ( settings, transform ) ->
  switch arity = arguments.length
    when 1
      [ settings, transform, ] = [ null, settings, ]
    when 2 then null
    else throw new Error "µ23112 expected 1 or 2 arguments, got #{arity}"
  #.........................................................................................................
  if ( leapfrog = settings?.leapfrog )?
    throw new Error "µ65533 leapfrogging with lookaround not yet implemented"
    delete settings.leapfrog
  #.........................................................................................................
  pipeline = []
  pipeline.push @$lookaround settings
  pipeline.push transform
  R = @pull pipeline...
  #.........................................................................................................
  if leapfrog?
    return @leapfrog leapfrog, R
  #.........................................................................................................
  return R



