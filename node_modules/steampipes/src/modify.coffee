

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'STEAMPIPES/MODIFY'
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
  type_of }               = require './types'
misfit                    = Symbol 'misfit'


#-----------------------------------------------------------------------------------------------------------
remit_defaults = Object.freeze
  first:    misfit
  last:     misfit
  between:  misfit
  after:    misfit
  before:   misfit

#-----------------------------------------------------------------------------------------------------------
@_get_remit_settings = ( settings ) ->
  validate.function settings.leapfrog if settings.leapfrog?
  settings._surround = \
    ( settings.first    isnt misfit ) or \
    ( settings.last     isnt misfit ) or \
    ( settings.between  isnt misfit ) or \
    ( settings.after    isnt misfit ) or \
    ( settings.before   isnt misfit )
  #.........................................................................................................
  return settings

#-----------------------------------------------------------------------------------------------------------
@modify = ( modifications..., transform ) ->
  ### Can always call `modify $ ( d, send ) -> ...` with no effect: ###
  return transform if modifications.length is 0
  #.........................................................................................................
  settings              = @_get_remit_settings Object.assign {}, remit_defaults, modifications...
  self                  = null
  do_leapfrog           = settings.leapfrog
  data_first            = settings.first
  data_before           = settings.before
  data_between          = settings.between
  data_after            = settings.after
  data_last             = settings.last
  send_first            = data_first    isnt misfit
  send_before           = data_before   isnt misfit
  send_between          = data_between  isnt misfit
  send_after            = data_after    isnt misfit
  send_last             = data_last     isnt misfit
  is_first              = true
  #.........................................................................................................
  ### slow track with surround features ###
  R = ( d, send ) =>
    has_returned  = false
    #.......................................................................................................
    if send_last and d is @signals.last
      transform data_last, send
    #.......................................................................................................
    else
      if is_first then ( ( transform data_first,   send ) if send_first   )
      else             ( ( transform data_between, send ) if send_between )
      ( transform data_before, send ) if send_before
      is_first = false
      #.....................................................................................................
      # When leapfrogging is being called for, only call transform if the jumper returns false:
      if ( not do_leapfrog ) or ( not settings.leapfrog d ) then  transform d, send
      else                                                        send d
      #.....................................................................................................
      ( transform data_after, send ) if send_after
    has_returned = true
    return null
  #.........................................................................................................
  R.sink = transform.sink
  R.send = transform.send
  delete transform.sink
  delete transform.send
  R[ @marks.send_last ] = @marks.send_last if send_last
  return R

