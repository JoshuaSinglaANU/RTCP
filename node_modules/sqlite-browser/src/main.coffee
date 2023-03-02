
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'SQLITE-BROWSER/MAIN'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
{ assign
  jr }                    = CND
#...........................................................................................................
require './exception-handler'
types                     = require './types'
{ isa
  validate
  type_of }               = types
FS                        = require 'fs'
PATH                      = require 'path'
# glob                      = require 'glob'
# minimatch                 = require 'minimatch'
PD                        = require 'pipedreams'
{ $
  $async
  select }                = PD
#...........................................................................................................
PSPG                      = require 'pspg'
DB                        = require './db'

#-----------------------------------------------------------------------------------------------------------
_$count = ( step ) ->
  nr = 0
  return PD.$watch ( d ) =>
    nr += +1
    if ( nr %% step ) is 0
      whisper 'µ44744', nr
    return null

#-----------------------------------------------------------------------------------------------------------
@browse = ( db_path, key, value ) -> new Promise ( resolve, reject ) =>
  # validate.sqlb_settings settings
  throw new Error "µ33221 Error" unless key is 'c'
  validate.nonempty_text value
  S       = {}
  S.db    = DB.new_db db_path
  sql     = value
  source  = PD.new_generator_source S.db.$.query sql
  #.........................................................................................................
  pipeline = []
  pipeline.push source
  pipeline.push _$count 100
  ### TAINT resolve may be called twice ###
  # pipeline.push PD.$sort()                          if testing
  pipeline.push PSPG.$tee_as_table -> resolve()
  ### TAINT resolve may be called before tee has finished writing (?) ###
  pipeline.push PD.$drain()
  PD.pull pipeline...
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@cli = ( db_path, key, value ) ->
  #.......................................................................................................
  validate.sqlb_db_path db_path
  validate.sqlb_key     key
  # debug 'µ33444', arguments
  # debug 'µ33444', "running #{__filename} #{jr [ db_path, key, value, ]}"
  await @browse db_path, key, value
  # settings = L.new_settings './README.md'
  # db_path = PATH.resolve '/home/flow/jzr/mkts-mirage/db/mkts.db'
  # await L.browse db_path, 'c', "select * from main;"
  # help 'ok'


############################################################################################################
unless module.parent?
  testing = true
  L = @
  do ->
    await L.cli process.argv[ 2 .. ]...
    help 'ok'


