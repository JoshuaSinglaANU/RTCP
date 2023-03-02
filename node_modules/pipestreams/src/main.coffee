
'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS'
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
types                     = require './_types'
{ isa
  validate
  declare
  size_of
  type_of }               = types
Multimix                  = require 'multimix'


#-----------------------------------------------------------------------------------------------------------
class Pipestreams extends Multimix
  # @extend   object_with_class_properties
  @include require './basics'
  @include require './logging'
  @include require './main'
  @include require './njs-streams-and-files'
  @include require './sort'
  @include require './_symbols'
  @include require './text'
  @include require './tsv'
  @include require './wye-tee-merge'
  #---------------------------------------------------------------------------------------------------------
  constructor: ( @settings = null ) ->
    super()
    # @specs    = {}
    # @isa      = Multimix.get_keymethod_proxy @, isa
    # # @validate = Multimix.get_keymethod_proxy @, validate
    # declarations.declare_types.apply @

############################################################################################################
module.exports  = L = new Pipestreams()
L.Pipestreams   = Pipestreams




