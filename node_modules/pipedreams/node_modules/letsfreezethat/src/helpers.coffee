'use strict'

#-----------------------------------------------------------------------------------------------------------
@type_of   = ( x ) ->
  if ( R = ( ( Object::toString.call x ).slice 8, -1 ).toLowerCase() ) is 'object'
    return x.constructor.name.toLowerCase()
  return R

#-----------------------------------------------------------------------------------------------------------
@is_computed = ( d, key ) -> @is_descriptor_of_computed_value Object.getOwnPropertyDescriptor d, key

#-----------------------------------------------------------------------------------------------------------
@is_descriptor_of_computed_value = ( descriptor ) ->
  return ( ( keys = Object.keys descriptor ).includes 'set' ) or ( keys.includes 'get' )

#-----------------------------------------------------------------------------------------------------------
@set_writable_value = ( d, key, value ) ->
  ### Acc to MDN `defineProperty`, a 'writable data descriptor'. ###
  Object.defineProperty d, key, { enumerable: true, writable: true, configurable: true, value, }

#-----------------------------------------------------------------------------------------------------------
@set_readonly_value = ( d, key, value ) ->
  ### Acc to MDN `defineProperty`, a 'readonly data descriptor'. ###
  Object.defineProperty d, key, { enumerable: true, writable: false, configurable: false, value, }

#-----------------------------------------------------------------------------------------------------------
@set_computed_value = ( d, key, get = null, set = null ) ->
  ### Acc to MDN `defineProperty`, an 'accessor descriptor'. ###
  descriptor  = { enumerable: true, configurable: false, }
  type_of_get = if get? then @type_of get else null
  type_of_set = if set? then @type_of set else null
  throw new Error "^lft@h1^ must define getter or setter" unless type_of_get? or type_of_set?
  if type_of_get?
    throw new Error "^lft@h2^ expected a function, got a #{type}" unless type_of_get is 'function'
    descriptor.get = get
  if type_of_set?
    throw new Error "^lft@h3^ expected a function, got a #{type}" unless type_of_set is 'function'
    descriptor.set = set
  Object.defineProperty d, key, descriptor

############################################################################################################
do => @[ k ] = v.bind @ for k, v of @


