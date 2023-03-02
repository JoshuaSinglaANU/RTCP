
'use strict'


#===========================================================================================================
# MODULE METACLASS provides static methods `@extend()`, `@include()`
#-----------------------------------------------------------------------------------------------------------
### The little dance around the module_keywords variable is to ensure we have callback support when mixins
extend a class. See https://arcturo.github.io/library/coffeescript/03_classes.html ###
#-----------------------------------------------------------------------------------------------------------
module_keywords = [ 'extended', 'included', ]

#===========================================================================================================
class Multimix

  #---------------------------------------------------------------------------------------------------------
  @extend: ( object, settings = null ) ->
    ### TAINT code duplication ###
    settings = { { overwrite: true, }..., ( settings ? null )..., }
    for key, value of object when key not in module_keywords
      if ( not settings.overwrite ) and ( @::[ key ]? or @[ key ]? )
        throw new Error "^multimix/include@5684 overwrite set to false but name already set: #{JSON.stringify key}"
      @[ key ] = value
    object.extended?.apply @
    return @

  #---------------------------------------------------------------------------------------------------------
  @include: ( object, settings = null ) ->
    ### TAINT code duplication ###
    settings = { { overwrite: true, }..., ( settings ? null )..., }
    for key, value of object when key not in module_keywords
      if ( not settings.overwrite ) and ( @::[ key ]? or @[ key ]? )
        throw new Error "^multimix/include@5683 overwrite set to false but name already set: #{JSON.stringify key}"
      # Assign properties to the prototype
      @::[ key ] = value
    object.included?.apply @
    return @

  #---------------------------------------------------------------------------------------------------------
  export: ( target = null ) ->
    ### Return an object with methods, bound to the current instance. ###
    R       = target ? {}
    for k from ( require './cataloguing' ).walk_all_keys_of @
      v = @[ k ]
      unless v?.bind?                                       then  R[ k ] = v
      else if ( v[ Multimix.isa_keymethod_proxy ] ? false ) then  R[ k ] = Multimix.get_keymethod_proxy @, v
      else                                                        R[ k ] = v.bind @
    return R

  #---------------------------------------------------------------------------------------------------------
  get_my_prototype: -> Object.getPrototypeOf Object.getPrototypeOf @

  #---------------------------------------------------------------------------------------------------------
  new: ( P... ) -> new @constructor P...


  #=========================================================================================================
  # KEYMETHOD FACTORY
  #---------------------------------------------------------------------------------------------------------
  @get_keymethod_proxy = ( bind_target, f ) ->
    R = new Proxy ( f.bind bind_target ),
      get: ( target, key ) ->
        return target[ key ] if key in [ 'bind', ] # ... other properties ...
        return target[ key ] if ( typeof key ) is 'symbol'
        return ( xP... ) -> target key, xP...
    R[ Multimix.isa_keymethod_proxy ] = true
    return R

  #=========================================================================================================
  # @js_type_of = ( x ) -> return ( ( Object::toString.call x ).slice 8, -1 ).toLowerCase()
  @isa_keymethod_proxy = Symbol 'proxy'


############################################################################################################
module.exports = Multimix


