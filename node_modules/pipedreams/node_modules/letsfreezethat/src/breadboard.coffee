
'use strict'

#-----------------------------------------------------------------------------------------------------------
{ type_of
  is_descriptor_of_computed_value
  set_writable_value
  set_readonly_value
  set_computed_value } = require './helpers'

#-----------------------------------------------------------------------------------------------------------
freeze = ( x ) ->
  try
    return _freeze x
  catch error
    if error.name is 'RangeError' and error.message is 'Maximum call stack size exceeded'
      throw new Error "µ45666 unable to freeze circular objects"
    throw error

#-----------------------------------------------------------------------------------------------------------
thaw = ( x ) ->
  try
    return _thaw x
  catch error
    if error.name is 'RangeError' and error.message is 'Maximum call stack size exceeded'
      throw new Error "µ45667 unable to thaw circular objects"
    throw error

#-----------------------------------------------------------------------------------------------------------
_freeze = ( x ) ->
  type = type_of x
  if ( level is 0 ) and ( type isnt 'object' )
    throw new Failure '^lft/breadboard@error_not_an_object', "breadboard.freeze needs an object, got a #{type}"
  switch type
    #.......................................................................................................
    when 'array'
      return Object.seal ( ( _freeze value ) for value in x )
    #.......................................................................................................
    when 'object'
      #.....................................................................................................
      if level is 0
        if ( Object.isSealed x ) or ( Object.isFrozen )
          throw new Failure '^lft/bb@error_frozen_sealed', "unable to modify a sealed or frozen object"
        Object.preventExtensions x
        R = x
      #.....................................................................................................
      else
        R = {}
      #.....................................................................................................
      for key, descriptor of Object.getOwnPropertyDescriptors x
        if is_descriptor_of_computed_value descriptor
          Object.defineProperty R, key, descriptor
        else
          if ( type_of descriptor.value ) in [ 'object', 'array', ]
            descriptor.value = _freeze descriptor.value
          descriptor.configurable = false
          descriptor.writable     = false
          Object.defineProperty R, key, descriptor
      return Object.seal R
  #.........................................................................................................
  return x

#-----------------------------------------------------------------------------------------------------------
_thaw = ( x ) ->
  switch type = type_of x
    #.......................................................................................................
    when 'array'
      return ( ( _thaw value ) for value in x )
    #.......................................................................................................
    when 'object'
      R = {}
      for key, descriptor of Object.getOwnPropertyDescriptors x
        descriptor.configurable = true
        if is_descriptor_of_computed_value descriptor
          Object.defineProperty R, key, descriptor
        else
          if ( type_of descriptor.value ) in [ 'object', 'array', ]
            descriptor.value = _thaw descriptor.value
          descriptor.writable     = true
          Object.defineProperty R, key, descriptor
      return R
  #.........................................................................................................
  return x

#-----------------------------------------------------------------------------------------------------------
lets = ( original, modifier ) ->
  draft = thaw original
  modifier draft if modifier?
  return freeze draft

#-----------------------------------------------------------------------------------------------------------
lets_compute = ( original, key, get = null, set = null ) ->
  draft = thaw original
  set_computed_value draft, key, get, set
  return freeze draft

#-----------------------------------------------------------------------------------------------------------
fix = ( target, key, value ) ->
  set_readonly_value target, key, freeze value
  return target

#-----------------------------------------------------------------------------------------------------------
module.exports = {
  lets, freeze, thaw, fix, lets_compute,
  nofreeze: ( require './nofreeze' ),
  partial: ( require './partial' ), }

