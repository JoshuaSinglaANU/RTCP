

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'STEAMPIPES/TESTS/PIPESTREAM-ADAPTER'
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
PATH                      = require 'path'
FS                        = require 'fs'
OS                        = require 'os'
test                      = require 'guy-test'
{ jr }                    = CND
#...........................................................................................................
SP                        = require '../..'
{ $
  $async
  $watch
  $show  }                = SP.export()


#-----------------------------------------------------------------------------------------------------------
@[ "adapt 1" ] = ( T, done ) ->
  try PD = require 'pipedreams' catch error
    throw error unless error.code is 'MODULE_NOT_FOUND'
    message = "^33877^ must install pipedreams to run adapter test; skipping"
    warn message
    # T.fail message
    return done()
  probe   = "just a bunch of words really".split /\s+/
  matcher = [ probe..., ]
  error   = null
  await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
    R           = []
    source      = probe
    pipeline    = []
    #.......................................................................................................
    pipeline.push source
    pipeline.push SP.$watch ( d ) -> info jr d
    pipeline.push SP.adapt_ps_transform PD.$collect { collector: R, }
    pipeline.push SP.$drain -> help 'ok'; resolve R
    SP.pull pipeline...
    return null
  #.........................................................................................................
  done()
  return null


############################################################################################################
unless module.parent?
  test @, 'timeout': 30000
