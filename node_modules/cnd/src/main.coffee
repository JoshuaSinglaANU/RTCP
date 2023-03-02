
'use strict'

############################################################################################################
njs_util                  = require 'util'
rpr                       = njs_util.inspect
#...........................................................................................................
σ_cnd                     = Symbol.for 'cnd'
global[ σ_cnd ]          ?= {}
global[ σ_cnd ].t0       ?= Date.now()


#===========================================================================================================
# ACQUISITION
#-----------------------------------------------------------------------------------------------------------
method_count  = 0
routes        = [ './TRM', './BITSNPIECES', './TYPES', ]
L             = @
#...........................................................................................................
for route in routes
  for name, value of module = require route
    throw new Error "duplicate name #{rpr name}" if @[ name ]?
    method_count += +1
    # value         = value.bind module if ( Object::toString.call value ) is '[object Function]'
    value         = value.bind L if ( Object::toString.call value ) is '[object Function]'
    @[ name ]     = value
#...........................................................................................................
@XJSON    = require './XJSON'
@suspend  = require './suspend'

# ############################################################################################################
# unless module.parent?
#   console.log "acquired #{method_count} names from #{routes.length} sub-modules"
#   @dir @



