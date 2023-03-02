

'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'ICQL/MAIN'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
# PATH                      = require 'path'
# PD                        = require 'pipedreams'
# { $
#   $async
#   select }                = PD
{ assign
  jr }                    = CND
# #...........................................................................................................
# join_path                 = ( P... ) -> PATH.resolve PATH.join P...
# boolean_as_int            = ( x ) -> if x then 1 else 0
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }
#...........................................................................................................
FS                        = require 'fs'
IC                        = require 'intercourse'
@HOLLERITH                = HOLLERITH = require 'hollerith-codec'
#...........................................................................................................
@types                    = require './types'
{ isa
  validate
  declare
  size_of
  type_of }               = @types
max_excerpt_length        = 10000
LFT                       = require 'letsfreezethat'


#===========================================================================================================
# LOCAL METHODS
#-----------------------------------------------------------------------------------------------------------
@_local_methods =

  #---------------------------------------------------------------------------------------------------------
  _statements: {}

  #---------------------------------------------------------------------------------------------------------
  _echo: ( ref, sql ) ->
    return null unless @settings.echo
    echo ( CND.reverse CND.blue "^icql@888-#{ref}^" ) + ( CND.reverse CND.yellow sql )
    return null

  #---------------------------------------------------------------------------------------------------------
  limit: ( n, iterator ) ->
    count = 0
    for x from iterator
      return if count >= n
      count += +1
      yield x
    return

  #---------------------------------------------------------------------------------------------------------
  single_row:   ( iterator ) ->
    throw new Error "µ33833 expected at least one row, got none" if ( R = @first_row iterator ) is undefined
    return R

  #---------------------------------------------------------------------------------------------------------
  all_first_values: ( iterator ) ->
    R = []
    for row from iterator
      for key, value of row
        R.push value
        break
    return R

  #---------------------------------------------------------------------------------------------------------
  first_values: ( iterator ) ->
    R = []
    for row from iterator
      for key, value of row
        yield value
    return R

  #---------------------------------------------------------------------------------------------------------
  first_row:    ( iterator  ) -> return row for row from iterator
  ### TAINT must ensure order of keys in row is same as order of fields in query ###
  single_value: ( iterator  ) -> return value for key, value of @single_row iterator
  first_value:  ( iterator  ) -> return value for key, value of @first_row iterator
  all_rows:     ( iterator  ) -> [ iterator..., ]

  #---------------------------------------------------------------------------------------------------------
  query: ( sql, P... ) ->
    @_echo '1', sql
    statement = ( @_statements[ sql ] ?= @db.prepare sql )
    return statement.iterate P...

  #---------------------------------------------------------------------------------------------------------
  run: ( sql, P... ) ->
    @_echo '2', sql
    statement = ( @_statements[ sql ] ?= @db.prepare sql )
    return statement.run P...

  #---------------------------------------------------------------------------------------------------------
  _run_or_query: ( entry_type, is_last, sql, Q ) ->
    @_echo '3', sql
    statement     = ( @_statements[ sql ] ?= @db.prepare sql )
    returns_data  = statement.reader
    #.......................................................................................................
    ### Always use `run()` method if statement does not return data: ###
    unless returns_data
      return if Q? then ( statement.run Q ) else statement.run()
    #.......................................................................................................
    ### If statement does return data, consume iterator unless this is the last statement: ###
    if ( entry_type is 'procedure' ) or ( not is_last )
      return if Q? then ( statement.all Q ) else statement.all()
    #.......................................................................................................
    ### Return iterator: ###
    return if Q? then ( statement.iterate Q ) else statement.iterate()

  #---------------------------------------------------------------------------------------------------------
  execute: ( sql  ) ->
    @_echo '4', sql
    return @db.exec sql

  #---------------------------------------------------------------------------------------------------------
  prepare:        ( P...  ) -> @db.prepare          P...
  aggregate:      ( P...  ) -> @db.aggregate        P...
  backup:         ( P...  ) -> @db.backup           P...
  checkpoint:     ( P...  ) -> @db.checkpoint       P...
  close:          ( P...  ) -> @db.close            P...
  read:           ( path  ) -> @db.exec FS.readFileSync path, { encoding: 'utf-8', }
  function:       ( P...  ) -> @db.function         P...
  load:           ( P...  ) -> @db.loadExtension    P...
  pragma:         ( P...  ) -> @db.pragma           P...
  transaction:    ( P...  ) -> @db.transaction      P...

  #---------------------------------------------------------------------------------------------------------
  catalog: ->
    ### TAINT kludge: we sort by descending types so views, tables come before indexes (b/c you can't drop a
    primary key index in SQLite) ###
    # throw new Error "µ45222 deprecated until next major version"
    @query "select * from sqlite_master order by type desc, name;"

  #---------------------------------------------------------------------------------------------------------
  list_objects: ( schema = 'main' ) ->
    validate.ic_schema schema
    return @all_rows @query """
      select
          type      as type,
          name      as name,
          sql       as sql
        from #{@as_identifier schema}.sqlite_master
        order by type desc, name;"""

  #---------------------------------------------------------------------------------------------------------
  list_schemas:       -> @pragma "database_list;"
  list_schema_names:  -> new Set ( d.name for d in @list_schemas() )

  #---------------------------------------------------------------------------------------------------------
  ### TAINT must escape path, schema ###
  attach: ( path, schema ) ->
    validate.ic_path path
    validate.ic_schema schema
    return @execute "attach #{@as_sql path} as #{@as_identifier schema};"

  #-----------------------------------------------------------------------------------------------------------
  copy_schema: ( from_schema, to_schema ) ->
    schemas       = @list_schema_names()
    inserts       = []
    validate.ic_schema from_schema
    validate.ic_schema to_schema
    throw new Error "µ57873 unknown schema #{rpr from_schema}" unless schemas.has from_schema
    throw new Error "µ57873 unknown schema #{rpr to_schema}"   unless schemas.has to_schema
    @pragma "#{@as_identifier to_schema}.foreign_keys = off;"
    to_schema_x   = @as_identifier to_schema
    from_schema_x = @as_identifier from_schema
    #.......................................................................................................
    for d in @list_objects from_schema
      debug '^44463^', "DB object:", d if @settings.verbose
      continue if ( not d.sql? ) or ( d.sql is '' )
      continue if d.name in [ 'sqlite_sequence', ]
      #.....................................................................................................
      ### TAINT consider to use `validate.ic_db_object_type` ###
      unless d.type in [ 'table', 'view', 'index', ]
        throw new Error "µ49888 unknown type #{rpr d.type} for DB object #{rpr d}"
      #.....................................................................................................
      ### TAINT using not-so reliable string replacement as substitute for proper parsing ###
      name_x  = @as_identifier d.name
      sql     = d.sql.replace /\s*CREATE\s*(TABLE|INDEX|VIEW)\s*/i, "create #{d.type} #{to_schema_x}."
      #.....................................................................................................
      if sql is d.sql
        throw new Error "µ49889 unexpected SQL string #{rpr d.sql}"
      #.....................................................................................................
      @execute sql
      if d.type is 'table'
        inserts.push "insert into #{to_schema_x}.#{name_x} select * from #{from_schema_x}.#{name_x};"
    #.......................................................................................................
    if @settings.verbose
      debug '^49864^', "starting with inserts"
      debug '^49864^', "objects in #{rpr from_schema}: #{rpr ( "(#{d.type})#{d.name}" for d in @list_objects from_schema ).join ', '}"
      debug '^49864^', "objects in #{rpr to_schema}:   #{rpr ( "(#{d.type})#{d.name}" for d in @list_objects to_schema ).join ', '}"
    #.......................................................................................................
    @execute sql for sql in inserts
    @pragma "#{@as_identifier to_schema}.foreign_keys = on;"
    @pragma "#{@as_identifier to_schema}.foreign_key_check;"
    return null

  #---------------------------------------------------------------------------------------------------------
  type_of: ( name, schema = 'main' ) ->
    for row from @catalog()
      return row.type if row.name is name
    return null

  #---------------------------------------------------------------------------------------------------------
  column_types: ( table ) ->
    R = {}
    ### TAINT we apparently have to call the pragma in this roundabout fashion since SQLite refuses to
    accept placeholders in that statement: ###
    for row from @query @interpolate "pragma table_info( $table );", { table, }
      R[ row.name ] = row.type
    return R

  #---------------------------------------------------------------------------------------------------------
  _dependencies_of: ( table, schema = 'main' ) ->
    return @query "pragma #{@as_identifier schema}.foreign_key_list( #{@as_identifier table} )"

  #---------------------------------------------------------------------------------------------------------
  dependencies_of:  ( table, schema = 'main' ) ->
    validate.ic_schema schema
    return ( row.table for row from @_dependencies_of table )

  #---------------------------------------------------------------------------------------------------------
  get_toposort: ( schema = 'main' ) ->
    LTSORT  = require 'ltsort'
    g       = LTSORT.new_graph()
    indexes = []
    types   = {}
    sqls    = {}
    for x from @list_objects schema
      types[ x.name ] = x.type
      sqls[  x.name ] = x.sql
      unless x.type is 'table'
        indexes.push x.name
        continue
      dependencies = @dependencies_of x.name
      if dependencies.length is 0
        LTSORT.add g, x.name
      else
        for dependency in dependencies
          LTSORT.add g, x.name, dependency
    R = [ ( LTSORT.linearize g )..., indexes..., ]
    return ( { name, type: types[ name ], sql: sqls[ name ] } for name in R )

  #---------------------------------------------------------------------------------------------------------
  clear: ->
    count = 0
    for { type, name, } in @get_toposort()
      statement = "drop #{type} if exists #{@as_identifier name};"
      @execute statement
      count += +1
    return count

  #---------------------------------------------------------------------------------------------------------
  as_identifier:  ( text  ) -> '"' + ( text.replace /"/g, '""' ) + '"'
  # as_identifier:  ( text  ) -> '[' + ( text.replace /\]/g, ']]' ) + ']'

  #---------------------------------------------------------------------------------------------------------
  escape_text: ( x ) ->
    validate.text x
    x.replace /'/g, "''"

  #---------------------------------------------------------------------------------------------------------
  list_as_json: ( x ) ->
    validate.list x
    return jr x

  #---------------------------------------------------------------------------------------------------------
  as_sql: ( x ) ->
    switch type = type_of x
      when 'text'     then return "'#{@escape_text x}'"
      when 'list'     then return "'#{@list_as_json x}'"
      when 'float'    then return x.toString()
      when 'boolean'  then return ( if x then '1' else '0' )
      when 'null'     then return 'null'
      when 'undefined'
        throw new Error "µ12341 unable to express 'undefined' as SQL literal"
    throw new Error "µ12342 unable to express a #{type} as SQL literal, got #{rpr x}"

  #---------------------------------------------------------------------------------------------------------
  interpolate: ( sql, Q ) ->
    return sql.replace @_interpolation_pattern, ( $0, $1 ) =>
      try
        return @as_sql Q[ $1 ]
      catch error
        throw new Error \
          "µ55563 when trying to express placeholder #{rpr $1} as SQL literal, an error occurred: #{rpr error.message}"
  _interpolation_pattern: /// \$ (?: ( .+? ) \b | \{ ( [^}]+ ) \} ) ///g

  #---------------------------------------------------------------------------------------------------------
  as_hollerith:   ( x ) -> HOLLERITH.encode x
  from_hollerith: ( x ) -> HOLLERITH.decode x


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@bind = ( settings ) ->
  validate.icql_settings settings
  me            = { $: { settings, }, }
  connector     = settings.connector ? require 'better-sqlite3'
  me.icql_path  = settings.icql_path
  @connect                    me, connector, settings.db_path, settings.db_settings
  @definitions_from_path_sync me, settings.icql_path
  @bind_definitions           me
  @bind_udfs                  me
  return me

#-----------------------------------------------------------------------------------------------------------
### TAINT should check connector API compatibility ###
### TAINT consider to use `new`-less call convention (should be possible acc. to bsql3 docs) ###
@connect = ( me, connector, db_path, db_settings = {} ) ->
  me.$     ?= {}
  me.$.db   = new connector db_path, db_settings
  # me.$.dbr  = me.$.db
  # me.$.dbw  = new connector db_path, db_settings
  return me

#-----------------------------------------------------------------------------------------------------------
@definitions_from_path_sync = ( me, icql_path ) ->
  ( me.$ ?= {} ).sql = IC.definitions_from_path_sync icql_path
  return me

#-----------------------------------------------------------------------------------------------------------
@bind_definitions = ( me ) ->
  check_unique = ( name ) ->
    throw new Error "µ11292 name collision: #{rpr name} already defined" if me[ name ]?
  me.$ ?= {}
  #.........................................................................................................
  ### TAINT use `new` ###
  for name, local_method of LFT._deep_copy @_local_methods
    do ( name, local_method ) ->
      check_unique name
      if ( isa.function local_method )
        local_method  = local_method.bind me.$
        method = ( P... ) ->
          try
            local_method P...
          catch error
            excerpt = rpr P
            if excerpt.length > max_excerpt_length
              x       = max_excerpt_length / 2
              excerpt = excerpt[ .. x ] + ' ... ' + excerpt[ excerpt.length - x .. ]
            warn "^icql#15543^ when trying to call method #{name} with #{excerpt}"
            warn "^icql#15544^ an error occurred: #{error.name ? error.code}: #{error.message}"
            throw error
        me.$[ name ]  = method.bind me.$
      else
        me.$[ name ]  = local_method
  #.........................................................................................................
  for name, ic_entry of me.$.sql
    ### TAINT fix in intercourse ###
    ic_entry.name = name
    check_unique name
    me[ name ] = @_method_from_ic_entry me, ic_entry
  #.........................................................................................................
  return me

#-----------------------------------------------------------------------------------------------------------
@bind_udfs = ( me ) ->
  me.$.function 'as_hollerith',   { deterministic: true, varargs: false }, ( x ) => HOLLERITH.encode x
  me.$.function 'from_hollerith', { deterministic: true, varargs: false }, ( x ) => HOLLERITH.decode x
  return me

#-----------------------------------------------------------------------------------------------------------
@_method_from_ic_entry = ( me, ic_entry ) ->
  validate.ic_entry_type ic_entry.type
  #.........................................................................................................
  if ic_entry.type is 'fragment' then return ( Q ) =>
    descriptor  = @_descriptor_from_arguments me, ic_entry, Q
    sql         = descriptor.parts.join '\n'
    return me.$.interpolate sql, Q
  #.........................................................................................................
  return ( Q ) =>
    descriptor  = @_descriptor_from_arguments me, ic_entry, Q
    last_idx    = descriptor.parts.length - 1
    try
      for part, idx in descriptor.parts
        is_last = idx is last_idx
        R       = me.$._run_or_query ic_entry.type, is_last, part, Q
    catch error
      name      = ic_entry.name
      type      = ic_entry.type
      kenning   = descriptor.kenning
      line_nr   = descriptor.location.line_nr
      location  = "line #{line_nr}, #{type} #{name}#{kenning}"
      throw new Error "µ11123 At *.icql #{location}: #{error.message}"
    return R

#-----------------------------------------------------------------------------------------------------------
@_descriptor_from_arguments = ( me, ic_entry, Q ) ->
  [ signature, kenning, ]         = IC.get_signature_and_kenning Q
  is_void_signature               = kenning in [ '()', 'null', ]
  if is_void_signature  then  R   = ic_entry[ '()'    ] ? ic_entry[ 'null' ]
  else                        R   = ic_entry[ kenning ]
  R                              ?= ic_entry[ 'null'  ]
  #.........................................................................................................
  unless R?
    throw new Error "µ93832 calling method #{rpr ic_entry.name} with signature #{kenning} not implemented"
  return R




