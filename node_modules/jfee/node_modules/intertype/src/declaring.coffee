
'use strict'

############################################################################################################
{ assign
  jr
  rpr
  xrpr
  js_type_of }            = require './helpers'
isa_copy                  = Symbol 'isa_copy'
constructor_of_generators = ( ( -> yield 42 )() ).constructor

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
  ### Check with `type_of()` if type not in spec: ###
  unless ( spec = @specs[ type ] )?
    return null if ( factual_type = @type_of xP... ) is type
    return "#{rpr type} is a known type"
  ### Check all constraints in spec: ###
  for aspect, test of spec.tests
    unless test.apply @, xP
      return aspect
  return null

#-----------------------------------------------------------------------------------------------------------
@type_of = ( x ) ->
  throw new Error "^7746^ expected 1 argument, got #{arity}" unless arguments.length is 1
  return 'null'       if x is null
  return 'undefined'  if x is undefined
  return 'infinity'   if ( x is Infinity  ) or  ( x is -Infinity  )
  return 'boolean'    if ( x is true      ) or  ( x is false      )
  return 'nan'        if ( Number.isNaN     x )
  return 'buffer'     if ( Buffer.isBuffer  x )
  #.........................................................................................................
  if ( tagname = x[ Symbol.toStringTag ] )?
    return 'arrayiterator'  if tagname is 'Array Iterator'
    return 'stringiterator' if tagname is 'String Iterator'
    return 'mapiterator'    if tagname is 'Map Iterator'
    return 'setiterator'    if tagname is 'Set Iterator'
    return tagname.toLowerCase()
  #.........................................................................................................
  ### Domenic Denicola Device, see https://stackoverflow.com/a/30560581 ###
  return 'nullobject' if ( c = x.constructor ) is undefined
  return 'object'     if ( typeof c ) isnt 'function'
  if ( R = c.name.toLowerCase() ) is ''
    return 'generator' if x.constructor is constructor_of_generators
    ### NOTE: throw error since this should never happen ###
    return ( ( Object::toString.call x ).slice 8, -1 ).toLowerCase() ### Mark Miller Device ###
  #.........................................................................................................
  return 'wrapper'  if ( typeof x is 'object' ) and R in [ 'boolean', 'number', 'string', ]
  return 'float'    if R is 'number'
  return 'regex'    if R is 'regexp'
  return 'text'     if R is 'string'
  return 'list'     if R is 'array'
  ### thx to https://stackoverflow.com/a/29094209 ###
  ### TAINT may produce an arbitrarily long throwaway string ###
  return 'class'    if R is 'function' and x.toString().startsWith 'class '
  return R


#-----------------------------------------------------------------------------------------------------------
@types_of = ( xP... ) ->
  R = []
  for type, spec of @specs
    ok = true
    for aspect, test of spec.tests
      unless test.apply @, xP
        ok = false
        break
    R.push type if ok
  return R

#-----------------------------------------------------------------------------------------------------------
@declare = ( P... ### type, spec?, test? ### ) ->
  switch arity = P.length
    when 1 then return @_declare_1 P...
    when 2 then return @_declare_2 P...
    when 3 then return @_declare_3 P...
  throw new Error "µ6746 expected between 1 and 3 arguments, got #{arity}"

#-----------------------------------------------------------------------------------------------------------
@_declare_1 = ( spec ) ->
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


