

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/EXPERIMENTS/PULL-STREAM-EXAMPLES-PULL'
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
after                     = ( dts, f ) -> setTimeout  f, dts * 1000
every                     = ( dts, f ) -> setInterval f, dts * 1000
defer                     = setImmediate
{ jr
  is_empty }              = CND
#...........................................................................................................
PS                        = require '../..'
test                      = require 'guy-test'
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }


### Create a simple source stream that reads from an array.

A pull stream is just an async stream that is called repeatedly. Note that when
every item in the array has been called back, it returns true in the error slot.
This indicates the end of the stream. Both `error` and `end` mean the stream is
over, but there are many possible ways an error can occur (`error && error !==
true`), and only one way a stream can correctly end (`true`).

In pull-streams I like to call streams that data comes out of 'sources', while
in NodeJS they are usually called 'readables'. ###

#-----------------------------------------------------------------------------------------------------------
source_from_values = ( list ) ->
  idx       = -1
  last_idx  = list.length - 1
  read = ( abort, handler ) ->
    return handler abort if abort             # acknowledge `abort` condition, if any
    return handler true  if idx >= last_idx   # terminate normally with `true`
    idx += +1
    ### Can callback later: ###
    if O.async.value_source
      defer -> handler null, list[ idx ]
    else
      handler null, list[ idx ]
    return null
  return read

### Pull-streams don't really have a writable stream per se. 'Writable' implies that
the writer is the active partner, and the stream which is written to is passive
(like you are when you watch TV, the TV writes its lies into neocortex via your retinas).

Instead of a writable, pull-streams have a 'sink', i.e. a 'reader'. Here the
reader is the active party, actively consuming more data. When you read a book,
you are in control, and must actively turn the pages to get more information.

So, a sink is a function that you pass a source to, which then reads from that
function until it gets to the end or decides to stop. ###

#-----------------------------------------------------------------------------------------------------------
sink = ( read ) ->
  ### NOTE this implementation will call the `read()` method recursively, risking to blow the call stack
  when streams get longer. This can be alleviated (I think) by deferring the callback to the next turn of
  the event loop, or by using a linear transformation (a trampoline) of the recursive call, as per
  https://github.com/pull-stream/pull-stream/blob/master/sinks/drain.js. ###
  #.........................................................................................................
  next = ( error, data ) ->
    if error?
      return whisper "µ33874 ended" if error is true
      throw error
    debug '89983', data
    ### Can read next later: ###
    # recursively call read again!
    if O.async.standard_sink_2
      defer -> read null, next
    else
      read null, next
    return null
  if O.async.standard_sink_1
    defer -> read null, next
  else
    read null, next
  return null

### We could now consume the source with just these two functions: `sink( source_from_values( [1,2,3] ) )`.

So simple. We didn't use any libraries, yet, we have streams with two-way
back-pressure. Since the pattern is async, the source can slow down by
back-calling slower, and the sink can slow down by waiting longer before calling
`read()` again!

Okay, to be useful, we also need a way to transform inputs into different
outputs, i.e. a transform stream. In pull-streams a transform is implemented as
a sink that returns a source. ###

#-----------------------------------------------------------------------------------------------------------
map = ( mapper ) ->
  # a sink function: accept a source...
  return ( read ) ->
    # ...but return another source!
    return ( abort, handler ) ->
      read abort, ( error, data ) ->
        # if the stream has ended, pass that on.
        return handler error if error
        if O.async.map
          # apply a mapping to that data
          defer -> handler null, mapper data
        else
          handler null, mapper data
        return null
      return null
    return null

#-----------------------------------------------------------------------------------------------------------
map_with_end = ( mapper ) ->
  # a sink function: accept a source...
  return ( read ) ->
    # ...but return another source!
    return ( abort, handler ) ->
      read abort, ( error, data ) ->
        # if the stream has ended, pass that on.
        if error
          return handler error unless error is true
          if O.async.map
            defer ->
              handler null, last_result if ( last_result = mapper null )?
              handler error
            return null
          else
            handler null, last_result if ( last_result = mapper null )?
            handler error
            return null
        # apply a mapping to that data
        if O.async.map
          defer -> handler null, mapper data
        else
          handler null, mapper data
        return null
      return null
    return null


### right now, we could combine these 3 streams by passing them to each other.

and then combine these with function composition:

sink(mapper(source))

this would be equavalent to node's .pipe
except with node streams it would look like

source.pipe(mapper).pipe(sink)

to be honest, it's easier to read if it does left to right.
because the direction the data flows is the same as you read.

lets write a quick function that allows us to compose pull streams left-to-right

pull(source, mapper, sink)
###


#-----------------------------------------------------------------------------------------------------------
pull = ( P... ) ->
  R = P.shift()
  R = P.shift() R while P.length > 0
  return R

### thats it! just call the next thing with the previous thing until there are no things left.
if we return the last thing, then we can even do this:

pull(pull(source, mapper), sink) ###


### Infinite streams. here is a stream that never ends. ###

#-----------------------------------------------------------------------------------------------------------
infinite_counter = ->
  i = -1
  return ( abort, handler ) ->
    return handler abort if abort
    i += +1
    handler null, i
    return null

### Now, reading all of an infinite stream will take forever...
BUT! the cool thing about pull streams is that they are LAZY.
that means it only gives us the next thing when we ask for it.

Also, you can ABORT a pull stream when you don't want any more.

here is a take(n) stream that reads n items from a source and then stops.
it's a transform stream like map, except it will stop early. ###

#-----------------------------------------------------------------------------------------------------------
take = ( n ) ->
  return ( read ) ->
    return ( abort, handler ) ->
      # after n reads, tell the source to abort!
      n += -1
      return read true, handler if n < 0
      read null, handler
      return null

#-----------------------------------------------------------------------------------------------------------
$is_equal = ( x ) ->
  return map ( d ) ->
    if CND.equals d, x
      help "ok: #{jr d}"
    else
      warn "not ok: #{jr d} (expected #{x})"
    return d

#-----------------------------------------------------------------------------------------------------------
$square = -> map ( d ) ->
  return d unless ( CND.isa_number d )
  return d ** 2

#-----------------------------------------------------------------------------------------------------------
$foo = -> map_with_end ( d ) ->
  if d?
    return null
  else
    urge '$foo: end'
    return 17
  return null

#-----------------------------------------------------------------------------------------------------------
$collect_A = ( collector = null ) ->
  pull_map_last = require 'pull-map-last'
  # _pull         = require 'pull-stream'
  collector    ?= []
  discard_sym   = Symbol.for 'pipestreams:discard'
  map_on_data = ( d ) ->
    collector.push d
    debug "$collect/on_data: #{rpr d}, #{rpr collector}"
    return discard_sym
  map_on_end = ->
    debug "$collect/on_end: #{rpr collector}"
    return collector
  # return pull ( pull_map_last map_on_data, map_on_end ), ( _pull.filter ( d ) -> d isnt discard_sym )
  return pull_map_last map_on_data, map_on_end

#-----------------------------------------------------------------------------------------------------------
O =
  async:
    value_source:     false
    standard_sink_2:  false
    standard_sink_1:  false
    map:              false


### now we can pipe the infinite stream through this,
and it will stop after n items! ###

# pipeline = []
# pipeline.push infinite_counter()
# pipeline.push $square()
# pipeline.push $foo()
# pipeline.push take 10
# pipeline.push PS.$show { title: 'A', }
# pipeline.push PS.$collect()
# pipeline.push $is_equal [0,1,4,9,16,25,36,49,64,81]
# pipeline.push sink
# pull pipeline...



#-----------------------------------------------------------------------------------------------------------
@[ "demo through with null" ] = ( T, done ) ->
  # through = require 'pull-through'
  probes_and_matchers = [
    [[ 5, 15, 20, undefined, 25, 30, ], [ 10, 30, 40, undefined, 50, 60 ]]
    [[ 5, 15, 20, null, 25, 30, ], [ 10, 30, 40, null, 50, 60 ]]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      #.....................................................................................................
      source    = source_from_values probe
      collector = []
      pipeline  = []
      pipeline.push source
      pipeline.push map ( d ) -> info '--->', d; return d
      pipeline.push PS.$ ( d, send ) -> send if d? then d * 2 else d
      # pipeline.push map ( d ) -> collector.push d; return d
      pipeline.push PS.$collect { collector, }
      pipeline.push PS.$drain ->
        help collector
        resolve collector
      pull pipeline...
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "demo watch pipeline on abort 1" ] = ( T, done ) ->
  # through = require 'pull-through'
  probes_and_matchers = [
    [[false,[1,2,3,null,5]],[1,1,1,2,2,2,3,3,3,null,null,null,5,5,5],null]
    [[true,[1,2,3,null,5]],[1,1,1,2,2,2,3,3,3,null,null,null,5,5,5],null]
    [[false,[1,2,3,null,"stop",25,30]],[1,1,1,2,2,2,3,3,3,null,null,null],null]
    [[true,[1,2,3,null,"stop",25,30]],[1,1,1,2,2,2,3,3,3,null,null,null],null]
    [[false,[1,2,3,undefined,"stop",25,30]],[1,1,1,2,2,2,3,3,3,undefined,undefined,undefined,],null]
    [[true,[1,2,3,undefined,"stop",25,30]],[1,1,1,2,2,2,3,3,3,undefined,undefined,undefined,],null]
    [[false,["stop",25,30]],[],null]
    [[true,["stop",25,30]],[],null]
    ]
  #.........................................................................................................
  aborting_map = ( use_defer, mapper ) ->
    react = ( handler, data ) ->
      if data is 'stop' then  handler true
      else                    handler null, mapper data
    # a sink function: accept a source...
    return ( read ) ->
      # ...but return another source!
      return ( abort, handler ) ->
        read abort, ( error, data ) ->
          # if the stream has ended, pass that on.
          return handler error if error
          if use_defer then  defer -> react handler, data
          else                        react handler, data
          return null
        return null
      return null
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      #.....................................................................................................
      [ use_defer
        values ]  = probe
      source      = source_from_values values
      collector   = []
      pipeline    = []
      pipeline.push source
      pipeline.push aborting_map use_defer, ( d ) -> info '22398-1', xrpr d; return d
      pipeline.push map ( d ) -> info '22398-2', xrpr d; collector.push d; return d
      pipeline.push map ( d ) -> info '22398-3', xrpr d; collector.push d; return d
      pipeline.push map ( d ) -> info '22398-4', xrpr d; collector.push d; return d
      pipeline.push PS.$drain ->
        help '44998', xrpr collector
        resolve collector
      pull pipeline...
  #.........................................................................................................
  done()
  return null




############################################################################################################
unless module.parent?
  null
  test @
  # test @[ "demo through with null" ]
  # test @[ "demo watch pipeline on abort 1" ]
  # test @[ "demo watch pipeline on abort 2" ]

###
That covers 3 types of pull streams. Source, Transform, & Sink.
There is one more important type, although it's not used as much.

Duplex streams

(see duplex.js!)
###
