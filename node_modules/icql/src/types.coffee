


'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'MKTS-PARSER/TYPES'
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
@declare 'icql_settings',
  tests:
    "x is a object":                          ( x ) -> @isa.object          x
    # "x has key 'db_path'":                    ( x ) -> @has_key             x, 'db_path'
    # "x has key 'icql_path'":                  ( x ) -> @has_key             x, 'icql_path'
    "x.db_path is a nonempty text":           ( x ) -> @isa.nonempty_text x.db_path
    "x.icql_path is a nonempty text":         ( x ) -> @isa.nonempty_text x.icql_path
    "x.echo? is a boolean":                   ( x ) -> @isa_optional.boolean x.echo

#-----------------------------------------------------------------------------------------------------------
@declare 'ic_entry_type',
  tests:
    "x is a text":                              ( x ) -> @isa.text    x
    "x is in 'procedure', 'query', 'fragment'": ( x ) -> x in [ 'procedure', 'query', 'fragment', ]

#-----------------------------------------------------------------------------------------------------------
@declare 'ic_schema', ( x ) ->
  ### NOTE to keep things simple, only allow lower case ASCII letters, digits, underscores in schemas ###
  return false unless @isa.text x
  return ( /^[a-z][a-z0-9_]*$/ ).test x

#-----------------------------------------------------------------------------------------------------------
@declare 'ic_path', ( x ) -> @isa.nonempty_text x




