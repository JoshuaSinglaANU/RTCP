


'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/TSV'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
flatten                   = require 'lodash.flattendeep'

#-----------------------------------------------------------------------------------------------------------
@$name_fields = ( names... ) ->
  names = flatten names
  return @$ ( fields, send ) =>
    throw new Error "µ43613 expected a list, got a #{type}" unless ( type = CND.type_of fields ) is 'list'
    R = {}
    for value, idx in fields
      name      = names[ idx ] ?= "field_#{idx}"
      R[ name ] = value
    send R

#-----------------------------------------------------------------------------------------------------------
@$split_on_tabs = ( settings ) ->
  return @$ ( line, send ) =>
    "µ27918 expected a text, got a #{type}" unless ( type = CND.type_of line ) is 'text'
    send line.split /\t/

# #-----------------------------------------------------------------------------------------------------------
# @$split_on_whitespace = ( field_count = null ) ->
#   if ( field_count is 0 )
#     throw new Error "µ43714 field_count can not be zero"
#   #.........................................................................................................
#   ### If user requested null or zero fields, we can just split the line: ###
#   if ( not field_count? ) # or ( field_count is 0 )
#     return @$ ( line, send ) => send line.split /\s+/
#   #.........................................................................................................
#   ### If user requested one field, then the entire line is the field: ###
#   if field_count is 1
#     return @$ ( line, send ) => send [ line, ]
#   #.........................................................................................................
#   ### TAINT validate field_count is integer ###
#   ### TAINT validate field_count is non-negative ###
#   return @$ ( line, send ) =>
#     "µ28239 expected a text, got a #{type}" unless ( type = CND.type_of line ) is 'text'
#     fields  = []
#     parts   = line.split /(\s+)/
#     pairs   = ( [ parts[ idx ], parts[ idx + 1 ] ? '' ] for idx in [ 0 ... parts.length ] by +2 )
#     #.......................................................................................................
#     ### Shift-push line contents from `pairs` into `fields` until exhausted or saturated: ###
#     loop
#       break if pairs.length <= 0
#       break if fields.length >= field_count - 1
#       fields.push pairs.shift()[ 0 ]
#     #.......................................................................................................
#     ### Concat remaining parts and add as one more field: ###
#     if pairs.length > 0
#       fields.push ( ( ( fld + spc ) for [ fld, spc, ] in pairs ).join '' ).trim()
#     #.......................................................................................................
#     ### Pad missing fields with `null`: ###
#     ### TAINT allow to configure padding value ###
#     fields.push null while fields.length < field_count
#     #.......................................................................................................
#     send fields

#-----------------------------------------------------------------------------------------------------------
@$split_on_whitespace = ( field_count = null ) ->
  #.........................................................................................................
  if ( field_count is 0 )
    throw new Error "µ43815 field_count can not be zero"
  #.........................................................................................................
  ### If called with field_count `null`, we can just split the line: ###
  if ( not field_count? )
    return @$ ( line, send ) =>
      R = ( ( if p is '' then null else p ) for p in line.split /\s+/ )
      R.pop() while R[ R.length - 1 ] is null
      send R
  #.........................................................................................................
  ### If user requested one field, then the entire line is the field: ###
  if field_count is 1
    return @$ ( line, send ) => send [ line, ]
  #.........................................................................................................
  get_pattern = ( field_count ) =>
    # return /^(*){1,}$/ if ( not field_count? ) or ( field_count is 0 )
    R           = []
    subpattern  = []
    R.push '^'
    subpattern.push '(\\S*)' for _ in [ 1 .. field_count - 1 ] by +1
    R.push subpattern.join '\\s*'
    R.push '\\s*(.*)'
    R.push '$'
    return new RegExp R.join ''
  pattern = get_pattern field_count
  #.........................................................................................................
  return @$ ( line, send ) =>
    "µ27918 expected a text, got a #{type}" unless ( type = CND.type_of line ) is 'text'
    # debug 'µ78765-1', ( rpr pattern ), ( rpr line )
    if ( '\n' in line ) or not ( match = line.match pattern )?
      throw new Error "µ43916 illegal line: #{rpr line}"
    match = [ match..., ]
    R     = []
    # debug 'µ78765-2', ( rpr pattern ), ( rpr line ), ( rpr match )
    for idx in [ 1 .. field_count ]
      R.push if ( field = match[ idx ] ) is '' then null else field
    send R

#-----------------------------------------------------------------------------------------------------------
@$trim_fields = -> @$watch ( fields  ) =>
  throw new Error "µ44017 expected a list, got a #{type}" unless ( type = CND.type_of fields ) is 'list'
  fields[ idx ] = field.trim() for field, idx in fields
  return null

#-----------------------------------------------------------------------------------------------------------
@$split_tsv = ->
  R = []
  R.push @$split()
  # R.push @$trim()
  R.push @$skip_blank()
  ### TAINT use named method; allow to configure comment marker ###
  R.push @$filter ( line ) -> not line.startsWith '#'
  R.push @$split_on_tabs()
  R.push @$trim_fields()
  return @pull R...

#-----------------------------------------------------------------------------------------------------------
### TAINT use `settings` for extensibility ###
@$split_wsv = ( field_count = null ) ->
  R = []
  R.push @$split()
  # R.push @$sample 1 / 20000
  # R.push @$trim()
  R.push @$skip_blank()
  ### TAINT use named method; allow to configure comment marker ###
  R.push @$filter ( line ) -> not line.startsWith '#'
  R.push @$split_on_whitespace field_count
  return @pull R...


