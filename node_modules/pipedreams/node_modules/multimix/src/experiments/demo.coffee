
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'MULTIMIX/EXPERIMENTS/ES6-CLASSES-WITH.MIXINS'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge


#-----------------------------------------------------------------------------------------------------------
rewritten_example = ->


  #=========================================================================================================
  # MODULE METACLASS provides static methods `@extend()`, `@include()`
  #---------------------------------------------------------------------------------------------------------
  ### The little dance around the module_keywords variable is to ensure we have callback support when mixins
  extend a class. See https://arcturo.github.io/library/coffeescript/03_classes.html ###
  #---------------------------------------------------------------------------------------------------------
  module_keywords = [ 'extended', 'included', ]

  #=========================================================================================================
  class Multimix

    #-------------------------------------------------------------------------------------------------------
    @extend: ( object ) ->
      for key, value of object when key not in module_keywords
        @[ key ] = value
      object.extended?.apply @
      return @

    #-------------------------------------------------------------------------------------------------------
    @include: ( object ) ->
      for key, value of object when key not in module_keywords
        # Assign properties to the prototype
        @::[ key ] = value
      object.included?.apply @
      return @

    #-------------------------------------------------------------------------------------------------------
    export: ->
      ### Return an object with methods, bound to the current instance. ###
      R = {}
      for k, v of @
        continue unless v?.bind?
        if ( v[ isa_keymethod_proxy ] ? false )
          R[ k ] = _get_keymethod_proxy @, v
        else
          R[ k ] = v.bind @
      return R

  #=========================================================================================================
  # KEYMETHOD FACTORY
  #---------------------------------------------------------------------------------------------------------
  _get_keymethod_proxy = ( bind_target, f ) ->
    R = new Proxy ( f.bind bind_target ),
      get: ( target, key ) ->
        return target[ key ] if key in [ 'bind', ] # ... other properties ...
        return target[ key ] if ( js_type_of key ) is 'symbol'
        return ( xP... ) -> target key, xP...
    R[ isa_keymethod_proxy ] = true
    return R


  #=========================================================================================================
  # SAMPLE OBJECTS WITH INSTANCE METHODS, STATIC METHODS
  #---------------------------------------------------------------------------------------------------------
  object_with_class_properties =
    find:   ( id    ) -> info "class method 'find()'", ( k for k of @ )
    create: ( attrs ) -> info "class method 'create()'", ( k for k of @ )

  #---------------------------------------------------------------------------------------------------------
  object_with_instance_properties =
    save: -> info "instance method 'save()'", ( k for k of @ )

  #=========================================================================================================
  js_type_of = ( x ) -> return ( ( Object::toString.call x ).slice 8, -1 ).toLowerCase()
  isa_keymethod_proxy = Symbol 'proxy'

  #---------------------------------------------------------------------------------------------------------
  isa = ( type, xP... ) ->
    ### NOTE realistic method should throw error when `type` not in `specs` ###
    urge "µ1129 object #{rpr @instance_name} isa #{rpr type} called with #{rpr xP}"
    urge "µ1129 my @specs: #{rpr @specs}"
    urge "µ1129 spec for type #{rpr type}: #{rpr @specs[ type ]}"

  #---------------------------------------------------------------------------------------------------------
  class Intertype extends Multimix
    @extend   object_with_class_properties
    @include  object_with_instance_properties

    #-------------------------------------------------------------------------------------------------------
    constructor: ( @instance_name ) ->
      super()
      @specs = {}
      @declare type, value for type, value of @constructor.base_types
      @isa = _get_keymethod_proxy @, isa

    #-------------------------------------------------------------------------------------------------------
    declare: ( type, value ) ->
      whisper 'µ7474', 'declare', type, rpr value
      @specs[ type ] = value

    #-------------------------------------------------------------------------------------------------------
    @base_types =
      foo: 'spec for type foo'
      bar: 'spec for type bar'


  ##########################################################################################################
  intertype_1 = new Intertype
  intertype_2 = new Intertype

  info 'µ002-1', Intertype.base_types
  info 'µ002-2', intertype_1.declare 'new_on_it1', 'a new hope'
  info 'µ002-3', 'intertype_1.specs', intertype_1.specs
  info 'µ002-4', 'intertype_2.specs', intertype_2.specs
  info 'µ002-5', intertype_1.isa 'new_on_it1', 1, 2, 3
  info 'µ002-6', intertype_1.isa.new_on_it1    1, 2, 3
  info 'µ002-7', intertype_2.isa 'new_on_it1', 1, 2, 3
  info 'µ002-8', intertype_2.isa.new_on_it1    1, 2, 3
  { isa, declare, } = intertype_1.export()
  info 'µ002-9', isa 'new_on_it1', 1, 2, 3
  info 'µ002-10', isa.new_on_it1    1, 2, 3

#-----------------------------------------------------------------------------------------------------------
example_using_multimix = ->
  Multimix = require '../..'

  #=========================================================================================================
  # SAMPLE OBJECTS WITH INSTANCE METHODS, STATIC METHODS
  #---------------------------------------------------------------------------------------------------------
  object_with_class_properties =
    find:   ( id    ) -> info "class method 'find()'", ( k for k of @ )
    create: ( attrs ) -> info "class method 'create()'", ( k for k of @ )

  #---------------------------------------------------------------------------------------------------------
  object_with_instance_properties =
    save: -> info "instance method 'save()'", ( k for k of @ )
    find: -> info "instance method 'find()'", ( k for k of @ )

  #=========================================================================================================
  # CLASS DECLARATION
  #---------------------------------------------------------------------------------------------------------
  isa = ( type, xP... ) ->
    ### NOTE realistic method should throw error when `type` not in `specs` ###
    urge "µ1129 object #{rpr @instance_name} isa #{rpr type} called with #{rpr xP}"
    urge "µ1129 my @specs: #{rpr @specs}"
    urge "µ1129 spec for type #{rpr type}: #{rpr @specs[ type ]}"

  #---------------------------------------------------------------------------------------------------------
  class Intertype extends Multimix
    @extend   object_with_class_properties,     { overwrite: true, }
    @include  object_with_instance_properties,  { overwrite: true, }

    #-------------------------------------------------------------------------------------------------------
    constructor: ( @instance_name ) ->
      super()
      @specs = {}
      @declare type, value for type, value of @constructor.base_types
      @isa = Multimix.get_keymethod_proxy @, isa

    #-------------------------------------------------------------------------------------------------------
    declare: ( type, value ) ->
      whisper 'µ7474', 'declare', type, rpr value
      @specs[ type ] = value

    #-------------------------------------------------------------------------------------------------------
    @base_types =
      foo: 'spec for type foo'
      bar: 'spec for type bar'


  ##########################################################################################################
  target      = {}
  intertype_1 = new Intertype target
  intertype_2 = new Intertype

  info 'µ002-1', Intertype.base_types
  info 'µ002-2', intertype_1.declare 'new_on_it1', 'a new hope'
  info 'µ002-3', 'intertype_1.specs', intertype_1.specs
  info 'µ002-4', 'intertype_2.specs', intertype_2.specs
  info 'µ002-5', intertype_1.isa 'new_on_it1', 1, 2, 3
  info 'µ002-6', intertype_1.isa.new_on_it1    1, 2, 3
  info 'µ002-7', intertype_2.isa 'new_on_it1', 1, 2, 3
  info 'µ002-8', intertype_2.isa.new_on_it1    1, 2, 3
  target = {}
  { isa, declare, } = intertype_1.export target
  info 'µ002-9',  isa 'new_on_it1', 1, 2, 3
  info 'µ002-10', isa.new_on_it1    1, 2, 3
  info 'µ002-11', target.isa 'new_on_it1', 1, 2, 3
  info 'µ002-12', target.isa.new_on_it1    1, 2, 3
  info 'µ002-13', intertype_1.find()
  info 'µ002-14', intertype_2.find()
  debug target
  debug intertype_2


#-----------------------------------------------------------------------------------------------------------
example_for_overwrite_false = ->
  Multimix = require '../..'

  #=========================================================================================================
  # SAMPLE OBJECTS WITH INSTANCE METHODS, STATIC METHODS
  #---------------------------------------------------------------------------------------------------------
  object_with_class_properties =
    find:   ( id    ) -> info "class method 'find()'", ( k for k of @ )
    create: ( attrs ) -> info "class method 'create()'", ( k for k of @ )

  #---------------------------------------------------------------------------------------------------------
  object_with_instance_properties =
    save: -> info "instance method 'save()'", ( k for k of @ )
    find: -> info "instance method 'find()'", ( k for k of @ )

  #=========================================================================================================
  # CLASS DECLARATION
  #---------------------------------------------------------------------------------------------------------
  isa = ( type, xP... ) ->
    ### NOTE realistic method should throw error when `type` not in `specs` ###
    urge "µ1129 object #{rpr @instance_name} isa #{rpr type} called with #{rpr xP}"
    urge "µ1129 my @specs: #{rpr @specs}"
    urge "µ1129 spec for type #{rpr type}: #{rpr @specs[ type ]}"

  #---------------------------------------------------------------------------------------------------------
  try
    class Intertype extends Multimix
      @extend   object_with_class_properties,     { overwrite: false, }
      @include  object_with_instance_properties,  { overwrite: false, }
    # intertype = new Intertype()
  catch error
    warn error.message
  return null


############################################################################################################
unless module.parent?
  # raw_example()
  # rewritten_example()
  example_using_multimix()
  example_for_overwrite_false()

