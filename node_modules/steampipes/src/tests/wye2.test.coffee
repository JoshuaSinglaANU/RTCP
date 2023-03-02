

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'STEAMPIPES/TESTS/WYE2'
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
  type_of }               = require '../types'
#...........................................................................................................
SP                        = require '../..'
{ $
  $async
  $drain
  $watch
  $show  }                = SP.export()



#-----------------------------------------------------------------------------------------------------------
@[ "tentative implementation" ] = ( T, done ) ->
  [ probe, matcher, error, ] = ["abcde","(a)A(b)B(c)C(d)D(e)E",null]
  await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
    pipeline  = []
    t1        = $ ( d, send ) ->
      send d
      wye.send "(#{d})"
    wye        = SP.$pass()
    pipeline.push probe
    pipeline.push t1
    pipeline.push $ ( d, send ) -> send d.toUpperCase()
    pipeline.push wye
    pipeline.push $drain ( Σ ) -> resolve Σ.join ''
    SP.pull pipeline...
    return null
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "leapfrogging compared to wye" ] = ( T, done ) ->
  [ probe, matcher, error, ] = ["abcde","aBCdE",null]
  results = []
  #.........................................................................................................
  await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
    pipeline  = []
    pipeline.push probe
    pipeline.push $ ( d, send ) ->
      if ( d.match /a|d/ )?  then  wye.send d
      else                        send d
    pipeline.push $ ( d, send ) -> send d.toUpperCase()
    pipeline.push wye = SP.$pass()
    pipeline.push $drain ( Σ ) ->
      results.push R = Σ.join ''
      resolve R
    SP.pull pipeline...
    return null
  #.........................................................................................................
  await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
    leapfrog  = ( d ) -> ( d.match /a|d/ )?
    pipeline  = []
    pipeline.push probe
    pipeline.push $ { leapfrog, }, ( d, send ) -> send d.toUpperCase()
    pipeline.push wye = SP.$pass()
    pipeline.push $drain ( Σ ) ->
      results.push R = Σ.join ''
      resolve R
    SP.pull pipeline...
    return null
  #.........................................................................................................
  await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
    pipeline    = []
    pipeline.push probe
    # pipeline.push $show()
    pipeline.push SP.leapfrog ( ( d ) -> ( d.match /a|d/ )? ), $ ( d, send ) -> send d.toUpperCase()
    pipeline.push wye = SP.$pass()
    pipeline.push $drain ( Σ ) ->
      results.push R = Σ.join ''
      resolve R
    SP.pull pipeline...
    return null
  #.........................................................................................................
  T.eq results.length, 3
  T.eq results...
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "wye 2" ] = ( T, done ) ->
  [ probe, matcher, error, ] = ["a","[a](a)A",null]
  # [ probe, matcher, error, ] = ['abcde','A(a)B(b)C(c)D(d)E(e)',null]
  await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
    t1 = $ ( d, send ) ->
      wye.send "[#{d}]"
      wye.send "(#{d})"
      send d
    pipeline  = []
    pipeline.push probe
    pipeline.push t1
    pipeline.push $ ( d, send ) -> send d.toUpperCase()
    pipeline.push wye = SP.$pass()
    pipeline.push $drain ( Σ ) -> resolve Σ.join ''
    SP.pull pipeline...
    return null
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "wye 3" ] = ( T, done ) ->
  [ probe, matcher, error, ] = [[24],[12,6,3,10,5,16,8,4,2,1],null]
  # [ probe, matcher, error, ] = ['abcde','A(a)B(b)C(c)D(d)E(e)',null]
  await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
    source    = SP.new_push_source()
    pipeline  = []
    pipeline.push source
    # pipeline.push wye = SP.$pass()
    # pipeline.push $show()
    pipeline.push $ ( d, send ) -> send if ( d %% 2 is 0 ) then ( d / 2 ) else ( d * 3 + 1 )
    pipeline.push $show()
    pipeline.push $ ( d, send ) -> send d; if ( d is 1 ) then source.end() else source.send d
    pipeline.push $drain ( Σ ) -> resolve Σ
    SP.pull pipeline...
    source.send d for d in probe
    return null
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "wye construction (sync)" ] = ( T, done ) ->
  probes_and_matchers = [
    [["abc","UVWXYZ"],"abcUVWXYZ",null]
    ]
  for [ [ probe_A, probe_B, ], matcher, error, ] in probes_and_matchers
    await T.perform [ probe_A, probe_B, ], matcher, error, -> return new Promise ( resolve, reject ) ->
      # wye         = SP.new_wye()
      last        = Symbol 'last'
      #.....................................................................................................
      source_A    = probe_A
      A_has_ended = false
      B_has_ended = false
      pipeline_A  = []
      pipeline_A.push source_A
      pipeline_A.push $watch ( d ) -> help 'A', jr d
      pipeline_A.push $ { last, }, ( d, send ) ->
        if d is last
          A_has_ended = true
          return end_source_C()
        source_C.send d
      pipeline_A.push $drain -> whisper 'A'
      #.....................................................................................................
      source_B    = probe_B
      pipeline_B  = []
      pipeline_B.push source_B
      pipeline_B.push $watch ( d ) -> urge 'B', jr d
      pipeline_B.push $ { last, }, ( d, send ) ->
        if d is last
          B_has_ended = true
          return end_source_C()
        source_C.send d
      pipeline_B.push $drain -> whisper 'B'
      #.....................................................................................................
      source_C    = SP.new_push_source()
      pipeline_C  = []
      pipeline_C.push source_C
      pipeline_C.push $watch ( d ) -> info 'C', jr d
      pipeline_C.push $drain ( Σ ) ->
        whisper 'C', jr Σ
        resolve Σ.join ''
      #.....................................................................................................
      end_source_C = ->
        return unless ( A_has_ended and B_has_ended )
        source_C.end()
      #.....................................................................................................
      # pipeline_A.push wye
      duct_C  = SP.pull pipeline_C...
      duct_A  = SP.pull pipeline_A...
      duct_B  = SP.pull pipeline_B...
      return null
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "wye construction (async)" ] = ( T, done ) ->
  probes_and_matchers = [
    [["abc","UVWXYZ"],"aUbVcWXYZ",null]
    ]
  for [ [ probe_A, probe_B, ], matcher, error, ] in probes_and_matchers
    await T.perform [ probe_A, probe_B, ], matcher, error, -> return new Promise ( resolve, reject ) ->
      # wye         = SP.new_wye()
      last        = Symbol 'last'
      #.....................................................................................................
      source_A    = probe_A
      A_has_ended = false
      B_has_ended = false
      pipeline_A  = []
      pipeline_A.push source_A
      pipeline_A.push $watch ( d ) -> help 'A', jr d
      pipeline_A.push $async ( d, send, done ) -> source_C.send d; done()
      pipeline_A.push $ { last, }, ( d, send ) -> return unless d is last; A_has_ended = true; end_source_C()
      pipeline_A.push $drain -> whisper 'A'
      #.....................................................................................................
      source_B    = probe_B
      pipeline_B  = []
      pipeline_B.push source_B
      pipeline_B.push $watch ( d ) -> urge 'B', jr d
      pipeline_B.push $async ( d, send, done ) -> source_C.send d; done()
      pipeline_B.push $ { last, }, ( d, send ) -> return unless d is last; B_has_ended = true; end_source_C()
      pipeline_B.push $drain -> whisper 'B'
      #.....................................................................................................
      source_C    = SP.new_push_source()
      pipeline_C  = []
      pipeline_C.push source_C
      pipeline_C.push $watch ( d ) -> info 'C', jr d
      pipeline_C.push $drain ( Σ ) ->
        whisper 'C', jr Σ
        resolve Σ.join ''
      #.....................................................................................................
      end_source_C = ->
        return unless ( A_has_ended and B_has_ended )
        source_C.end()
      #.....................................................................................................
      # pipeline_A.push wye
      duct_C  = SP.pull pipeline_C...
      duct_A  = SP.pull pipeline_A...
      duct_B  = SP.pull pipeline_B...
      return null
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "wye construction (source, transform, drain ducts)" ] = ( T, done ) ->
  await T.perform null, null, null, -> return new Promise ( resolve, reject ) ->
    #.......................................................................................................
    pipeline    = []
    pipeline.push 'abc'
    pipeline.push $watch ( d ) -> help 'A', jr d
    pipeline.push SP.new_wye 'UVW'
    pipeline.push $watch ( d ) -> urge 'AB', jr d
    SP.pull pipeline...
    resolve null
  #.........................................................................................................
  await T.perform null, null, null, -> return new Promise ( resolve, reject ) ->
    #.......................................................................................................
    pipeline    = []
    pipeline.push $watch ( d ) -> help 'A', jr d
    pipeline.push SP.new_wye 'UVW'
    pipeline.push $watch ( d ) -> urge 'AB', jr d
    SP.pull pipeline...
    resolve null
  #.........................................................................................................
  await T.perform null, null, null, -> return new Promise ( resolve, reject ) ->
    #.......................................................................................................
    pipeline    = []
    pipeline.push $watch ( d ) -> help 'A', jr d
    pipeline.push SP.new_wye 'UVW'
    pipeline.push $watch ( d ) -> urge 'AB', jr d
    pipeline.push $drain ->
    SP.pull pipeline...
    resolve null
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "wye construction (method)" ] = ( T, done ) ->
  probes_and_matchers = [
    [["abc","UVWXYZ"],"abcUVWXYZ",null]
    ]
  for [ [ probe_A, probe_B, ], matcher, error, ] in probes_and_matchers
    await T.perform [ probe_A, probe_B, ], matcher, error, -> return new Promise ( resolve, reject ) ->
      # wye         = SP.new_wye()
      #.....................................................................................................
      source_A    = probe_A
      source_B    = probe_B
      pipeline    = []
      pipeline.push source_A
      pipeline.push $watch ( d ) -> help 'A', jr d
      pipeline.push SP.new_wye source_B
      pipeline.push $watch ( d ) -> urge 'AB', jr d
      pipeline.push $drain ( Σ ) ->
        whisper 'AB', jr Σ
        resolve Σ.join ''
      SP.pull pipeline...
      return null
  #.........................................................................................................
  done()
  return null


############################################################################################################
if module is require.main then do => # await do =>
  test @, 'timeout': 30000
  # test @[ "leapfrogging compared to wye" ]
  # test @[ "wye construction (sync)" ]
  # test @[ "wye construction (async)" ]
  # test @[ "wye construction (method)" ]
  # test @[ "wye construction (source, transform, drain ducts)" ]







