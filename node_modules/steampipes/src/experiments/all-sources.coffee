

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'STEAMPIPES/TESTS/ALL-SOURCES'
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
{ jr, }                   = CND
#...........................................................................................................
{ isa
  validate
  defaults
  types_of
  type_of }               = require '../types'
#...........................................................................................................
SP                        = require '../..'
{ $
  $async
  $drain
  $watch
  $show  }                = SP.export()
#...........................................................................................................
rpad                      = ( x, P... ) -> x.padEnd   P...
lpad                      = ( x, P... ) -> x.padStart P...
sleep                     = ( dts ) -> new Promise ( done ) => setTimeout done, dts * 1000



#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@_get_custom_iterable_1 = ->
  ### ths to https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Iteration_protocols ###
  myIterable =
    [Symbol.iterator]: ->
        yield "𫠠"
        yield "𫠡"
        yield "𫠢"
  return [ 'mdn_custom_iterable', myIterable, ["𫠠","𫠡","𫠢",], null, ]

#-----------------------------------------------------------------------------------------------------------
@_get_custom_iterable_2 = ->
  myIterable_2 =
    [Symbol.iterator]: -> yield from ["𫠠","𫠡","𫠢",]
  return [ 'object_with_list_as_iterator', myIterable_2, ["𫠠","𫠡","𫠢",], null, ]

#-----------------------------------------------------------------------------------------------------------
@_get_standard_iterables = ->
  return [
    [ 'text',       "𫠠𫠡𫠢",["𫠠","𫠡","𫠢",],null]
    [ 'list',       ["𫠠","𫠡","𫠢",],["𫠠","𫠡","𫠢",],null]
    [ 'set',        ( new Set "𫠠𫠡𫠢" ),["𫠠","𫠡","𫠢",],null]
    [ 'map',        ( new Map [[ "𫠠", "𫠡𫠢" ]] ),[[ "𫠠", "𫠡𫠢" ]],null]
    [ 'generator',  ( -> yield '𫠠'; yield '𫠡'; yield '𫠢')(), ["𫠠","𫠡","𫠢",],null]
    ]

#-----------------------------------------------------------------------------------------------------------
@_get_generatorfunction = ->
  return [ 'generatorfunction', ( -> yield '𫠠'; yield '𫠡'; yield '𫠢' ), ["𫠠","𫠡","𫠢",],null]

#-----------------------------------------------------------------------------------------------------------
@_get_asyncgenerator = ->
  return [ 'asyncgenerator', ( -> await 42; yield '𫠠'; yield '𫠡'; yield '𫠢' )(), ["𫠠","𫠡","𫠢",],null]

#-----------------------------------------------------------------------------------------------------------
@_get_asyncgeneratorfunction = ->
  return [ 'asyncgeneratorfunction', ( -> await 42; yield '𫠠'; yield '𫠡'; yield '𫠢' ), ["𫠠","𫠡","𫠢",],null]

#-----------------------------------------------------------------------------------------------------------
@_get_function_1      = -> [ 'function_1',      ( ->           ["𫠠","𫠡","𫠢",] ),                                   ["𫠠","𫠡","𫠢",], null, ]
@_get_asyncfunction_1 = -> [ 'asyncfunction_1', ( -> await 42; ["𫠠","𫠡","𫠢",] ),                                   ["𫠠","𫠡","𫠢",], null, ]
@_get_function_2      = -> [ 'function_2',      ( ->           ( ->           yield '𫠠'; yield '𫠡'; yield '𫠢' ) ), ["𫠠","𫠡","𫠢",], null, ]
@_get_asyncfunction_2 = -> [ 'asyncfunction_2', ( -> await 42; ( ->           yield '𫠠'; yield '𫠡'; yield '𫠢' ) ), ["𫠠","𫠡","𫠢",], null, ]
@_get_function_3      = -> [ 'function_3',      ( ->           ( -> await 42; yield '𫠠'; yield '𫠡'; yield '𫠢' ) ), ["𫠠","𫠡","𫠢",], null, ]
@_get_asyncfunction_3 = -> [ 'asyncfunction_3', ( -> await 42; ( -> await 42; yield '𫠠'; yield '𫠡'; yield '𫠢' ) ), ["𫠠","𫠡","𫠢",], null, ]

#-----------------------------------------------------------------------------------------------------------
@_get_all_probes_and_matchers = ->
  return [
    @_get_standard_iterables()...
    @_get_custom_iterable_2()
    @_get_generatorfunction()
    @_get_asyncgenerator()
    @_get_asyncgeneratorfunction()
    @_get_custom_iterable_1()
    @_get_function_1()
    @_get_asyncfunction_1()
    @_get_function_2()
    @_get_asyncfunction_2()
    @_get_function_3()
    @_get_asyncfunction_3()
    ]

#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@[ "tabulate distinctive features" ] = ( T, done ) ->
  await do =>
    probes_and_matchers = @_get_all_probes_and_matchers()
    for [ name, probe, ] in probes_and_matchers
      #.....................................................................................................
      ### STEP 1 ###
      mode                  = 'sync'
      probe_type            = type_of probe
      #.....................................................................................................
      if probe_type in [ 'generatorfunction', 'asyncgeneratorfunction', ]
        probe                 = probe()
        probe_type            = type_of probe
      #.....................................................................................................
      ### STEP 2 ###
      iterator              = probe[ Symbol.iterator ]
      iterator_type         = type_of iterator
      iterator_return_type  = './.'
      #.....................................................................................................
      if iterator_type is 'function'
        ### TAINT should not call iterator before ready; here done for illustration ###
        iterator_return_type = type_of iterator.apply probe
      #.....................................................................................................
      ### STEP 3 ###
      async_iterator        = undefined
      async_iterator_type   = 'undefined'
      unless iterator?
        async_iterator            = probe[ Symbol.asyncIterator ]
        async_iterator_type       = type_of async_iterator
        mode                      = 'async'
      #.....................................................................................................
      iterator_type             = './.' if iterator_type is 'undefined'
      async_iterator_type       = './.' if async_iterator_type is 'undefined'
      #.....................................................................................................
      ### STEP 4 ###
      switch mode
        when 'sync'   then  result = ( d for        d from       iterator.apply probe )
        when 'async'  then  result = ( d for await  d from async_iterator.apply probe )
      #.....................................................................................................
      name_txt                  = CND.blue  rpad  name,                   30
      probe_type_txt            = CND.gold  rpad  probe_type,             23
      mode_txt                  = CND.steel lpad  mode,                    5
      iterator_type_txt         = CND.gold  rpad  iterator_type,          20
      iterator_return_type_txt  = CND.lime  rpad  iterator_return_type,   20
      async_iterator_type_txt   = CND.gold  rpad  async_iterator_type,    20
      result_txt                = CND.green rpad  ( jr result )[ .. 15 ], 15
      probe_txt                 = CND.grey  ( ( rpr probe ).replace /\s+/g, ' ' )[ .. 40 ]
      #.....................................................................................................
      echo \
        name_txt,
        probe_type_txt,
        mode_txt,
        iterator_type_txt,
        ( CND.white '->' ),
        iterator_return_type_txt,
        async_iterator_type_txt,
        result_txt
        # probe_txt
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "iterate" ] = ( T, done ) ->
  probes_and_matchers = @_get_all_probes_and_matchers()
  check_count         = 0
  hit_count           = 0
  #.........................................................................................................
  for [ name, source, matcher, error, ] in probes_and_matchers
    check_count++
    types     = []
    mode      = 'sync'
    types.push type_of source
    #.......................................................................................................
    if ( type = type_of source ) is 'function'
      source = source()
      types.push type_of source
    #.......................................................................................................
    else if type is 'asyncfunction'
      mode    = 'async'
      source  = await source()
      types.push type_of source
    #.......................................................................................................
    if ( type_of source ) in [ 'generatorfunction', 'asyncgeneratorfunction', ]
      source = source()
      types.push type_of source
    #.......................................................................................................
    error     = null
    type      = type_of source
    name_txt  = CND.blue rpad name, 30
    types_txt = CND.grey rpad ( types.join ' -> ' ), 60
    ### NOTE mode is 'async' if procuring generator or iteration is async ###
    mode      = 'async' if type is 'asyncgenerator'
    mode_txt  = if mode is 'sync' then ( CND.green 'sync ' ) else ( CND.red 'async' )
    try
      if type is 'asyncgenerator' then  result = ( d for await d from source )
      else                              result = ( d for       d from source )
    catch error
      warn name_txt, ( CND.grey type ), ( CND.red error.message )
    result_txt  = jr result
    unless error?
      if CND.equals result, matcher
        hit_count++
        result_txt = CND.green result_txt
      else
        result_txt = CND.red   result_txt, '≠', ( jr matcher )
      info name_txt, mode_txt, types_txt, result_txt
  #.........................................................................................................
  urge "#{hit_count} / #{check_count}"
  T.eq hit_count, check_count
  #.........................................................................................................
  done()

############################################################################################################
if module is require.main then do =>
  # test @, { timeout: 5000, }
  test @[ "iterate" ].bind @
  # test @[ "tabulate distinctive features" ].bind @
  # test @[ "wye construction (async)" ]
  # test @[ "wye construction (method)" ]
  # test @[ "generatorfunction" ]
  # test @[ "asyncgeneratorfunction" ]

