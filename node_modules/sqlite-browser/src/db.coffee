

'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'SQLITE-BROWSER/DB'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
PATH                      = require 'path'
# FS                        = require 'fs'
PD                        = require 'pipedreams'
{ $
  $async
  select }                = PD
{ assign
  jr }                    = CND
{ cwd_abspath
  cwd_relpath
  here_abspath
  _drop_extension
  project_abspath }       = require './helpers'
#...........................................................................................................
join_path                 = ( P... ) -> PATH.resolve PATH.join P...
boolean_as_int            = ( x ) -> if x then 1 else 0
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }
xrpr2                     = ( x ) -> inspect x, { colors: yes, breakLength: 80,       maxArrayLength: Infinity, depth: Infinity, }
#...........................................................................................................
ICQL                      = require 'icql'


#-----------------------------------------------------------------------------------------------------------
@_get_icql_settings = ( db_path ) ->
  defaults          =
    connector:        require 'better-sqlite3' ### TAINT stopgap, will be moved into ICQL ###
    db_path:          db_path
    icql_path:        project_abspath './db/sqlite-browser.icql'
    clear:            false
  R                 = assign {}, defaults
  R.db_path         = cwd_abspath R.db_path
  R.icql_path       = cwd_abspath R.icql_path
  return R

#-----------------------------------------------------------------------------------------------------------
@new_db = ( db_path ) ->
  settings              = @_get_icql_settings db_path
  db                    = ICQL.bind settings
  @load_extensions      db
  @set_pragmas          db
  #.........................................................................................................
  if settings.clear
    clear_count = db.$.clear()
  #.........................................................................................................
  @create_db_functions  db
  return db

#-----------------------------------------------------------------------------------------------------------
@set_pragmas = ( db ) ->
  db.$.pragma 'foreign_keys = on'
  db.$.pragma 'synchronous = off' ### see https://sqlite.org/pragma.html#pragma_synchronous ###
  db.$.pragma 'journal_mode = WAL' ### see https://github.com/JoshuaWise/better-sqlite3/issues/125 ###
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@load_extensions = ( db ) ->
  return null
  # extensions_path = project_abspath './sqlite-for-mingkwai-ime/extensions'
  # debug 'µ39982', "extensions_path", extensions_path
  # db.$.load join_path extensions_path, 'spellfix.so'
  # db.$.load join_path extensions_path, 'csv.so'
  # db.$.load join_path extensions_path, 'regexp.so'
  # db.$.load join_path extensions_path, 'series.so'
  # db.$.load join_path extensions_path, 'nextchar.so'
  # # db.$.load join_path extensions_path, 'stmt.so'
  # #.........................................................................................................
  # return null

#-----------------------------------------------------------------------------------------------------------
@create_db_functions = ( db ) ->
  # db.$.function 'add_spellfix_confusable', ( a, b ) ->
  # db.$.function 'spellfix1_phonehash', ( x ) ->
  #   debug '23363', x
  #   return x.toUpperCase()

  #---------------------------------------------------------------------------------------------------------
  db.$.function 'echo', { deterministic: false, varargs: true }, ( P... ) ->
    ### Output text to command line. ###
    ### TAINT consider to use logging method to output to app console. ###
    urge ( CND.grey 'DB' ), P...
    return null

  #---------------------------------------------------------------------------------------------------------
  db.$.function 'e', { deterministic: false, varargs: false }, ( x ) ->
    ### Output text to command line, but returns single input value so can be used within an expression. ###
    urge ( CND.grey 'DB' ), rpr x
    return x

  #---------------------------------------------------------------------------------------------------------
  db.$.function 'e', { deterministic: false, varargs: false }, ( mark, x ) ->
    ### Output text to command line, but returns single input value so can be used within an expression. ###
    urge ( CND.grey "DB #{mark}" ), rpr x
    return x

  #---------------------------------------------------------------------------------------------------------
  db.$.function 'contains_word', { deterministic: true, varargs: false }, ( text, probe ) ->
    return if ( ( ' ' + text + ' ' ).indexOf ' ' + probe + ' ' ) > -1 then 1 else 0

  #---------------------------------------------------------------------------------------------------------
  db.$.function 'get_words', { deterministic: true, varargs: false }, ( text ) ->
    ### Given a text, return a JSON array with words (whitespace-separated non-empty substrings). ###
    JSON.stringify ( word for word in text.split /\s+/ when word isnt '' )

  # #---------------------------------------------------------------------------------------------------------
  # db.$.function 'vnr_encode_textual', { deterministic: true, varargs: false }, ( vnr ) ->
  #   ( ( "#{idx}".padStart 6, '0' ) for idx in ( JSON.parse vnr ) ).join '-'

  #---------------------------------------------------------------------------------------------------------
  db.$.function 'vnr_encode', { deterministic: true, varargs: false }, ( vnr ) ->
    try
      Uint32Array.from JSON.parse vnr
    catch error
      warn "µ33211 when trying to convert #{xrpr2 vnr}"
      warn "µ33211 to a typed array, an error occurred:"
      warn "µ33211 #{error.message}"
      throw error

  #---------------------------------------------------------------------------------------------------------
  return null







