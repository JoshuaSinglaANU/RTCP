
'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/DEMO'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND
PS                        = require '../..'
{ $
  $watch }                = PS.export()
first                     = Symbol 'first'
last                      = Symbol 'last'
first                     = Symbol 'first'
last                      = Symbol 'last'
between                   = Symbol 'between'
after                     = Symbol 'after'
before                    = Symbol 'before'


#-----------------------------------------------------------------------------------------------------------
@$show_signals = -> $ { first, last, between, after, before, }, ( d, send ) =>
  info d
  send d

#-----------------------------------------------------------------------------------------------------------
@demo_signals = -> new Promise ( resolve, reject ) =>
  source    = PS.new_push_source()
  pipeline  = []
  pipeline.push source
  pipeline.push @$show()
  pipeline.push PS.$drain resolve
  PS.pull pipeline...
  for idx in [ 1 .. 5 ]
    source.send idx
  source.end()
  return null

#-----------------------------------------------------------------------------------------------------------
@$wrapsignals = ->
  ### NOTE: this functionality has been implemented in PipeDreams ###
  is_first  = true
  prv_d     = null
  return $ { last, }, ( d, send ) =>
    if d is last
      if prv_d?
        prv_d.first = true if is_first
        prv_d.last  = true
        send prv_d
    else
      if prv_d?
        send prv_d
      prv_d       = { value: d, }
      prv_d.first = true if is_first
      is_first    = false
    return null

#-----------------------------------------------------------------------------------------------------------
@demo_wrapsignals = -> new Promise ( resolve, reject ) =>
  source    = PS.new_push_source()
  pipeline  = []
  pipeline.push source
  pipeline.push PS.$wrapsignals()
  pipeline.push PS.$show()
  pipeline.push PS.$drain resolve
  PS.pull pipeline...
  n = 5
  for idx in [ 1 .. n ]
    source.send idx
  source.end()
  return null

############################################################################################################
unless module.parent?
  L = @
  do ->
    # await L.demo_signals()
    await L.demo_wrapsignals()
    help 'ok'





