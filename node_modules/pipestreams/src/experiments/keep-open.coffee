

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/EXPERIMENTS/VARIOUS-PULL-STREAMS'
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
PS                        = require '../..'
{ $, $async, }            = PS.export()
#...........................................................................................................
after                     = ( dts, f ) -> setTimeout  f, dts * 1000
every                     = ( dts, f ) -> setInterval f, dts * 1000
defer                     = setImmediate
{ jr
  is_empty }              = CND


#-----------------------------------------------------------------------------------------------------------
test_continuity_1 = ->
  P               = require 'pull-stream'
  pull_through    = require 'pull-through'
  new_pushable    = require 'pull-pushable'
  map             = require '../_map_errors'
  #.........................................................................................................
  $keep_open_with_timer = ->
    timer = every 1, -> process.stdout.write '*'
    process.on 'unhandledRejection',  ( reason, promise ) ->
      clearInterval timer
      throw reason
    return map ( d ) ->
      debug '20922', d
      # debug '20922', send
      if d is PS.symbols.end
        clearInterval timer
      return d
  #.........................................................................................................
  $terminate_on_end_symbol = ->
    return P.asyncMap ( d, handler ) -> if d is PS.symbols.end then handler true else handler null, d
  #.........................................................................................................
  $end_as_symbol = ->
    count = 0
    on_data = ( d ) -> @queue d
    on_end = ->
      count += +1
      throw new Error "µ30903 on_end called more than once" if count > 1
      help 'on_end'
      @queue 'yo'
      @queue PS.symbols.end
    return pull_through on_data, on_end
  #.........................................................................................................
  demo = -> new Promise ( resolve ) ->
    new_PS_pushable = PS.new_push_source
    source          = new_PS_pushable()
    pipeline      = []
    pipeline.push source
    pipeline.push $end_as_symbol()
    pipeline.push $keep_open_with_timer()
    pipeline.push map ( d ) -> whisper d; return d
    pipeline.push P.asyncMap ( d, handler ) ->
      after 0.1, -> handler null, d
    ### Convert end symbol to actual end action ###
    pipeline.push $terminate_on_end_symbol()
    pipeline.push P.onEnd -> help 'ok'; resolve()
    #.......................................................................................................
    P.pull pipeline...
    source.send 42
    after 0.5, -> source.send null
    return null
  await demo()
  return null



#-----------------------------------------------------------------------------------------------------------
demo_x = ->
  #.........................................................................................................
  demo = -> new Promise ( resolve ) ->
    P               = require 'pull-stream'
    pull_through    = require 'pull-through'
    new_pushable    = require 'pull-pushable'
    merge           = require 'pull-merge'
    source          = PS.new_push_source()
    bysource        = PS.new_push_source()
    pipeline        = []
    # pipeline.push P.values [ 1 .. 3 ]
    bysource.send n for n in [ 1 .. 5 ]
    pipeline.push source
    pipeline.push do ->
      othersource = PS.new_push_source()
      subline = []
      # subline.push merge bysource, othersource, ( -> -1 )
      next_value = null

      x = +1
      subline.push merge bysource, othersource, ( a, b ) -> x = -x
      subline.push PS.$show title: 'subline'
      subline.push PS.$drain -> "subline terminated"
      PS.pull subline...
      othersource.send 'a'
      othersource.send 'b'
      othersource.send 'c'
      after 5, ->
      # othersource.end()
      return $ { last: null, }, ( d, send ) ->
        if d?
          send d
        else
          info 'ok'
    # pipeline.push P.asyncMap ( d, handler ) ->
    #   after 0.1, -> handler null, d
    # pipeline.push PS.$show title: '-->'
    # pipeline.push P.onEnd -> help 'ok'; resolve()
    # # pipeline.push P.drain -> help 'ok'; resolve()
    # P.pull pipeline...
    # source.send 108
    # # source.end()
    # after 0.5, -> source.send null
    #.......................................................................................................
    return null
  await demo()
  return null



############################################################################################################
unless module.parent?
  do ->
    # await test_continuity_1()
    await demo_x()





