
'use strict'


###
Testing Parameters

* number of no-op pass-through transforms
* highWaterMark for input stream
* whether input stream emits buffers or strings (if it emits strings, whether `$utf8` transform should be kept)
* implementation model for transforms
* implementation model for pass-throughs

Easy to show that `$split` doesn't work correctly on buffers (set highWaterMark to, say, 3 and have
input stream emit buffers).

###


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'BASIC-STREAM-BENCHMARKS-2/COPY-LINES-WITH-PULL-STREAM'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
new_numeral               = require 'numeral'
format_float              = ( x ) -> ( new_numeral x ).format '0,0.000'
format_integer            = ( x ) -> ( new_numeral x ).format '0,0'
#...........................................................................................................
PATH                      = require 'path'
FS                        = require 'fs'
#...........................................................................................................
$split                    = require 'pull-split'
$stringify                = require 'pull-stringify'
$utf8                     = require 'pull-utf8-decoder'
new_file_source           = require 'pull-file'
pull                      = require 'pull-stream'
### NOTE these two are different: ###
# $pass_through             = require 'pull-stream/throughs/through'
through                   = require 'pull-through'
async_map                 = require 'pull-stream/throughs/async-map'
$drain                    = require 'pull-stream/sinks/drain'
STPS                      = require 'stream-to-pull-stream'
#...........................................................................................................
S                         = {}
S.pass_through_count      = 0
# S.pass_through_count      = 1
# S.pass_through_count      = 100
# S.implementation          = 'pull-stream'
S.implementation          = 'pipestreams-map'
# S.implementation          = 'pipestreams-remit'
#...........................................................................................................
test                      = require 'guy-test'
#...........................................................................................................
PS                        = require '../..'
{ $, $async, }            = PS.export()
#...........................................................................................................
### Avoid to try to require `v8-profiler` when running this module with `devtool`: ###
S.running_in_devtools     = console.profile?
V8PROFILER                = null
unless S.running_in_devtools
  try
    V8PROFILER = require 'v8-profiler'
  catch error
    throw error unless error[ 'code' ] is 'MODULE_NOT_FOUND'
    warn "unable to `require v8-profiler`"

PRFLR           = {}
PRFLR.timers    = {}
PRFLR.sums      = {}
PRFLR.dt_total  = null
PRFLR.counts    = {}
if global.performance? then PRFLR.now = global.performance.now.bind global.performance
else                        PRFLR.now = require 'performance-now'
PRFLR.start = ( title ) ->
  ( @timers[ title ] ?= [] ).push -@now()
  return null
PRFLR.stop  = ( title ) ->
  @timers[ title ].push @now() + @timers[ title ].pop()
  return null
PRFLR.wrap  = ( title, method ) ->
  throw new Error "expected a text, got a #{type}"      unless ( type = CND.type_of title  ) is 'text'
  throw new Error "expected a function, got a #{type}"  unless ( type = CND.type_of method ) is 'function'
  parameters = ( "a#{idx}" for idx in [ 1 .. method.length ] by +1 ).join ', '
  title_txt = JSON.stringify title
  source = """
    var R;
    R = function ( #{parameters} ) {
      PRFLR.start( #{title_txt} );
      R = method.apply( null, arguments );
      PRFLR.stop( #{title_txt} );
      return R;
      }
    """
  R = eval source
  return R
PRFLR._average = ->
  ### only call after calibration, before actual usage ###
  @aggregate()
  @dt = @sums[ 'dt' ] / 10
  delete @sums[ 'dt' ]
  delete @counts[ 'dt' ]
PRFLR.aggregate = ->
  if @timers[ '*' ]?
    @stop '*' if @timers[ '*' ] < 0
    @dt_total = @timers[ '*' ]
    delete @timers[ '*' ]
    delete @counts[ '*' ]
  for title, timers of @timers
    dts               = @timers[ title ]
    @counts[ title ]  = dts.length
    @sums[ title ]    = ( @sums[ title ] ? 0 ) + dts.reduce ( ( a, b ) -> a + b ), 0
    delete @timers[ title ]
  return null
PRFLR.report = ->
  @aggregate()
  lines   = []
  dt_sum  = 0
  for title, dt of @sums
    count   = ' ' + @counts[ title ]
    leader  = '...'
    leader += '.' until title.length + leader.length + count.length > 50
    dt_sum += dt
    dt_txt  = format_float dt
    dt_txt  = ' ' + dt_txt until dt_txt.length > 10
    line    = [ title, leader, count, dt_txt, ].join ' '
    lines.push [ dt, line, ]
  lines.sort ( a, b ) ->
    return +1 if a[ 0 ] > b[ 0 ]
    return -1 if a[ 0 ] < b[ 0 ]
    return  0
  dt_reference = @dt_total ? dt_sum
  whisper "epsilon: #{@dt}"
  percentage_txt = ( ( dt_sum / dt_reference * 100 ).toFixed 0 ) + '%'
  whisper "dt reference: #{format_float dt_reference / 1000}s (#{percentage_txt})"
  for [ dt, line, ] in lines
    percentage_txt = ( ( dt / dt_reference * 100 ).toFixed 0 ) + '%'
    percentage_txt = ' ' + percentage_txt until percentage_txt.length > 3
    info line, percentage_txt

#-----------------------------------------------------------------------------------------------------------
### provide a minmum delta time: ###
for _ in [ 1 .. 10 ]
  PRFLR.start 'dt'
  PRFLR.stop  'dt'
PRFLR._average()

#-----------------------------------------------------------------------------------------------------------
start_profile = ( S ) ->
  S.t0 = Date.now()
  if running_in_devtools
    console.profile S.job_name
  else if V8PROFILER?
    V8PROFILER.startProfiling S.job_name

#-----------------------------------------------------------------------------------------------------------
stop_profile = ( S, handler ) ->
  if running_in_devtools
    console.profileEnd S.job_name
  else if V8PROFILER?
    step ( resume ) ->
      profile         = V8PROFILER.stopProfiling S.job_name
      profile_data    = yield profile.export resume
      S.profile_name  = "profile-#{S.job_name}.json"
      S.profile_home  = PATH.resolve __dirname, '../results', S.fingerprint, 'profiles'
      mkdirp.sync S.profile_home
      S.profile_path  = PATH.resolve S.profile_home, S.profile_name
      FS.writeFileSync S.profile_path, profile_data
      handler()

#-----------------------------------------------------------------------------------------------------------
TAP.test "performance regression", ( T ) ->

  #---------------------------------------------------------------------------------------------------------
  input_settings  = { encoding: 'utf-8', }
  input_path      = PATH.resolve __dirname, '../../test-data/ids.txt'
  # input_path      = PATH.resolve __dirname, '../../test-data/ids-short.txt'
  # input_path      = PATH.resolve __dirname, '../../test-data/Unicode-NamesList-tiny.txt'
  output_path     = PATH.resolve __dirname, '../../test-data/ids-copy.txt'

  #---------------------------------------------------------------------------------------------------------
  input                     = PS.new_file_source input_path, input_settings
  # output                    = PS.new_file_sink              output_path
  # output                    = PS._new_file_sink_using_stps  output_path
  # output                    = PS._new_file_sink_using_pwf   output_path
  output                    = PS.new_file_sink output_path

  #---------------------------------------------------------------------------------------------------------
  pipeline                  = []
  push                      = pipeline.push.bind pipeline
  t0                        = null
  t1                        = null
  item_count                = 0


  #---------------------------------------------------------------------------------------------------------
  $on_start = ->
    return PS.map_start ->
      help 44402, "start"
      PRFLR.start '*'
      t0 = Date.now()
      console.profile 'copy-lines' if S.running_in_devtools

  #---------------------------------------------------------------------------------------------------------
  $on_stop = ->
    return PS.map_stop ->
      PRFLR.stop '*'
      PRFLR.report()
      console.profileEnd 'copy-lines' if S.running_in_devtools
      t1              = Date.now()
      dts             = ( t1 - t0 ) / 1000
      dts_txt         = format_float dts
      item_count_txt  = format_integer item_count
      ips             = item_count / dts
      ips_txt         = format_float ips
      help PATH.basename __filename
      help "pass-through count: #{S.pass_through_count}"
      help "#{item_count_txt} items; dts: #{dts_txt}, ips: #{ips_txt}"
      T.pass "looks good"
      T.end()

  ```
  function XXX_map (read, map) {
    //return a readable function!
    return function (end, cb) {
      read(end, function (end, data) {
        debug(20323,rpr(data))
        cb(end, data != null ? map(data) : null)
      })
    }
  }
  ```


  ```
  function XXX_through (op, onEnd) {
    var a = false

    function once (abort) {
      if(a || !onEnd) return
      a = true
      onEnd(abort === true ? null : abort)
    }

    return function (read) {
      return function (end, cb) {
        if(end) once(end)
        return read(end, function (end, data) {
          if(!end) op && op(data)
          else once(end)
          cb(end, data)
        })
      }
    }
  }
  ```

  XXX_through2 = ( on_data, on_stop ) ->
    has_ended = false
    collector = []

    once = ( abort ) ->
      return null if has_ended
      return null if not on_stop?
      has_ended = true
      on_stop if abort is true then null else abort
      return null

    send = ( data ) -> collector.push data

    return ( read ) ->
      return ( end, handler ) ->
        once end if end
        read end, ( end, data ) ->
          if end
            once end
          else
            on_data data, send if on_data?
          if collector.length > 0
            handler end, d for d in collector
            collector.length = 0
          else
            handler end, null
          return


  #---------------------------------------------------------------------------------------------------------
  switch S.implementation
    #.......................................................................................................
    when 'pull-stream'
      $as_line            = -> pull.map ( line    ) -> line + '\n'
      $as_text            = -> pull.map ( fields  ) -> JSON.stringify fields
      $count              = -> pull.map ( line    ) -> item_count += +1; return line
      # $count              = -> pull.map ( line    ) -> item_count += +1; whisper item_count if item_count % 1000 is 0; return line
      $select_fields      = -> pull.map ( fields  ) -> [ _, glyph, formula, ] = fields; return [ glyph, formula, ]
      $split_fields       = -> pull.map ( line    ) -> line.split '\t'
      $trim               = -> pull.map ( line    ) -> line.trim()
      $pass               = -> pull.map ( line    ) -> line
    #.......................................................................................................
    when 'pipestreams-remit'
      $as_line            = -> $ ( line,   send ) -> send line + '\n'
      $as_text            = -> $ ( fields, send ) -> send JSON.stringify fields
      $count              = -> $ ( line,   send ) -> item_count += +1; send line
      # $count              = -> $ ( line,   send ) -> item_count += +1; whisper item_count if item_count % 1000 is 0; send line
      $select_fields      = -> $ ( fields, send ) -> [ _, glyph, formula, ] = fields; send [ glyph, formula, ]
      $split_fields       = -> $ ( line,   send ) -> send line.split '\t'
      $trim               = -> $ ( line,   send ) -> send line.trim()
      $pass               = -> $ ( line,   send ) -> send line
    #.......................................................................................................
    when 'pipestreams-map'
      $as_line            = -> PS.map PRFLR.wrap '$as_line',        ( line    ) -> line + '\n'
      $as_text            = -> PS.map PRFLR.wrap '$as_text',        ( fields  ) -> JSON.stringify fields
      $count              = -> PS.map PRFLR.wrap '$count',          ( line    ) -> item_count += +1; return line
      $select_fields      = -> PS.map PRFLR.wrap '$select_fields',  ( fields  ) -> [ _, glyph, formula, ] = fields; return [ glyph, formula, ]
      $split_fields       = -> PS.map PRFLR.wrap '$split_fields',   ( line    ) -> line.split '\t'
      $trim               = -> PS.map PRFLR.wrap '$trim',           ( line    ) -> line.trim()
      $pass               = -> PS.map PRFLR.wrap '$pass',           ( line    ) -> line
      $my_utf8            = -> PS.map PRFLR.wrap '$my_utf8',        ( buffer  ) -> debug buffer; buffer.toString 'utf-8'
      $show               = -> PS.map PRFLR.wrap '$show',           ( data    ) -> info rpr data; return data

  #.........................................................................................................
  $filter_empty       = -> PS.$filter PRFLR.wrap '$filter_empty',       ( line   ) -> line.length > 0
  $filter_comments    = -> PS.$filter PRFLR.wrap '$filter_comments',    ( line   ) -> not line.startsWith '#'
  $filter_incomplete  = -> PS.$filter PRFLR.wrap '$filter_incomplete',  ( fields ) -> [ a, b, ] = fields; return a? or b?

  #---------------------------------------------------------------------------------------------------------
  push input
  push $on_start()
  # push $utf8()
  push PRFLR.wrap '$split', $split()
  # push $show()
  push $count()
  push $trim()
  push $filter_empty()
  push $filter_comments()
  # push pull.filter   ( line    ) -> ( /魚/ ).test line
  push $split_fields()
  push $select_fields()
  push $filter_incomplete()
  # push XXX_through2 ( data, send ) ->
  #   urge data
  #   send data
  #   send data
  push $as_text()
  push $as_line()
  # push ( pull.map ( line ) -> line ) for idx in [ 1 .. S.pass_through_count ] by +1
  ###
  ###
  push $pass() for idx in [ 1 .. S.pass_through_count ] by +1
  push $on_stop()
  # push $sink_example()
  # push output
  # push $drain ( ( data ) -> urge data ), ( ( P... )-> help P )
  push PRFLR.wrap '$drain', $drain()
  pull pipeline...

