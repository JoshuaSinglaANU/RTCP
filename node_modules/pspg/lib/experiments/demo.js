(function() {
  'use strict';
  var $, $async, CND, PATH, PS, PSPG, abspath, as_csv, badge, debug, declare, echo, help, info, isa, join_paths, jr, path_1, rpr, select, size_of, to_width, type_of, types, urge, validate, warn, whisper, width_of,
    modulo = function(a, b) { return (+a % (b = +b) + b) % b; };

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'PSPG/EXPERIMENTS/DEMO';

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

  ({$, $async, select} = PS.export());

  types = require('../types');

  ({isa, validate, declare, size_of, type_of} = types);

  //...........................................................................................................
  require('../exception-handler');

  join_paths = function(...P) {
    return PATH.resolve(PATH.join(...P));
  };

  abspath = function(...P) {
    return join_paths(__dirname, ...P);
  };

  ({to_width, width_of} = require('to-width'));

  PSPG = require('../..');

  path_1 = abspath('../../src/experiments/test-data-1.tsv');

  jr = JSON.stringify;

  //-----------------------------------------------------------------------------------------------------------
  this.demo_tabular_output = function() {
    return new Promise((resolve) => {
      var pipeline, source;
      source = PS.read_from_file(path_1);
      pipeline = [];
      pipeline.push(source);
      pipeline.push(PS.$split_tsv());
      pipeline.push(PS.$name_fields('fncr', 'glyph', 'formula'));
      pipeline.push(this.$add_random_words(10));
      pipeline.push(this.$add_ncrs());
      pipeline.push(this.$add_numbers());
      pipeline.push(this.$add_nulls());
      pipeline.push(this.$reorder_fields());
      pipeline.push(PSPG.$tee_as_table(function() {
        return resolve();
      }));
      pipeline.push(PS.$drain());
      return PS.pull(...pipeline);
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.demo_many_rows = function() {
    return new Promise((resolve) => {
      var pipeline, source;
      source = PS.new_value_source(this.get_random_words(800));
      pipeline = [];
      pipeline.push(source);
      pipeline.push($(function(word, send) {
        return send(`${word} `.repeat(CND.random_integer(1, 20)));
      }));
      pipeline.push($(function(text, send) {
        return send({text});
      }));
      pipeline.push(PSPG.$tee_as_table(function() {
        return resolve();
      }));
      pipeline.push(PS.$drain());
      return PS.pull(...pipeline);
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.demo_tabular_output_with_different_shapes = function() {
    /* This is to demonstrate that when objects with different shapes—i.e. different sets of properties—are
    tabulated, the columns displayed represent the union of all keys of all objects. */
    return new Promise((resolve) => {
      var pipeline, source;
      source = PS.read_from_file(path_1);
      pipeline = [];
      pipeline.push(source);
      pipeline.push(PS.$split_tsv());
      pipeline.push(PS.$name_fields('fncr', 'glyph', 'formula'));
      pipeline.push(this.$add_random_words(10));
      pipeline.push(this.$add_ncrs());
      pipeline.push(this.$add_numbers());
      pipeline.push(this.$reorder_fields());
      pipeline.push(this.$drop_keys());
      pipeline.push(PSPG.$tee_as_table(function() {
        return resolve();
      }));
      pipeline.push(PS.$drain());
      return PS.pull(...pipeline);
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.demo_paged_output = function() {
    return new Promise((resolve) => {
      var pipeline, source;
      source = PS.read_from_file(path_1);
      pipeline = [];
      pipeline.push(source);
      pipeline.push(PS.$split_tsv());
      pipeline.push(PS.$name_fields('fncr', 'glyph', 'formula'));
      pipeline.push(this.$add_random_words(10));
      pipeline.push(this.$add_ncrs());
      pipeline.push(this.$add_numbers());
      pipeline.push(this.$reorder_fields());
      pipeline.push(this.$as_line());
      pipeline.push(PSPG.$page_output(function() {
        return resolve();
      }));
      pipeline.push(PS.$drain());
      return PS.pull(...pipeline);
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.demo_csv_output = function() {
    return new Promise((resolve) => {
      var pipeline, source;
      source = PS.read_from_file(path_1);
      pipeline = [];
      pipeline.push(source);
      pipeline.push(PS.$split_tsv());
      pipeline.push(PS.$name_fields('fncr', 'glyph', 'formula'));
      pipeline.push(this.$add_random_words(10));
      pipeline.push(this.$add_ncrs());
      pipeline.push(this.$add_numbers());
      pipeline.push(this.$reorder_fields());
      pipeline.push(this.$add_csv_header());
      pipeline.push(this.$as_csv_line());
      // pipeline.push PS.$watch ( d ) -> urge '^77766^', jr d
      pipeline.push(PSPG.$page_output({
        csv: true
      }, function() {
        return resolve();
      }));
      pipeline.push(PS.$drain());
      return PS.pull(...pipeline);
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.demo_key_value = function() {
    return new Promise((resolve) => {
      var pipeline, source;
      source = PS.read_from_file(path_1);
      pipeline = [];
      pipeline.push(source);
      pipeline.push(PS.$split_tsv());
      pipeline.push(PS.$name_fields('fncr', 'glyph', 'formula'));
      pipeline.push($(function(d, send) {
        return send({
          key: d.glyph,
          value: d.formula
        });
      }));
      pipeline.push(this.$add_csv_header());
      pipeline.push(this.$as_csv_line());
      // pipeline.push PS.$watch ( d ) -> urge '^77766^', jr d
      pipeline.push(PSPG.$page_output({
        csv: true
      }, function() {
        return resolve();
      }));
      pipeline.push(PS.$drain());
      return PS.pull(...pipeline);
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$reorder_fields = function() {
    return $((row, send) => {
      var bs, fncr, formula, formula_ncr, glyph, glyph_ncr, nr, nr2, nr3;
      ({nr, fncr, nr2, glyph, glyph_ncr, nr3, formula, formula_ncr, bs} = row);
      return send({nr, fncr, nr2, glyph, glyph_ncr, nr3, formula, formula_ncr, bs});
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$add_ncrs = function() {
    return $((row, send) => {
      row.glyph_ncr = to_width(this.text_as_ncrs(row.glyph), 20);
      row.formula_ncr = to_width(this.text_as_ncrs(row.formula), 20);
      return send(row);
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$add_numbers = function() {
    var nr;
    nr = 0;
    return $((row, send) => {
      nr += +1;
      row.nr = nr;
      row.nr2 = nr ** 2;
      row.nr3 = nr ** 3;
      return send(row);
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$add_nulls = function() {
    return $((row, send) => {
      switch (row.nr) {
        case 3:
          delete row.glyph;
          break;
        case 4:
          row.bs = null;
      }
      return send(row);
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$drop_keys = function() {
    return $((row, send) => {
      var idx, key, keys;
      keys = (function() {
        var results;
        results = [];
        for (key in row) {
          results.push(key);
        }
        return results;
      })();
      idx = modulo(row.nr, keys.length);
      key = keys[idx];
      return send({
        [`${key}`]: row[key]
      });
    });
  };

  // send row

  //-----------------------------------------------------------------------------------------------------------
  this.text_as_ncrs = function(text) {
    var R, chr, cid_hex, i, len, ref;
    R = [];
    ref = Array.from(text);
    for (i = 0, len = ref.length; i < len; i++) {
      chr = ref[i];
      cid_hex = (chr.codePointAt(0)).toString(16);
      R.push(`&#x${cid_hex};`);
    }
    return R.join('');
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$add_random_words = function(n = 1) {
    var CP, count, word, words;
    validate.count(n);
    CP = require('child_process');
    count = Math.min(1e5, n * 1000);
    words = ((CP.execSync(`shuf -n ${count} /usr/share/dict/words`)).toString('utf-8')).split('\n');
    words = (function() {
      var i, len, results;
      results = [];
      for (i = 0, len = words.length; i < len; i++) {
        word = words[i];
        results.push(word.replace(/'s$/g, ''));
      }
      return results;
    })();
    words = (function() {
      var i, len, results;
      results = [];
      for (i = 0, len = words.length; i < len; i++) {
        word = words[i];
        if (word !== '') {
          results.push(word);
        }
      }
      return results;
    })();
    return $((fields, send) => {
      var _;
      fields.bs = ((function() {
        var i, ref, results;
        results = [];
        for (_ = i = 0, ref = n; (0 <= ref ? i <= ref : i >= ref); _ = 0 <= ref ? ++i : --i) {
          results.push(words[CND.random_integer(0, count)]);
        }
        return results;
      })()).join(' ');
      return send(fields);
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.get_random_words = function(n = 10) {
    var CP, word, words;
    validate.count(n);
    CP = require('child_process');
    words = ((CP.execSync(`shuf -n ${n} /usr/share/dict/words`)).toString('utf-8')).split('\n');
    words = (function() {
      var i, len, results;
      results = [];
      for (i = 0, len = words.length; i < len; i++) {
        word = words[i];
        results.push(word.replace(/'s$/g, ''));
      }
      return results;
    })();
    words = (function() {
      var i, len, results;
      results = [];
      for (i = 0, len = words.length; i < len; i++) {
        word = words[i];
        if (word !== '') {
          results.push(word);
        }
      }
      return results;
    })();
    return words;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$as_line = function() {
    return $((d, send) => {
      if (!isa.text(d)) {
        d = jr(d);
      }
      if (!isa.line(d)) {
        d += '\n';
      }
      return send(d);
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  as_csv = function(x) {
    if (!isa.text(x)) {
      x = x.toString();
    }
    return '"' + (x.replace(/"/g, '""')) + '"';
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$add_csv_header = function() {
    var is_first;
    is_first = true;
    return $((d, send) => {
      var _, k;
      if (is_first) {
        is_first = false;
        send((((function() {
          var results;
          results = [];
          for (k in d) {
            _ = d[k];
            results.push(as_csv(k));
          }
          return results;
        })()).join(',')) + '\n');
      } else {
        send(d);
      }
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$as_csv_line = function() {
    return $((d, send) => {
      var _, v;
      if (isa.text(d)) {
        return send(d);
      }
      return send((((function() {
        var results;
        results = [];
        for (_ in d) {
          v = d[_];
          results.push(as_csv(v));
        }
        return results;
      })()).join(',')) + '\n');
    });
  };

  //###########################################################################################################
  if (module.parent == null) {
    (async() => {
      // await @demo_many_rows()
      await this.demo_tabular_output();
      // await @demo_tabular_output_with_different_shapes()
      // await @demo_paged_output()
      await this.demo_csv_output();
      return (await this.demo_key_value());
    })();
  }

}).call(this);
