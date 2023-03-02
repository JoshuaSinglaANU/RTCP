

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'INTERCOURSE/EXPERIMENTS/DEMO-PARTITION'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
jr                        = JSON.stringify
IC                        = require '../..'
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }
xrpr2                     = ( x ) -> inspect x, { colors: yes, breakLength: 20, maxArrayLength: Infinity, depth: Infinity, }
#...........................................................................................................
PD                        = require 'pipedreams'
{ $
  $async
  select }                = PD
#...........................................................................................................
types                     = require '../types'
{ isa
  validate
  declare
  size_of
  type_of }               = types

# #-----------------------------------------------------------------------------------------------------------
# get_partitioner = ->
#   pipeline = []
#   pipeline.push
#   return ( text ) =>
#     source.send


#-----------------------------------------------------------------------------------------------------------
partition = ( S ) ->
  text = """
    -- Select a number:
    select 42;
    -- Select something else:
    select x from sometable
      order by id;
    update sometable
      set frob = frob + 1
      where id = $baz;
  """
  R     = []
  part  = null
  for line in text.split /\n/
    continue if ( line.match S.comments )?
    # part ?= []
    debug part
    if ( line.match /^\S/ )?
      R.push ( part.join '\n' ) if part?
      part = []
    part.push line
  R.push ( part.join '\n' ) if part?
  return R

#-----------------------------------------------------------------------------------------------------------
demo = ->
  source = """
  -- -------------------------------------------------------------------------------------------------------
  procedure foobar( baz ):
    -- Select a number:
    select 42;
    -- Select something else:
    select x from sometable
      order by id;
    update sometable
      set frob = frob + 1
      where id = $baz;
  """
  source = "procedure x:\n  foo bar"
  definitions = IC.definitions_from_text source
  for key, entry of definitions
    # debug 'µ44452', entry
    # debug 'µ44452', entry.type
    validate.ic_toplevel_entry entry
    for kenning, signature_entry of entry
      continue unless isa.ic_kenning kenning
      urge 'µ44433', signature_entry
      # validate.ic_prepartition_signature_entry signature_entry
      validate.ic_signature_entry signature_entry

############################################################################################################
unless module.parent?
  demo()
  # urge partition { partition: 'indent', comments: /^--/, }

