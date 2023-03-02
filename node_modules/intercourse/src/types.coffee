


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
@declare 'ic_toplevel_entry',
  tests:
    "? is an object":                         ( x ) -> @isa.object  x
    # "? has key 'type'":                       ( x ) -> @has_key     x, 'type'
    "?.type is a text":                       ( x ) -> @isa.text    x.type

#-----------------------------------------------------------------------------------------------------------
@declare 'ic_signature_entry',
  tests:
    "? is an object":                         ( x ) -> @isa.object        x
    # "? has key 'location'":                   ( x ) -> @has_key           x, 'location'
    # "? has key 'kenning'":                    ( x ) -> @has_key           x, 'kenning'
    # "? has key 'type'":                       ( x ) -> @has_key           x, 'type'
    "?.location is a ic_location":            ( x ) -> @isa.ic_location   x.location
    "?.kenning is a ic_kenning":              ( x ) -> @isa.ic_kenning    x.kenning
    "?.type is a text":                       ( x ) -> @isa.text          x.type
    # "? has key 'parts'":                      ( x ) -> @has_key           x, 'parts'
    "?.parts is a nonempty list":             ( x ) -> @isa.nonempty_list x.parts
    # "? has key 'signature'":                  ( x ) -> @has_key           x, 'signature'
    # "?.signature is a list":                  ( x ) -> @isa.list          x.signature

#-----------------------------------------------------------------------------------------------------------
@declare 'ic_location',
  tests:
    "? is an object":                         ( x ) -> @isa.object    x
    # "? has key 'line_nr'":                    ( x ) -> @has_key       x, 'line_nr'
    "?.line_nr is a positive":                ( x ) -> @isa.positive  x.line_nr

#-----------------------------------------------------------------------------------------------------------
@declare 'ic_settings',
  tests:
    "? is an object":                         ( x ) -> @isa.object    x
    # "? has key 'partition'":                  ( x ) -> @has_key       x, 'partition'
    # "? has key 'comments'":                   ( x ) -> @has_key       x, 'comments'
    "?.partition is null, false or 'indent'": ( x ) -> x.partition in [ null, false, 'indent', ]
    "?.comments is a regex":                  ( x ) -> @isa.regex     x.comments

#-----------------------------------------------------------------------------------------------------------
kenning_pattern = /// ^ null | \( \S* \)  $ ///
@declare 'ic_null_kenning',                   ( x ) -> x is 'null'
@declare 'ic_kenning',                        ( x ) -> ( @isa.text x ) and ( x.match kenning_pattern )?

#-----------------------------------------------------------------------------------------------------------
@declare 'datom',
  tests:
    "? is an object":                         ( x ) -> @isa.object    x
    # "? has key 'key'":                        ( x ) -> @has_key x, 'key'
    # "? has key 'value'":                      ( x ) -> @has_key x, 'value'
    "?.$key is a nonempty text":              ( x ) -> @isa.nonempty_text x.$key



