(function() {
  'use strict';
  var $, $async, CND, PATH, PS, abspath, assign, badge, debug, declare, echo, help, info, isa, join_paths, jr, new_pager, path_to_pspg, rpr, select, size_of, to_width, type_of, types, urge, validate, warn, whisper, width_of;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'PSPG/MAIN';

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  info = CND.get_logger('info', badge);

  urge = CND.get_logger('urge', badge);

  help = CND.get_logger('help', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  // FS                        = require 'fs'
  PATH = require('path');

  PS = require('pipestreams');

  ({$, $async, select} = PS);

  types = require('./types');

  ({isa, validate, declare, size_of, type_of} = types);

  //...........................................................................................................
  require('./exception-handler');

  join_paths = function(...P) {
    return PATH.resolve(PATH.join(...P));
  };

  abspath = function(...P) {
    return join_paths(__dirname, ...P);
  };

  ({to_width, width_of} = require('to-width'));

  new_pager = require('default-pager');

  path_to_pspg = abspath('../pspg');

  ({jr} = CND);

  assign = Object.assign;

  //-----------------------------------------------------------------------------------------------------------
  this.walk_table_header = function*(keys, widths) {
    var key;
    yield ' ' + (((function() {
      var ref, results;
      ref = keys.values();
      results = [];
      for (key of ref) {
        results.push(to_width(key, widths[key]));
      }
      return results;
    })()).join(' | ')) + ' ';
    yield '-' + (((function() {
      var ref, results;
      ref = keys.values();
      results = [];
      for (key of ref) {
        results.push(to_width('', widths[key], {
          padder: '-'
        }));
      }
      return results;
    })()).join('-+-')) + '-';
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.walk_formatted_table_row = function*(row, keys, widths) {
    var key;
    return (yield ' ' + (((function() {
      var ref, ref1, results;
      ref = keys.values();
      results = [];
      for (key of ref) {
        results.push(to_width((ref1 = row[key]) != null ? ref1 : '', widths[key]));
      }
      return results;
    })()).join(' | ')) + ' ');
  };

  //-----------------------------------------------------------------------------------------------------------
  this.walk_table_footer = function*(count) {
    yield `(${count} rows)`;
    yield '\n\n';
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.to_text = function(value) {
    var R, ref, type;
    switch (type = type_of(value)) {
      case 'text':
        R = jr(value);
        R = R.slice(1, R.length - 1);
        return R.replace(/\\"/g, '"');
      case 'buffer':
        return value.toString('hex');
      case 'number':
        return `${value}`;
      case 'null':
        return '∎';
      case 'undefined':
        return '?';
      default:
        return (ref = value != null ? value.toString() : void 0) != null ? ref : '';
    }
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$collect_etc = function(limit = 1000) {
    var cache, count, flush, key_widths, keys, last, send, widths;
    validate.positive(limit);
    last = Symbol('last');
    cache = [];
    widths = {};
    keys = new Set();
    key_widths = {};
    count = 0;
    send = null;
    //.........................................................................................................
    flush = () => {
      var cached_row, i, len, line, ref, ref1;
      if (cache == null) {
        return null;
      }
      ref = this.walk_table_header(keys, widths);
      for (line of ref) {
        send(line);
      }
      for (i = 0, len = cache.length; i < len; i++) {
        cached_row = cache[i];
        ref1 = this.walk_formatted_table_row(cached_row, keys, widths);
        for (line of ref1) {
          send(line);
        }
      }
      return cache = null;
    };
    //.........................................................................................................
    return PS.$({last}, (row, send_) => {
      var d, key, key_width, line, ref, ref1, ref2, ref3, value;
      send = send_;
      //.......................................................................................................
      if (row === last) {
        flush();
        ref = this.walk_table_footer(count);
        for (line of ref) {
          send(line);
        }
        return null;
      }
      //.......................................................................................................
      count++;
      //.......................................................................................................
      if (count > limit) {
        flush();
        ref1 = keys.values();
        for (key of ref1) {
          row[key] = this.to_text(row[key]);
        }
        ref2 = this.walk_formatted_table_row(row, keys, widths);
        for (line of ref2) {
          send(line);
        }
        return null;
      }
      //.......................................................................................................
      d = {};
      for (key in row) {
        keys.add(key);
        d[key] = value = this.to_text(row[key]);
        key_width = (key_widths[key] != null ? key_widths[key] : key_widths[key] = width_of(key));
        widths[key] = Math.max(2, (ref3 = widths[key]) != null ? ref3 : 2, width_of(value), key_width);
      }
      cache.push(d);
      //.......................................................................................................
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$tee_as_table = function(settings, handler) {
    var pipeline;
    //.........................................................................................................
    pipeline = [];
    pipeline.push(this.$collect_etc());
    pipeline.push(this.$page_output(...arguments));
    pipeline.push(PS.$drain());
    //.........................................................................................................
    return PS.$tee(PS.pull(...pipeline));
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$page_output = function(settings, handler) {
    var arity, defaults, last, source, stream;
    switch (arity = arguments.length) {
      case 0:
        null;
        break;
      case 1:
        if (isa.function(settings)) {
          [settings, handler] = [null, settings];
        }
        break;
      case 2:
        null;
        break;
      default:
        throw new Error(`µ33981 expected between 0 and 2 arguments, got ${arity}`);
    }
    if (handler != null) {
      validate.function(handler);
    }
    if (settings != null) {
      validate.object(settings);
    }
    //.........................................................................................................
    defaults = {
      pager: path_to_pspg,
      args: ['-s17', '--force-uniborder']
    };
    //.........................................................................................................
    settings = settings != null ? assign({}, defaults, settings) : defaults;
    if (settings.csv/* ??? */) {
      settings.args = [...settings.args, '--csv', '--csv-border', '2', '--csv-double-header'];
    }
    //.........................................................................................................
    source = PS.new_push_source();
    stream = PS.node_stream_from_source(PS.pull(source));
    stream.pipe(new_pager(settings, handler));
    last = Symbol('last');
    //.........................................................................................................
    return PS.$watch({last}, function(line) {
      if (line === last) {
        return source.end();
      }
      if (line == null) {
        line = '';
      }
      if (!isa.text(line)) {
        line = line.toString();
      }
      if (!isa.line(line)) {
        line += '\n';
      }
      source.send(line);
      return null;
    });
  };

}).call(this);
