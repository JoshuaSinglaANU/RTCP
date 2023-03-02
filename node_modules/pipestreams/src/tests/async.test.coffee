
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/TESTS/ASYNC-MAP'
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
PS                        = require '../..'
{ $, $async, }            = PS.export()

#-----------------------------------------------------------------------------------------------------------
after = ( dts, f ) -> setTimeout f, dts * 1000



#-----------------------------------------------------------------------------------------------------------
@[ "async 1" ] = ( T, done ) ->
  ok                  = false
  [ probe, matcher, ] = ["abcdef","1a-2a-1b-2b-1c-2c-1d-2d-1e-2e-1f-2f"]
  pipeline            = []
  pipeline.push PS.new_value_source Array.from probe
  pipeline.push $async ( d, send, done ) ->
    send "1#{d}"
    send "2#{d}"
    done()
  pipeline.push PS.$surround { between: '-', }
  pipeline.push PS.$join()
  #.........................................................................................................
  pipeline.push PS.$watch ( result ) ->
    echo CND.gold jr [ probe, result, ]
    T.eq result, matcher
    ok = true
  #.........................................................................................................
  pipeline.push PS.$drain ->
    T.fail "failed to pass test" unless ok
    done()
  #.........................................................................................................
  PS.pull pipeline...
  return null

#-----------------------------------------------------------------------------------------------------------
$send_three = ->
  return PS.$async ( d, send, done ) ->
    count = 0
    for nr in [ 1 .. 3 ]
      do ( d, nr ) ->
        after ( Math.random() / 5 ), ->
          count += 1
          send "(#{d}:#{nr})"
          done() if count is 3
    return null

#-----------------------------------------------------------------------------------------------------------
@[ "async 2" ] = ( T, done ) ->
  ok        = false
  probe     = "abcdef"
  matcher   = "(a:1)(a:2)(a:3)(b:1)(b:2)(b:3)(c:1)(c:2)(c:3)(d:1)(d:2)(d:3)(e:1)(e:2)(e:3)(f:1)(f:2)(f:3)"
  pipeline  = []
  pipeline.push PS.new_value_source Array.from probe
  pipeline.push $send_three()
  pipeline.push PS.$sort()
  pipeline.push PS.$join()
  #.........................................................................................................
  pipeline.push PS.$watch ( result ) ->
    T.eq result, matcher
    ok = true
  #.........................................................................................................
  pipeline.push PS.$watch ( d ) -> urge d
  pipeline.push PS.$drain ->
    T.fail "failed to pass test" unless ok
    done()
  #.........................................................................................................
  PS.pull pipeline...
  return null


############################################################################################################
unless module.parent?
  test @
  # test @[ "async 1" ]
  # test @[ "async 2" ]



