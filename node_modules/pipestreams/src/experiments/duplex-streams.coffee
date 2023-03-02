
'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/EXPERIMENTS/DUPLEX-STREAMS'
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
test                      = require 'guy-test'
assign                    = Object.assign
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }


###
Duplex streams are used to communicate with a remote service,
and they are a pair of source and sink streams `{source, sink}`

in node, you see duplex streams to connect replication or rpc protocols.
client.pipe(server).pipe(client)
or
server.pipe(client).pipe(server)
both do the same thing.

the pull function we wrote before doesn't detect this,
but if you use the pull-stream module it will.
Then we can pipe duplex pull-streams like this:

var pull = require('pull-stream')
pull(client, server, client)

Also, sometimes you'll need to interact with a regular node stream.
there are two modules for this.

stream-to-pull-stream
and
pull-stream-to-stream
###


#-----------------------------------------------------------------------------------------------------------
@wye_1 = ->
  new_pair    = require 'pull-pair'
  #.........................................................................................................
  $wye = ( bystream ) ->
    pair        = new_pair()
    pushable    = PS.new_push_source()
    pipeline_1  = []
    pipeline_2  = []
    #.......................................................................................................
    pipeline_1.push pair.source
    pipeline_1.push PS.$surround before: '(', after: ')', between: '-'
    # pipeline_1.push PS.$join()
    pipeline_1.push PS.$show title: 'substream'
    pipeline_1.push PS.$watch ( d ) -> pushable.send d
    pipeline_1.push PS.$drain -> urge "substream ended"
    #.......................................................................................................
    pipeline_2.push bystream
    pipeline_2.push $ { last: null, }, ( d, send ) -> urge "bystream ended" unless d?; send d
    pipeline_2.push PS.$show title: 'bystream'
    #.......................................................................................................
    PS.pull pipeline_1...
    confluence = PS.$merge pushable, PS.pull pipeline_2...
    return { sink: pair.sink, source: confluence, }
  #.........................................................................................................
  bysource = PS.new_value_source [ 3 .. 7 ]
  pipeline = []
  pipeline.push PS.new_value_source "just a few words".split /\s/
  # pipeline.push PS.$watch ( d ) -> whisper d
  pipeline.push $wye bysource
  pipeline.push PS.$collect()
  pipeline.push PS.$show title: 'mainstream'
  pipeline.push PS.$drain -> help 'ok'
  PS.pull pipeline...
  return null

#-----------------------------------------------------------------------------------------------------------
@wye_2 = ->
  new_pair    = require 'pull-pair'
  #.........................................................................................................
  $wye = ( bystream ) ->
    pair              = new_pair()
    pushable          = PS.new_push_source()
    subline           = []
    byline            = []
    end_sym           = Symbol 'end'
    bystream_ended    = false
    substream_ended   = false
    #.......................................................................................................
    subline.push pair.source
    subline.push $ { last: end_sym, }, ( d, send ) ->
      if d is end_sym
        substream_ended = true
        pushable.end() if bystream_ended
      else
        pushable.send d
    subline.push PS.$drain()
    #.......................................................................................................
    byline.push bystream
    byline.push $ { last: end_sym, }, ( d, send ) ->
      if d is end_sym
        bystream_ended = true
        pushable.end() if substream_ended
      else
        send d
    #.......................................................................................................
    PS.pull subline...
    confluence = PS.$merge pushable, PS.pull byline...
    return { sink: pair.sink, source: confluence, }
  #.........................................................................................................
  demo = ->
    return new Promise ( resolve ) ->
      byline = []
      byline.push PS.new_value_source [ 3 .. 7 ]
      byline.push PS.$watch ( d ) -> whisper 'bystream', jr d
      #.......................................................................................................
      mainline = []
      mainline.push PS.new_value_source "just a few words".split /\s/
      mainline.push PS.$watch ( d ) -> whisper 'mainstream', jr d
      mainline.push $wye PS.pull byline...
      mainline.push PS.$collect()
      mainline.push PS.$show title: 'mainstream'
      mainline.push PS.$drain -> help 'ok'; resolve()
      PS.pull mainline...
  await demo()
  return null


#-----------------------------------------------------------------------------------------------------------
@pull_pair_1 = ->
  new_pair    = require 'pull-pair'
  pair        = new_pair()
  pipeline_1  = []
  pipeline_2  = []
  #.........................................................................................................
  # read values into this sink...
  pipeline_1.push PS.new_value_source [ 1, 2, 3, ]
  pipeline_1.push PS.$watch ( d ) -> urge d
  pipeline_1.push pair.sink
  PS.pull pipeline_1...
  #.........................................................................................................
  # but that should become the source over here.
  pipeline_2.push pair.source
  pipeline_2.push PS.$collect()
  pipeline_2.push PS.$show()
  pipeline_2.push PS.$drain()
  #.........................................................................................................
  PS.pull pipeline_2...
  return null

#-----------------------------------------------------------------------------------------------------------
@pull_pair_2 = ->
  new_pair    = require 'pull-pair'
  #.........................................................................................................
  f = ->
    pair        = new_pair()
    pushable    = PS.new_push_source()
    pipeline_1  = []
    #.......................................................................................................
    pipeline_1.push pair.source
    pipeline_1.push PS.$surround before: '(', after: ')', between: '-'
    pipeline_1.push PS.$join()
    pipeline_1.push PS.$show title: 'substream'
    pipeline_1.push PS.$watch ( d ) -> pushable.send d
    pipeline_1.push PS.$drain()
    #.......................................................................................................
    PS.pull pipeline_1...
    return { sink: pair.sink, source: pushable, }
  #.........................................................................................................
  pipeline = []
  pipeline.push PS.new_value_source "just a few words".split /\s/
  pipeline.push PS.$watch ( d ) -> whisper d
  pipeline.push f()
  pipeline.push PS.$show title: 'mainstream'
  pipeline.push PS.$drain()
  PS.pull pipeline...
  return null



#-----------------------------------------------------------------------------------------------------------
@[ "_duplex 1" ] = ->
  NET           = require 'net'
  toPull        = require 'stream-to-pull-stream'
  pull          = require 'pull-stream'
  bylog         = PS.get_logger 'b', 'red'
  mainlog       = PS.get_logger 'm', 'gold'
  #.........................................................................................................
  server_as_duplex_stream = ( nodejs_stream ) ->
    ### convert into a duplex pull-stream ###
    server_stream = toPull.duplex nodejs_stream
    extra_stream  = PS.new_random_async_value_source "xxx here comes the sun".split /\s+/
    pipeline      = []
    # pipeline.push server_stream
    pipeline.push PS.new_merged_source server_stream, extra_stream
    pipeline.push bylog PS.$split()
    pipeline.push bylog pull.map ( x ) -> x.toString().toUpperCase() + '!!!'
    # pipeline.push server_stream
    pipeline.push bylog pull.map ( x ) -> "*#{x}*"
    pipeline.push bylog PS.$as_line()
    pipeline.push PS.$watch ( d ) -> debug '32387', xrpr d
    pipeline.push server_stream
    # pipeline.push PS.$watch ( d ) -> console.log d.toString()
    # pipeline.push bylog PS.$drain()
    PS.pull pipeline...
    return null
  #.........................................................................................................
  server = NET.createServer server_as_duplex_stream
  listener = ->
    client_stream = toPull.duplex NET.connect 9999
    pipeline      = []
    pipeline.push PS.new_random_async_value_source [ 'quiet stream\n', 'great thing\n', ]
    # pipeline.push PS.new_value_source [ 'quiet stream\n', 'great thing\n', ]
    pipeline.push client_stream
    pipeline.push mainlog PS.$split()
    pipeline.push PS.$watch ( d ) -> debug '32388', xrpr d
    pipeline.push mainlog PS.$drain ->
      help 'ok'
      server.close()
    PS.pull pipeline...
    return null
  #.........................................................................................................
  server.listen 9999, listener

#-----------------------------------------------------------------------------------------------------------
@[ "_duplex 2" ] = ->
  NET           = require 'net'
  toPull        = require 'stream-to-pull-stream'
  pull          = require 'pull-stream'
  bylog         = PS.get_logger 'b', 'red'
  mainlog       = PS.get_logger 'm', 'gold'
  #.........................................................................................................
  server_as_duplex_stream = ( nodejs_stream ) ->
    ### convert into a duplex pull-stream ###
    extra_stream  = PS.new_random_async_value_source "xxx here comes the sun".split /\s+/
    server_stream = toPull.duplex nodejs_stream
    pipeline      = []
    pipeline.push PS.new_merged_source server_stream, extra_stream
    pipeline.push bylog PS.$split()
    pipeline.push bylog pull.map ( x ) -> x.toString().toUpperCase() + '!!!'
    # pipeline.push server_stream
    pipeline.push bylog pull.map ( x ) -> "*#{x}*"
    pipeline.push bylog PS.$as_line()
    pipeline.push PS.$watch ( d ) -> debug '32387', xrpr d
    pipeline.push server_stream
    # pipeline.push PS.$watch ( d ) -> console.log d.toString()
    # pipeline.push bylog PS.$drain()
    PS.pull pipeline...
    return null
  #.........................................................................................................
  server = NET.createServer server_as_duplex_stream
  listener = ->
    client_stream = toPull.duplex NET.connect 9999
    pipeline      = []
    pipeline.push PS.new_random_async_value_source 'quiet stream this is one great thing'.split /\s+/
    # pipeline.push PS.new_value_source [ 'quiet stream\n', 'great thing\n', ]
    pipeline.push client_stream
    pipeline.push mainlog PS.$split()
    pipeline.push PS.$watch ( d ) -> debug '32388', xrpr d
    pipeline.push mainlog PS.$drain ->
      help 'ok'
      server.close()
    PS.pull pipeline...
    return null
  #.........................................................................................................
  server.listen 9999, listener

#-----------------------------------------------------------------------------------------------------------
@duplex_stream_3 = ->
  new_duplex_pair     = require 'pull-pair/duplex'
  [ client, server, ] = new_duplex_pair()
  clientline          = []
  serverline          = []
  refillable          = []
  extra_stream        = PS.new_refillable_source refillable, { repeat: 10, show: true, }
  # extra_stream        = PS.new_push_source()
  #.........................................................................................................
  # pipe the second duplex stream back to itself.
  serverline.push PS.new_merged_source server, extra_stream
  # serverline.push client
  serverline.push PS.$defer()
  serverline.push PS.$watch ( d ) -> urge d
  serverline.push $ ( d, send ) -> send d * 10
  serverline.push server
  PS.pull serverline...
  #.........................................................................................................
  clientline.push PS.new_value_source [ 1, 2, 3, ]
  # clientline.push PS.$defer()
  clientline.push client
  # clientline.push PS.$watch ( d ) -> extra_stream.send d if d < 30
  clientline.push PS.$watch ( d ) -> refillable.push d if d < 30
  clientline.push PS.$collect()
  clientline.push PS.$show()
  # clientline.push client
  clientline.push PS.$drain()
  PS.pull clientline...
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "wye with duplex pair" ] = ( T, done ) ->
  new_duplex_pair     = require 'pull-pair/duplex'
  probes_and_matchers = [
    [[false,false,false,[11,12,13],[21,22,23,24,25]],[22,42,24,44,26,46,48,50],null]
    [[false,false,true,[11,12,13],[21,22,23,24,25]],[22,42,24,44,26,46,48,50],null]
    [[false,true,false,[11,12,13],[21,22,23,24,25]],[22,42,24,44,26,46,48,50],null]
    [[false,true,true,[11,12,13],[21,22,23,24,25]],[22,42,24,44,26,46,48,50],null]
    [[true,false,false,[11,12,13],[21,22,23,24,25]],[42,44,46,48,50,22,24,26],null]
    [[true,false,true,[11,12,13],[21,22,23,24,25]],[42,44,46,48,50,22,24,26],null]
    [[true,true,false,[11,12,13],[21,22,23,24,25]],[42,44,46,48,50,22,24,26],null]
    [[true,true,true,[11,12,13],[21,22,23,24,25]],[42,44,46,48,50,22,24,26],null]
    ]
  #.........................................................................................................
  $wye = ( stream, use_defer ) ->
    $log                = PS.get_logger 'b', 'red'
    [ client, server, ] = new_duplex_pair()
    serverline          = []
    serverline.push PS.new_merged_source server, stream
    serverline.push PS.$defer() if use_defer
    # serverline.push PS.$watch ( d ) -> urge d
    serverline.push $ ( d, send ) -> send d * 2
    serverline.push server
    PS.pull serverline...
    return client
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      $log                = PS.get_logger 'm', 'gold'
      [ use_defer_1
        use_defer_2
        use_defer_3
        a
        b ]               = probe
      source_a            = PS.new_value_source a
      source_b            = PS.new_value_source b
      collector           = []
      clientline          = []
      clientline.push source_a
      clientline.push PS.$defer() if use_defer_1
      clientline.push $wye source_b, use_defer_3
      clientline.push PS.$defer() if use_defer_2
      clientline.push PS.$collect { collector, }
      # clientline.push PS.$show()
      clientline.push PS.$drain -> resolve collector
      PS.pull clientline...
  #.........................................................................................................
  done()
  return null


############################################################################################################
unless module.parent?
  do =>
    # await @duplex_stream_3()
    # await @wye_1()
    # await @wye_2()
    # await @pull_pair_1()
    # await @pull_pair_2()
    # await @[ "_duplex 1" ]()
    # await @[ "_duplex 2" ]()
    # await @wye_with_duplex_pair()
    test @[ "wye with duplex pair" ]

