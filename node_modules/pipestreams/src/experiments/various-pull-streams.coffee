

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

# https://pull-stream.github.io/#pull-through
# nope https://github.com/dominictarr/pull-flow (https://github.com/pull-stream/pull-stream/issues/4)

# https://github.com/pull-stream/pull-cont
# https://github.com/pull-stream/pull-defer
# https://github.com/scrapjs/pull-imux

#-----------------------------------------------------------------------------------------------------------
demo_merge_1 = ->
  ### https://github.com/pull-stream/pull-merge ###
  pull      = require 'pull-stream'
  merge     = require 'pull-merge'
  pipeline  = []
  # pipeline.push merge ( pull.values [ 1, 5, 6, ] ), ( pull.values [ 2, 4, 7, ] )
  # pipeline.push merge ( pull.values [ 1, 5, 6, ] ), ( pull.values [ 2, 4, 7, 10, 11, 12, ] )
  # pipeline.push merge ( pull.values [ 1, 5, 6, ] ), ( pull.values [] )
  # pipeline.push merge ( pull.values [ 1, 5, 6, ] ), ( pull.values [ 1, 5, 6, ] )
  # pipeline.push merge ( pull.values [ [1], [5], [6], ] ), ( pull.values [ [1], [5], [6], [7], ] )
  x = +1
  pipeline.push merge ( pull.values [ 1, 5, 6, ] ), ( pull.values [ 20, 19, 18, 17, ] ), ( a, b ) -> x = -x
  pipeline.push pull.collect ( error, collector ) ->
    throw error if error?
    help collector
  pull pipeline...
  return null

#-----------------------------------------------------------------------------------------------------------
new_async_source = ( name ) ->
    source    = PS.new_push_source()
    pipeline  = []
    pipeline.push source
    pipeline.push PS.$watch ( d ) -> urge name, jr d
    R         = PS.pull pipeline...
    R.push    = ( x ) -> source.push x
    R.end     = -> source.end()
    return R

#-----------------------------------------------------------------------------------------------------------
demo_merge_async_sources = ->
  ### won't take all inputs from both sources ###
  merge     = require 'pull-merge'
  source_1 = new_async_source 's1'
  source_2 = new_async_source 's2'
  return new Promise ( resolve ) ->
    pipeline  = []
    pipeline.push merge source_2, source_1, ( a, b ) -> -1
    pipeline.push PS.$watch ( d ) -> help '-->', jr d
    pipeline.push PS.$drain ->
      help 'ok'
      resolve null
    PS.pull pipeline...
    after 0.1, -> source_2.push 4
    after 0.2, -> source_2.push 5
    after 0.3, -> source_2.push 6
    after 0.4, -> source_1.push 1
    after 0.5, -> source_1.push 2
    after 0.6, -> source_1.push 3
    # after 1.0, -> source_1.push null
    # after 1.0, -> source_2.push null
    return null

#-----------------------------------------------------------------------------------------------------------
demo_mux_async_sources_1 = ->
  mux = require 'pull-mux' ### https://github.com/nichoth/pull-mux ###
  #.........................................................................................................
  $_mux = ( sources... ) ->
    R = {}
    for source, idx in sources
      R[ idx ] = source
    return mux R
  #.........................................................................................................
  $_demux = ->
    return PS.$map ( [ k, v, ] ) -> v
  #.........................................................................................................
  return new Promise ( resolve ) ->
    pipeline  = []
    source_1  = new_async_source 's1'
    source_2  = new_async_source 's2'
    pipeline.push $_mux source_1, source_2
    pipeline.push $_demux()
    pipeline.push PS.$collect()
    pipeline.push PS.$watch ( d ) -> help '-->', jr d
    pipeline.push PS.$drain ->
      help 'ok'
      resolve null
    PS.pull pipeline...
    after 0.1, -> source_2.push 4
    after 0.5, -> source_1.push 2
    after 0.6, -> source_1.push 3
    after 0.2, -> source_2.push 5
    after 0.3, -> source_2.push 6
    after 0.4, -> source_1.push 1
    after 0.4, -> source_1.push 1
    after 0.4, -> source_1.push 1
    after 0.4, -> source_1.push 1
    after 0.05, -> source_2.push 42
    after 1.0, -> source_1.end()
    after 1.0, -> source_2.end()
    return null

#-----------------------------------------------------------------------------------------------------------
demo_mux_async_sources_2 = ->
  mux = require 'pull-mux' ### https://github.com/nichoth/pull-mux ###
  #-----------------------------------------------------------------------------------------------------------
  PS.$wye = ( sources... ) ->
    #.........................................................................................................
    $_mux = ( sources... ) ->
      R = {}
      R[ idx ] = source for source, idx in sources
      return mux R
    #.........................................................................................................
    $_demux = -> PS.$map ( [ k, v, ] ) -> v
    #.........................................................................................................
    pipeline  = []
    pipeline.push $_mux sources...
    pipeline.push $_demux()
    return PS.pull pipeline...
  #.........................................................................................................
  return new Promise ( resolve ) ->
    pipeline  = []
    source_1  = new_async_source 's1'
    source_2  = new_async_source 's2'
    pipeline.push PS.$wye source_1, source_2
    pipeline.push PS.$collect()
    pipeline.push PS.$watch ( d ) -> help '-->', jr d
    pipeline.push PS.$drain ->
      help 'ok'
      resolve null
    PS.pull pipeline...
    after 0.1, -> source_2.push 4
    after 0.5, -> source_1.push 2
    after 0.6, -> source_1.push 3
    after 0.2, -> source_2.push 5
    after 0.3, -> source_2.push 6
    after 0.4, -> source_1.push 1
    after 0.4, -> source_1.push 1
    after 0.4, -> source_1.push 1
    after 0.4, -> source_1.push 1
    after 0.05, -> source_2.push 42
    after 1.0, -> source_1.end()
    after 1.0, -> source_2.end()
    return null

#-----------------------------------------------------------------------------------------------------------
demo_through = ->
  through = require 'pull-through' ### https://github.com/pull-stream/pull-through ###

#-----------------------------------------------------------------------------------------------------------
async_with_end_detection = ->
  buffer    = [ 11 .. 15 ]
  pipeline  = []
  send      = null
  flush     = => send buffer.pop() while not is_empty buffer
  pipeline.push PS.new_value_source [ 1 .. 5 ]
  pipeline.push PS.$defer()
  #.........................................................................................................
  pipeline.push do =>
    is_first = true
    return $ { last: PS.symbols.last, }, ( d, send ) =>
      if is_first
        is_first = false
        send PS.symbols.first
      send d
  #.........................................................................................................
  pipeline.push PS.$async ( d, _send, done ) =>
    send = _send
    switch d
      when PS.symbols.first
        debug 'start'
        send buffer.pop()
        done()
      when PS.symbols.last
        flush()
        debug 'end'
        # done()
        after 2, done
      else
        send d
        done()
    return null
  #.........................................................................................................
  pipeline.push PS.$show()
  pipeline.push PS.$drain()
  PS.pull pipeline...
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
async_with_end_detection_2 = ->
  buffer    = [ 11 .. 15 ]
  pipeline  = []
  send      = null
  flush     = => send buffer.pop() while not is_empty buffer
  #.........................................................................................................
  pipeline.push PS.new_value_source [ 1 .. 5 ]
  pipeline.push PS.$defer()
  #.........................................................................................................
  pipeline.push PS.$async 'null', ( d, _send, done ) =>
    send = _send
    if d?
      send d
      done()
    else
      flush()
      debug 'end'
      # done()
      after 2, done
    return null
  #.........................................................................................................
  pipeline.push PS.$show()
  pipeline.push PS.$drain()
  PS.pull pipeline...
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
sync_with_first_and_last = ->
  drainer   = -> help 'ok'
  pipeline  = []
  pipeline.push PS.new_value_source [ 1 .. 5 ]
  #.........................................................................................................
  pipeline.push PS.$surround { first: '[', last: ']', before: '(', between: ',', after: ')' }
  pipeline.push PS.$surround { first: 'first', last: 'last', }
  # pipeline.push PS.$surround { first: 'first', last: 'last', before: 'before', between: 'between', after: 'after' }
  # pipeline.push PS.$surround { first: '[', last: ']', }
  #.........................................................................................................
  pipeline.push PS.$collect()
  pipeline.push $ ( d, send ) -> send ( x.toString() for x in d ).join ''
  pipeline.push PS.$show()
  pipeline.push PS.$drain drainer
  PS.pull pipeline...
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
async_with_first_and_last = ->
  drainer   = -> help 'ok'
  pipeline  = []
  pipeline.push PS.new_value_source [ 1 .. 3 ]
  #.........................................................................................................
  pipeline.push PS.$surround { first: 'first', last: 'last', }
  pipeline.push $async { first: '[', last: ']', between: '|', }, ( d, send, done ) =>
    defer ->
      # debug '22922', jr d
      send d
      done()
  #.........................................................................................................
  # pipeline.push PS.$watch ( d ) -> urge '20292', d
  pipeline.push PS.$collect()
  pipeline.push $ ( d, send ) -> send ( x.toString() for x in d ).join ''
  pipeline.push PS.$show()
  pipeline.push PS.$drain drainer
  PS.pull pipeline...
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
wye_3b = ->
  #.........................................................................................................
  demo = -> new Promise ( resolve ) ->
    bysource  = PS.new_push_source()
    byline    = []
    byline.push bysource
    byline.push $ ( d, send ) ->
      if CND.isa_text d
        send d.length
      else
        send d
      return null
    byline.push PS.$watch ( d ) -> whisper 'bystream', jr d
    #.......................................................................................................
    mainline = []
    mainline.push PS.new_random_async_value_source "just a few words".split /\s/
    mainline.push PS.$watch ( d ) -> whisper 'mainstream', jr d
    mainline.push PS.$wye PS.pull byline...
    mainline.push $ ( d, send ) ->
      if CND.isa_text d
        bysource.send d
        send d
      else
        send d
      return null
    mainline.push PS.$show title: 'confluence'
    mainline.push PS.$collect()
    mainline.push PS.$show title: 'mainstream'
    mainline.push PS.$drain -> help 'ok'; resolve()
    PS.pull mainline...
    #.......................................................................................................
    return null
  await demo()
  return null

#-----------------------------------------------------------------------------------------------------------
wye_4 = ->
  #.........................................................................................................
  demo = -> new Promise ( resolve ) ->
    bysource  = PS.new_push_source()
    byline    = []
    byline.push bysource
    byline.push PS.$watch ( d ) -> whisper 'bystream', jr d
    bystream = PS.pull byline...
    #.......................................................................................................
    mainline = []
    mainline.push PS.new_value_source [ 5, 7, ]
    mainline.push PS.$watch ( d ) -> whisper 'mainstream', jr d
    mainline.push PS.$wye bystream
    mainline.push PS.$show title: 'confluence'
    mainline.push $ ( d, send ) ->
      if d < 1.001
        send null
      else
        send d
        bysource.send Math.sqrt d
    mainline.push PS.$map ( d ) -> d.toFixed 3
    mainline.push PS.$collect()
    mainline.push PS.$show title: 'mainstream'
    mainline.push PS.$drain -> help 'ok'; resolve()
    PS.pull mainline...
    #.......................................................................................................
    return null
  await demo()
  return null

#-----------------------------------------------------------------------------------------------------------
wye_with_random_value_source = ->
  #.........................................................................................................
  demo = -> new Promise ( resolve ) ->
    byline    = []
    byline.push PS.new_random_async_value_source 0.1, [ 3 .. 8 ]
    byline.push PS.$watch ( d ) -> whisper 'bystream', jr d
    #.......................................................................................................
    mainline = []
    mainline.push PS.new_random_async_value_source "just a few words".split /\s/
    mainline.push PS.$watch ( d ) -> whisper 'mainstream', jr d
    mainline.push PS.$wye PS.pull byline...
    mainline.push PS.$show title: 'confluence'
    mainline.push PS.$collect()
    mainline.push PS.$show title: 'mainstream'
    mainline.push PS.$drain -> help 'ok'; resolve()
    PS.pull mainline...
    #.......................................................................................................
    return null
  await demo()
  return null

#-----------------------------------------------------------------------------------------------------------
wye_with_value_source = ->
  #.........................................................................................................
  demo = -> new Promise ( resolve ) ->
    byline    = []
    byline.push PS.new_value_source [ 3 .. 8 ]
    byline.push PS.$watch ( d ) -> whisper 'bystream', jr d
    #.......................................................................................................
    mainline = []
    mainline.push PS.new_random_async_value_source "just a few words".split /\s/
    mainline.push PS.$watch ( d ) -> whisper 'mainstream', jr d
    mainline.push PS.$wye PS.pull byline...
    mainline.push PS.$show title: 'confluence'
    mainline.push PS.$collect()
    mainline.push PS.$show title: 'mainstream'
    mainline.push PS.$drain -> help 'ok'; resolve()
    PS.pull mainline...
    #.......................................................................................................
    return null
  await demo()
  return null

#-----------------------------------------------------------------------------------------------------------
wye_with_external_push_source = ->
  #.........................................................................................................
  demo = -> new Promise ( resolve ) ->
    bysource  = PS.new_push_source ( error ) -> debug '10203', "Bysource ended"
    byline    = []
    byline.push bysource
    byline.push PS.$watch ( d ) -> whisper 'bystream', jr d
    #.......................................................................................................
    mainline = []
    mainline.push PS.new_random_async_value_source "just a few words".split /\s/
    mainline.push PS.$watch ( d ) -> whisper 'mainstream', jr d
    mainline.push PS.$wye PS.pull byline...
    mainline.push PS.$show title: 'confluence'
    mainline.push PS.$collect()
    mainline.push PS.$show title: 'mainstream'
    mainline.push PS.$drain -> help 'ok'; resolve()
    PS.pull mainline...
    for x in [ 3 .. 8 ]
      bysource.send x
    bysource.send null
    #.......................................................................................................
    return null
  await demo()
  return null

#-----------------------------------------------------------------------------------------------------------
wye_with_internal_push_source = ->
  #.........................................................................................................
  demo = -> new Promise ( resolve ) ->
    tick = ->
      process.stdout.write '*'
      after 0.5, tick
      return null
    after 0.5, tick
    #.......................................................................................................
    bysource  = PS.new_push_source ( error ) -> debug '10203', "Bysource ended"
    # bysource  = PS.new_push_source()
    byline    = []
    byline.push bysource
    byline.push PS.$watch ( d ) -> whisper 'bystream', jr d
    #.......................................................................................................
    mainline = []
    mainline.push PS.new_random_async_value_source "just a few words".split /\s/
    mainline.push PS.$watch ( d ) -> whisper 'mainstream', jr d
    mainline.push PS.$wye PS.pull byline...
    mainline.push $async ( d, send, done ) ->
      debug '34844', d
      send d
      done() if d isnt 'few'
    mainline.push PS.$show title: 'confluence'
    mainline.push $ { last: null, }, ( d, send ) ->
      debug '10191', CND.green d
      if d?
        if CND.isa_text d
          bysource.send d.length
          send d
        else
          send d
      else
        bysource.send null
      return null
    mainline.push PS.$defer()
    mainline.push PS.$collect()
    mainline.push PS.$show title: 'mainstream'
    mainline.push PS.$drain -> help 'ok'; resolve()
    PS.pull mainline...
    #.......................................................................................................
    return null
  await demo()
  return null

#-----------------------------------------------------------------------------------------------------------
generator_source = ->
  #.........................................................................................................
  demo = -> new Promise ( resolve ) ->
    #.......................................................................................................
    g = ->
      for nr in [ 1 ... 10 ]
        x = yield nr
        debug '77873', x
      return null
    #.......................................................................................................
    iterator  = g()
    bysource  = PS.new_generator_source iterator
    byline    = []
    byline.push bysource
    byline.push PS.$watch ( d ) -> whisper 'bystream', jr d
    #.......................................................................................................
    mainline = []
    mainline.push PS.new_random_async_value_source "just a few words".split /\s/
    mainline.push PS.$watch ( d ) -> whisper 'mainstream', jr d
    mainline.push PS.$wye PS.pull byline...
    mainline.push PS.$show title: 'confluence'
    mainline.push PS.$collect()
    mainline.push PS.$show title: 'mainstream'
    # mainline.push PS.$drain -> help 'ok'; resolve()
    urge iterator.next()
    urge iterator.next 'foo'
    PS.pull mainline...
    # for x in [ 3 .. 8 ]
    #   bysource.send x
    # bysource.send null
    #.......................................................................................................
    return null
  await demo()
  return null

#-----------------------------------------------------------------------------------------------------------
demo_alternating_source = ->
  #.........................................................................................................
  demo = -> new Promise ( resolve ) ->
    source_1        = PS.new_push_source()
    source_2        = PS.new_push_source()
    pipeline        = []
    pipeline.push PS.new_alternating_source source_1, source_2
    pipeline.push PS.$show title: 'pipeline'
    pipeline.push PS.$drain -> "pipeline terminated"
    PS.pull pipeline...
    source_1.send 'a'
    source_1.send 'b'
    # source_1.send 'c'
    source_2.send n for n in [ 1 .. 5 ]
    info '----'
    after 1.0, -> whisper "source_1 ended"; source_1.end()
    after 1.5, -> whisper "source_2 ended"; source_2.end()
    #.......................................................................................................
    return null
  await demo()
  return null

#-----------------------------------------------------------------------------------------------------------
demo_on_demand_source = ->
  #.........................................................................................................
  demo = -> new Promise ( resolve ) ->
    # mainsource            = PS.new_push_source()
    mainsource            = PS.new_value_source [ 1 .. 5 ]
    pipeline              = []
    on_demand_source      = PS.new_on_demand_source mainsource
    pipeline.push on_demand_source
    pipeline.push PS.$watch ( d ) -> info ( if ( CND.type_of d ) is 'symbol' then CND.grey else CND.white ) d
    pipeline.push PS.$drain -> "pipeline terminated"
    PS.pull pipeline...
    # mainsource.send n for n in [ 1 .. 5 ]
    for nr in [ 1 .. 3 ]
      on_demand_source.next()
    # on_demand_source.next()
    # on_demand_source.next()
    info '----'
    # after 1.0, -> whisper "triggersource ended"; triggersource.end()
    # after 1.5, -> whisper "mainsource ended"; mainsource.end()
    #.......................................................................................................
    return null
  await demo()
  return null

#-----------------------------------------------------------------------------------------------------------
demo_on_demand_transform = ->
  $gate = ->
  #.........................................................................................................
  demo = -> new Promise ( resolve ) ->
    # mainsource            = PS.new_push_source()
    mainsource  = PS.new_value_source [ 1 .. 5 ]
    pipeline    = []
    gate        = $gate()
    pipeline.push mainsource
    pipeline.push gate
    pipeline.push PS.$drain -> "pipeline terminated"
    PS.pull pipeline...
    for nr in [ 1 .. 3 ]
      gate.next()
    # after 1.5, -> whisper "mainsource ended"; mainsource.end()
    #.......................................................................................................
    return null
  await demo()
  return null


############################################################################################################
unless module.parent?
  do ->
    # demo_merge_1()
    # demo_merge_async_sources()
    # demo_mux_async_sources_1()
    # demo_mux_async_sources_2()
    # demo_through()
    # async_with_end_detection()
    # async_with_end_detection_2()
    # sync_with_first_and_last()
    # async_with_first_and_last()
    # await wye_1()
    await wye_2()
    # await wye_with_random_value_source()
    # await wye_with_value_source()
    # await wye_with_external_push_source()
    # await wye_with_internal_push_source()
    # await generator_source()
    # await test_continuity()
    # wye_3b()
    # wye_4()
    # await demo_alternating_source()
    # await demo_on_demand_source()




