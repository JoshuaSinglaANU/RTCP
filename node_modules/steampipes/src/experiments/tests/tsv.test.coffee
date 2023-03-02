

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'STEAMPIPES/TESTS/TSV'
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
SP                        = require '../..'
{ $, $async, }            = SP


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
      pipeline.push SP.new_value_source probe
      # pipeline.push SP.$split()
      pipeline.push SP.$split_tsv()
      pipeline.push SP.$collect { collector: R, }
      pipeline.push SP.$show()
      pipeline.push SP.$drain -> resolve R
      SP.pull pipeline...
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
      pipeline.push SP.new_value_source probe
      pipeline.push SP.$split()
      pipeline.push SP.$split_wsv()
      pipeline.push SP.$collect { collector: R, }
      pipeline.push SP.$show()
      pipeline.push SP.$drain -> resolve R
      SP.pull pipeline...
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
      pipeline.push SP.new_value_source [ text, ]
      # pipeline.push SP.$split()
      pipeline.push SP.$split_wsv field_count
      pipeline.push SP.$show title: 'µ45456'
      pipeline.push SP.$collect { collector: R, }
      pipeline.push SP.$drain -> resolve R
      SP.pull pipeline...
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
      pipeline.push SP.new_value_source [ values, ]
      pipeline.push SP.$show()
      pipeline.push SP.$name_fields names...
      pipeline.push SP.$collect { collector: R, }
      pipeline.push SP.$drain -> resolve R
      SP.pull pipeline...
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



