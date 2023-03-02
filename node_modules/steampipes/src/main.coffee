

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'STEAMPIPES/BASICS'
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
@types                    = require './types'
{ isa
  validate
  type_of }               = @types
Multimix                  = require 'multimix'

#-----------------------------------------------------------------------------------------------------------
class Steampipes extends Multimix
  @include require './modify'
  @include require './njs-streams-and-files'
  @include require './pipestreams-adapter'
  @include require './pull-remit'
  @include require './sort'
  @include require './sources'
  @include require './standard-transforms'
  @include require './text'
  @include require './windowing'
  @include require './fs-fifos-and-tailing'
  @include require './extras'

  #---------------------------------------------------------------------------------------------------------
  constructor: ( @settings = null ) ->
    super()

############################################################################################################
module.exports 	= L = new Steampipes()
L.Steampipes 		= Steampipes


