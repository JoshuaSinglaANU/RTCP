

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'STEAMPIPES/PIPESTREAM-ADAPTER'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND
#...........................................................................................................


#-----------------------------------------------------------------------------------------------------------
@adapt_ps_transform = ( ps_transform ) ->
  PD        = require 'pipedreams'
  ps_source = PD.new_push_source()
  send      = null
  pipeline  = []
  pipeline.push ps_source
  pipeline.push ps_transform
  pipeline.push PD.$show { title: 'PS pipeline', }
  pipeline.push PD.$watch ( d ) -> send d
  pipeline.push PD.$drain ->
  PD.pull pipeline...
  return @$ ( d, send_ ) ->
    send = send_
    ps_source.send d



