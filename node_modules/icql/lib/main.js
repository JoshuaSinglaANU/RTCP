(function() {
  'use strict';
  var CND, FS, HOLLERITH, IC, LFT, assign, badge, debug, declare, echo, help, info, inspect, isa, jr, max_excerpt_length, rpr, size_of, type_of, urge, validate, warn, whisper, xrpr;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'ICQL/MAIN';

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  info = CND.get_logger('info', badge);

  urge = CND.get_logger('urge', badge);

  help = CND.get_logger('help', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  // PATH                      = require 'path'
  // PD                        = require 'pipedreams'
  // { $
  //   $async
  //   select }                = PD
  ({assign, jr} = CND);

  // #...........................................................................................................
  // join_path                 = ( P... ) -> PATH.resolve PATH.join P...
  // boolean_as_int            = ( x ) -> if x then 1 else 0
  ({inspect} = require('util'));

  xrpr = function(x) {
    return inspect(x, {
      colors: true,
      breakLength: 2e308,
      maxArrayLength: 2e308,
      depth: 2e308
    });
  };

  //...........................................................................................................
  FS = require('fs');

  IC = require('intercourse');

  this.HOLLERITH = HOLLERITH = require('hollerith-codec');

  //...........................................................................................................
  this.types = require('./types');

  ({isa, validate, declare, size_of, type_of} = this.types);

  max_excerpt_length = 10000;

  LFT = require('letsfreezethat');

  //===========================================================================================================
  // LOCAL METHODS
  //-----------------------------------------------------------------------------------------------------------
  this._local_methods = {
    //---------------------------------------------------------------------------------------------------------
    _statements: {},
    //---------------------------------------------------------------------------------------------------------
    _echo: function(ref, sql) {
      if (!this.settings.echo) {
        return null;
      }
      echo((CND.reverse(CND.blue(`^icql@888-${ref}^`))) + (CND.reverse(CND.yellow(sql))));
      return null;
    },
    //---------------------------------------------------------------------------------------------------------
    limit: function*(n, iterator) {
      var count, x;
      count = 0;
      for (x of iterator) {
        if (count >= n) {
          return;
        }
        count += +1;
        yield x;
      }
    },
    //---------------------------------------------------------------------------------------------------------
    single_row: function(iterator) {
      var R;
      if ((R = this.first_row(iterator)) === void 0) {
        throw new Error("µ33833 expected at least one row, got none");
      }
      return R;
    },
    //---------------------------------------------------------------------------------------------------------
    all_first_values: function(iterator) {
      var R, key, row, value;
      R = [];
      for (row of iterator) {
        for (key in row) {
          value = row[key];
          R.push(value);
          break;
        }
      }
      return R;
    },
    //---------------------------------------------------------------------------------------------------------
    first_values: function*(iterator) {
      var R, key, row, value;
      R = [];
      for (row of iterator) {
        for (key in row) {
          value = row[key];
          yield value;
        }
      }
      return R;
    },
    //---------------------------------------------------------------------------------------------------------
    first_row: function(iterator) {
      var row;
      for (row of iterator) {
        return row;
      }
    },
    /* TAINT must ensure order of keys in row is same as order of fields in query */
    single_value: function(iterator) {
      var key, ref1, value;
      ref1 = this.single_row(iterator);
      for (key in ref1) {
        value = ref1[key];
        return value;
      }
    },
    first_value: function(iterator) {
      var key, ref1, value;
      ref1 = this.first_row(iterator);
      for (key in ref1) {
        value = ref1[key];
        return value;
      }
    },
    all_rows: function(iterator) {
      return [...iterator];
    },
    //---------------------------------------------------------------------------------------------------------
    query: function(sql, ...P) {
      var base, statement;
      this._echo('1', sql);
      statement = ((base = this._statements)[sql] != null ? base[sql] : base[sql] = this.db.prepare(sql));
      return statement.iterate(...P);
    },
    //---------------------------------------------------------------------------------------------------------
    run: function(sql, ...P) {
      var base, statement;
      this._echo('2', sql);
      statement = ((base = this._statements)[sql] != null ? base[sql] : base[sql] = this.db.prepare(sql));
      return statement.run(...P);
    },
    //---------------------------------------------------------------------------------------------------------
    _run_or_query: function(entry_type, is_last, sql, Q) {
      var base, returns_data, statement;
      this._echo('3', sql);
      statement = ((base = this._statements)[sql] != null ? base[sql] : base[sql] = this.db.prepare(sql));
      returns_data = statement.reader;
      //.......................................................................................................
      /* Always use `run()` method if statement does not return data: */
      if (!returns_data) {
        if (Q != null) {
          return statement.run(Q);
        } else {
          return statement.run();
        }
      }
      //.......................................................................................................
      /* If statement does return data, consume iterator unless this is the last statement: */
      if ((entry_type === 'procedure') || (!is_last)) {
        if (Q != null) {
          return statement.all(Q);
        } else {
          return statement.all();
        }
      }
      //.......................................................................................................
      /* Return iterator: */
      if (Q != null) {
        return statement.iterate(Q);
      } else {
        return statement.iterate();
      }
    },
    //---------------------------------------------------------------------------------------------------------
    execute: function(sql) {
      this._echo('4', sql);
      return this.db.exec(sql);
    },
    //---------------------------------------------------------------------------------------------------------
    prepare: function(...P) {
      return this.db.prepare(...P);
    },
    aggregate: function(...P) {
      return this.db.aggregate(...P);
    },
    backup: function(...P) {
      return this.db.backup(...P);
    },
    checkpoint: function(...P) {
      return this.db.checkpoint(...P);
    },
    close: function(...P) {
      return this.db.close(...P);
    },
    read: function(path) {
      return this.db.exec(FS.readFileSync(path, {
        encoding: 'utf-8'
      }));
    },
    function: function(...P) {
      return this.db.function(...P);
    },
    load: function(...P) {
      return this.db.loadExtension(...P);
    },
    pragma: function(...P) {
      return this.db.pragma(...P);
    },
    transaction: function(...P) {
      return this.db.transaction(...P);
    },
    //---------------------------------------------------------------------------------------------------------
    catalog: function() {
      /* TAINT kludge: we sort by descending types so views, tables come before indexes (b/c you can't drop a
         primary key index in SQLite) */
      // throw new Error "µ45222 deprecated until next major version"
      return this.query("select * from sqlite_master order by type desc, name;");
    },
    //---------------------------------------------------------------------------------------------------------
    list_objects: function(schema = 'main') {
      validate.ic_schema(schema);
      return this.all_rows(this.query(`select
    type      as type,
    name      as name,
    sql       as sql
  from ${this.as_identifier(schema)}.sqlite_master
  order by type desc, name;`));
    },
    //---------------------------------------------------------------------------------------------------------
    list_schemas: function() {
      return this.pragma("database_list;");
    },
    list_schema_names: function() {
      var d;
      return new Set((function() {
        var i, len, ref1, results;
        ref1 = this.list_schemas();
        results = [];
        for (i = 0, len = ref1.length; i < len; i++) {
          d = ref1[i];
          results.push(d.name);
        }
        return results;
      }).call(this));
    },
    //---------------------------------------------------------------------------------------------------------
    /* TAINT must escape path, schema */
    attach: function(path, schema) {
      validate.ic_path(path);
      validate.ic_schema(schema);
      return this.execute(`attach ${this.as_sql(path)} as ${this.as_identifier(schema)};`);
    },
    //-----------------------------------------------------------------------------------------------------------
    copy_schema: function(from_schema, to_schema) {
      var d, from_schema_x, i, inserts, j, len, len1, name_x, ref1, ref2, ref3, schemas, sql, to_schema_x;
      schemas = this.list_schema_names();
      inserts = [];
      validate.ic_schema(from_schema);
      validate.ic_schema(to_schema);
      if (!schemas.has(from_schema)) {
        throw new Error(`µ57873 unknown schema ${rpr(from_schema)}`);
      }
      if (!schemas.has(to_schema)) {
        throw new Error(`µ57873 unknown schema ${rpr(to_schema)}`);
      }
      this.pragma(`${this.as_identifier(to_schema)}.foreign_keys = off;`);
      to_schema_x = this.as_identifier(to_schema);
      from_schema_x = this.as_identifier(from_schema);
      ref1 = this.list_objects(from_schema);
      //.......................................................................................................
      for (i = 0, len = ref1.length; i < len; i++) {
        d = ref1[i];
        if (this.settings.verbose) {
          debug('^44463^', "DB object:", d);
        }
        if ((d.sql == null) || (d.sql === '')) {
          continue;
        }
        if ((ref2 = d.name) === 'sqlite_sequence') {
          continue;
        }
        //.....................................................................................................
        /* TAINT consider to use `validate.ic_db_object_type` */
        if ((ref3 = d.type) !== 'table' && ref3 !== 'view' && ref3 !== 'index') {
          throw new Error(`µ49888 unknown type ${rpr(d.type)} for DB object ${rpr(d)}`);
        }
        //.....................................................................................................
        /* TAINT using not-so reliable string replacement as substitute for proper parsing */
        name_x = this.as_identifier(d.name);
        sql = d.sql.replace(/\s*CREATE\s*(TABLE|INDEX|VIEW)\s*/i, `create ${d.type} ${to_schema_x}.`);
        //.....................................................................................................
        if (sql === d.sql) {
          throw new Error(`µ49889 unexpected SQL string ${rpr(d.sql)}`);
        }
        //.....................................................................................................
        this.execute(sql);
        if (d.type === 'table') {
          inserts.push(`insert into ${to_schema_x}.${name_x} select * from ${from_schema_x}.${name_x};`);
        }
      }
      //.......................................................................................................
      if (this.settings.verbose) {
        debug('^49864^', "starting with inserts");
        debug('^49864^', `objects in ${rpr(from_schema)}: ${rpr(((function() {
          var j, len1, ref4, results;
          ref4 = this.list_objects(from_schema);
          results = [];
          for (j = 0, len1 = ref4.length; j < len1; j++) {
            d = ref4[j];
            results.push(`(${d.type})${d.name}`);
          }
          return results;
        }).call(this)).join(', '))}`);
        debug('^49864^', `objects in ${rpr(to_schema)}:   ${rpr(((function() {
          var j, len1, ref4, results;
          ref4 = this.list_objects(to_schema);
          results = [];
          for (j = 0, len1 = ref4.length; j < len1; j++) {
            d = ref4[j];
            results.push(`(${d.type})${d.name}`);
          }
          return results;
        }).call(this)).join(', '))}`);
      }
      for (j = 0, len1 = inserts.length; j < len1; j++) {
        sql = inserts[j];
        //.......................................................................................................
        this.execute(sql);
      }
      this.pragma(`${this.as_identifier(to_schema)}.foreign_keys = on;`);
      this.pragma(`${this.as_identifier(to_schema)}.foreign_key_check;`);
      return null;
    },
    //---------------------------------------------------------------------------------------------------------
    type_of: function(name, schema = 'main') {
      var ref1, row;
      ref1 = this.catalog();
      for (row of ref1) {
        if (row.name === name) {
          return row.type;
        }
      }
      return null;
    },
    //---------------------------------------------------------------------------------------------------------
    column_types: function(table) {
      var R, ref1, row;
      R = {};
      ref1 = this.query(this.interpolate("pragma table_info( $table );", {table}));
      /* TAINT we apparently have to call the pragma in this roundabout fashion since SQLite refuses to
         accept placeholders in that statement: */
      for (row of ref1) {
        R[row.name] = row.type;
      }
      return R;
    },
    //---------------------------------------------------------------------------------------------------------
    _dependencies_of: function(table, schema = 'main') {
      return this.query(`pragma ${this.as_identifier(schema)}.foreign_key_list( ${this.as_identifier(table)} )`);
    },
    //---------------------------------------------------------------------------------------------------------
    dependencies_of: function(table, schema = 'main') {
      var row;
      validate.ic_schema(schema);
      return (function() {
        var ref1, results;
        ref1 = this._dependencies_of(table);
        results = [];
        for (row of ref1) {
          results.push(row.table);
        }
        return results;
      }).call(this);
    },
    //---------------------------------------------------------------------------------------------------------
    get_toposort: function(schema = 'main') {
      var LTSORT, R, dependencies, dependency, g, i, indexes, len, name, ref1, sqls, types, x;
      LTSORT = require('ltsort');
      g = LTSORT.new_graph();
      indexes = [];
      types = {};
      sqls = {};
      ref1 = this.list_objects(schema);
      for (x of ref1) {
        types[x.name] = x.type;
        sqls[x.name] = x.sql;
        if (x.type !== 'table') {
          indexes.push(x.name);
          continue;
        }
        dependencies = this.dependencies_of(x.name);
        if (dependencies.length === 0) {
          LTSORT.add(g, x.name);
        } else {
          for (i = 0, len = dependencies.length; i < len; i++) {
            dependency = dependencies[i];
            LTSORT.add(g, x.name, dependency);
          }
        }
      }
      R = [...(LTSORT.linearize(g)), ...indexes];
      return (function() {
        var j, len1, results;
        results = [];
        for (j = 0, len1 = R.length; j < len1; j++) {
          name = R[j];
          results.push({
            name,
            type: types[name],
            sql: sqls[name]
          });
        }
        return results;
      })();
    },
    //---------------------------------------------------------------------------------------------------------
    clear: function() {
      var count, i, len, name, ref1, statement, type;
      count = 0;
      ref1 = this.get_toposort();
      for (i = 0, len = ref1.length; i < len; i++) {
        ({type, name} = ref1[i]);
        statement = `drop ${type} if exists ${this.as_identifier(name)};`;
        this.execute(statement);
        count += +1;
      }
      return count;
    },
    //---------------------------------------------------------------------------------------------------------
    as_identifier: function(text) {
      return '"' + (text.replace(/"/g, '""')) + '"';
    },
    // as_identifier:  ( text  ) -> '[' + ( text.replace /\]/g, ']]' ) + ']'

    //---------------------------------------------------------------------------------------------------------
    escape_text: function(x) {
      validate.text(x);
      return x.replace(/'/g, "''");
    },
    //---------------------------------------------------------------------------------------------------------
    list_as_json: function(x) {
      validate.list(x);
      return jr(x);
    },
    //---------------------------------------------------------------------------------------------------------
    as_sql: function(x) {
      var type;
      switch (type = type_of(x)) {
        case 'text':
          return `'${this.escape_text(x)}'`;
        case 'list':
          return `'${this.list_as_json(x)}'`;
        case 'float':
          return x.toString();
        case 'boolean':
          return (x ? '1' : '0');
        case 'null':
          return 'null';
        case 'undefined':
          throw new Error("µ12341 unable to express 'undefined' as SQL literal");
      }
      throw new Error(`µ12342 unable to express a ${type} as SQL literal, got ${rpr(x)}`);
    },
    //---------------------------------------------------------------------------------------------------------
    interpolate: function(sql, Q) {
      return sql.replace(this._interpolation_pattern, ($0, $1) => {
        var error;
        try {
          return this.as_sql(Q[$1]);
        } catch (error1) {
          error = error1;
          throw new Error(`µ55563 when trying to express placeholder ${rpr($1)} as SQL literal, an error occurred: ${rpr(error.message)}`);
        }
      });
    },
    _interpolation_pattern: /\$(?:(.+?)\b|\{([^}]+)\})/g,
    //---------------------------------------------------------------------------------------------------------
    as_hollerith: function(x) {
      return HOLLERITH.encode(x);
    },
    from_hollerith: function(x) {
      return HOLLERITH.decode(x);
    }
  };

  //===========================================================================================================

  //-----------------------------------------------------------------------------------------------------------
  this.bind = function(settings) {
    var connector, me, ref1;
    validate.icql_settings(settings);
    me = {
      $: {settings}
    };
    connector = (ref1 = settings.connector) != null ? ref1 : require('better-sqlite3');
    me.icql_path = settings.icql_path;
    this.connect(me, connector, settings.db_path, settings.db_settings);
    this.definitions_from_path_sync(me, settings.icql_path);
    this.bind_definitions(me);
    this.bind_udfs(me);
    return me;
  };

  //-----------------------------------------------------------------------------------------------------------
  /* TAINT should check connector API compatibility */
  /* TAINT consider to use `new`-less call convention (should be possible acc. to bsql3 docs) */
  this.connect = function(me, connector, db_path, db_settings = {}) {
    if (me.$ == null) {
      me.$ = {};
    }
    me.$.db = new connector(db_path, db_settings);
    // me.$.dbr  = me.$.db
    // me.$.dbw  = new connector db_path, db_settings
    return me;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.definitions_from_path_sync = function(me, icql_path) {
    (me.$ != null ? me.$ : me.$ = {}).sql = IC.definitions_from_path_sync(icql_path);
    return me;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.bind_definitions = function(me) {
    var check_unique, ic_entry, local_method, name, ref1, ref2;
    check_unique = function(name) {
      if (me[name] != null) {
        throw new Error(`µ11292 name collision: ${rpr(name)} already defined`);
      }
    };
    if (me.$ == null) {
      me.$ = {};
    }
    ref1 = LFT._deep_copy(this._local_methods);
    //.........................................................................................................
    /* TAINT use `new` */
    for (name in ref1) {
      local_method = ref1[name];
      (function(name, local_method) {
        var method;
        check_unique(name);
        if (isa.function(local_method)) {
          local_method = local_method.bind(me.$);
          method = function(...P) {
            var error, excerpt, ref2, x;
            try {
              return local_method(...P);
            } catch (error1) {
              error = error1;
              excerpt = rpr(P);
              if (excerpt.length > max_excerpt_length) {
                x = max_excerpt_length / 2;
                excerpt = excerpt.slice(0, +x + 1 || 9e9) + ' ... ' + excerpt.slice(excerpt.length - x);
              }
              warn(`^icql#15543^ when trying to call method ${name} with ${excerpt}`);
              warn(`^icql#15544^ an error occurred: ${(ref2 = error.name) != null ? ref2 : error.code}: ${error.message}`);
              throw error;
            }
          };
          return me.$[name] = method.bind(me.$);
        } else {
          return me.$[name] = local_method;
        }
      })(name, local_method);
    }
    ref2 = me.$.sql;
    //.........................................................................................................
    for (name in ref2) {
      ic_entry = ref2[name];
      /* TAINT fix in intercourse */
      ic_entry.name = name;
      check_unique(name);
      me[name] = this._method_from_ic_entry(me, ic_entry);
    }
    //.........................................................................................................
    return me;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.bind_udfs = function(me) {
    me.$.function('as_hollerith', {
      deterministic: true,
      varargs: false
    }, (x) => {
      return HOLLERITH.encode(x);
    });
    me.$.function('from_hollerith', {
      deterministic: true,
      varargs: false
    }, (x) => {
      return HOLLERITH.decode(x);
    });
    return me;
  };

  //-----------------------------------------------------------------------------------------------------------
  this._method_from_ic_entry = function(me, ic_entry) {
    validate.ic_entry_type(ic_entry.type);
    //.........................................................................................................
    if (ic_entry.type === 'fragment') {
      return (Q) => {
        var descriptor, sql;
        descriptor = this._descriptor_from_arguments(me, ic_entry, Q);
        sql = descriptor.parts.join('\n');
        return me.$.interpolate(sql, Q);
      };
    }
    //.........................................................................................................
    return (Q) => {
      var R, descriptor, error, i, idx, is_last, kenning, last_idx, len, line_nr, location, name, part, ref1, type;
      descriptor = this._descriptor_from_arguments(me, ic_entry, Q);
      last_idx = descriptor.parts.length - 1;
      try {
        ref1 = descriptor.parts;
        for (idx = i = 0, len = ref1.length; i < len; idx = ++i) {
          part = ref1[idx];
          is_last = idx === last_idx;
          R = me.$._run_or_query(ic_entry.type, is_last, part, Q);
        }
      } catch (error1) {
        error = error1;
        name = ic_entry.name;
        type = ic_entry.type;
        kenning = descriptor.kenning;
        line_nr = descriptor.location.line_nr;
        location = `line ${line_nr}, ${type} ${name}${kenning}`;
        throw new Error(`µ11123 At *.icql ${location}: ${error.message}`);
      }
      return R;
    };
  };

  //-----------------------------------------------------------------------------------------------------------
  this._descriptor_from_arguments = function(me, ic_entry, Q) {
    var R, is_void_signature, kenning, ref1, signature;
    [signature, kenning] = IC.get_signature_and_kenning(Q);
    is_void_signature = kenning === '()' || kenning === 'null';
    if (is_void_signature) {
      R = (ref1 = ic_entry['()']) != null ? ref1 : ic_entry['null'];
    } else {
      R = ic_entry[kenning];
    }
    if (R == null) {
      R = ic_entry['null'];
    }
    //.........................................................................................................
    if (R == null) {
      throw new Error(`µ93832 calling method ${rpr(ic_entry.name)} with signature ${kenning} not implemented`);
    }
    return R;
  };

}).call(this);

//# sourceMappingURL=main.js.map