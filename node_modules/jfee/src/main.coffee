
'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'JFEE'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
PATH                      = require 'path'
FS                        = require 'fs'
types                     = new ( require 'intertype' ).Intertype()
{ isa
  type_of
  validate }              = types.export()
{ freeze, }               = Object

#-----------------------------------------------------------------------------------------------------------
defaults =
  bare: false
  raw:  true

#-----------------------------------------------------------------------------------------------------------
types.declare "jfee_settings", tests:
  "x is an object":           ( x ) -> @isa.object x
  "x.bare is a boolean":      ( x ) -> @isa.boolean x.bare
  "x.raw is a boolean":       ( x ) -> @isa.boolean x.raw


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
class @Receiver # extends Object
  constructor: ( settings ) ->
    @settings             = freeze { defaults..., settings..., }
    validate.jfee_settings @settings
    @collector            = []
    @[ Symbol.iterator ]  = -> yield from @collector; @collector = []
    @_resolve             = ->
    @done                 = false
    @initializer          = null
    @is_first             = true
    @send                 = _send.bind @
    @advance              = _advance.bind @
    @ratchet              = new Promise ( resolve ) => @_resolve = resolve
    return null

  #---------------------------------------------------------------------------------------------------------
  add_data_channel: ( eventemitter, eventname, $key ) ->
    switch type = types.type_of $key
      when 'null', 'undefined'
        handler = ( $value ) =>
          @send $value
          @advance()
      when 'text'
        validate.nonempty_text $key
        handler = ( $value ) =>
          @send freeze { $key, $value, }
          @advance()
      when 'function'
        handler = ( $value ) =>
          @send $key $value
          @advance()
      when 'generatorfunction'
        handler = ( $value ) =>
          @send d for d from $key $value
          @advance()
      else
        throw new Error "^receiver/add_data_channel@445^ expected a text, a function, or a generatorfunction, got a #{type}"
    eventemitter.on eventname, handler
    return null

  #---------------------------------------------------------------------------------------------------------
  ### TAINT make `$key` behave as in `add_data_channel()` ###
  add_initializer: ( $key ) ->
    ### Send a datom before any other data. ###
    validate.nonempty_text $key
    @initializer = freeze { $key, }

  #---------------------------------------------------------------------------------------------------------
  ### TAINT make `$key` behave as in `add_data_channel()` ###
  add_terminator: ( eventemitter, eventname, $key = null ) ->
    ### Terminates async iterator after sending an optional datom to mark termination in stream. ###
    eventemitter.on eventname, =>
      @send freeze { $key, } if $key?
      @advance false

  #---------------------------------------------------------------------------------------------------------
  @from_child_process: ( cp, settings ) ->
    validate.childprocess cp
    rcv = new Receiver settings
    rcv.add_initializer   '<cp' unless rcv.settings.bare
    rcv.add_data_channel  cp.stdout, 'data', '^stdout'
    rcv.add_data_channel  cp.stderr, 'data', '^stderr'
    rcv.add_terminator    cp, 'close', if rcv.settings.bare then null else '>cp'
    while not rcv.done
      await rcv.ratchet; yield from rcv
    return null

  #---------------------------------------------------------------------------------------------------------
  @from_readstream: ( stream, settings ) ->
    validate.readstream stream
    rcv = new Receiver settings
    rcv.add_initializer  '<stream' unless rcv.settings.bare
    rcv.add_data_channel  stream, 'data',   if rcv.settings.raw  then null else '^line'
    rcv.add_terminator    stream, 'close',  if rcv.settings.bare then null else '>stream'
    while not rcv.done
      await rcv.ratchet; yield from rcv
    return null

#-----------------------------------------------------------------------------------------------------------
_send = ( d ) ->
  if @is_first
    @is_first = false
    @collector.push @initializer if @initializer?
  @collector.push d

#-----------------------------------------------------------------------------------------------------------
_advance  = ( go_on = true ) ->
  @done     = not go_on
  @_resolve()
  @ratchet  = new Promise ( resolve ) => @_resolve = resolve


# #===========================================================================================================
# #
# #-----------------------------------------------------------------------------------------------------------
# create_translation_pipeline = ( file_path ) -> new Promise ( resolve_outer, reject_outer ) =>
#   validate.nonempty_text file_path
#   #---------------------------------------------------------------------------------------------------------
#   SP = require 'steampipes'
#   { $
#     $watch
#     $drain }  = SP.export()
#   #---------------------------------------------------------------------------------------------------------
#   $split_lines = ->
#     ctx   = SL.new_context()
#     last  = Symbol 'last'
#     return $ { last, }, ( d, send ) =>
#       if d is last
#         send line for line from SL.flush ctx
#         return null
#       return if not d?
#       return if not isa.buffer d
#       send line for line from SL.walk_lines ctx, d
#       return null
#   #---------------------------------------------------------------------------------------------------------
#   $skip_empty_etc = -> SP.$filter ( d ) =>
#     return false if d is ''
#     return true
#   #---------------------------------------------------------------------------------------------------------
#   $as_batches = ->
#     collector = null
#     n         = 1e4
#     last      = Symbol 'last'
#     return $ { last, }, ( d, send ) ->
#       if d is last
#         if collector?
#           send collector
#           collector = null
#         return
#       return send d unless isa.text d
#       ( collector ?= [] ).push d
#       if collector.length >= n
#         send collector
#         collector = null
#   #---------------------------------------------------------------------------------------------------------
#   $as_sql_insert = ->
#     return $ ( batch, send ) ->
#       return send batch unless isa.list batch
#       send """insert into T.pwd ( pwd ) values"""
#       last_idx  = batch.length - 1
#       for d, idx in batch
#         d_sql = d
#         ### TAINT also remove other control characters, U+fdfe etc ###
#         d_sql = d_sql.replace /\\x([0-9a-f][0-9a-f])/g, ( $0, $1 ) -> String.fromCodePoint parseInt $1, 16
#         d_sql = d_sql.replace /[\x00-\x1f�]/g, ''
#         d_sql = d_sql.replace /'/g, "''"
#         comma = if idx is last_idx then ';' else ','
#         send """( '#{d_sql}' )#{comma}"""
#   #---------------------------------------------------------------------------------------------------------
#   $echo = ->
#     return $watch ( d ) ->
#       if isa.text d
#         process.stdout.write d + '\n'
#       else
#         process.stderr.write ( CND.grey d ) + '\n'
#   #---------------------------------------------------------------------------------------------------------
#   source      = SP.new_push_source()
#   pipeline    = []
#   pipeline.push source
#   pipeline.push $split_lines()
#   pipeline.push $skip_empty_etc()
#   pipeline.push $as_batches()
#   pipeline.push $as_sql_insert()
#   pipeline.push $echo()
#   pipeline.push $drain ->
#     help "^3776^ pipeline: finished"
#     return resolve_outer()
#   SP.pull pipeline...
#   #.........................................................................................................
#   stream = FS.createReadStream file_path
#   source.send x for await x from Receiver.from_readstream stream
#   source.end()
#   return null
