
'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'STEAMPIPES-EXTRA'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
types                     = new ( require 'intertype' ).Intertype()
{ isa
  validate
  validate_optional }     = types.export()
SL                        = require 'intertext-splitlines'
freeze                    = Object.freeze

#-----------------------------------------------------------------------------------------------------------
@$split_lines = ( settings = null ) ->
  ctx   = SL.new_context settings
  last  = Symbol 'last'
  return @$ { last, }, ( d, send ) =>
    if d is last
      send line for line from SL.flush ctx
      return null
    return unless d?
    return unless isa.buffer d
    send line for line from SL.walk_lines ctx, d
    return null

#-----------------------------------------------------------------------------------------------------------
@$split_channels = ->
  splitliners = {}
  last        = Symbol 'last'
  return @$ { last, }, ( d, send ) =>
    { $key, $value, } = d
    unless ( ctx = splitliners[ $key ] )?
      ctx = splitliners[ $key ] = SL.new_context()
    if d is last
      send ( freeze { $key, $value, } ) for $value from SL.flush ctx
      return null
    return send d if ( not d? ) or ( not types.isa.buffer d.$value )
    send ( freeze { $key, $value, } ) for $value from SL.walk_lines ctx, $value
    return null

#-----------------------------------------------------------------------------------------------------------
@$batch = ( size, transform ) ->
  validate.positive_integer size
  validate_optional.function transform
  collector = null
  last      = Symbol 'last'
  return @$ { last, }, ( d, send ) ->
    if d is last
      if collector?
        send collector
        collector = null
      return
    ( collector ?= [] ).push d
    if collector.length >= size
      send if transform? then transform collector else collector
      collector = null

#-----------------------------------------------------------------------------------------------------------
@$sample = ( p = 0.5, settings ) ->
  validate.nonnegative p
  # validate_optional.positive settings.seed
  #.........................................................................................................
  return ( $ ( d, send ) -> send d  ) if p is 1
  return ( $ ( d, send ) -> null    ) if p is 0
  #.........................................................................................................
  headers   = settings?[ 'headers'     ] ? false
  seed      = settings?[ 'seed'        ] ? null
  is_first  = headers
  rnd       = if seed? then CND.get_rnd seed else Math.random
  #.........................................................................................................
  return @$ ( d, send ) =>
    if is_first
      is_first = false
      return send d
    send d if rnd() < p




