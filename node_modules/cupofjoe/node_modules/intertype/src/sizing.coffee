
'use strict'

############################################################################################################
{ assign
  jr
  xrpr
  js_type_of }            = require './helpers'


#===========================================================================================================
# OBJECT SIZES
#-----------------------------------------------------------------------------------------------------------
@_sizeof_method_from_spec = ( type, spec ) ->
  do ( s = spec.size ) =>
    return null unless s?
    switch T = js_type_of s
      when 'string'   then return ( x ) -> x[ s ]   ### TAINT allows empty strings ###
      when 'function' then return s                 ### TAINT disallows async funtions ###
      when 'number'   then return -> s              ### TAINT allows NaN, Infinity ###
    throw new Error "µ30988 expected null, a text or a function for size of #{type}, got a #{T}"

#-----------------------------------------------------------------------------------------------------------
@size_of = ( x, P... ) ->
  ### The `size_of()` method uses a per-type configurable methodology to return the size of a given value;
  such methodology may permit or necessitate passing additional arguments (such as `size_of text`, which
  comes in several flavors depending on whether bytes or codepoints are to be counted). As such, it is a
  model for how to implement Go-like method dispatching. ###
  type = @type_of x
  unless ( @isa.function ( getter = @specs[ type ]?.size ) )
    throw new Error "µ88793 unable to get size of a #{type}"
  return getter x, P...

#-----------------------------------------------------------------------------------------------------------
### TAINT faulty implementation:
  * does not use size_of but length
  * does not accept additional arguments as needed for texts
  * risks to break codepoints apart
  ###
@first_of   = ( collection ) -> collection[ 0 ]
@last_of    = ( collection ) -> collection[ collection.length - 1 ]

#-----------------------------------------------------------------------------------------------------------
@arity_of = ( x ) ->
  unless ( type = @supertype_of x ) is 'callable'
    throw new Error "µ88733 expected a callable, got a #{type}"
  return x.length

#-----------------------------------------------------------------------------------------------------------
@has_size = ( x ) -> @isa.function @specs[ @type_of x ]?.size


