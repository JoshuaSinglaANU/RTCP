(function() {
  'use strict';
  var CND, Intertype, alert, badge, debug, help, info, intertype, jr, kenning_pattern, rpr, urge, warn, whisper;

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
  this.declare('ic_toplevel_entry', {
    tests: {
      "? is an object": function(x) {
        return this.isa.object(x);
      },
      // "? has key 'type'":                       ( x ) -> @has_key     x, 'type'
      "?.type is a text": function(x) {
        return this.isa.text(x.type);
      }
    }
  });

  //-----------------------------------------------------------------------------------------------------------
  this.declare('ic_signature_entry', {
    tests: {
      "? is an object": function(x) {
        return this.isa.object(x);
      },
      // "? has key 'location'":                   ( x ) -> @has_key           x, 'location'
      // "? has key 'kenning'":                    ( x ) -> @has_key           x, 'kenning'
      // "? has key 'type'":                       ( x ) -> @has_key           x, 'type'
      "?.location is a ic_location": function(x) {
        return this.isa.ic_location(x.location);
      },
      "?.kenning is a ic_kenning": function(x) {
        return this.isa.ic_kenning(x.kenning);
      },
      "?.type is a text": function(x) {
        return this.isa.text(x.type);
      },
      // "? has key 'parts'":                      ( x ) -> @has_key           x, 'parts'
      "?.parts is a nonempty list": function(x) {
        return this.isa.nonempty_list(x.parts);
      }
    }
  });

  // "? has key 'signature'":                  ( x ) -> @has_key           x, 'signature'
  // "?.signature is a list":                  ( x ) -> @isa.list          x.signature

  //-----------------------------------------------------------------------------------------------------------
  this.declare('ic_location', {
    tests: {
      "? is an object": function(x) {
        return this.isa.object(x);
      },
      // "? has key 'line_nr'":                    ( x ) -> @has_key       x, 'line_nr'
      "?.line_nr is a positive": function(x) {
        return this.isa.positive(x.line_nr);
      }
    }
  });

  //-----------------------------------------------------------------------------------------------------------
  this.declare('ic_settings', {
    tests: {
      "? is an object": function(x) {
        return this.isa.object(x);
      },
      // "? has key 'partition'":                  ( x ) -> @has_key       x, 'partition'
      // "? has key 'comments'":                   ( x ) -> @has_key       x, 'comments'
      "?.partition is null, false or 'indent'": function(x) {
        var ref;
        return (ref = x.partition) === null || ref === false || ref === 'indent';
      },
      "?.comments is a regex": function(x) {
        return this.isa.regex(x.comments);
      }
    }
  });

  //-----------------------------------------------------------------------------------------------------------
  kenning_pattern = /^null|\(\S*\)$/;

  this.declare('ic_null_kenning', function(x) {
    return x === 'null';
  });

  this.declare('ic_kenning', function(x) {
    return (this.isa.text(x)) && ((x.match(kenning_pattern)) != null);
  });

  //-----------------------------------------------------------------------------------------------------------
  this.declare('datom', {
    tests: {
      "? is an object": function(x) {
        return this.isa.object(x);
      },
      // "? has key 'key'":                        ( x ) -> @has_key x, 'key'
      // "? has key 'value'":                      ( x ) -> @has_key x, 'value'
      "?.$key is a nonempty text": function(x) {
        return this.isa.nonempty_text(x.$key);
      }
    }
  });

}).call(this);

//# sourceMappingURL=types.js.map