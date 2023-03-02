

'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'STEAMPIPES/TESTS/WYE'
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
SP                        = require '../..'
{ $, $async, }            = SP
#...........................................................................................................
{ jr
  is_empty }              = CND
defer                     = setImmediate
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }

# https://pull-stream.github.io/#pull-through

# https://github.com/pull-stream/pull-cont
# https://github.com/pull-stream/pull-defer
# https://github.com/scrapjs/pull-imux
# https://github.com/dominictarr/pull-flow (https://github.com/pull-stream/pull-stream/issues/4)


#-----------------------------------------------------------------------------------------------------------
@[ "wye with duplex pair" ] = ( T, done ) ->
  probes_and_matchers = [
    [[false,false,false,[11,12,13],[21,22,23,24,25]],[11,21,12,22,13,23,24,25],null]
    [[false,false,true, [11,12,13],[21,22,23,24,25]],[11,21,12,22,13,23,24,25],null]
    [[false,true, false,[11,12,13],[21,22,23,24,25]],[11,21,12,22,13,23,24,25],null]
    [[false,true, true, [11,12,13],[21,22,23,24,25]],[11,21,12,22,13,23,24,25],null]
    [[true, false,false,[11,12,13],[21,22,23,24,25]],[21,22,23,24,25,11,12,13],null]
    [[true, false,true, [11,12,13],[21,22,23,24,25]],[21,22,23,24,25,11,12,13],null]
    [[true, true, false,[11,12,13],[21,22,23,24,25]],[21,22,23,24,25,11,12,13],null]
    [[true, true, true, [11,12,13],[21,22,23,24,25]],[21,22,23,24,25,11,12,13],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      $log                = SP.get_logger 'm', 'gold'
      [ use_defer_1
        use_defer_2
        use_defer_3
        a
        b ]               = probe
      source_a            = SP.new_value_source a
      source_b            = SP.new_value_source b
      collector           = []
      clientline          = []
      clientline.push source_a
      clientline.push SP.$defer() if    use_defer_1
      clientline.push SP.$wye source_b, use_defer_3
      clientline.push SP.$defer() if    use_defer_2
      clientline.push SP.$collect { collector, }
      # clientline.push SP.$show()
      clientline.push SP.$drain -> resolve collector
      SP.pull clientline...
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "new_merged_source 1" ] = ( T, done ) ->
  probes_and_matchers = [
    [[["a","b","c"],[1,2,3,4,5,6]],["a",1,"b",2,"c",3,4,5,6],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve, reject ) ->
      R                   = []
      drainer             = -> resolve R
      source_1            = SP.new_push_source()
      source_2            = SP.new_push_source()
      #...................................................................................................
      pipeline_1          = []
      pipeline_1.push source_1
      pipeline_1.push SP.$watch ( d ) -> whisper '10191-2', d
      #...................................................................................................
      pipeline_2          = []
      pipeline_2.push source_2
      pipeline_2.push SP.$watch ( d ) -> whisper '10191-3', d
      #...................................................................................................
      pipeline_3          = []
      pipeline_3.push SP.new_merged_source ( SP.pull pipeline_1... ), ( SP.pull pipeline_2... )
      pipeline_3.push SP.$watch ( d ) -> R.push d
      pipeline_3.push SP.$watch ( d ) -> urge '10191-4', d
      pipeline_3.push SP.$drain drainer
      SP.pull pipeline_3...
      max_idx = ( Math.max probe[ 0 ].length, probe[ 1 ].length ) - 1
      for idx in [ 0 .. max_idx ]
        source_1.send x if ( x = probe[ 0 ][ idx ] )?
        source_2.send x if ( x = probe[ 1 ][ idx ] )?
      source_1.end()
      source_2.end()
    done()
  return null

#-----------------------------------------------------------------------------------------------------------
new_filtered_bysink = ( name, collector, filter ) ->
  R = []
  R.push SP.$filter filter
  R.push SP.$watch ( d ) -> collector.push d
  # R.push SP.$watch ( d ) -> whisper '10191', '------------>', name, xrpr d
  R.push SP.$drain()
  return SP.pull R...

#-----------------------------------------------------------------------------------------------------------
@[ "$wye 1" ] = ( T, done ) ->
  probes_and_matchers = [
    [[["a","b","c"],[1,2,3,4,5,6]],[[1,2,3,4,5,6],["a","b","c"],[]],null]
    [[["a",null,"b","c",true],[null,1,2,3,4,5,6,null,undefined,Infinity]],[ [ 1, 2, 3, 4, 5, 6 ], [ 'a', 'b', 'c' ], [ null, null, true, null, undefined, Infinity ] ],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve, reject ) ->
      numbers             = []
      texts               = []
      others              = []
      R                   = [ numbers, texts, others, ]
      source_1            = SP.new_push_source()
      source_2            = SP.new_push_source()
      #...................................................................................................
      bysource            = []
      bysource.push source_2
      # bysource.push SP.$watch ( d ) -> whisper '10191-5', 'bysource', jr d
      # bysource.push SP.$defer()
      bysource            = SP.pull bysource...
      #...................................................................................................
      mainstream          = []
      mainstream.push source_1
      # mainstream.push SP.$defer()
      mainstream.push SP.$wye bysource
      # mainstream.push SP.$watch ( d ) -> whisper '10191-6', 'confluence', jr d
      mainstream.push SP.$tee new_filtered_bysink 'number', numbers,  ( d ) -> CND.isa_number d
      mainstream.push SP.$tee new_filtered_bysink 'text',   texts,    ( d ) -> CND.isa_text d
      mainstream.push SP.$tee new_filtered_bysink 'other',  others,   ( d ) -> ( not CND.isa_number d ) and ( not CND.isa_text d )
      mainstream.push SP.$drain ->
        echo xrpr R
        resolve R
      SP.pull mainstream...
      #...................................................................................................
      max_idx = ( Math.max probe[ 0 ].length, probe[ 1 ].length ) - 1
      for idx in [ 0 .. max_idx ]
        source_1.send probe[ 0 ][ idx ] if idx < probe[ 0 ].length
        source_2.send probe[ 1 ][ idx ] if idx < probe[ 1 ].length
      source_1.end()
      source_2.end()
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "$wye 2" ] = ( T, done ) ->
  probes_and_matchers = [
    [[true,true,["a","b","c"],[1,2,3,4,5,6]],["a",1,"b",2,"c",3,4,5,6],null]
    [[false,true,["a","b","c"],[1,2,3,4,5,6]],["a",1,"b",2,"c",3,4,5,6],null]
    [[false,false,["a","b","c"],[1,2,3,4,5,6]],["a",1,"b",2,"c",3,4,5,6],null]
    [[true,false,["a","b","c"],[1,2,3,4,5,6]],["a",1,"b",2,"c",3,4,5,6],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    matcher = matcher.sort()
    await T.perform probe, matcher, error, ->
      return new Promise ( resolve, reject ) ->
        [ defer_mainstream
          defer_bystream
          mainstream_values
          bystream_values ] = probe
        R                   = []
        drainer             = -> R = R.sort(); resolve R
        mainsource          = SP.new_push_source()
        bysource            = SP.new_push_source()
        #...................................................................................................
        bystream            = []
        bystream.push bysource
        bystream.push SP.$watch ( d ) -> whisper '10192-1', 'bysource', jr d
        bystream.push SP.$defer() if defer_bystream
        bystream.push SP.$watch ( d ) -> whisper '10192-1a', 'bysource', jr d
        bystream = SP.pull bystream...
        #...................................................................................................
        mainstream          = []
        mainstream.push mainsource
        mainstream.push $ { last: 'last' }, ( d, send ) -> urge '10192-2', 'mainstream', d; send d unless d is 'last'
        mainstream.push SP.$defer() if defer_mainstream
        mainstream.push SP.$watch ( d ) -> whisper '10192-3', 'mainstream', jr d
        mainstream.push SP.$wye bystream
        mainstream.push SP.$watch ( d ) -> R.push d
        mainstream.push SP.$watch ( d ) -> urge CND.white '10192-4', 'confluence', jr d
        mainstream.push SP.$drain drainer
        SP.pull mainstream...
        max_idx = ( Math.max mainstream_values.length, bystream_values.length ) - 1
        for idx in [ 0 .. max_idx ]
          mainsource.send x if ( x = mainstream_values[ idx ] )?
          bysource.send   x if ( x = bystream_values[   idx ] )?
        mainsource.end()
        bysource.end()
        return null
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "tee with filter" ] = ( T, done ) ->
  probes_and_matchers = [
    [[10,11,12,13,14,15,16,17,18,19,20],{"odd_numbers":[11,13,15,17,19],"all_numbers":[10,11,12,13,14,15,16,17,18,19,20]},null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    #.......................................................................................................
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      is_odd      = ( d ) -> ( d % 2 ) isnt 0
      odd_numbers = []
      all_numbers = []
      R           = { odd_numbers, all_numbers, }
      #.....................................................................................................
      byline      = []
      mainline    = []
      #.....................................................................................................
      byline.push SP.$show title: 'bystream'
      byline.push SP.$watch ( d ) -> odd_numbers.push d
      byline.push SP.$drain()
      bystream  = SP.pull byline...
      #.....................................................................................................
      mainline.push SP.new_value_source probe
      mainline.push SP.$tee is_odd, bystream
      mainline.push SP.$show title: 'mainstream'
      mainline.push SP.$watch ( d ) -> all_numbers.push d
      mainline.push SP.$drain ->
        help 'ok'
        resolve R
      SP.pull mainline...
      #.....................................................................................................
      return null
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "bifurcate" ] = ( T, done ) ->
  probes_and_matchers = [
    [[10,11,12,13,14,15,16,17,18,19,20],{"odd_numbers":[11,13,15,17,19],"even_numbers":[10,12,14,16,18,20]},null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    #.......................................................................................................
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      is_even       = ( d ) -> ( d % 2 ) is 0
      odd_numbers   = []
      even_numbers  = []
      R             = { odd_numbers, even_numbers, }
      #.....................................................................................................
      byline        = []
      mainline      = []
      #.....................................................................................................
      byline.push SP.$show title: 'bystream'
      byline.push SP.$watch ( d ) -> even_numbers.push d
      byline.push SP.$drain()
      bystream  = SP.pull byline...
      #.....................................................................................................
      mainline.push SP.new_value_source probe
      mainline.push SP.$bifurcate is_even, bystream
      mainline.push SP.$show title: 'mainstream'
      mainline.push SP.$watch ( d ) -> odd_numbers.push d
      mainline.push SP.$drain ->
        help 'ok'
        resolve R
      SP.pull mainline...
      #.....................................................................................................
      return null
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "wye from asnyc random sources" ] = ( T, done ) ->
  ### A mainstream and a bystream are created from lists of values using
  `SP.new_random_async_value_source()`. Values from both streams are marked up for their respective source.
  After being funnelled together using `SP.$wye()`, the result is a POD whose keys are the source names
  and whose values are lists of the values in the order they were seen. The expected result is that the
  ordering of each stream is preserved, no values get lost, and that relative ordering of values in the
  mainstream and the bystream is arbitrary. ###
  probes_and_matchers = [
    # [[[3,4,5,6,7,8],["just","a","few","words"]],{"bystream":[3,4,5,6,7,8],"mainstream":["just","a","few","words"]},null]
    # [[[3,4],[9,10,11,true]],{"bystream":[3,4],"mainstream":[9,10,11,true]},null]
    [[[3,4,{"foo":"bar"}],[false,9,10,11,true]],{"bystream":[3,4,{"foo":"bar"}],"mainstream":[false,9,10,11,true]},null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    R = { bystream: [], mainstream: [], }
    #.......................................................................................................
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      byline    = []
      byline.push SP.new_random_async_value_source 0.1, probe[ 0 ]
      byline.push $ ( d, send ) -> send [ 'bystream', d, ]
      # byline.push SP.$watch ( d ) -> debug '37333', 'bystream', xrpr d
      # byline.push $ { first: 'first', last: 'last', }, ( d, send ) ->
      #   if d in [ 'first', 'last', ] then warn    'bystream', xrpr d
      #   else                              whisper 'bystream', xrpr d
      #.....................................................................................................
      mainline = []
      mainline.push SP.new_random_async_value_source probe[ 1 ]
      mainline.push $ ( d, send ) -> send [ 'mainstream', d, ]
      mainline.push SP.$wye SP.pull byline...
      # mainline.push $ { first: 'first', last: 'last', }, ( d, send ) ->
      #   if d in [ 'first', 'last', ] then warn    'mainstream', xrpr d
      #   else                              whisper 'mainstream', xrpr d
      mainline.push SP.$watch ( d ) ->
        debug '37333', xrpr d
        R[ d[ 0 ] ].push d[ 1 ]
      mainline.push SP.$drain ->
        echo 'result:   ', xrpr R
        echo 'matcher:  ', xrpr matcher
        help 'ok'
        resolve R
      SP.pull mainline...
      #.....................................................................................................
      return null
  #.........................................................................................................
  done()
  return null


#-----------------------------------------------------------------------------------------------------------
@[ "$wye 3" ] = ( T, done ) ->
  probes_and_matchers = [
    [{"start_value":0.5,"delta":0.01,},[0.5,0.25,0.375,0.3125,0.34375,0.328125],null]
    ]
  end_sym = Symbol 'end'
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      R                   = []
      drainer             = -> debug '10191-1', "mainstream ended"; resolve R
      mainsource          = SP.new_push_source()
      bysource            = SP.new_push_source()
      #...................................................................................................
      bystream            = []
      bystream.push bysource
      bystream.push $ { last: end_sym,}, ( d, send ) ->
        if d is end_sym
          debug '22092-1', "bystream ended"
        else
          send d
        return null
      bystream.push SP.$watch ( d ) -> whisper '10191-1', 'bysource', jr d
      bystream = SP.pull bystream...
      #...................................................................................................
      mainstream          = []
      mainstream.push mainsource
      mainstream.push SP.$wye bystream
      mainstream.push SP.$async ( d, send, done ) ->
        send d
        if ( 1 / 3 - probe.delta ) <= d <= ( 1 / 3 + probe.delta )
          defer ->
            # send end_sym
            mainsource.end()
            bysource.end()
            done()
        else
          defer ->
            bysource.send ( 1 - d ) / 2
            done()
        return null
      mainstream.push SP.$defer()
      mainstream.push SP.$watch ( d ) -> urge CND.white '10191-4', 'confluence', jr d
      mainstream.push SP.$watch ( d ) -> R.push d
      mainstream.push SP.$drain drainer
      SP.pull mainstream...
      mainsource.send probe.start_value
      return null
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "$wye 4" ] = ( T, done ) ->
  probes_and_matchers = [
    [[true,true,[10,11,12,13,14,15],[20,21,22,23,24,25]],[10,11,12,13,14,15,20,21,22,23,24,25],null]
    [[false,false,[10,11,12,13,14,15],[20,21,22,23,24,25]],[10,11,12,13,14,15,20,21,22,23,24,25],null]
    [[false,true,[10,11,12,13,14,15],[20,21,22,23,24,25]],[10,11,12,13,14,15,20,21,22,23,24,25],null]
    # [[true,false,[10,11,12,13,14,15],[20,21,22,23,24,25]],[10,11,12,13,14,15,20,21,22,23,24,25],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    #.......................................................................................................
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      [ use_bystream_vs
        use_mainstream_vs
        byline_values
        mainline_values ] = probe
      R                   = []
      #.....................................................................................................
      byline              = []
      mainline            = []
      #.....................................................................................................
      byline.push ( if use_bystream_vs then SP.new_value_source else SP.new_random_async_value_source ) byline_values
      byline.push SP.$show title: 'bystream'
      bystream            = SP.pull byline...
      #.....................................................................................................
      mainline.push ( if use_mainstream_vs then SP.new_value_source else SP.new_random_async_value_source ) mainline_values
      mainline.push SP.$show title: 'mainstream'
      # mainline.push SP.$defer()
      mainline.push SP.$wye bystream
      mainline.push SP.$show title: 'confluence'
      mainline.push SP.$collect { collector: R, }
      mainline.push SP.$drain ->
        help 'ok'
        resolve R.sort()
      mainstream          = SP.pull mainline...
      #.....................................................................................................
      return null
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "$wye 5" ] = ( T, done ) ->
  ### This test uses a wye to implement a looping transform. The transform's
  byline starts with a wye whose refillable source is used to implement the
  loop. Observe that a wye cannot come first in  pipeline, so we put a `$pass()`
  transform first to satisfy that requirement. The transform will accept texts
  and pass them with as many stars as needed, one at a time, until the text's
  length is at least 5 characters. Hence, each incoming text may loop for a
  number of times: a 4-character text gets an additional `*` and doesn't loop at
  all, a single-character text gets one star and is the sent back into the
  wye,so it will loop 3 times before having grown to 5 characters. These
  different looping times mean that a new text may enter the loop before a
  previous data item has finished looping; to prevent that, a synchronizing
  stage has been implemented with a pausable transform and two gates; these are
  situated in the mainline.

  For unknown reasons, the construct does not work with
  `SP.new_random_async_value_source()`.
  ###
  probes_and_matchers = [
    [[true,false,["a","fine","day"]],["a****","fine*","day**"],null]
    [[true,true,["a","fine","day"]],["a****","fine*","day**"],null]
    # [[false,false,["a","fine","day"]],["a****","fine*","day**"],null]
    # [[false,true,["a","fine","day"]],["a****","fine*","day**"],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    #.......................................................................................................
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      [ use_mainstream_vs
        use_defer_1
        mainline_values ] = probe
      R                   = []
      #.....................................................................................................
      $process = ->
        byline      = []
        refillable  = []
        byline.push SP.$pass()
        # byline.push SP.$defer()
        byline.push SP.$wye SP.new_refillable_source refillable, { repeat: 3, show: true, }
        byline.push SP.$watch ( d ) -> info 'bystream', xrpr d
        byline.push $ ( d, send ) ->
          if d.length < 5 then refillable.push d + '*'
          else send d
          return null
        return SP.pull byline...
      #.....................................................................................................
      pausable = SP.new_pausable()
      mainline = []
      if      use_mainstream_vs then  mainline.push SP.new_value_source               mainline_values
      else                            mainline.push SP.new_random_async_value_source  mainline_values
      mainline.push SP.$show title: 'mainstream'
      mainline.push SP.$defer() if use_defer_1
      mainline.push pausable
      mainline.push SP.$watch ( d ) -> pausable.pause(); debug '37787', 'pause'
      mainline.push SP.$watch ( d ) -> urge 'mainstream 1', xrpr d
      mainline.push $process()
      mainline.push SP.$watch ( d ) -> pausable.resume(); debug '37787', 'resume'
      mainline.push SP.$watch ( d ) -> urge 'mainstream 2', xrpr d
      mainline.push SP.$collect { collector: R, }
      mainline.push SP.$drain ->
        help 'ok'
        resolve R
      mainstream          = SP.pull mainline...
      #.....................................................................................................
      return null
  #.........................................................................................................
  done()
  return null


#-----------------------------------------------------------------------------------------------------------
@[ "circular stream with wye and refillable" ] = ( T, done ) ->
  probes_and_matchers = [
    [[true,true,true,[1,]],[4],null]
    [[true,true,true,[2]],[2],null]
    [[true,true,true,[3]],[10],null]
    [[true,true,true,[1,2,3]],[2,4,10],null]
    [[true,true,true,[10,11,12,13,14,15]],[10,12,14,34,40,46],null]
    [[true,false,false,[1,]],[4],null]
    [[true,false,false,[2]],[2],null]
    [[true,false,false,[3]],[10],null]
    [[true,false,false,[1,2,3]],[2,4,10],null]
    [[true,false,false,[10,11,12,13,14,15]],[10,12,14,34,40,46],null]
    [[false,true,false,[1]],[4],null]
    [[false,true,false,[2]],[2],null]
    [[false,true,false,[3]],[10],null]
    [[false,true,false,[1,2,3]],[2,4,10],null]
    [[false,true,false,[10,11,12,13,14,15]],[10,12,14,34,40,46],null]
    [[false,false,false,[1]],[4],null]
    [[false,false,false,[2]],[2],null]
    [[false,false,false,[3]],[10],null]
    [[false,false,false,[1,2,3]],[2,4,10],null]
    [[false,false,false,[10,11,12,13,14,15]],[10,12,14,34,40,46],null]
    [[false,false,true,[1]],[4],null]
    [[false,false,true,[2]],[2],null]
    [[false,false,true,[3]],[10],null]
    [[false,false,true,[1,2,3]],[2,4,10],null]
    [[false,false,true,[10,11,12,13,14,15]],[10,12,14,34,40,46],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    #.......................................................................................................
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      [ use_defer_1
        use_defer_2
        use_defer_3
        values ]        = probe
      collector         = []
      mainline          = []
      byline            = []
      refillable        = []
      refillable_source = SP.new_refillable_source refillable, { repeat: 5, show: false, }
      #.........................................................................................................
      # pipe the second duplex stream back to itself.
      byline.push refillable_source
      # byline.push client
      byline.push SP.$defer() if use_defer_3
      byline.push $ ( d, send ) -> send d * 3 + 1
      bystream = SP.pull byline...
      #.........................................................................................................
      mainline.push SP.new_value_source values
      mainline.push SP.$defer() if use_defer_1
      mainline.push SP.$wye bystream, defer: true
      mainline.push SP.$defer() if use_defer_2
      mainline.push $ ( d, send ) ->
        if d %% 2 isnt 0 then refillable.push d
        else send d
      mainline.push SP.$collect { collector, }
      # mainline.push client
      mainline.push SP.$drain =>
        # echo xrpr collector
        resolve collector
      SP.pull mainline...
  #.........................................................................................................
  done()
  return null


############################################################################################################
unless module.parent?
  test @
  # test @, { timeout: 5000, }
  # test @[ "new_merged_source 1"             ]
  # test @[ "$wye 1"                          ]
  # test @[ "$wye 2"                          ]
  # test @[ "tee with filter"                 ]
  # test @[ "bifurcate"                       ]
  # test @[ "wye from asnyc random sources"   ]
  # test @[ "$wye 3"                          ]
  # test @[ "$wye 4"                          ]
  # test @[ "$wye 5"                          ]
  # test @[ "circular stream with wye and refillable" ]


