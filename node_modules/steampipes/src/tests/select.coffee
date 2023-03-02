
'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'STEAMPIPES/TESTS/MODIFIERS'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND
#...........................................................................................................
PATH                      = require 'path'
FS                        = require 'fs'
OS                        = require 'os'
test                      = require 'guy-test'
#...........................................................................................................
# SP                        = require '../..'
# { $
#   $async
#   $watch
#   $show  }                = SP.export()
#...........................................................................................................
types                     = require '../types'
{ isa
  validate
  type_of }               = types
#...........................................................................................................
read                      = ( path ) -> FS.readFileSync path, { encoding: 'utf-8', }
defer                     = setImmediate
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }
jr                        = JSON.stringify


#-----------------------------------------------------------------------------------------------------------
@[ "$select with no argument" ] = ( T, done ) ->
  DATOM         = require 'datom'
  { new_datom
    select    } = DATOM.export()
  #.........................................................................................................
  SP            = require '../..'
  { $
    $async
    $select
    $drain
    $show     } = SP.export()
  #.........................................................................................................
  call_count  = 0
  callback    = => info 'callback'; call_count++
  #.........................................................................................................
  do =>
    source    = [
      new_datom '^foo'
      new_datom '^bar'
      new_datom '^baz'
      new_datom '^bar' ]
    matcher   = [{"$key":"^foo"},{"$key":"^bar"},{"$key":"^baz"},{"$key":"^bar"}]
    pipeline  = []
    pipeline.push source
    pipeline.push $select '^bar', callback
    pipeline.push $show()
    pipeline.push $drain ( result ) =>
      help jr result
      T.eq call_count, 2
      T.eq result, matcher
      done()
    SP.pull pipeline...
    return null
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "$select with one argument" ] = ( T, done ) ->
  DATOM         = require 'datom'
  { new_datom
    select    } = DATOM.export()
  #.........................................................................................................
  SP            = require '../..'
  { $
    $async
    $select
    $drain
    $show     } = SP.export()
  #.........................................................................................................
  call_count  = 0
  callback    = ( d ) =>
    info 'callback', d
    call_count++
    T.eq d, { $key: '^bar', }
  #.........................................................................................................
  do =>
    source    = [
      new_datom '^foo'
      new_datom '^bar'
      new_datom '^baz'
      new_datom '^bar' ]
    matcher   = [{"$key":"^foo"},{"$key":"^bar"},{"$key":"^baz"},{"$key":"^bar"}]
    pipeline  = []
    pipeline.push source
    pipeline.push $select '^bar', callback
    pipeline.push $show()
    pipeline.push $drain ( result ) =>
      help jr result
      T.eq call_count, 2
      T.eq result, matcher
      done()
    SP.pull pipeline...
    return null
  #.........................................................................................................
  return null

# #-----------------------------------------------------------------------------------------------------------
# @[ "$select with function as selector" ] = ( T, done ) ->
#   DATOM         = require 'datom'
#   { new_datom
#     select    } = DATOM.export()
#   #.........................................................................................................
#   SP            = require '../..'
#   { $
#     $async
#     $select
#     $drain
#     $show     } = SP.export()
#   #.........................................................................................................
#   call_count  = 0
#   selector    = ( d ) => whisper '^3322^', d; return d %% 3 is 0
#   callback    = ( d ) =>
#     info 'callback', d
#     call_count++
#   #.........................................................................................................
#   do =>
#     source    = [ 1 .. 20 ]
#     matcher   = ( n for n in [ 1 .. 20 ] when n %% 3 is 0 )
#     pipeline  = []
#     pipeline.push source
#     pipeline.push $select selector, callback
#     pipeline.push $show()
#     pipeline.push $drain ( result ) =>
#       help jr result
#       T.eq call_count, 2
#       T.eq result, matcher
#       done()
#     SP.pull pipeline...
#     return null
#   #.........................................................................................................
#   return null

#-----------------------------------------------------------------------------------------------------------
@[ "$select with two arguments" ] = ( T, done ) ->
  DATOM         = require 'datom'
  { new_datom
    select    } = DATOM.export()
  #.........................................................................................................
  SP            = require '../..'
  { $
    $async
    $select
    $drain
    $show     } = SP.export()
  #.........................................................................................................
  call_count  = 0
  callback    = ( d, send ) =>
    info 'callback', d, send
    call_count++
    T.eq d, { $key: '^bar', }
    send d
  #.........................................................................................................
  do =>
    source    = [
      new_datom '^foo'
      new_datom '^bar'
      new_datom '^baz'
      new_datom '^bar' ]
    matcher   = [{"$key":"^foo"},{"$key":"^bar"},{"$key":"^baz"},{"$key":"^bar"}]
    pipeline  = []
    pipeline.push source
    pipeline.push $select '^bar', callback
    pipeline.push $show()
    pipeline.push $drain ( result ) =>
      help jr result
      T.eq call_count, 2
      T.eq result, matcher
      done()
    SP.pull pipeline...
    return null
  #.........................................................................................................
  return null



############################################################################################################
unless module.parent?
  test @
