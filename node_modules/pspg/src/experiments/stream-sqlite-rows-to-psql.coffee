

'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'MKTS-PARSER/TEXT-TO-TABLE'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
warn "this module not yet ready"
process.exit 1

FS                        = require 'fs'
PATH                      = require 'path'
PD                        = require 'pipedreams'
{ $
  $async
  select }                = PD
{ assign
  jr }                    = CND
@_drop_extension          = ( path ) -> path[ ... path.length - ( PATH.extname path ).length ]
types                     = require './types'
#...........................................................................................................
{ isa
  validate
  declare
  size_of
  type_of }               = types
#...........................................................................................................
{ assign
  abspath
  relpath }               = require '../helpers'
#...........................................................................................................
require                   '../exception-handler'
PSPG                      = require '../..'

#-----------------------------------------------------------------------------------------------------------
_$count = ( step ) ->
  nr = 0
  return PD.$watch ( d ) =>
    nr += +1
    if ( nr %% step ) is 0
      whisper 'µ44744', nr
    return null

#-----------------------------------------------------------------------------------------------------------
@show_mkts_document = ( settings ) -> new Promise ( resolve, reject ) =>
  validate.object settings
  S       = settings
  source  = PD.new_generator_source S.db.read_lines()
  #.........................................................................................................
  pipeline = []
  pipeline.push source
  pipeline.push _$count 5000
  ### TAINT resolve may be called twice ###
  # pipeline.push PD.$sort()                          if testing
  pipeline.push PSPG.$tee_as_table -> resolve()
  ### TAINT resolve may be called before tee has finished writing (?) ###
  pipeline.push PD.$drain()
  PD.pull pipeline...
  #.........................................................................................................
  return null



############################################################################################################
unless module.parent?
  testing = true
  L = @
  do ->
    #.......................................................................................................
    # settings = L.new_settings './README.md'
    settings = L.new_settings '/media/flow/kamakura/home/flow/io/mingkwai-rack/jizura-datasources/data/flat-files/shape/shape-breakdown-formula-v2.txt'
    await L.write_sql_cache     settings
    await L.populate_db         settings
    await L.cleanup             settings
    # await L.show_mkts_document  settings
    delete settings.db
    debug 'µ69688', settings
    help 'ok'


