



'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr.bind CND
badge                     = 'CUPOFJOE'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
#...........................................................................................................
@types                    = new ( require 'intertype' ).Intertype()
{ isa
  validate
  type_of }               = @types.export()
#...........................................................................................................
{ jr }                    = CND
Multimix                  = require 'multimix'

#-----------------------------------------------------------------------------------------------------------
remove_notgiven = ( list ) ->
  return list.filter ( e ) -> e? ### mutating variant ###
  # return ( e for e in list when e? ) ### non-mutating variant ###

#-----------------------------------------------------------------------------------------------------------
MAIN = @
class Cupofjoe extends Multimix
  @include MAIN, { overwrite: false, }
  # @extend MAIN, { overwrite: false, }
  _defaults:      { flatten: false, }

  #---------------------------------------------------------------------------------------------------------
  constructor: ( settings = null) ->
    super()
    @settings       = { @_defaults..., settings..., }
    @_crammed       = false
    @clear()
    return @

  #---------------------------------------------------------------------------------------------------------
  expand: ->
    @collector  = @collector.flat Infinity if @settings.flatten
    R           = @collector
    @clear()
    return R

  #---------------------------------------------------------------------------------------------------------

  #---------------------------------------------------------------------------------------------------------
  cram: ( x... ) ->
    for p, idx in x
      if isa.function p
        prv_collector   = @collector
        @collector      = []
        @_crammed       = false
        rvalue          = p()
        if @_crammed    then  x[ idx .. idx ] = @collector
        else if rvalue? then  x[ idx .. idx ] = rvalue
        @collector      = prv_collector
    x = remove_notgiven x
    @collector.push x unless x.length is 0
    @_crammed = true
    return null

  #---------------------------------------------------------------------------------------------------------
  clear: ->
    @collector = []
    return null

#-----------------------------------------------------------------------------------------------------------
module.exports = { Cupofjoe, }


############################################################################################################
if module is require.main then do =>
  null

