

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'STEAMPIPES/SOURCES'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
{ jr }                    = CND
assign                    = Object.assign
#...........................................................................................................
{ isa
  validate
  defaults
  type_of }               = require './types'

#-----------------------------------------------------------------------------------------------------------
@new_value_source = ( x ) -> yield from x

#-----------------------------------------------------------------------------------------------------------
@new_push_source = ->
  send = ( d ) =>
    return R.buffer.push d unless R.duct?
    R.buffer = null
    return end() if d is @signals.end
    R.duct.buckets[ 0 ].push d
    R.duct.exhaust_pipeline()
    return null
  end = =>
    R.has_ended = true
    return unless R.duct? ### NOTE: ensuring that multiple calls to `end()` will be OK ###
    R.duct.buckets[ 0 ].push @signals.last
    R.duct.exhaust_pipeline()
    drain = R.duct.transforms[ R.duct.transforms.length - 1 ]
    if ( on_end = drain.on_end )?
      if drain.call_with_datoms then drain.on_end drain.sink else drain.on_end()
    return R.duct = null
  R = { [@marks.isa_pusher], send, end, buffer: [], duct: null, has_ended: false, }
  return R

#-----------------------------------------------------------------------------------------------------------
@new_wye = ( settings, source ) ->
  switch arity = arguments.length
    when 1 then [ settings, source, ] = [ null, settings, ]
    when 2 then null
    else throw new Error "µ44578 expected 1 or 2 arguments, got #{arity}"
  settings = { defaults.steampipes_new_wye_settings..., settings..., }
  validate.steampipes_new_wye_settings settings
  return { [@marks.isa_wye], settings, source, }

#-----------------------------------------------------------------------------------------------------------
@source_from_child_process = ( cp, settings ) ->
  JFEE = require 'jfee'
  ### TAINT should wait until pipeline pulled? ###
  for await x from JFEE.Receiver.from_child_process cp, settings
    yield x
  return null

### TAINT we should use this implementation but fails in hengist/dev/steampipes/src/nodejs-eventemitter-as-stream-source.coffee
#-----------------------------------------------------------------------------------------------------------
@source_from_child_process_2 = ( cp, settings ) ->
  JFEE = require 'jfee'
  R = @new_push_source()
  R.start = ->
    setImmediate =>
      for await x from JFEE.Receiver.from_child_process cp, settings
        R.send x
      R.end()
    return null
  return R
###

#-----------------------------------------------------------------------------------------------------------
@source_from_readstream = ( readstream, settings ) ->
  JFEE = require 'jfee'
  R = @new_push_source()
  R.start = ->
    setImmediate =>
      for await x from JFEE.Receiver.from_readstream readstream, settings
        R.send x
      R.end()
    return null
  return R




