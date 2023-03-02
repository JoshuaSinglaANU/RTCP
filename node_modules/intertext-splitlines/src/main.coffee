

'use strict'


############################################################################################################
CND                       = require 'cnd'
badge                     = 'INTERTEXT/SPLITLINES'
debug                     = CND.get_logger 'debug',     badge
urge                      = CND.get_logger 'urge',      badge
warn                      = CND.get_logger 'warn',      badge
@types                    = new ( require 'intertype' ).Intertype()
{ isa
  validate
  validate_optional
  type_of }               = @types.export()

#-----------------------------------------------------------------------------------------------------------
@types.declare 'sl_settings', tests:
  'x is an object':                     ( x ) -> @isa.object x
  'x.?splitter is a nonempty_text or a nonempty buffer':  ( x ) ->
    return true unless x.splitter?
    return ( @isa.nonempty_text x.splitter ) or ( ( @isa.buffer x.splitter ) and x.length > 0 )
  ### TAINT use `encoding` for better flexibility ###
  'x.?decode is a boolean':             ( x ) -> @isa_optional.boolean x.decode
  'x.?skip_empty_last is a boolean':    ( x ) -> @isa_optional.boolean x.skip_empty_last
  'x.?keep_newlines is a boolean':      ( x ) -> @isa_optional.boolean x.keep_newlines

#-----------------------------------------------------------------------------------------------------------
defaults =
  splitter:         '\n'
  decode:           true
  skip_empty_last:  true
  keep_newlines:    false

#-----------------------------------------------------------------------------------------------------------
@new_context = ( settings ) ->
  validate_optional.sl_settings settings
  settings            = { defaults..., settings..., }
  settings.offset     = 0
  settings.lastMatch  = 0
  settings.splitter   = ( Buffer.from settings.splitter ) if isa.text settings.splitter
  return { collector: null, settings..., }

#-----------------------------------------------------------------------------------------------------------
decode = ( me, data ) ->
  return data unless me.decode
  return data.toString 'utf-8'

#-----------------------------------------------------------------------------------------------------------
@walk_lines = ( me, d ) ->
  ### thx to https://github.com/maxogden/binary-split/blob/master/index.js ###
  validate.buffer d
  me.offset     = 0
  me.lastMatch  = 0
  delta         = if me.keep_newlines then me.splitter.length else 0
  if me.collector?
    d             = Buffer.concat [ me.collector, d, ]
    me.offset     = me.collector.length
    me.collector  = null
  loop
    idx = d.indexOf me.splitter, me.offset - me.splitter.length + 1
    if idx >= 0 and idx < d.length
      yield decode me, d.slice me.lastMatch, idx + delta
      me.offset    = idx + me.splitter.length
      me.lastMatch = me.offset
    else
      me.collector  = d.slice me.lastMatch
      break
  return null

#-----------------------------------------------------------------------------------------------------------
@flush = ( me ) ->
  if me.collector?
    line = decode me, me.collector
    yield line unless me.skip_empty_last and line.length is 0
    me.collector = null
  return null

#-----------------------------------------------------------------------------------------------------------
@splitlines = ( settings, buffers... ) ->
  buffers = buffers.flat Infinity
  switch type = type_of settings
    when 'object', 'null' then null
    when 'buffer'         then buffers.unshift settings; settings = null
    when 'list'           then buffers.splice 0, 0, ( settings.flat Infinity )...; settings = null
    else throw new Error "^splitlines@26258^ expected null, an object, a buffer or a list, got a #{type}"
  ctx = @new_context settings
  R   = []
  for buffer in buffers
    for line from @walk_lines ctx, buffer
      R.push line
  for line from @flush ctx
    R.push line
  return R




