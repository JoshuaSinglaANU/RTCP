

'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PSPG/MAIN'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
# FS                        = require 'fs'
PATH                      = require 'path'
PS                        = require 'pipestreams'
{ $
  $async
  select }                = PS
types                     = require './types'
{ isa
  validate
  declare
  size_of
  type_of }               = types
#...........................................................................................................
require                   './exception-handler'
join_paths                = ( P... ) -> PATH.resolve PATH.join P...
abspath                   = ( P... ) -> join_paths __dirname, P...
{ to_width, width_of, }   = require 'to-width'
new_pager                 = require 'default-pager'
path_to_pspg              = abspath '../pspg'
{ jr, }                   = CND
assign                    = Object.assign

#-----------------------------------------------------------------------------------------------------------
@walk_table_header = ( keys, widths ) ->
  yield ' ' + (  ( ( to_width key, widths[ key ] ) for key from keys.values() ).join ' | ' ) + ' '
  yield '-' + (  ( ( to_width '', widths[ key ], { padder: '-', } ) for key from keys.values() ).join '-+-' ) + '-'
  return null

#-----------------------------------------------------------------------------------------------------------
@walk_formatted_table_row = ( row, keys, widths ) ->
  yield ' ' + (  ( ( to_width ( row[ key ] ? '' ), widths[ key ] ) for key from keys.values() ).join ' | ' ) + ' '

#-----------------------------------------------------------------------------------------------------------
@walk_table_footer = ( count ) ->
  yield "(#{count} rows)"
  yield '\n\n'
  return null

#-----------------------------------------------------------------------------------------------------------
@to_text = ( value ) ->
  return switch type = type_of value
    when 'text'       then R = jr value; R = R[ 1 ... R.length - 1 ]; R.replace /\\"/g, '"'
    when 'buffer'     then value.toString 'hex'
    when 'number'     then "#{value}"
    when 'null'       then '∎'
    when 'undefined'  then '?'
    else value?.toString() ? ''

#-----------------------------------------------------------------------------------------------------------
@$collect_etc = ( limit = 1000 ) ->
  validate.positive limit
  last        = Symbol 'last'
  cache       = []
  widths      = {}
  keys        = new Set()
  key_widths  = {}
  count       = 0
  send        = null
  #.........................................................................................................
  flush = =>
    return null unless cache?
    send line for line from @walk_table_header keys, widths
    for cached_row in cache
      send line for line from @walk_formatted_table_row cached_row, keys, widths
    cache = null
  #.........................................................................................................
  return PS.$ { last, }, ( row, send_ ) =>
    send = send_
    #.......................................................................................................
    if row is last
      flush()
      send line for line from @walk_table_footer count
      return null
    #.......................................................................................................
    count++
    #.......................................................................................................
    if count > limit
      flush()
      row[ key ] = @to_text row[ key ] for key from keys.values()
      send line for line from @walk_formatted_table_row row, keys, widths
      return null
    #.......................................................................................................
    d = {}
    for key of row
      keys.add key
      d[ key ]      = value = @to_text row[ key ]
      key_width     = ( key_widths[ key ] ?= width_of key )
      widths[ key ] = Math.max 2, ( widths[ key ] ? 2 ), ( width_of value ), key_width
    cache.push d
    #.......................................................................................................
    return null

#-----------------------------------------------------------------------------------------------------------
@$tee_as_table = ( settings, handler ) ->
  #.........................................................................................................
  pipeline = []
  pipeline.push @$collect_etc()
  pipeline.push @$page_output arguments...
  pipeline.push PS.$drain()
  #.........................................................................................................
  return PS.$tee PS.pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@$page_output = ( settings, handler ) ->
  switch arity = arguments.length
    when 0 then null
    when 1
      if isa.function settings
        [ settings, handler, ] = [ null, settings, ]
    when 2 then null
    else throw new Error "µ33981 expected between 0 and 2 arguments, got #{arity}"
  validate.function handler   if handler?
  validate.object   settings  if settings?
  #.........................................................................................................
  defaults    =
    pager:  path_to_pspg
    args:   [  '-s17', '--force-uniborder', ]
  #.........................................................................................................
  settings    = if settings? then assign {}, defaults, settings else defaults
  if settings.csv ### ??? ###
    settings.args = [ settings.args..., '--csv', '--csv-border', '2', '--csv-double-header', ]
  #.........................................................................................................
  source      = PS.new_push_source()
  stream      = PS.node_stream_from_source PS.pull source
  stream.pipe new_pager settings, handler
  last        = Symbol 'last'
  #.........................................................................................................
  return PS.$watch { last, }, ( line ) ->
    return source.end() if line is last
    line  = '' unless line?
    line  = line.toString() unless isa.text line
    line += '\n'            unless isa.line line
    source.send line
    return null

