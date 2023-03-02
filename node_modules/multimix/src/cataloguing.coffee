
'use strict'


#===========================================================================================================
# OBJECT PROPERTY CATALOGUING
#-----------------------------------------------------------------------------------------------------------
@keys_of              = ( P... ) -> @values_of @walk_keys_of      P...
@all_keys_of          = ( P... ) -> @values_of @walk_all_keys_of  P...
@all_own_keys_of      = ( x    ) -> if x? then Object.getOwnPropertyNames x else []
@walk_all_own_keys_of = ( x    ) -> yield k for k in @all_own_keys_of x

#-----------------------------------------------------------------------------------------------------------
@walk_keys_of = ( x, settings ) ->
  defaults = { skip_undefined: true, }
  settings = { defaults..., settings..., }
  for k of x
    ### TAINT should use property descriptors to avoid possible side effects ###
    continue if ( x[ k ] is undefined ) and settings.skip_undefined
    yield k

#-----------------------------------------------------------------------------------------------------------
@walk_all_keys_of = ( x, settings ) ->
  defaults = { skip_object: true, skip_undefined: true, }
  settings = { defaults..., settings..., }
  return @_walk_all_keys_of x, new Set(), settings

#-----------------------------------------------------------------------------------------------------------
@_walk_all_keys_of = ( x, seen, settings ) ->
  if ( not settings.skip_object ) and x is Object::
    yield return
  #.........................................................................................................
  for k from @walk_all_own_keys_of x
    continue if seen.has k
    seen.add k
    ### TAINT should use property descriptors to avoid possible side effects ###
    ### TAINT trying to access `arguments` causes error ###
    try value = x[ k ] catch error then continue
    continue if ( value is undefined ) and settings.skip_undefined
    if settings.symbol?
      continue unless value?
      continue unless value[ settings.symbol ]
    yield k
  #.........................................................................................................
  if ( proto = Object.getPrototypeOf x )?
    yield from @_walk_all_keys_of proto, seen, settings

#-----------------------------------------------------------------------------------------------------------
### Turn iterators into lists, copy lists: ###
@values_of = ( x ) -> [ x... ]

#-----------------------------------------------------------------------------------------------------------
@has_keys = ( x, P... ) ->
  ### Observe that `has_keys()` always considers `undefined` as 'not set' ###
  return false unless x? ### TAINT or throw error ###
  for key in P.flat Infinity
    ### TAINT should use property descriptors to avoid possible side effects ###
    return false if x[ key ] is undefined
  return true

#-----------------------------------------------------------------------------------------------------------
@has_key = ( x, key ) -> @has_keys x, key

#-----------------------------------------------------------------------------------------------------------
@has_only_keys = ( x, P... ) ->
  probes  = ( P.flat Infinity ).sort()
  keys    = ( @values_of @keys_of x ).sort()
  return probes.length = keys.length and probes.every ( x, idx ) -> x == keys[ idx ]

