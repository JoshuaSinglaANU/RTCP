
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'INTERTYPE/DECLARING'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge
#...........................................................................................................
{ assign
  jr
  flatten
  xrpr
  js_type_of }            = require './helpers'
isa_copy                  = Symbol 'isa_copy'

#-----------------------------------------------------------------------------------------------------------
### TAINT make catalog of all 'deep JS' names that must never be used as types, b/c e.g a type 'bind'
would shadow native `f.bind()` ###
@illegal_types = [
  'bind'
  'toString'
  'valueOf'
  ]

#-----------------------------------------------------------------------------------------------------------
copy_if_original = ( x ) ->
  return x if x[ isa_copy ]
  R = assign {}, x
  R[ isa_copy ] = true
  return R

#-----------------------------------------------------------------------------------------------------------
@_satisfies_all_aspects = ( type, xP... ) ->
  return true unless ( @_get_unsatisfied_aspect type, xP... )?
  return false

#-----------------------------------------------------------------------------------------------------------
@_get_unsatisfied_aspect = ( type, xP... ) ->
  ### Check all constraints in spec: ###
  throw new Error "µ6500 unknown type #{rpr type}" unless ( spec = @specs[ type ] )?
  for aspect, test of spec.tests
    return aspect unless test.apply @, xP
  return null

#-----------------------------------------------------------------------------------------------------------
@type_of = ( xP... ) ->
  ### TAINT this should be generalized for all Intertype types that split up / rename a JS type: ###
  switch R = js_type_of xP...
    when 'uint8array'
      R = 'buffer' if Buffer.isBuffer xP...
    when 'number'
      [ x, ] = xP
      unless Number.isFinite x
        R = if ( Number.isNaN x ) then 'nan' else 'infinity'
    when 'regexp' then R = 'regex'
    when 'string' then R = 'text'
    when 'array'  then R = 'list'
  ### Refuse to answer question in case type found is not in specs: ###
  # debug 'µ33332', R, ( k for k of @specs )
  throw new Error "µ6623 unknown type #{rpr R}" unless R of @specs
  return R

#-----------------------------------------------------------------------------------------------------------
@types_of = ( xP... ) ->
  R = []
  for type, spec of @specs
    ok = true
    for aspect, test of spec.tests
      # debug 'µ27722', "#{type}/#{aspect}", test.apply @, xP
      unless test.apply @, xP
        ok = false
        break
    R.push type if ok
  return R

#-----------------------------------------------------------------------------------------------------------
@declare = ( P... ### type, spec?, test? ### ) ->
  # debug 'µ33374-0', 'declare', P
  switch arity = P.length
    when 1 then return @_declare_1 P...
    when 2 then return @_declare_2 P...
    when 3 then return @_declare_3 P...
  throw new Error "µ6746 expected between 1 and 3 arguments, got #{arity}"

#-----------------------------------------------------------------------------------------------------------
@_declare_1 = ( spec ) ->
  # debug 'µ33374-1', '_declare_1', spec
  #.........................................................................................................
  unless ( T = js_type_of spec ) is 'object'
    throw new Error "µ6869 expected an object for spec, got a #{T}"
  #.........................................................................................................
  unless ( T = js_type_of spec.type ) is 'string'
    throw new Error "µ6992 expected a text for spec.type, got a #{T}"
  #.........................................................................................................
  switch ( T = js_type_of spec.tests )
    when 'function' then spec.tests = { main: spec.tests, }
    when 'object'   then null
    else throw new Error "µ7115 expected an object for spec.tests, got a #{T}"
  #.........................................................................................................
  return @_declare spec

#-----------------------------------------------------------------------------------------------------------
@_declare_2 = ( type, spec_or_test ) ->
  # debug 'µ33374-2', '_declare_2', type, spec_or_test
  switch T = js_type_of spec_or_test
    #.......................................................................................................
    when 'function'
      return @_declare_1 { type, tests: { main: spec_or_test, }, }
    #.......................................................................................................
    when 'asyncfunction'
      throw "µ7238 asynchronous functions not yet supported"
  #.........................................................................................................
  if T isnt 'object'
    throw new Error "µ7361 expected an object, got a #{T} for spec"
  #.........................................................................................................
  if spec_or_test.type? and ( not spec_or_test.type is type )
    throw new Error "µ7484 type declarations #{rpr type} and #{rpr spec_or_test.type} do not match"
  #.........................................................................................................
  spec      = copy_if_original spec_or_test
  spec.type = type
  return @_declare_1 spec

#-----------------------------------------------------------------------------------------------------------
@_declare_3 = ( type, spec, test ) ->
  # debug 'µ33374-3', '_declare_3', type, spec, test
  #.........................................................................................................
  if ( T = js_type_of spec ) isnt 'object'
    throw new Error "µ7607 expected an object, got a #{T} for spec"
  #.........................................................................................................
  unless ( T = js_type_of test ) is 'function'
    throw new Error "µ7730 expected a function for test, got a #{T}"
  #.........................................................................................................
  if spec.tests?
    throw new Error "µ7853 spec cannot have tests when tests are passed as argument"
  #.........................................................................................................
  spec       = copy_if_original spec
  spec.tests = { main: test, }
  return @_declare_2 type, spec

#-----------------------------------------------------------------------------------------------------------
@_declare = ( spec ) ->
  spec      = copy_if_original spec
  delete spec[ isa_copy ]
  # debug 'µ33374-4', '_declare', spec
  { type, } = spec
  spec.type = type
  #.........................................................................................................
  if type in @illegal_types
    throw new Error "µ7976 #{rpr type} is not a legal type name"
  #.........................................................................................................
  if ( @specs[ type ] )?
    throw new Error "µ8099 type #{rpr type} already declared"
  #.........................................................................................................
  @specs[ type ]  = spec
  @isa[ type ]    = ( P... ) => @isa type, P...
  # @validate[ type ]    = ( P... ) => @validate type, P...
  spec.size       = @_sizeof_method_from_spec type, spec
  #.........................................................................................................
  return null


