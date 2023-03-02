
#-----------------------------------------------------------------------------------------------------------
pluck = ( x, key, fallback ) ->
  R = x[ key ]
  R = fallback if R is undefined
  delete x[ key ]
  return R

#-----------------------------------------------------------------------------------------------------------
@$pluck = ( settings ) ->
  throw new Error "µ29303 need settings 'keys', got #{rpr settings}" unless settings?
  { keys, } = settings
  throw new Error "µ30068 need settings 'keys', got #{rpr settings}" unless keys?
  keys      = keys.split /,\s*|\s+/ if CND.isa_text keys
  throw new Error "µ30833 need settings 'keys', got #{rpr settings}" unless keys.length > 0
  as        = settings[ 'as' ] ? 'object'
  unless as in [ 'list', 'object', 'pod', ]
    throw new Error "µ31598 expected 'list', 'object' or 'pod', got #{rpr as}"
  if as is 'list'
    return @map ( data ) => ( data[ key ] for key in keys )
  return @map ( data ) =>
    Z         = {}
    Z[ key ]  = data[ key ] for key in keys
    return Z
