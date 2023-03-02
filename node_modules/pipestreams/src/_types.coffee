


'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/_TYPES'
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
@declare 'pipestreams_$window_settings',
  tests:
    "x is an object":                         ( x ) -> @isa.object x
    "x.width is a positive":                  ( x ) -> @isa.positive x.width

#-----------------------------------------------------------------------------------------------------------
@declare 'pipestreams_$lookaround_settings',
  tests:
    "x is an object":                         ( x ) -> @isa.object x
    "x.delta is a count":                     ( x ) -> @isa.count x.delta


#-----------------------------------------------------------------------------------------------------------
@declare 'positive_proper_fraction',          ( x ) -> 0 <= x <= 1
@declare 'pipestreams_number_or_text',        ( x ) -> ( @isa.number x ) or ( @isa.text x )


