
'use strict'

############################################################################################################
Multimix                  = require 'multimix'
#...........................................................................................................
HELPERS                   = require './helpers'
{ assign
  jr
  rpr
  xrpr
  get_rprs_of_tprs
  js_type_of }            = HELPERS
#...........................................................................................................
declarations              = require './declarations'
sad                       = ( require './checks' ).sad
jk_equals                 = require '../deps/jkroso-equals'


#-----------------------------------------------------------------------------------------------------------
isa                 = ( type, xP... ) -> @_satisfies_all_aspects  type, xP...
isa_list_of         = ( type, xP... ) -> @isa.list_of             type, xP...
isa_object_of       = ( type, xP... ) -> @isa.object_of           type, xP...
validate_list_of    = ( type, xP... ) -> @validate.list_of        type, xP...
validate_object_of  = ( type, xP... ) -> @validate.object_of      type, xP...
isa_optional        = ( type, xP... ) -> ( not xP[ 0 ]? ) or @_satisfies_all_aspects   type, xP...
validate_optional   = ( type, xP... ) -> ( not xP[ 0 ]? ) or @validate                 type, xP...

#-----------------------------------------------------------------------------------------------------------
cast = ( type_a, type_b, x, xP... ) ->
  @validate type_a, x, xP...
  return x if type_a is type_b
  return x if @isa type_b, x, xP...
  if ( casts = @specs[ type_a ].casts )?
    return ( converter.call @, x, xP... ) if ( converter = casts[ type_b ] )?
  return "#{x}" if type_b is 'text' ### TAINT use better method like util.inspect ###
  throw new Error "^intertype/cast@1234^ unable to cast a #{type_a} as #{type_b}"

#-----------------------------------------------------------------------------------------------------------
check = ( type, x, xP... ) ->
  if @specs[ type ]?
    return if ( @isa type, x, xP... ) then true else sad
  throw new Error "^intertype/check@1345^ unknown type or check #{rpr type}" unless ( check = @checks[ type ] )?
  return try check.call @, x, xP... catch error then error

#-----------------------------------------------------------------------------------------------------------
validate = ( type, xP... ) ->
  return true unless ( aspect = @_get_unsatisfied_aspect type, xP... )?
  [ x, P..., ] = xP
  { rpr_of_tprs, srpr_of_tprs, } = get_rprs_of_tprs P
  message = if aspect is 'main'
    "^intertype/validate@1456^ not a valid #{type}: #{xrpr x}#{srpr_of_tprs}"
  else
    "^intertype/validate@1567^ not a valid #{type} (violates #{rpr aspect}): #{xrpr x}#{srpr_of_tprs}"
  throw new Error message




#===========================================================================================================
class @Intertype extends Multimix
  # @extend   object_with_class_properties
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
    @sad                = sad
    @specs              = {}
    @checks             = {}
    @isa                = Multimix.get_keymethod_proxy @, isa
    @isa_optional       = Multimix.get_keymethod_proxy @, isa_optional
    @isa_list_of        = Multimix.get_keymethod_proxy @, isa_list_of
    @isa_object_of      = Multimix.get_keymethod_proxy @, isa_object_of
    @cast               = Multimix.get_keymethod_proxy @, cast
    @validate           = Multimix.get_keymethod_proxy @, validate
    @validate_optional  = Multimix.get_keymethod_proxy @, validate_optional
    @validate_list_of   = Multimix.get_keymethod_proxy @, validate_list_of
    @validate_object_of = Multimix.get_keymethod_proxy @, validate_object_of
    @check              = Multimix.get_keymethod_proxy @, check
    @nowait             = ( x ) -> @validate.immediate x; return x
    @_helpers           = HELPERS
    declarations.declare_types.apply @
    declarations.declare_checks.apply @
    @export target if target?

  #---------------------------------------------------------------------------------------------------------
  equals: ( a, P... ) ->
    if ( arity = arguments.length ) < 2
      throw new Error "^intertype/equals@3489^ expected at least 2 arguments, got #{arity}"
    type_of_a = @type_of a
    for b in P
      return false unless type_of_a is @type_of b
      ### TAINT this call involves its own typechecking code and thus may mysteriously fail ###
      return false unless jk_equals a, b
    return true


