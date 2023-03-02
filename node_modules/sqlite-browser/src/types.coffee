


'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'SQLITE-BROWSER/TYPES'
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


# #-----------------------------------------------------------------------------------------------------------
# @declare 'pd_datom_sigil',
#   tests:
#     "x is a chr":                             ( x ) -> @isa.chr x
#     "x has sigil":                            ( x ) -> x in '^<>~[]'

#-----------------------------------------------------------------------------------------------------------
@declare 'sqlb_settings',
  tests:
    "x is a object":                          ( x ) -> @isa.object          x
#     "x has key 'key'":                        ( x ) -> @has_key             x, 'key'
#     "x.key is a pd_datom_key":                ( x ) -> @isa.pd_datom_key    x.key
#     "x.$stamped is an optional boolean":      ( x ) -> ( not x.$stamped? ) or ( @isa.boolean x.$stamped )
#     "x.$dirty is an optional boolean":        ( x ) -> ( not x.$dirty?   ) or ( @isa.boolean x.$dirty   )
#     "x.$fresh is an optional boolean":        ( x ) -> ( not x.$fresh?   ) or ( @isa.boolean x.$fresh   )
#     #.......................................................................................................
#     "x.$vnr is an optional nonempty list of positive integers": ( x ) ->
#       ( not x.$vnr? ) or @isa.pd_nonempty_list_of_positive_integers x.$vnr


#-----------------------------------------------------------------------------------------------------------
@declare 'sqlb_db_path',
  tests:
    "x is a nonempty_text":                          ( x ) -> @isa.nonempty_text          x

#-----------------------------------------------------------------------------------------------------------
@declare 'sqlb_key',
  tests:
    "x is a nonempty_text":                          ( x ) -> @isa.nonempty_text          x


