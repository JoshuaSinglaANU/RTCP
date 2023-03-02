(function() {
  'use strict';
  var $, $async, CND, DATOM, PATH, SP, assign, badge, collapse_text, copy, debug, declare, echo, has_full_signatures, help, info, isa, jr, lets, new_datom, partition, rpr, select, size_of, type_of, types, urge, validate, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'INTERCOURSE/MAIN';

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  info = CND.get_logger('info', badge);

  urge = CND.get_logger('urge', badge);

  help = CND.get_logger('help', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  PATH = require('path');

  SP = require('steampipes');

  ({$, $async} = SP.export());

  DATOM = require('datom');

  ({new_datom, select, lets} = DATOM.export());

  ({assign, jr} = CND);

  copy = function(x) {
    return assign({}, x);
  };

  //...........................................................................................................
  types = require('./types');

  ({isa, validate, declare, size_of, type_of} = types);

  //-----------------------------------------------------------------------------------------------------------
  collapse_text = function(list_of_texts) {
    var R;
    R = list_of_texts;
    R = R.join('\n');
    R = R.replace(/^\s*/, '');
    R = R.replace(/\s*$/, '');
    if (R.length !== 0) {
      R = R + '\n';
    }
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  has_full_signatures = function(entry) {
    var k;
    for (k in entry) {
      if (k.startsWith('(')) {
        return true;
      }
    }
    return false;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$as_line_datoms = function(S) {
    var line_nr;
    line_nr = 0;
    return $(function(line, send) {
      var d;
      line_nr += +1;
      if ((line.match(/^\s*$/)) != null) {
        d = new_datom('^line', {
          value: line,
          $: {line_nr},
          ref: 'ald/1',
          is_blank: true
        });
      } else {
        d = new_datom('^line', {
          value: line,
          $: {line_nr},
          ref: 'ald/2'
        });
      }
      send(d);
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$skip_comments = function(S) {
    return SP.$filter(function(d) {
      return (d.value.match(S.comments)) == null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$add_headers = function(S) {
    var header_plain_re, header_sig_re, ignore_re;
    header_sig_re = /^(?<ictype>\S+)\s+(?<icname>\S+?)(?<signature>\(.*?\))\s*:\s*(?<trailer>.*?)\s*$/;
    header_plain_re = /^(?<ictype>\S+)\s+(?<icname>\S+)\s*:\s*(?<trailer>.*?)\s*$/;
    ignore_re = /^ignore\s*:\s*$/;
    return $((d, send) => {
      var m;
      if (d.is_blank) {
        return send(d);
      }
      if ((d.value.match(/^\s/)) != null) {
        return send(d);
      }
      if ((m = d.value.match(ignore_re)) != null) {
        return send(new_datom('^ignore', {
          value: copy(m.groups),
          $: d,
          ref: 'ah/1'
        }));
      }
      if ((m = d.value.match(header_sig_re)) != null) {
        return send(new_datom('^definition', {
          value: copy(m.groups),
          $: d,
          ref: 'ah/2'
        }));
      }
      if ((m = d.value.match(header_plain_re)) != null) {
        return send(new_datom('^definition', {
          value: copy(m.groups),
          $: d,
          ref: 'ah/3'
        }));
      }
      //.......................................................................................................
      throw new Error(`µ83473 illegal line ${rpr(d)}`);
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$add_regions = function(S) {
    var last, prv_name, within_region;
    within_region = false;
    prv_name = null;
    last = Symbol('last');
    //.........................................................................................................
    return $({last}, (d, send) => {
      //.......................................................................................................
      if (d === last) {
        if (prv_name != null) {
          send(new_datom('>' + prv_name, {
            ref: 'ar/1'
          }));
          prv_name = null;
        }
        return;
      }
      //.......................................................................................................
      if (select(d, '^line')) {
        if (within_region) {
          return send(d);
        }
        if (d.is_blank) {
          return;
        }
        throw new Error(`µ85818 found line outside of any region: ${rpr(d)}`);
      }
      //.......................................................................................................
      if (prv_name != null) {
        send(new_datom('>' + prv_name, {
          ref: 'ar/2'
        }));
        within_region = false;
        prv_name = null;
      }
      //.......................................................................................................
      if (!within_region) {
        prv_name = d.$key.slice(1);
        d = lets(d, function(d) {
          d.$key = '<' + prv_name;
          return d.ref = 'ar/3';
        });
        within_region = true;
        send(d);
      }
      //.......................................................................................................
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$skip_ignored = function(S) {
    var within_ignore;
    within_ignore = false;
    return $((d, send) => {
      if (select(d, '<ignore')) {
        within_ignore = true;
      } else if (select(d, '>ignore')) {
        within_ignore = false;
      } else if (!within_ignore) {
        send(d);
      }
      //.......................................................................................................
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$reorder_trailers = function(S) {
    var is_oneliner, within_definition;
    within_definition = false;
    is_oneliner = false;
    return $((d, send) => {
      var trailer;
      //.......................................................................................................
      if (select(d, '<definition')) {
        within_definition = true;
        trailer = d.value.trailer;
        d = lets(d, function(d) {
          return delete d.value.trailer;
        });
        if ((trailer != null) && (trailer.length > 0)) {
          is_oneliner = true;
          send(d);
          send(new_datom('^line', {
            value: '  ' + trailer.trim(),
            $: d,
            ref: 'rt/1'
          }));
        } else {
          send(d);
        }
      //.......................................................................................................
      } else if (select(d, '>definition')) {
        is_oneliner = false;
        within_definition = false;
        send(d);
      //.......................................................................................................
      } else if (within_definition && is_oneliner && (!select(d, '>definition')) && !d.is_blank) {
        throw new Error(`µ87872 illegal follow-up after one-liner: ${rpr(d)}`);
      } else {
        //.......................................................................................................
        send(d);
      }
      //.......................................................................................................
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.get_signature_and_kenning = function(signature = null) {
    var kenning;
    if (signature == null) {
      return [null, 'null'];
    }
    if (!isa.list(signature)) {
      signature = Object.keys(signature);
    }
    signature = signature.slice(0).sort();
    kenning = '(' + (signature.join(',')) + ')';
    return [signature, kenning];
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$compile_definitions = function(S) {
    var this_definition, this_indentation;
    this_definition = null;
    this_indentation = null;
    //.........................................................................................................
    return $((d, send) => {
      var argument, i, kenning, len, location, match, name, ref, signature, text, type;
      //.......................................................................................................
      if (select(d, '<definition')) {
        name = d.value.icname;
        type = d.value.ictype;
        location = d.$;
        signature = null;
        this_definition = {
          name,
          type,
          text: [],
          location,
          kenning: 'null'
        };
        if (d.value.signature != null) {
          signature = [];
          ref = (d.value.signature.replace(/[()]/g, '')).split(',');
          for (i = 0, len = ref.length; i < len; i++) {
            argument = ref[i];
            if (((argument = argument.trim()) != null) && argument.length > 0) {
              signature.push(argument);
            }
          }
          [signature, kenning] = this.get_signature_and_kenning(signature);
          this_definition.signature = signature;
          this_definition.kenning = kenning;
        }
      //.......................................................................................................
      } else if (select(d, '>definition')) {
        this_definition.text = collapse_text(this_definition.text);
        send(new_datom('^definition', {
          value: this_definition,
          $: this_definition.location,
          ref: 'cd/1'
        }));
        this_definition = null;
        this_indentation = null;
      //.......................................................................................................
      } else if (select(d, '^line')) {
        if (d.is_blank) {
          return this_definition.text.push('');
        }
        text = d.value;
        //.....................................................................................................
        if (this_indentation == null) {
          if ((match = text.match(/^\s+/)) == null) {
            throw new Error(`µ88163 unexpected indentation: ${rpr(d)}`);
          }
          this_indentation = match[0];
        } else {
          //.....................................................................................................
          if (!text.startsWith(this_indentation)) {
            throw new Error(`µ90508 unexpected indentation: ${rpr(d)}`);
          }
        }
        //.....................................................................................................
        text = text.slice(this_indentation.length);
        this_definition.text.push(text);
      } else {
        //.......................................................................................................
        throw new Error(`µ92853 unexpected datom: ${rpr(d)}`);
      }
      //.......................................................................................................
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$collect = function(S, collector) {
    return $((d, send) => {
      var definition, entry, kenning, lnr, location, name1, parts, signature, type;
      if (!select(d, '^definition')) {
        throw new Error(`µ23982 expected a '^definition', got ${rpr(d)}`);
      }
      //.......................................................................................................
      lnr = d.$.line_nr;
      definition = d.value;
      ({type, parts, location, kenning, signature} = definition);
      entry = (collector[name1 = definition.name] != null ? collector[name1] : collector[name1] = {type});
      //.......................................................................................................
      if (d.value.type !== entry.type) {
        throw new Error(`µ94432
${rpr(definition.name)} is of type ${rpr(entry.type)}, unable to change to ${rpr(definition.type)}
(line #${lnr})`);
      }
      //.......................................................................................................
      if (entry[kenning] != null) {
        throw new Error(`µ23983
name ${definition.name} with kenning ${rpr(kenning)} already defined:
${rpr(definition)}
(line #${lnr})`);
      }
      //.......................................................................................................
      /* TAINT must re-implement */
      if ((kenning === 'null') && (has_full_signatures(entry))) {
        debug('µ23983', entry);
        throw new Error(`µ23983
can't overload explicit-signature definition with a null-signature definition:
${rpr(definition)}
(line #${lnr})`);
      }
      //.......................................................................................................
      entry[kenning] = {parts, location, kenning, type};
      if (signature != null) {
        entry[kenning].signature = signature;
      }
      //.......................................................................................................
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$validate_definition = function(S, collector) {
    return $((d, send) => {
      validate.datom(d);
      validate.true(d.$key === '^definition');
      validate.ic_signature_entry(d.value);
      return send(d);
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  partition = function(S, text) {
    var R, flush, i, len, line, part, ref;
    R = [];
    part = null;
    //.........................................................................................................
    flush = function() {
      if ((part == null) || (part.length === 0)) {
        return null;
      }
      R.push((part.join('\n')).replace(/\s+$/, ''));
      part = null;
      return null;
    };
    ref = text.split(/\n/);
    //.........................................................................................................
    for (i = 0, len = ref.length; i < len; i++) {
      line = ref[i];
      if ((line.match(S.comments)) != null) {
        continue;
      }
      if ((line.match(/^\S/)) != null) {
        flush();
      }
      if (part == null) {
        part = [];
      }
      part.push(line);
    }
    flush();
    //.........................................................................................................
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$partition = function(S, collector) {
    return $((d, send) => {
      // if S.partition is 'indent'
      send(lets(d, function(d) {
        var definition, text;
        definition = d.value;
        text = definition.text;
        if (S.partition === 'indent') {
          definition.parts = partition(S, text);
        } else {
          definition.parts = [text];
        }
        return delete definition.text;
      }));
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.definitions_from_path = function(path, settings) {
    return new Promise((resolve, reject) => {
      return this._read_definitions(SP.read_from_file(path), settings, (error, R) => {
        if (error != null) {
          return reject(error);
        }
        return resolve(R);
      });
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.definitions_from_path_sync = function(path, settings) {
    return this.definitions_from_text((require('fs')).readFileSync(path), settings);
  };

  //-----------------------------------------------------------------------------------------------------------
  this.definitions_from_text = function(text, settings) {
    var buffer;
    buffer = Buffer.from(text, {
      encoding: 'utf-8'
    });
    return this._read_definitions(SP.new_value_source([buffer]), settings);
  };

  //-----------------------------------------------------------------------------------------------------------
  this._read_definitions = function(source, settings, handler = null) {
    /* TAINT find a way to ensure pipeline after source is indeed synchronous */
    var R, S, pipeline;
    R = {};
    S = assign({
      partition: 'indent',
      comments: /^--/
    });
    pipeline = [];
    validate.ic_settings(S);
    pipeline.push(source);
    pipeline.push(SP.$split());
    pipeline.push(this.$as_line_datoms(S));
    pipeline.push(this.$skip_comments(S));
    pipeline.push(this.$add_headers(S));
    pipeline.push(this.$add_regions(S));
    pipeline.push(this.$skip_ignored(S));
    pipeline.push(this.$reorder_trailers(S));
    // pipeline.push SP.$show()
    pipeline.push(this.$compile_definitions(S));
    pipeline.push(this.$partition(S));
    pipeline.push(this.$validate_definition(S));
    pipeline.push(this.$collect(S, R));
    pipeline.push(SP.$drain(function() {
      if (handler != null) {
        return handler(null, R);
      }
    }));
    SP.pull(...pipeline);
    if (handler != null) {
      return null;
    } else {
      return R;
    }
  };

}).call(this);

//# sourceMappingURL=main.js.map