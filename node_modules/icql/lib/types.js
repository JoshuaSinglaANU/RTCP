(function() {
  'use strict';
  var CND, Intertype, alert, badge, debug, help, info, intertype, jr, rpr, urge, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'MKTS-PARSER/TYPES';

  debug = CND.get_logger('debug', badge);

  alert = CND.get_logger('alert', badge);

  whisper = CND.get_logger('whisper', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  info = CND.get_logger('info', badge);

  jr = JSON.stringify;

  Intertype = (require('intertype')).Intertype;

  intertype = new Intertype(module.exports);

  //-----------------------------------------------------------------------------------------------------------
  this.declare('icql_settings', {
    tests: {
      "x is a object": function(x) {
        return this.isa.object(x);
      },
      // "x has key 'db_path'":                    ( x ) -> @has_key             x, 'db_path'
      // "x has key 'icql_path'":                  ( x ) -> @has_key             x, 'icql_path'
      "x.db_path is a nonempty text": function(x) {
        return this.isa.nonempty_text(x.db_path);
      },
      "x.icql_path is a nonempty text": function(x) {
        return this.isa.nonempty_text(x.icql_path);
      },
      "x.echo? is a boolean": function(x) {
        return this.isa_optional.boolean(x.echo);
      }
    }
  });

  //-----------------------------------------------------------------------------------------------------------
  this.declare('ic_entry_type', {
    tests: {
      "x is a text": function(x) {
        return this.isa.text(x);
      },
      "x is in 'procedure', 'query', 'fragment'": function(x) {
        return x === 'procedure' || x === 'query' || x === 'fragment';
      }
    }
  });

  //-----------------------------------------------------------------------------------------------------------
  this.declare('ic_schema', function(x) {
    if (!this.isa.text(x)) {
      /* NOTE to keep things simple, only allow lower case ASCII letters, digits, underscores in schemas */
      return false;
    }
    return /^[a-z][a-z0-9_]*$/.test(x);
  });

  //-----------------------------------------------------------------------------------------------------------
  this.declare('ic_path', function(x) {
    return this.isa.nonempty_text(x);
  });

}).call(this);

//# sourceMappingURL=types.js.map