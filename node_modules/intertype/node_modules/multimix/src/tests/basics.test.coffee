
'use strict'


############################################################################################################
# njs_util                  = require 'util'
njs_path                  = require 'path'
# njs_fs                    = require 'fs'
#...........................................................................................................
CND                       = require 'cnd'
rpr                       = CND.rpr.bind CND
badge                     = 'MULTIMIX/TESTS/BASICS'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
praise                    = CND.get_logger 'praise',    badge
echo                      = CND.echo.bind CND
#...........................................................................................................
test                      = require 'guy-test'


# #===========================================================================================================
# # OBJECT PROPERTY CATALOGUING
# #-----------------------------------------------------------------------------------------------------------
# provide_cataloguing = ->
#   @keys_of              = ( P... ) -> @values_of @walk_keys_of      P...
#   @all_keys_of          = ( P... ) -> @values_of @walk_all_keys_of  P...
#   @all_own_keys_of      = ( x    ) -> if x? then Object.getOwnPropertyNames x else []
#   @walk_all_own_keys_of = ( x    ) -> yield k for k in @all_own_keys_of x

#   #-----------------------------------------------------------------------------------------------------------
#   @walk_keys_of = ( x, settings ) ->
#     defaults = { skip_undefined: true, }
#     settings = if settings? then ( assign {}, settings, defaults ) else defaults
#     for k of x
#       ### TAINT should use property descriptors to avoid possible side effects ###
#       continue if ( x[ k ] is undefined ) and settings.skip_undefined
#       yield k

#   #-----------------------------------------------------------------------------------------------------------
#   @walk_all_keys_of = ( x, settings ) ->
#     defaults = { skip_object: true, skip_undefined: true, }
#     settings = { defaults..., settings..., }
#     return @_walk_all_keys_of x, new Set(), settings

#   #-----------------------------------------------------------------------------------------------------------
#   @_walk_all_keys_of = ( x, seen, settings ) ->
#     if ( not settings.skip_object ) and x is Object::
#       yield return
#     #.........................................................................................................
#     for k from @walk_all_own_keys_of x
#       continue if seen.has k
#       seen.add k
#       ### TAINT should use property descriptors to avoid possible side effects ###
#       ### TAINT trying to access `arguments` causes error ###
#       try value = x[ k ] catch error then continue
#       continue if ( value is undefined ) and settings.skip_undefined
#       if settings.symbol?
#         continue unless value?
#         continue unless value[ settings.symbol ]
#       yield [ x, k, ]
#     #.........................................................................................................
#     if ( proto = Object.getPrototypeOf x )?
#       yield from @_walk_all_keys_of proto, seen, settings
# provide_cataloguing.apply C = {}

#-----------------------------------------------------------------------------------------------------------
@[ "classes with MultiMix" ] = ( T, done ) ->
  Multimix                  = require '../..'
  #.........................................................................................................
  class A
    method1: ( x ) -> x + 2
    method2: ( x ) -> ( @method1 x ) * 2
  a = new A()
  T.eq ( a.method1 100 ), 102
  T.eq ( a.method2 100 ), 204
  #.........................................................................................................
  class B extends Multimix
    method1: ( x ) -> x + 2
    method2: ( x ) -> ( @method1 x ) * 2
  b = new B()
  T.eq ( b.method1 100 ), 102
  T.eq ( b.method2 100 ), 204
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "multimix.export()" ] = ( T, done ) ->
  Multimix                  = require '../..'
  types                     = new ( require 'intertype' ).Intertype()
  #.........................................................................................................
  class A extends Multimix
    constructor: -> super(); @name = 'class A'
    identify_1: -> @name
  #.........................................................................................................
  class B extends A
    constructor: -> super(); @name = 'class B'
    identify_2: -> @name
  #.........................................................................................................
  a = new A()
  b = new B()
  #.........................................................................................................
  { identify_1
    identify_2 } = a.export()
  T.eq identify_1(), 'class A'
  T.eq identify_2,   undefined
  #.........................................................................................................
  { identify_1
    identify_2 } = b.export()
  T.eq identify_1(), 'class B'
  T.eq identify_2(), 'class B'
  #.........................................................................................................
  done()




