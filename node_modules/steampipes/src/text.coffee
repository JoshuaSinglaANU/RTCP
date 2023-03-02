

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'STEAMPIPES/TEXT'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
{ jr }                    = CND
#...........................................................................................................
{ isa
  validate
  type_of }               = require './types'

# $pull_split               = require 'pull-split'
# $pull_utf8_decoder        = require 'pull-utf8-decoder'

#-----------------------------------------------------------------------------------------------------------
@new_text_source = ( text ) -> $values [ text, ]

# #-----------------------------------------------------------------------------------------------------------
# @new_text_sink = -> throw new Error "µ66539 not implemented"

# #-----------------------------------------------------------------------------------------------------------
# @$split = ( settings ) ->
#   throw new Error "µ66662 MEH" if settings?
#   R         = []
#   matcher   = null
#   mapper    = null
#   reverse   = no
#   skip_last = yes
#   R.push $pull_utf8_decoder()
#   R.push $pull_split matcher, mapper, reverse, skip_last
#   R.push @$ ( line, send ) -> send line.replace /\r+$/g, ''
#   return @pull R...

#-----------------------------------------------------------------------------------------------------------
@$join = ( joiner = null ) ->
  collector = []
  length    = 0
  type      = null
  is_first  = yes
  return @$ { last: null, }, ( data, send ) ->
    if data?
      if is_first
        is_first  = no
        type      = type_of data
        switch type
          when 'text'
            joiner ?= ''
          when 'buffer'
            throw new Error "µ66785 joiner not supported for buffers, got #{rpr joiner}" if joiner?
          else
            throw new Error "µ66908 expected a text or a buffer, got a #{type}"
      else
        unless ( this_type = type_of data ) is type
          throw new Error "µ67031 expected a #{type}, got a #{this_type}"
      length += data.length
      collector.push data
    else
      return send '' if ( collector.length is 0 ) or ( length is 0 )
      return send collector.join '' if type is 'text'
      return send Buffer.concat collector, length
    return null

#-----------------------------------------------------------------------------------------------------------
@$as_line = ->
  return @$map ( line ) =>
    "µ67154 expected a text, got a #{type}" unless ( type = type_of line ) is 'text'
    line + '\n'

#-----------------------------------------------------------------------------------------------------------
@$trim = ->
  return @$map ( line ) =>
    "µ67277 expected a text, got a #{type}" unless ( type = type_of line ) is 'text'
    return line.trim()

#-----------------------------------------------------------------------------------------------------------
@$skip_empty = ->
  return @$filter ( line ) =>
    "µ67400 expected a text, got a #{type}" unless ( type = type_of line ) is 'text'
    return line.length > 0

#-----------------------------------------------------------------------------------------------------------
@$skip_blank = ->
  return @$filter ( line ) =>
    "µ67523 expected a text, got a #{type}" unless ( type = type_of line ) is 'text'
    return not ( line.match /^\s*$/ )?

#-----------------------------------------------------------------------------------------------------------
@$as_text = ( settings ) ->
  serialize = settings?[ 'serialize' ] ? JSON.stringify
  return @$map ( data ) => serialize data

#-----------------------------------------------------------------------------------------------------------
@$desaturate = ->
  ### remove ANSI escape sequences ###
  pattern = /\x1b\[[0-9;]*[JKmsu]/g
  return @$map ( line ) => line.replace pattern, ''



