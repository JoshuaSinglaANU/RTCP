



'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'STEAMPIPES/TESTS/NJS-STREAMS-AND-FILES'
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
{ jr }                    = CND
#...........................................................................................................
SP                        = require '../..'
{ $
  $async
  $watch
  $show  }                = SP.export()
defer                     = setImmediate
types                     = require '../types'
{ isa
  validate
  type_of }               = types

#-----------------------------------------------------------------------------------------------------------
@[ "write to file sync" ] = ( T, done ) ->
  ### TAINT use proper tmpfile ###
  path      = '/tmp/steampipes-testfile.txt'
  FS.unlinkSync path if FS.existsSync path
  probe     = "just a bunch of words really".split /\s+/
  matcher   = null
  error     = null
  await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
    R           = []
    source      = probe
    #.......................................................................................................
    pipeline    = []
    pipeline.push source
    pipeline.push $ ( d, send ) -> send d + '\n'
    pipeline.push $watch ( d ) -> info 'mainline', jr d
    # pipeline.push SP.tee_write_to_file path
    pipeline.push SP.tee_write_to_file_sync path
    pipeline.push SP.$drain ( sink ) ->
      matcher = sink.join ''
      if FS.existsSync path then  result  = FS.readFileSync path, { encoding: 'utf-8', }
      else                        result  = null
      # urge 'µ77655', ( jr result ), ( jr matcher )
      T.eq result, matcher
      help 'ok'
      resolve null
    SP.pull pipeline...
    return null
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "read_from_file" ] = ( T, done ) ->
  ### TAINT use proper tmpfile ###
  path      = __filename
  probe     = null
  matcher   = null
  error     = null
  sink      = []
  matcher   = FS.readFileSync path, { encoding: 'utf-8', }
  #.......................................................................................................
  pipeline = []
  pipeline.push SP.read_from_file path, 10
  pipeline.push $show { title: 'µ33321', }
  pipeline.push SP.$drain ( sink ) ->
    result  = ( Buffer.concat sink ).toString 'utf-8'
    T.eq result, matcher
    help 'ok'
    done()
  SP.pull pipeline...
  return null

#-----------------------------------------------------------------------------------------------------------
_as_chunked_buffers = ( text, size ) ->
  validate.text text
  validate.positive_integer size
  R       = []
  buffer  = Buffer.from text
  for idx in [ 0 ... buffer.length ] by size
    R.push buffer.slice idx, idx + size
  return R

#-----------------------------------------------------------------------------------------------------------
@[ "$split" ] = ( T, done ) ->
  ### TAINT use proper tmpfile ###
  path      = __filename
  probes_and_matchers = [
    [[ """A text that\nextends over several lines\näöüÄÖÜß""", '\n'],null,null]
    [[ """A text that\nextends over several lines\näöüÄÖÜß""", 'ä'],null,null]
    [[ """A text that\nextends over several lines\näöüÄÖÜß""", 'ö'],null,null]
    ]
  for [ probe, matcher, error, ] in probes_and_matchers
    [ text
      splitter ]  = probe
    matcher       = text.split splitter
    await T.perform [ text, splitter, ], matcher, error, => return new Promise ( resolve, reject ) =>
      values        = _as_chunked_buffers text, 3
      pipeline      = []
      pipeline.push values
      pipeline.push SP.$split splitter
      pipeline.push $watch ( d ) -> info jr d
      # pipeline.push SP.tee_write_to_file path
      pipeline.push SP.$drain ( result ) -> resolve result
      SP.pull pipeline...
      return null
  #.........................................................................................................
  done()
  return null


#-----------------------------------------------------------------------------------------------------------
@[ "demo" ] = ( T, done ) ->
  probe       = ''
  probe      += '[["白金ごるふ場","しろがねごるふじょう","白金ゴルフ場 [しろがねゴルフじょう] /Shirogane golf links (p)/"],'
  probe      += '["白金だむ","しろがねだむ","白金ダム [しろがねダム] /Shirogane dam (p)/"],'
  probe      += '["白金郁夫","しらかねいくお","Shirakane Ikuo (h)"],'
  probe      += '["白金温泉","しろがねおんせん","Shiroganeonsen (p)"],'
  probe      += '["白金橋","しろがねばし","Shiroganebashi (p)"],'
  probe      += '["白金原","しらかねばる","Shirakanebaru (p)"],'
  probe      += '["白金高輪駅","しろかねたかなわえき","Shirokanetakanawa Station (st)"],'
  probe      += '["白金山","しらかねやま","Shirakaneyama (u)"],'
  probe      += '["白金川","しろがねがわ","Shiroganegawa (u)"],'
  probe      += '["奉輔","ともすけ","Tomosuke (u)"],'
  probe      += '["奉免","ほうめ","Houme (p)"],'
  probe      += '["奉免","ほうめん","Houmen (p)"],'
  probe      += '["奉免町","ほうめんまち","Houmenmachi (p)"],'
  probe      += '["奉雄","ともお","Tomoo (g)"],'
  probe      += '["奉養","ほうよう","Houyou (s)"],'
  probe      += '["奉廣","ともひろ","Tomohiro (g)"],'
  probe      += '["奉鉉","ほうげん","Hougen (g)"],'
  probe      += '["宝","たから","Takara (s,m,f)"],'
  probe      += '["宝","たからさき","Takarasaki (s)"],'
  probe      += '["宝","とみ","Tomi (s)"],'
  probe      += '["宝","ひじり","Hijiri (f)"],'
  probe      += '["宝","みち","Michi (f)"],'
  probe      += '["宝が丘","たからがおか","Takaragaoka (p)"],'
  probe      += '["宝が池","たからがいけ","Takaragaike (p)"],'
  probe      += '["宝とも子","たからともこ","Takara Tomoko (1921.9.23-2001.8.2) (h)"],'
  probe      += '["宝の草池","たからのくさいけ","Takaranokusaike (p)"]]'
  matcher     = probe
  error       = null
  await T.perform probe, matcher, error, => return new Promise ( resolve, reject ) =>
    source    = _as_chunked_buffers probe, 10
    splitter  = '"],["'
    pipeline  = []
    # pipeline.push SP.read_from_file path, 10
    pipeline.push source
    pipeline.push SP.$split splitter
    pipeline.push $ ( d, send ) ->
      ### TAINT need only be done on first, last datom ###
      d = d.replace /^\[+"/, ''
      d = d.replace /"\]+$/, ''
      send d
    pipeline.push $ ( d, send ) -> send JSON.parse '["' + d + '"]'
    # pipeline.push $watch ( d ) -> info jr d
    pipeline.push SP.$drain ( sink ) ->
      # debug rpr jr sink
      resolve jr sink
    SP.pull pipeline...
  done()
  return null


############################################################################################################
unless module.parent?
  test @, 'timeout': 30000
  # test @[ "read_from_file" ]
  # test @[ "$split" ]




