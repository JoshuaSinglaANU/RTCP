
'use strict'

#-----------------------------------------------------------------------------------------------------------
{ type_of, } = require './helpers'

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
  #.........................................................................................................
  if Array.isArray x
    return Object.freeze ( ( _freeze value ) for value in x )
  #.........................................................................................................
  ### kludge to avoid `null` being mistaken as object; should use `type_of` instead of quirky `typeof`,
  but that breaks some tests in myterious ways, so hotfixing it like this FTTB: ###
  if ( x isnt null ) and typeof x is 'object'
    R = {}
    R[ key ] = _freeze value for key, value of x
    return Object.freeze R
  #.........................................................................................................
  return x

#-----------------------------------------------------------------------------------------------------------
_thaw = ( x ) ->
  #.........................................................................................................
  if Array.isArray x
    return ( ( _thaw value ) for value in x )
  #.........................................................................................................
  if ( type_of x ) is 'object'
    R = {}
    R[ key ] = _thaw value for key, value of x
    return R
  #.........................................................................................................
  return x

#-----------------------------------------------------------------------------------------------------------
lets = ( original, modifier ) ->
  draft = thaw original
  modifier draft if modifier?
  return freeze draft

#-----------------------------------------------------------------------------------------------------------
fix = ( target, name, value ) ->
  Object.defineProperty target, name, {
    enumerable:     true
    writable:       false
    configurable:   false
    value:          freeze value }
  return target

#-----------------------------------------------------------------------------------------------------------
module.exports = {
  lets, freeze, thaw, fix,
  nofreeze:   ( require './nofreeze'    ),
  partial:    ( require './partial'     ),
  breadboard: ( require './breadboard'  ), }

