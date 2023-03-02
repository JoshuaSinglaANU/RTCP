

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/TESTS/BASIC'
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
PS                        = require '../..'
{ $, $async, }            = PS.export()
#...........................................................................................................
pull                      = require 'pull-stream'
$take                     = require 'pull-stream/throughs/take'
$values                   = require 'pull-stream/sources/values'
$pull_drain               = require 'pull-stream/sinks/drain'
pull_through              = require 'pull-through'
#...........................................................................................................
read                      = ( path ) -> FS.readFileSync path, { encoding: 'utf-8', }
defer                     = setImmediate
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }

#-----------------------------------------------------------------------------------------------------------
@_prune = ->
  for name, value of @
    continue if name.startsWith '_'
    delete @[ name ] unless name in include
  return null

#-----------------------------------------------------------------------------------------------------------
@_main = ->
  test @, 'timeout': 30000

# #-----------------------------------------------------------------------------------------------------------
# @[ "test line assembler" ] = ( T, done ) ->
#   text = """
#   "　2. 纯；专：专～。～心～意。"
#   !"　3. 全；满：～生。～地水。"
#   "　4. 相同：～样。颜色不～。"
#   "　5. 另外!的：蟋蟀～名促织。!"
#   "　6. 表示动作短暂，或是一次，或具试探性：算～算。试～试。"!
#   "　7. 乃；竞：～至于此。"
#   """
#   # text = "abc\ndefg\nhijk"
#   chunks    = text.split '!'
#   text      = text.replace /!/g, ''
#   collector = []
#   assembler = PS._new_line_assembler { extra: true, splitter: '\n', }, ( error, line ) ->
#     throw error if error?
#     if line?
#       collector.push line
#       info rpr line
#     else
#       # urge rpr text
#       # help rpr collector.join '\n'
#       # debug collector
#       if CND.equals text, collector.join '\n'
#         T.succeed "texts are equal"
#       done()
#   for chunk in chunks
#     assembler chunk
#   assembler null

# #-----------------------------------------------------------------------------------------------------------
# @[ "test throughput (1)" ] = ( T, done ) ->
#   # input   = @new_stream PATH.resolve __dirname, '../test-data/guoxuedashi-excerpts-short.txt'
#   input   = PS.new_stream PATH.resolve __dirname, '../../test-data/Unicode-NamesList-tiny.txt'
#   output  = FS.createWriteStream '/tmp/output.txt'
#   lines   = []
#   input
#     .pipe PS.$split()
#     # .pipe PS.$show()
#     .pipe PS.$succeed()
#     .pipe PS.$as_line()
#     .pipe $ ( line, send ) ->
#       lines.push line
#       send line
#     .pipe output
#   ### TAINT use PipeStreams method ###
#   input.on 'end', -> outpudone()
#   output.on 'close', ->
#     # if CND.equals lines.join '\n'
#     T.succeed "assuming equality"
#     done()
#   return null

# #-----------------------------------------------------------------------------------------------------------
# @[ "test throughput (2)" ] = ( T, done ) ->
#   # input   = @new_stream PATH.resolve __dirname, '../test-data/guoxuedashi-excerpts-short.txt'
#   input   = PS.new_stream PATH.resolve __dirname, '../../test-data/Unicode-NamesList-tiny.txt'
#   output  = FS.createWriteStream '/tmp/output.txt'
#   lines   = []
#   p       = input
#   p       = p.pipe PS.$split()
#   # p       = p.pipe PS.$show()
#   p       = p.pipe PS.$succeed()
#   p       = p.pipe PS.$as_line()
#   p       = p.pipe $ ( line, send ) ->
#       lines.push line
#       send line
#   p       = p.pipe output
#   ### TAINT use PipeStreams method ###
#   input.on 'end', -> outpudone()
#   output.on 'close', ->
#     # if CND.equals lines.join '\n'
#     # debug '12001', lines
#     T.succeed "assuming equality"
#     done()
#   return null

# #-----------------------------------------------------------------------------------------------------------
# @[ "read with pipestreams" ] = ( T, done ) ->
#   matcher       = [
#     '01 ; charset=UTF-8',
#     '02 @@@\tThe Unicode Standard 9.0.0',
#     '03 @@@+\tU90M160615.lst',
#     '04 \tUnicode 9.0.0 final names list.',
#     '05 \tThis file is semi-automatically derived from UnicodeData.txt and',
#     '06 \ta set of manually created annotations using a script to select',
#     '07 \tor suppress information from the data file. The rules used',
#     '08 \tfor this process are aimed at readability for the human reader,',
#     '09 \tat the expense of some details; therefore, this file should not',
#     '10 \tbe parsed for machine-readable information.',
#     '11 @+\t\t© 2016 Unicode®, Inc.',
#     '12 \tFor terms of use, see http://www.unicode.org/terms_of_use.html',
#     '13 @@\t0000\tC0 Controls and Basic Latin (Basic Latin)\t007F',
#     '14 @@+'
#     ]
#   # input_path    = '../../test-data/Unicode-NamesList-tiny.txt'
#   input_path    = '/home/flow/io/basic-stream-benchmarks/test-data/Unicode-NamesList-tiny.txt'
#   # output_path   = '/dev/null'
#   output_path   = '/tmp/output.txt'
#   input         = PS.new_stream input_path
#   output        = FS.createWriteStream output_path
#   collector     = []
#   S             = {}
#   S.item_count  = 0
#   S.byte_count  = 0
#   p             = input
#   p             = p.pipe $ ( data, send ) -> whisper '20078-1', rpr data; send data
#   p             = p.pipe PS.$split()
#   p             = p.pipe $ ( data, send ) -> help '20078-1', rpr data; send data
#   #.........................................................................................................
#   p             = p.pipe PS.$ ( line, send ) ->
#     S.item_count += +1
#     S.byte_count += line.length
#     debug '22001-0', rpr line
#     collector.push line
#     send line
#   #.........................................................................................................
#   p             = p.pipe $ ( data, send ) -> urge '20078-2', rpr data; send data
#   p             = p.pipe PS.$as_line()
#   p             = p.pipe output
#   #.........................................................................................................
#   ### TAINT use PipeStreams method ###
#   output.on 'close', ->
#     # debug '88862', S
#     # debug '88862', collector
#     if CND.equals collector, matcher
#       T.succeed "collector equals matcher"
#     done()
#   #.........................................................................................................
#   ### TAINT should be done by PipeStreams ###
#   input.on 'end', ->
#     outpudone()
#   #.........................................................................................................
#   return null


# #-----------------------------------------------------------------------------------------------------------
# @[ "remit without end detection" ] = ( T, done ) ->
#   pipeline = []
#   pipeline.push $values Array.from 'abcdef'
#   pipeline.push $ ( data, send ) ->
#     send data
#     send '*' + data + '*'
#   pipeline.push PS.$show()
#   pipeline.push $pull_drain()
#   PS.pull pipeline...
#   T.succeed "ok"
#   done()

#-----------------------------------------------------------------------------------------------------------
@[ "remit with end detection 1" ] = ( T, done ) ->
  ### Sending `PS._symbols.end` has undefined behavior; in this case, it does end the stream, which is
  OK. ###
  # debug xrpr PS._symbols
  # debug xrpr PS._symbols.end; xxx
  pull_through              = require '../../deps/pull-through-with-end-symbol'
  pipeline = []
  # pipeline.push $values Array.from 'abcdef'
  pipeline.push PS.new_value_source Array.from 'abcdef'
  pipeline.push PS.$map ( d ) -> return d
  pipeline.push $ ( d, send ) -> send if d is 'c' then PS._symbols.end else d
  pipeline.push PS.$pass()
  pipeline.push pull_through ( ( d ) -> @queue d )
  pipeline.push $ { last: null, }, ( data, send ) ->
    if data?
      send data
      send '*' + data + '*'
    else
      send 'ok'
  pipeline.push $pull_drain null, ->
    T.succeed "ok"
    done()
  PS.pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@[ "remit with end detection 2" ] = ( T, done ) ->
  ### One of the proper ways to end (a.k.a. abort) a stream is to call `send.end()`. ###
  pull_through              = require '../../deps/pull-through-with-end-symbol'
  pipeline = []
  pipeline.push PS.new_value_source Array.from 'abcdef'
  pipeline.push PS.$map ( d ) -> return d
  pipeline.push $ ( d, send ) -> if d is 'c' then send.end() else send d
  pipeline.push PS.$pass()
  pipeline.push pull_through ( ( d ) -> @queue d )
  pipeline.push $ { last: null, }, ( data, send ) ->
    if data?
      send data
      send '*' + data + '*'
    else
      send 'ok'
  pipeline.push $pull_drain null, ->
    T.succeed "ok"
    done()
  PS.pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@[ "watch with end detection 1" ] = ( T, done ) ->
  [ probe, matcher, error, ] = ["abcdef",["(","*a*","|","*b*","|","*c*","|","*d*","|","*e*","|","*f*",")"],null]
  await T.perform probe, matcher, error, -> new Promise ( resolve, reject ) ->
    collector = []
    pipeline  = []
    pipeline.push PS.new_value_source Array.from probe
    pipeline.push $ ( d, send ) -> send "*#{d}*"
    pipeline.push PS.$watch { first: '(', between: '|', last: ')', }, ( d ) ->
      debug '44874', xrpr d
      collector.push d
    # pipeline.push PS.$collect { collector, }
    pipeline.push PS.$drain ->
      help 'ok'
      debug '44874', xrpr collector
      resolve collector
    PS.pull pipeline...
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "watch with end detection 2" ] = ( T, done ) ->
  [ probe, matcher, error, ] = ["abcdef",["*a*","*b*","*c*","*d*","*e*","*f*"],null]
  await T.perform probe, matcher, error, -> new Promise ( resolve, reject ) ->
    collector = []
    pipeline  = []
    pipeline.push PS.new_value_source Array.from probe
    pipeline.push $ ( d, send ) -> send "*#{d}*"
    pipeline.push PS.$watch { first: '(', between: '|', last: ')', }, ( d ) ->
      debug '44874', xrpr d
    pipeline.push PS.$collect { collector, }
    pipeline.push PS.$drain ->
      help 'ok'
      debug '44874', xrpr collector
      resolve collector
    PS.pull pipeline...
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "wrap FS object for sink" ] = ( T, done ) ->
  output_path   = '/tmp/pipestreams-test-output.txt'
  output_stream = FS.createWriteStream output_path
  sink          = PS.write_to_nodejs_stream output_stream #, ( error ) -> debug '37783', error
  pipeline      = []
  pipeline.push $values Array.from 'abcdef'
  pipeline.push PS.$show()
  pipeline.push sink
  pull pipeline...
  output_stream.on 'finish', =>
    T.ok CND.equals 'abcdef', read output_path
    done()

#-----------------------------------------------------------------------------------------------------------
@[ "function as pull-stream source" ] = ( T, done ) ->
  random = ( n ) =>
    return ( end, callback ) =>
      if end?
        debug '40998', rpr callback
        debug '40998', rpr end
        return callback end
      #only read n times, then stop.
      n += -1
      if n < 0
        return callback true
      callback null, Math.random()
      return null
  #.........................................................................................................
  pipeline  = []
  Ø         = ( x ) => pipeline.push x
  Ø random 10
  # Ø random 3
  Ø PS.$collect()
  Ø $ { last: null, }, ( data, send ) ->
    if data?
      T.ok data.length is 10
      debug data
      send data
    else
      T.succeed "function works as pull-stream source"
      done()
      send null
  Ø PS.$show()
  Ø PS.$drain()
  #.........................................................................................................
  PS.pull pipeline...
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "$surround" ] = ( T, done ) ->
  [ probe, matcher, error, ] = [null,"first[(1),(2),(3),(4),(5)]last",null]
  await T.perform probe, matcher, error, ->
    return new Promise ( resolve, reject ) ->
      R         = null
      drainer   = -> help 'ok'; resolve R
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
      pipeline.push PS.$watch ( d ) -> R = d
      pipeline.push PS.$drain drainer
      PS.pull pipeline...
      return null
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "$surround async" ] = ( T, done ) ->
  [ probe, matcher, error, ] = [null,"[first|1|2|3|4|5|last]",null]
  await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
    R         = null
    drainer   = -> help 'ok'; resolve R
    pipeline  = []
    pipeline.push PS.new_value_source [ 1 .. 5 ]
    #.........................................................................................................
    pipeline.push PS.$surround { first: 'first', last: 'last', }
    pipeline.push $async { first: '[', last: ']', between: '|', }, ( d, send, done ) =>
      defer ->
        # debug '22922', jr d
        send d
        done()
    #.........................................................................................................
    pipeline.push PS.$collect()
    pipeline.push $ ( d, send ) -> send ( x.toString() for x in d ).join ''
    pipeline.push PS.$watch ( d ) -> R = d
    pipeline.push PS.$drain drainer
    PS.pull pipeline...
    return null
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "end push source (1)" ] = ( T, done ) ->
  ### The proper way to end a push source is to call `source.end()`. ###
  [ probe, matcher, error, ] = [["what","a","lot","of","little","bottles"],["what","a","lot","of","little","bottles"],null]
  await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
    R         = []
    drainer   = -> help 'ok'; resolve R
    source    = PS.new_push_source()
    pipeline  = []
    pipeline.push source
    pipeline.push PS.$watch ( d ) -> info xrpr d
    pipeline.push PS.$collect { collector: R, }
    pipeline.push PS.$watch ( d ) -> info xrpr d
    pipeline.push PS.$drain drainer
    pull pipeline...
    for word in probe
      source.send word
    source.end()
    return null
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "end push source (2)" ] = ( T, done ) ->
  ### The proper way to end a push source is to call `source.end()`. ###
  [ probe, matcher, error, ] = [["what","a","lot","of","little","bottles","stop"],["what","a","lot","of","little","bottles"],null]
  await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
    R         = []
    drainer   = -> help 'ok'; resolve R
    source    = PS.new_push_source()
    pipeline  = []
    pipeline.push source
    pipeline.push PS.$watch ( d ) -> info xrpr d
    pipeline.push $ ( d, send ) -> if d is 'stop' then source.end() else send d
    pipeline.push PS.$collect { collector: R, }
    pipeline.push PS.$watch ( d ) -> info xrpr d
    pipeline.push PS.$drain drainer
    pull pipeline...
    for word in probe
      source.send word
    return null
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "end push source (3)" ] = ( T, done ) ->
  ### The proper way to end a push source is to call `source.end()`; `send.end()` is largely equivalent. ###
  [ probe, matcher, error, ] = [["what","a","lot","of","little","bottles","stop"],["what","a","lot","of","little","bottles"],null]
  await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
    R         = []
    drainer   = -> help 'ok'; resolve R
    source    = PS.new_push_source()
    pipeline  = []
    pipeline.push source
    pipeline.push PS.$watch ( d ) -> info xrpr d
    pipeline.push $ ( d, send ) -> if d is 'stop' then send.end() else send d
    pipeline.push PS.$collect { collector: R, }
    pipeline.push PS.$watch ( d ) -> info xrpr d
    pipeline.push PS.$drain drainer
    pull pipeline...
    for word in probe
      source.send word
    return null
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "end push source (4)" ] = ( T, done ) ->
  ### A stream may be ended by using an `$end_if()` (alternatively, `$continue_if()`) transform. ###
  [ probe, matcher, error, ] = [["what","a","lot","of","little","bottles","stop"],["what","a","lot","of","little","bottles"],null]
  await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
    R         = []
    drainer   = -> help 'ok'; resolve R
    source    = PS.new_push_source()
    pipeline  = []
    pipeline.push source
    pipeline.push PS.$watch ( d ) -> info xrpr d
    pipeline.push PS.$end_if ( d ) -> d is 'stop'
    pipeline.push PS.$collect { collector: R, }
    pipeline.push PS.$watch ( d ) -> info xrpr d
    pipeline.push PS.$drain drainer
    pull pipeline...
    for word in probe
      source.send word
    return null
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "end random async source" ] = ( T, done ) ->
  [ probe, matcher, error, ] = [["what","a","lot","of","little","bottles"],["what","a","lot","of","little","bottles"],null]
  await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
    R         = []
    drainer   = -> help 'ok'; resolve R
    source    = PS.new_random_async_value_source probe
    pipeline  = []
    pipeline.push source
    pipeline.push PS.$watch ( d ) -> info xrpr d
    pipeline.push PS.$collect { collector: R, }
    pipeline.push PS.$watch ( d ) -> info xrpr d
    pipeline.push PS.$drain drainer
    pull pipeline...
    return null
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "read file chunks" ] = ( T, done ) ->
  [ probe, matcher, error, ] = [ __filename, null, null, ]
  await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
    R         = []
    drainer   = -> help 'ok'; resolve null
    source    = PS.read_chunks_from_file probe, 50
    count     = 0
    pipeline  = []
    pipeline.push source
    pipeline.push $ ( d, send ) -> send d.toString 'utf-8'
    pipeline.push PS.$watch ->
      count += +1
      source.end() if count > 3
    pipeline.push PS.$collect { collector: R, }
    pipeline.push PS.$watch ( d ) -> info xrpr d
    pipeline.push PS.$drain drainer
    pull pipeline...
    return null
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "demo watch pipeline on abort 2" ] = ( T, done ) ->
  # through = require 'pull-through'
  probes_and_matchers = [
    [[false,[1,2,3,null,5]],[1,1,1,2,2,2,3,3,3,null,null,null,5,5,5],null]
    [[true,[1,2,3,null,5]],[1,1,1,2,2,2,3,3,3,null,null,null,5,5,5],null]
    [[false,[1,2,3,"stop",25,30]],[1,1,1,2,2,2,3,3,3],null]
    [[true,[1,2,3,"stop",25,30]],[1,1,1,2,2,2,3,3,3],null]
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
      source      = PS.new_value_source values
      collector   = []
      pipeline    = []
      pipeline.push source
      pipeline.push aborting_map use_defer, ( d ) -> info '22398-1', xrpr d; return d
      pipeline.push PS.$ ( d, send ) -> info '22398-2', xrpr d; collector.push d; send d
      pipeline.push PS.$ ( d, send ) -> info '22398-3', xrpr d; collector.push d; send d
      pipeline.push PS.$ ( d, send ) -> info '22398-4', xrpr d; collector.push d; send d
      # pipeline.push PS.$map ( d ) -> info '22398-2', xrpr d; collector.push d; return d
      # pipeline.push PS.$map ( d ) -> info '22398-3', xrpr d; collector.push d; return d
      # pipeline.push PS.$map ( d ) -> info '22398-4', xrpr d; collector.push d; return d
      pipeline.push PS.$drain ->
        help '44998', xrpr collector
        resolve collector
      pull pipeline...
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "$mark_position" ] = ( T, done ) ->
  # through = require 'pull-through'
  probes_and_matchers = [
    [["a"],[{"is_first":true,"is_last":true,"d":"a"}],null]
    [[],[],null]
    [[1,2,3],[{"is_first":true,"is_last":false,"d":1},{"is_first":false,"is_last":false,"d":2},{"is_first":false,"is_last":true,"d":3}],null]
    [["a","b"],[{"is_first":true,"is_last":false,"d":"a"},{"is_first":false,"is_last":true,"d":"b"}],null]
    ]
  #.........................................................................................................
  collector = []
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      #.....................................................................................................
      source      = PS.new_value_source probe
      collector   = []
      pipeline    = []
      pipeline.push source
      pipeline.push PS.$mark_position()
      pipeline.push PS.$collect { collector, }
      pipeline.push PS.$drain -> resolve collector
      pull pipeline...
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "leapfrog 1" ] = ( T, done ) ->
  # through = require 'pull-through'
  probes_and_matchers = [
    [[[ 1 .. 10], ( ( d ) -> d %% 2 isnt 0 ), ],[1,102,3,104,5,106,7,108,9,110],null]
    ]
  #.........................................................................................................
  collector = []
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      [ values
        jumper ]  = probe
      #.....................................................................................................
      source      = PS.new_value_source values
      collector   = []
      pipeline    = []
      pipeline.push source
      pipeline.push PS.$ { leapfrog: jumper, }, ( d, send ) -> send 100 + d
      pipeline.push PS.$collect { collector, }
      pipeline.push PS.$drain -> resolve collector
      pull pipeline...
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "leapfrog 2" ] = ( T, done ) ->
  # through = require 'pull-through'
  probes_and_matchers = [
    [[[ 1 .. 10], ( ( d ) -> d %% 2 isnt 0 ), ],[1,102,3,104,5,106,7,108,9,110],null]
    ]
  #.........................................................................................................
  collector = []
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      [ values
        jumper ]  = probe
      #.....................................................................................................
      source      = PS.new_value_source values
      collector   = []
      pipeline    = []
      pipeline.push source
      pipeline.push PS.$ { leapfrog: jumper, }, ( d, send ) -> send 100 + d
      pipeline.push PS.$collect { collector, }
      pipeline.push PS.$drain -> resolve collector
      pull pipeline...
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "$scramble" ] = ( T, done ) ->
  probes_and_matchers = [
    [[[],0.5,42],[],null]
    [[[1],0.5,42],[1],null]
    [[[1,2],0.5,42],[1,2],null]
    [[[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40],0.5,42],[1,4,2,5,3,6,7,14,12,9,13,8,16,10,15,11,17,18,19,20,21,22,24,26,23,25,27,28,29,30,32,31,33,34,35,37,36,38,39,40],null]
    [[[1,2,3,4,5,6,7,8,9,10],1,2],[9,2,7,5,8,4,10,1,3,6],null]
    [[[1,2,3,4,5,6,7,8,9,10],0.1,2],[1,2,3,4,5,6,7,8,9,10],null]
    [[[1,2,3,4,5,6,7,8,9,10],0,2],[1,2,3,4,5,6,7,8,9,10],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    #.......................................................................................................
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      [ values
        p
        seed ]    = probe
      cache       = {}
      collector   = []
      pipeline    = []
      pipeline.push PS.new_value_source values
      pipeline.push PS.$scramble p, { seed, }
      pipeline.push PS.$collect { collector, }
      pipeline.push PS.$drain -> resolve collector
      PS.pull pipeline...
      #.....................................................................................................
      return null
  #.........................................................................................................
  done()
  return null


############################################################################################################
unless module.parent?
  # include = []
  # @_prune()
  # @_main()
  # test @
  # test @[ "read file chunks" ]
  # test @[ "$mark_position" ]
  # test @[ "leapfrog 2" ]
  test @[ "$scramble" ]
  # test @[ "remit with end detection 1" ]
  # test @[ "remit with end detection 2" ]
  # test @[ "$surround async" ]
  # test @[ "end push source (1)" ]
  # test @[ "end push source (2)" ]
  # test @[ "end push source (3)" ]
  # test @[ "end push source (4)" ]
  # test @[ "end random async source" ]
  # test @[ "watch with end detection 1" ]
  # test @[ "watch with end detection 2" ]
  # test @[ "demo watch pipeline on abort 2" ]




