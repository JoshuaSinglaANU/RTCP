
'use strict'

############################################################################################################
njs_util                  = require 'util'
rpr                       = njs_util.inspect
#...........................................................................................................
σ_cnd                     = Symbol.for 'cnd'
global[ σ_cnd ]          ?= {}
global[ σ_cnd ].t0       ?= Date.now()
is_function								= ( x ) -> ( Object::toString.call x ) is '[object Function]'

#===========================================================================================================
# ACQUISITION
#-----------------------------------------------------------------------------------------------------------
( @[ k ] = if is_function v then v.bind @ else v ) for k, v of require './TRM'
( @[ k ] = if is_function v then v.bind @ else v ) for k, v of require './BITSNPIECES'
( @[ k ] = if is_function v then v.bind @ else v ) for k, v of require './TYPES'




