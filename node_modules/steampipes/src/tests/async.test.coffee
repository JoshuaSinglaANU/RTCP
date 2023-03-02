
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'STEAMPIPES/TESTS/ASYNC'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
test                      = require 'guy-test'
jr                        = JSON.stringify
#...........................................................................................................
SP                        = require '../..'
{ $
  $async
  $watch
  $drain
  $show }                 = SP.export()
defer                     = setImmediate
sleep                     = ( dts ) -> new Promise ( done ) -> setTimeout done, dts * 1000


#-----------------------------------------------------------------------------------------------------------
after = ( dts, f ) -> setTimeout f, dts * 1000

#-----------------------------------------------------------------------------------------------------------
@[ "async 0" ] = ( T, done ) ->
  ok                  = false
  [ probe, matcher, ] = ["abcdef","1a-2a-1b-2b-1c-2c-1d-2d-1e-2e-1f-2f"]
  for use_async in [ true, false, ]
    await do => new Promise ( resolve ) =>
      pipeline            = []
      pipeline.push probe
      # pipeline.push $watch ( d ) -> info 'µ1', jr d
      if use_async
        pipeline.push $async ( d, send, done ) ->
          defer -> send "1#{d}"
          after 0.1, -> send "2#{d}"; done()
      else
        pipeline.push $ ( d, send ) ->
          send "1#{d}"
          send "2#{d}"
      # pipeline.push $watch ( d ) -> urge 'µ2', jr d
      pipeline.push SP.$surround { between: '-', }
      pipeline.push SP.$join()
      #.........................................................................................................
      pipeline.push SP.$watch ( result ) ->
        echo CND.gold jr [ probe, result, ]
        T.eq result, matcher
        ok = true
      #.........................................................................................................
      pipeline.push SP.$drain ->
        T.fail "failed to pass test" unless ok
        resolve()
      #.........................................................................................................
      SP.pull pipeline...
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
$send_three = ->
  return $async ( d, send, done ) ->
    count = 0
    for nr in [ 1 .. 3 ]
      do ( d, nr ) ->
        dt = Math.random() / 10
        after dt, ->
          count += 1
          send "(#{d}:#{nr})"
          done() if count is 3
    return null

#-----------------------------------------------------------------------------------------------------------
@[ "async 2" ] = ( T, done ) ->
  ok        = false
  probe     = "fdcabe"
  matcher   = "(a:1)(a:2)(a:3)(b:1)(b:2)(b:3)(c:1)(c:2)(c:3)(d:1)(d:2)(d:3)(e:1)(e:2)(e:3)(f:1)(f:2)(f:3)"
  pipeline  = []
  pipeline.push Array.from probe
  pipeline.push $send_three()
  # pipeline.push $show { title: '2', }
  pipeline.push SP.$sort()
  pipeline.push SP.$join()
  #.........................................................................................................
  pipeline.push SP.$watch ( result ) ->
    T.eq result, matcher
    ok = true
  #.........................................................................................................
  pipeline.push SP.$watch ( d ) -> urge d
  pipeline.push SP.$drain ->
    T.fail "failed to pass test" unless ok
    done()
  #.........................................................................................................
  # T.throws /contains asynchronous transform/, -> SP.pull pipeline...
  SP.pull pipeline...
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "async 3" ] = ( T, done ) ->
  probe   = [ 2, 3, 5, 7, ]
  matcher = [ 2, 4, 4, 3, 6, 9, 5, 10, 25, 7, 14, 49, ]
  #.........................................................................................................
  $multiply = ->
    exec = ( require 'util' ).promisify ( require 'child_process' ).exec
    FSP = ( require 'fs' ).promises
    return $async ( d, send, done ) =>
      debug '^787^', d
      defer =>
        send d
        await sleep 0.1
        text = await FSP.readFile __filename, { encoding: 'utf-8', }
        debug '^030^', jr text[ 100 .. 200 ]
        send d * 2
        await sleep 0.1
        debug '^3344^', jr await exec 'ls'
        send d ** 2
        await sleep 0.1
        done()
  #.........................................................................................................
  do =>
    pipeline = []
    pipeline.push probe
    pipeline.push $watch ( d ) => help CND.grey   'before', jr d
    pipeline.push $multiply()
    pipeline.push $watch ( d ) => help CND.white  'after ', jr d
    pipeline.push $drain ( result ) ->
      debug jr result
      T.eq result, matcher
      done()
    SP.pull pipeline...
    return null

#-----------------------------------------------------------------------------------------------------------
@[ "async 4 w/ async source" ] = ( T, done ) ->
  #.........................................................................................................
  $frobulate = ->
    exec    = ( require 'util' ).promisify ( require 'child_process' ).exec
    FSP     = ( require 'fs' ).promises
    return $async ( d, send, done ) =>
      if d isnt '{'
        send d
        return done()
      send 'async started'
      info '^787^', d
      send d
      urge 'before'
      text = await FSP.readFile __filename, { encoding: 'utf-8', }
      urge 'after'
      # info '^030^', jr text[ 100 .. 200 ]
      send 'async complete'
      return done()
  #.........................................................................................................
  do =>
    PATH      = require 'path'
    path      = PATH.join __dirname, '../../package.json'
    sources   = [
      # ( await SP._KLUDGE_file_as_buffers path         )
      ( SP.read_from_file path                        )
      ( [ ( ( require 'fs' ).readFileSync path ), ]   )
      ]
    for source in sources
      await do ( source ) => new Promise ( resolve ) =>
        pipeline  = []
        pipeline.push source
        pipeline.push SP.$split()
        pipeline.push $frobulate()
        # pipeline.push $show()
        pipeline.push $drain ( result ) ->
          T.fail "did not receive 'async started'"  unless ( 'async started'  in result )
          T.fail "did not receive 'async complete'" unless ( 'async complete' in result )
          resolve()
        SP.pull pipeline...
    done()
    return null


############################################################################################################
unless module.parent?
  # test @, { timeout: 10000, }
  test @[ "async 4 w/ async source" ]
  # test @[ "async 2" ], { timeout: 10000, }



