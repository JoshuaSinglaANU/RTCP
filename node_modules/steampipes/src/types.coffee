


'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/TYPES'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge
jr                        = JSON.stringify
Intertype                 = ( require 'intertype' ).Intertype
intertype                 = new Intertype module.exports

#-----------------------------------------------------------------------------------------------------------
@declare 'pd_nonempty_list_of_positive_integers', ( x ) ->
  return false unless @isa.nonempty_list x
  return x.every ( xx ) => @isa.positive_integer xx

#-----------------------------------------------------------------------------------------------------------
@declare 'pd_datom_sigil',
  tests:
    "x is a chr":                             ( x ) -> @isa.chr x
    "x has sigil":                            ( x ) -> x in '^<>~[]'

#-----------------------------------------------------------------------------------------------------------
@declare 'pd_datom_key',
  tests:
    "x is a nonempty text":                   ( x ) -> @isa.nonempty_text   x
    "x has sigil":                            ( x ) -> @isa.pd_datom_sigil  x[ 0 ]

#-----------------------------------------------------------------------------------------------------------
@declare 'pd_datom',
  tests:
    "x is a object":                          ( x ) -> @isa.object          x
    "x has key 'key'":                        ( x ) -> @has_key             x, 'key'
    "x.key is a pd_datom_key":                ( x ) -> @isa.pd_datom_key    x.key
    "x.$stamped is an optional boolean":      ( x ) -> ( not x.$stamped? ) or ( @isa.boolean x.$stamped )
    "x.$dirty is an optional boolean":        ( x ) -> ( not x.$dirty?   ) or ( @isa.boolean x.$dirty   )
    "x.$fresh is an optional boolean":        ( x ) -> ( not x.$fresh?   ) or ( @isa.boolean x.$fresh   )
    #.......................................................................................................
    "x.$vnr is an optional nonempty list of positive integers": ( x ) ->
      ( not x.$vnr? ) or @isa.pd_nonempty_list_of_positive_integers x.$vnr

#-----------------------------------------------------------------------------------------------------------
@declare 'steampipes_new_wye_settings',
  tests:
    "x is a object":                          ( x ) -> @isa.object          x
    "x.mode is a text":                       ( x ) -> @isa.text            x.mode
    "x.mode is known value":                  ( x ) -> x.mode in [ 'asis', 'interleave', ]

#-----------------------------------------------------------------------------------------------------------
@defaults =
  steampipes_new_wye_settings:
    mode:   'asis'

# #-----------------------------------------------------------------------------------------------------------
# declare 'pipestreams_is_sink_or_through',
#   tests:
#     "x is a function":                        ( x ) -> @isa.function x
#     "x's arity is 1":                         ( x ) -> x.length is 1

# #-----------------------------------------------------------------------------------------------------------
# declare 'pipestreams_is_sink',
#   tests:
#     "x is a pipestreams_is_sink_or_through":  ( x ) -> @isa.pipestreams_is_sink_or_through x
#     "x[ Symbol.for 'sink' ] is true":         ( x ) -> x[ Symbol.for 'sink' ] ? false

# #-----------------------------------------------------------------------------------------------------------
# declare 'pipestreams_is_source',
#   tests:
#     "x is a function":                        ( x ) -> @isa.function x
#     "x's arity is 2":                         ( x ) -> x.length is 2
