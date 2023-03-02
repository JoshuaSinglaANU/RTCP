

'use strict'

############################################################################################################
log                       = console.log
frozen                    = Object.isFrozen
assign                    = Object.assign
shallow_freeze            = Object.freeze
shallow_copy              = ( x, P... ) -> assign ( if Array.isArray x then [] else {} ), x, P...


#===========================================================================================================
deep_copy = ( d ) ->
  ### TAINT code duplication ###
  ### immediately return for zero, empty string, null, undefined, NaN, false, true: ###
  return d if ( not d ) or d is true
  ### thx to https://github.com/lukeed/klona/blob/master/src/json.js ###
  switch ( Object::toString.call d )
    when '[object Array]'
      k = d.length
      R = []
      while ( k-- )
        if ( v = d[ k ] )? and ( ( typeof v ) is 'object' ) then  R[ k ] = deep_copy  v
        else                                                      R[ k ] =            v
      return R
    when '[object Object]'
      R = {}
      for k, v of d
        if v? and ( ( typeof v ) is 'object' ) then R[ k ] = deep_copy  v
        else                                        R[ k ] =            v
      return R
  return d

#===========================================================================================================
deep_freeze = ( d ) ->
  ### TAINT code duplication ###
  ### immediately return for zero, empty string, null, undefined, NaN, false, true: ###
  return d if ( not d ) or ( d is true )
  ### thx to https://github.com/lukeed/klona/blob/master/src/json.js ###
  is_first = true
  switch ( Object::toString.call d )
    when '[object Array]'
      k = d.length
      while ( k-- )
        if ( v = d[ k ] )? and ( ( typeof v ) is 'object' ) and ( not frozen v )
          if is_first and ( frozen d )
            is_first  = false
            d         = deep_copy d
          d[ k ] = deep_freeze v
      return shallow_freeze d
    when '[object Object]'
      for k, v of d
        if v? and ( ( typeof v ) is 'object' ) and ( not frozen v )
          if is_first and ( frozen d )
            is_first  = false
            d         = deep_copy d
          d[ k ] = deep_freeze v
      return shallow_freeze d
  return d

#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
freeze_lets = lets = ( original, modifier = null ) ->
  draft = freeze_lets.thaw original
  modifier draft if modifier?
  return deep_freeze draft

#-----------------------------------------------------------------------------------------------------------
freeze_lets.lets      = freeze_lets
freeze_lets.assign    = ( me, P...  ) -> deep_freeze  deep_copy shallow_copy  me, P...
freeze_lets.freeze    = ( me        ) -> deep_freeze                          me
freeze_lets.thaw      = ( me        ) ->              deep_copy               me
freeze_lets.get       = ( me, k     ) -> me[ k ]
freeze_lets.set       = ( me, k, v  ) ->
  R       = shallow_copy me
  R[ k ]  = v
  return shallow_freeze R
freeze_lets._deep_copy    = deep_copy
freeze_lets._deep_freeze  = deep_freeze


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
lets.nofreeze = nofreeze_lets = ( original, modifier = null ) ->
  draft = nofreeze_lets.thaw original
  modifier draft if modifier?
  ### TAINT do not copy ###
  return deep_copy draft

#-----------------------------------------------------------------------------------------------------------
nofreeze_lets.lets    = nofreeze_lets
nofreeze_lets.assign  = ( me, P...  ) -> deep_copy shallow_copy me, P...
nofreeze_lets.freeze  = ( me        ) ->                        me
nofreeze_lets.thaw    = ( me        ) -> deep_copy              me
nofreeze_lets.get     = freeze_lets.get
nofreeze_lets.set     = ( me, k, v  ) ->
  R       = shallow_copy me
  R[ k ]  = v
  return R
nofreeze_lets._deep_copy    = deep_copy
nofreeze_lets._deep_freeze  = deep_freeze

#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
module.exports = { freeze_lets, nofreeze_lets, }



