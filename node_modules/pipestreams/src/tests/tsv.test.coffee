

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/TESTS/TSV'
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
@[ "TSV 1" ] = ( T, done ) ->
  probes_and_matchers = [
    ["foo\tbar",[['foo','bar']],null]
    [" foo \t bar ",[['foo','bar']],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, => new Promise ( resolve, reject ) =>
      R         = []
      pipeline  = []
      pipeline.push PS.new_value_source probe
      # pipeline.push PS.$split()
      pipeline.push PS.$split_tsv()
      pipeline.push PS.$collect { collector: R, }
      pipeline.push PS.$show()
      pipeline.push PS.$drain -> resolve R
      PS.pull pipeline...
      return null
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "WSV 1" ] = ( T, done ) ->
  probes_and_matchers = [
    ["foo bar",[['foo','bar']],null]
    [" foo   bar ",[[null,'foo','bar']],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, => new Promise ( resolve, reject ) =>
      R         = []
      pipeline  = []
      pipeline.push PS.new_value_source probe
      pipeline.push PS.$split()
      pipeline.push PS.$split_wsv()
      pipeline.push PS.$collect { collector: R, }
      pipeline.push PS.$show()
      pipeline.push PS.$drain -> resolve R
      PS.pull pipeline...
      return null
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "WSV 2" ] = ( T, done ) ->
  probes_and_matchers = [
    [["foo bar baz another field",null],[["foo","bar","baz","another","field"]],null]
    [["foo bar baz another field",1],[['foo bar baz another field']],null]
    [[" foo bar baz another field",6],[[null,'foo','bar','baz', 'another', 'field']],null]
    [["foo",2],[['foo',null]],null]
    [["foo",null],[['foo']],null]
    [[" foo bar baz another field",null],[[null,'foo','bar','baz', 'another', 'field']],null]
    [["foo  ",2],[['foo',null]],null]
    [["foo  ",3],[['foo',null,null]],null]
    [["foo  ",null],[['foo']],null]
    [["foo bar baz another field",null],[['foo','bar','baz', 'another', 'field']],null]

    [["foo bar baz another field",2],[['foo','bar baz another field']],null]
    [["foo bar baz another field",3],[['foo','bar','baz another field']],null]
    [["foo bar baz another field",4],[['foo','bar','baz', 'another field']],null]
    [["foo bar baz another field",5],[['foo','bar','baz', 'another', 'field']],null]
    [["foo bar baz another field",6],[['foo','bar','baz', 'another', 'field',null]],null]
    [["foo bar baz another field",7],[['foo','bar','baz', 'another', 'field',null,null]],null]

    [["⺮ ⺮ [zhu2] /\"bamboo\" radical in Chinese characters (Kangxi radical 118)/\r",4],[["⺮","⺮","[zhu2]","/\"bamboo\" radical in Chinese characters (Kangxi radical 118)/"]],null]
    [["% % [pa1] /percent (Tw)/\r",4],[["%","%","[pa1]","/percent (Tw)/"]],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, => new Promise ( resolve, reject ) =>
      [ text, field_count, ]  = probe
      R                       = []
      pipeline                = []
      pipeline.push PS.new_value_source [ text, ]
      # pipeline.push PS.$split()
      pipeline.push PS.$split_wsv field_count
      pipeline.push PS.$show title: 'µ45456'
      pipeline.push PS.$collect { collector: R, }
      pipeline.push PS.$drain -> resolve R
      PS.pull pipeline...
      return null
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "name_fields" ] = ( T, done ) ->
  probes_and_matchers = [
    [[[42,108],[['foo','bar']]],[{foo:42,bar:108,}],null]
    [[[42,108],['foo','bar']],[{foo:42,bar:108,}],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, => new Promise ( resolve, reject ) =>
      [ values, names, ]  = probe
      debug 'µ33443', probe
      debug 'µ33443', values
      debug 'µ33443', names
      R                   = []
      pipeline            = []
      pipeline.push PS.new_value_source [ values, ]
      pipeline.push PS.$show()
      pipeline.push PS.$name_fields names...
      pipeline.push PS.$collect { collector: R, }
      pipeline.push PS.$drain -> resolve R
      PS.pull pipeline...
      return null
  done()
  return null


############################################################################################################
unless module.parent?
  # test @
  # test @[ "TSV 1" ]
  # test @[ "WSV 1" ]
  # test @[ "WSV 2" ]
  test @[ "name_fields" ]



