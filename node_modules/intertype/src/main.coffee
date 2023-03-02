
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'INTERTYPE/MAIN'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge
#...........................................................................................................
Multimix                  = require 'multimix'
#...........................................................................................................
{ assign
  jr
  flatten
  xrpr
  get_rprs_of_tprs
  js_type_of }            = require './helpers'
#...........................................................................................................
declarations              = require './declarations'
sad                       = ( require './checks' ).sad

#-----------------------------------------------------------------------------------------------------------
isa               = ( type, xP... ) -> @_satisfies_all_aspects  type, xP...
isa_list_of       = ( type, xP... ) -> @isa.list_of             type, xP...
validate_list_of  = ( type, xP... ) -> @validate.list_of        type, xP...

#-----------------------------------------------------------------------------------------------------------
cast = ( type_a, type_b, x, xP... ) ->
  @validate type_a, x, xP...
  return x if type_a is type_b
  return x if @isa type_b, x, xP...
  if ( casts = @specs[ type_a ].casts )?
    return ( converter.call @, x, xP... ) if ( converter = casts[ type_b ] )?
  return "#{x}" if type_b is 'text' ### TAINT use better method like util.inspect ###
  throw new Error "µ30981 unable to cast a #{type_a} as #{type_b}"

#-----------------------------------------------------------------------------------------------------------
check = ( type, x, xP... ) ->
  if @specs[ type ]?
    return if ( @isa type, x, xP... ) then true else sad
  throw new Error "µ44521 unknown type or check #{rpr type}" unless ( check = @checks[ type ] )?
  return try check.call @, x, xP... catch error then error

#-----------------------------------------------------------------------------------------------------------
validate = ( type, xP... ) ->
  return true unless ( aspect = @_get_unsatisfied_aspect type, xP... )?
  [ x, P..., ] = xP
  { rpr_of_tprs, srpr_of_tprs, } = get_rprs_of_tprs P
  message = if aspect is 'main'
    "µ3093 not a valid #{type}: #{xrpr x}#{srpr_of_tprs}"
  else
    "µ3093 not a valid #{type} (violates #{rpr aspect}): #{xrpr x}#{srpr_of_tprs}"
  throw new Error message


#===========================================================================================================
class @Intertype extends Multimix
  # @extend   object_with_class_properties
  @include require './cataloguing'
  @include require './sizing'
  @include require './declaring'
  @include require './checks'

  #---------------------------------------------------------------------------------------------------------
  constructor: ( target = null ) ->
    super()
    #.......................................................................................................
    ### TAINT bug in MultiMix, should be possible to declare methods in class, not the constructor,
    and still get a bound version with `export()`; declaring them here FTTB ###
    #.......................................................................................................
    @sad              = sad
    @specs            = {}
    @checks           = {}
    @isa              = Multimix.get_keymethod_proxy @, isa
    @isa_list_of      = Multimix.get_keymethod_proxy @, isa_list_of
    @cast             = Multimix.get_keymethod_proxy @, cast
    @validate         = Multimix.get_keymethod_proxy @, validate
    @validate_list_of = Multimix.get_keymethod_proxy @, validate_list_of
    @check            = Multimix.get_keymethod_proxy @, check
    @nowait           = ( x ) -> @validate.value x; return x
    declarations.declare_types.apply @
    declarations.declare_checks.apply @
    @export target if target?



