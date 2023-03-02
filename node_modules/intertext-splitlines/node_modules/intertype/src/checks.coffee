
'use strict'

############################################################################################################
@sad                      = sad = Symbol 'sad'
{ rpr
  js_type_of }            = require './helpers'


#-----------------------------------------------------------------------------------------------------------
@is_sad       = ( x ) -> ( x is sad ) or ( x instanceof Error ) or ( @is_saddened x )
@is_happy     = ( x ) -> not @is_sad x
@sadden       = ( x ) -> { [sad]: true, _: x, }
@is_saddened  = ( x ) -> ( ( js_type_of x ) is 'object' ) and ( x[ sad ] is true )

#-----------------------------------------------------------------------------------------------------------
@unsadden = ( x ) ->
  return x if @is_happy x
  @validate.saddened x
  return x._

#-----------------------------------------------------------------------------------------------------------
@declare_check = ( name, checker ) ->
  @validate.nonempty_text name
  @validate.function      checker
  throw new Error "µ8032 type #{rpr name} already declared"   if @specs[  name ]?
  throw new Error "µ8033 check #{rpr name} already declared"  if @checks[ name ]?
  @checks[ name ] = checker
  return null




