(function() {
  //###########################################################################################################
  var CND, VOID, badge, bytecount_date, bytecount_float, bytecount_singular, bytecount_typemarker, cast, debug, declare, grow_rbuffer, isa, rbuffer, rbuffer_max_size, rbuffer_min_size, release_extraneous_rbuffer_bytes, rpr, size_of, symbol_fallback, tm_date, tm_false, tm_hi, tm_list, tm_lo, tm_ninfinity, tm_nnumber, tm_null, tm_pinfinity, tm_pnumber, tm_private, tm_text, tm_true, tm_void, type_of, validate, warn;

  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'HOLLERITH-CODEC/MAIN';

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  //...........................................................................................................
  this.types = require('./types');

  ({isa, validate, cast, declare, size_of, type_of} = this.types);

  VOID = Symbol('VOID');

  //-----------------------------------------------------------------------------------------------------------
  this['typemarkers'] = {};

  //...........................................................................................................
  tm_lo = this['typemarkers']['lo'] = 0x00;

  tm_null = this['typemarkers']['null'] = 'B'.codePointAt(0); // 0x42

  tm_false = this['typemarkers']['false'] = 'C'.codePointAt(0); // 0x43

  tm_true = this['typemarkers']['true'] = 'D'.codePointAt(0); // 0x44

  tm_list = this['typemarkers']['list'] = 'E'.codePointAt(0); // 0x45

  tm_date = this['typemarkers']['date'] = 'G'.codePointAt(0); // 0x47

  tm_ninfinity = this['typemarkers']['ninfinity'] = 'J'.codePointAt(0); // 0x4a

  tm_nnumber = this['typemarkers']['nnumber'] = 'K'.codePointAt(0); // 0x4b

  tm_void = this['typemarkers']['void'] = 'L'.codePointAt(0); // 0x4c

  tm_pnumber = this['typemarkers']['pnumber'] = 'M'.codePointAt(0); // 0x4d

  tm_pinfinity = this['typemarkers']['pinfinity'] = 'N'.codePointAt(0); // 0x4e

  tm_text = this['typemarkers']['text'] = 'T'.codePointAt(0); // 0x54

  tm_private = this['typemarkers']['private'] = 'Z'.codePointAt(0); // 0x5a

  tm_hi = this['typemarkers']['hi'] = 0xff;

  //-----------------------------------------------------------------------------------------------------------
  this['bytecounts'] = {};

  bytecount_singular = this['bytecounts']['singular'] = 1;

  bytecount_typemarker = this['bytecounts']['typemarker'] = 1;

  bytecount_float = this['bytecounts']['float'] = 9;

  bytecount_date = this['bytecounts']['date'] = bytecount_float + 1;

  //-----------------------------------------------------------------------------------------------------------
  this['sentinels'] = {};

  //...........................................................................................................
  /* http://www.merlyn.demon.co.uk/js-datex.htm */
  this['sentinels']['firstdate'] = new Date(-8640000000000000);

  this['sentinels']['lastdate'] = new Date(+8640000000000000);

  //-----------------------------------------------------------------------------------------------------------
  this['keys'] = {};

  //...........................................................................................................
  this['keys']['lo'] = Buffer.alloc(1, this['typemarkers']['lo']);

  this['keys']['hi'] = Buffer.alloc(1, this['typemarkers']['hi']);

  //-----------------------------------------------------------------------------------------------------------
  this['symbols'] = {};

  symbol_fallback = this['fallback'] = Symbol('fallback');

  //===========================================================================================================
  // RESULT BUFFER (RBUFFER)
  //-----------------------------------------------------------------------------------------------------------
  rbuffer_min_size = 1024;

  rbuffer_max_size = 65536;

  rbuffer = Buffer.alloc(rbuffer_min_size);

  //-----------------------------------------------------------------------------------------------------------
  grow_rbuffer = function() {
    var factor, new_result_buffer, new_size;
    factor = 2;
    new_size = Math.floor(rbuffer.length * factor + 0.5);
    // warn "µ44542 growing rbuffer to #{new_size} bytes"
    new_result_buffer = Buffer.alloc(new_size);
    rbuffer.copy(new_result_buffer);
    rbuffer = new_result_buffer;
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  release_extraneous_rbuffer_bytes = function() {
    if (rbuffer.length > rbuffer_max_size) {
      // warn "µ44543 shrinking rbuffer to #{rbuffer_max_size} bytes"
      rbuffer = Buffer.alloc(rbuffer_max_size);
    }
    return null;
  };

  //===========================================================================================================
  // VARIANTS
  //-----------------------------------------------------------------------------------------------------------
  this.write_singular = function(idx, value) {
    var typemarker;
    while (!(rbuffer.length >= idx + bytecount_singular)) {
      grow_rbuffer();
    }
    if (value === null) {
      typemarker = tm_null;
    } else if (value === false) {
      typemarker = tm_false;
    } else if (value === true) {
      typemarker = tm_true;
    } else if (value === VOID) {
      typemarker = tm_void;
    } else {
      throw new Error(`µ56733 unable to encode value of type ${type_of(value)}`);
    }
    rbuffer[idx] = typemarker;
    return idx + bytecount_singular;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.read_singular = function(buffer, idx) {
    var typemarker, value;
    switch (typemarker = buffer[idx]) {
      case tm_null:
        value = null;
        break;
      case tm_false:
        value = false;
        break;
      case tm_true:
        value = true;
        break;
      /* TAINT not strictly needed as we eliminate VOID prior to decoding */
      case tm_void:
        value = VOID;
        break;
      default:
        throw new Error(`µ57564 unable to decode 0x${typemarker.toString(16)} at index ${idx} (${rpr(buffer)})`);
    }
    return [idx + bytecount_singular, value];
  };

  //===========================================================================================================
  // PRIVATES
  //-----------------------------------------------------------------------------------------------------------
  this.write_private = function(idx, value, encoder) {
    var encoded_value, proper_value, ref, type, wrapped_value;
    while (!(rbuffer.length >= idx + 3 * bytecount_typemarker)) {
      grow_rbuffer();
    }
    //.........................................................................................................
    rbuffer[idx] = tm_private;
    idx += bytecount_typemarker;
    //.........................................................................................................
    rbuffer[idx] = tm_list;
    idx += bytecount_typemarker;
    //.........................................................................................................
    type = (ref = value['type']) != null ? ref : 'private';
    proper_value = value['value'];
    //.........................................................................................................
    if (encoder != null) {
      encoded_value = encoder(type, proper_value, symbol_fallback);
      if (encoded_value !== symbol_fallback) {
        proper_value = encoded_value;
      }
    //.........................................................................................................
    } else if (type.startsWith('-')) {
      /* Built-in private types */
      switch (type) {
        case '-set':
          null; // already dealt with in `write`
          break;
        default:
          throw new Error(`µ58395 unknown built-in private type ${rpr(type)}`);
      }
    }
    //.........................................................................................................
    wrapped_value = [type, proper_value];
    idx = this._encode(wrapped_value, idx);
    //.........................................................................................................
    rbuffer[idx] = tm_lo;
    idx += bytecount_typemarker;
    //.........................................................................................................
    return idx;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.read_private = function(buffer, idx, decoder) {
    /* TAINT wasting bytes because wrapped twice */
    var R, type, value;
    idx += bytecount_typemarker;
    [idx, [type, value]] = this.read_list(buffer, idx);
    //.........................................................................................................
    if (decoder != null) {
      R = decoder(type, value, symbol_fallback);
      if (R === void 0) {
        throw new Error("µ59226 encountered illegal value `undefined` when reading private type");
      }
      if (R === symbol_fallback) {
        R = {type, value};
      }
    //.........................................................................................................
    } else if (type.startsWith('-')) {
      /* Built-in private types */
      switch (type) {
        case '-set':
          R = new Set(value[0]);
          break;
        default:
          throw new Error(`µ60057 unknown built-in private type ${rpr(type)}`);
      }
    } else {
      //.........................................................................................................
      R = {type, value};
    }
    return [idx, R];
  };

  //===========================================================================================================
  // NUMBERS
  //-----------------------------------------------------------------------------------------------------------
  this.write_number = function(idx, number) {
    var type;
    while (!(rbuffer.length >= idx + bytecount_float)) {
      grow_rbuffer();
    }
    if (number < 0) {
      type = tm_nnumber;
      number = -number;
    } else {
      type = tm_pnumber;
    }
    rbuffer[idx] = type;
    rbuffer.writeDoubleBE(number, idx + 1);
    if (type === tm_nnumber) {
      this._invert_buffer(rbuffer, idx);
    }
    return idx + bytecount_float;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.write_infinity = function(idx, number) {
    while (!(rbuffer.length >= idx + bytecount_singular)) {
      grow_rbuffer();
    }
    rbuffer[idx] = number === -2e308 ? tm_ninfinity : tm_pinfinity;
    return idx + bytecount_singular;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.read_nnumber = function(buffer, idx) {
    var copy;
    if (buffer[idx] !== tm_nnumber) {
      throw new Error(`µ60888 not a negative number at index ${idx}`);
    }
    copy = this._invert_buffer(Buffer.from(buffer.slice(idx, idx + bytecount_float)), 0);
    return [idx + bytecount_float, -(copy.readDoubleBE(1))];
  };

  //-----------------------------------------------------------------------------------------------------------
  this.read_pnumber = function(buffer, idx) {
    if (buffer[idx] !== tm_pnumber) {
      throw new Error(`µ61719 not a positive number at index ${idx}`);
    }
    return [idx + bytecount_float, buffer.readDoubleBE(idx + 1)];
  };

  //-----------------------------------------------------------------------------------------------------------
  this._invert_buffer = function(buffer, idx) {
    var i, j, ref, ref1;
    for (i = j = ref = idx + 1, ref1 = idx + 8; (ref <= ref1 ? j <= ref1 : j >= ref1); i = ref <= ref1 ? ++j : --j) {
      buffer[i] = ~buffer[i];
    }
    return buffer;
  };

  //===========================================================================================================
  // DATES
  //-----------------------------------------------------------------------------------------------------------
  this.write_date = function(idx, date) {
    var number;
    while (!(rbuffer.length >= idx + bytecount_date)) {
      grow_rbuffer();
    }
    number = +date;
    rbuffer[idx] = tm_date;
    return this.write_number(idx + 1, number);
  };

  //-----------------------------------------------------------------------------------------------------------
  this.read_date = function(buffer, idx) {
    var type, value;
    if (buffer[idx] !== tm_date) {
      throw new Error(`µ62550 not a date at index ${idx}`);
    }
    switch (type = buffer[idx + 1]) {
      case tm_nnumber:
        [idx, value] = this.read_nnumber(buffer, idx + 1);
        break;
      case tm_pnumber:
        [idx, value] = this.read_pnumber(buffer, idx + 1);
        break;
      default:
        throw new Error(`µ63381 unknown date type marker 0x${type.toString(16)} at index ${idx}`);
    }
    return [idx, new Date(value)];
  };

  //===========================================================================================================
  // TEXTS
  //-----------------------------------------------------------------------------------------------------------
  this.write_text = function(idx, text) {
    var bytecount_text;
    text = text.replace(/\x01/g, '\x01\x02');
    text = text.replace(/\x00/g, '\x01\x01');
    bytecount_text = (Buffer.byteLength(text, 'utf-8')) + 2;
    while (!(rbuffer.length >= idx + bytecount_text)) {
      grow_rbuffer();
    }
    rbuffer[idx] = tm_text;
    rbuffer.write(text, idx + 1);
    rbuffer[idx + bytecount_text - 1] = tm_lo;
    return idx + bytecount_text;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.read_text = function(buffer, idx) {
    var R, byte, stop_idx;
    if (buffer[idx] !== tm_text) {
      // urge '©J2d6R', buffer[ idx ], buffer[ idx ] is tm_text
      throw new Error(`µ64212 not a text at index ${idx}`);
    }
    stop_idx = idx;
    while (true) {
      stop_idx += +1;
      if ((byte = buffer[stop_idx]) === tm_lo) {
        break;
      }
      if (byte == null) {
        throw new Error(`µ65043 runaway string at index ${idx}`);
      }
    }
    R = buffer.toString('utf-8', idx + 1, stop_idx);
    R = R.replace(/\x01\x01/g, '\x00');
    R = R.replace(/\x01\x02/g, '\x01');
    return [stop_idx + 1, R];
  };

  //===========================================================================================================
  // LISTS
  //-----------------------------------------------------------------------------------------------------------
  this.read_list = function(buffer, idx) {
    var R, byte, value;
    if (buffer[idx] !== tm_list) {
      throw new Error(`µ65874 not a list at index ${idx}`);
    }
    R = [];
    idx += +1;
    while (true) {
      if ((byte = buffer[idx]) === tm_lo) {
        break;
      }
      [idx, value] = this._decode(buffer, idx, true);
      R.push(value[0]);
      if (byte == null) {
        throw new Error(`µ66705 runaway list at index ${idx}`);
      }
    }
    return [idx + 1, R];
  };

  //===========================================================================================================

  //-----------------------------------------------------------------------------------------------------------
  this.write = function(idx, value, encoder) {
    var type;
    if (value === VOID) {
      return this.write_singular(idx, value);
    }
    switch (type = type_of(value)) {
      case 'text':
        return this.write_text(idx, value);
      case 'float':
        return this.write_number(idx, value);
      case 'infinity':
        return this.write_infinity(idx, value);
      case 'date':
        return this.write_date(idx, value);
      //.......................................................................................................
      case 'set':
        /* TAINT wasting bytes because wrapped too deep */
        return this.write_private(idx, {
          type: '-set',
          value: [Array.from(value)]
        });
    }
    if (isa.object(value)) {
      //.........................................................................................................
      return this.write_private(idx, value, encoder);
    }
    return this.write_singular(idx, value);
  };

  //===========================================================================================================
  // PUBLIC API
  //-----------------------------------------------------------------------------------------------------------
  this.encode = function(key, encoder) {
    var R, idx, type;
    key = key.slice(0);
    key.push(VOID);
    rbuffer.fill(0x00);
    if ((type = type_of(key)) !== 'list') {
      throw new Error(`µ67536 expected a list, got a ${type}`);
    }
    idx = this._encode(key, 0, encoder);
    R = Buffer.alloc(idx);
    rbuffer.copy(R, 0, 0, idx);
    release_extraneous_rbuffer_bytes();
    //.........................................................................................................
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.encode_plus_hi = function(key, encoder) {
    var R, idx, type;
    /* TAINT code duplication */
    rbuffer.fill(0x00);
    if ((type = type_of(key)) !== 'list') {
      throw new Error(`µ68367 expected a list, got a ${type}`);
    }
    idx = this._encode(key, 0, encoder);
    while (!(rbuffer.length >= idx + 1)) {
      grow_rbuffer();
    }
    rbuffer[idx] = tm_hi;
    idx += +1;
    R = Buffer.alloc(idx);
    rbuffer.copy(R, 0, 0, idx);
    release_extraneous_rbuffer_bytes();
    //.........................................................................................................
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  this._encode = function(key, idx, encoder) {
    var element, element_idx, error, j, k, key_rpr, l, last_element_idx, len, len1, len2, sub_element;
    last_element_idx = key.length - 1;
    for (element_idx = j = 0, len = key.length; j < len; element_idx = ++j) {
      element = key[element_idx];
      try {
        if (isa.list(element)) {
          rbuffer[idx] = tm_list;
          idx += +1;
          for (k = 0, len1 = element.length; k < len1; k++) {
            sub_element = element[k];
            idx = this._encode([sub_element], idx, encoder);
          }
          rbuffer[idx] = tm_lo;
          idx += +1;
        } else {
          idx = this.write(idx, element, encoder);
        }
      } catch (error1) {
        error = error1;
        key_rpr = [];
        for (l = 0, len2 = key.length; l < len2; l++) {
          element = key[l];
          if (isa.buffer(element)) {
            throw new Error("µ45533 unable to encode buffers");
          } else {
            // key_rpr.push "#{@rpr_of_buffer element, key[ 2 ]}"
            key_rpr.push(rpr(element));
          }
        }
        warn(`µ44544 detected problem with key [ ${rpr(key_rpr.join(', '))} ]`);
        throw error;
      }
    }
    //.........................................................................................................
    return idx;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.decode = function(buffer, decoder) {
    buffer = buffer.slice(0, buffer.length - 1);
    return (this._decode(buffer, 0, false, decoder))[1];
  };

  //-----------------------------------------------------------------------------------------------------------
  this._decode = function(buffer, idx, single, decoder) {
    var R, last_idx, type, value;
    R = [];
    last_idx = buffer.length - 1;
    while (true) {
      if (idx > last_idx) {
        break;
      }
      switch (type = buffer[idx]) {
        case tm_list:
          [idx, value] = this.read_list(buffer, idx);
          break;
        case tm_text:
          [idx, value] = this.read_text(buffer, idx);
          break;
        case tm_nnumber:
          [idx, value] = this.read_nnumber(buffer, idx);
          break;
        case tm_ninfinity:
          [idx, value] = [idx + 1, -2e308];
          break;
        case tm_pnumber:
          [idx, value] = this.read_pnumber(buffer, idx);
          break;
        case tm_pinfinity:
          [idx, value] = [idx + 1, +2e308];
          break;
        case tm_date:
          [idx, value] = this.read_date(buffer, idx);
          break;
        case tm_private:
          [idx, value] = this.read_private(buffer, idx, decoder);
          break;
        default:
          [idx, value] = this.read_singular(buffer, idx);
      }
      R.push(value);
      if (single) {
        break;
      }
    }
    //.........................................................................................................
    return [idx, R];
  };

  // debug ( require './dump' ).@rpr_of_buffer null, buffer = @encode [ 'aaa', [], ]
  // debug '©tP5xQ', @decode buffer

  //===========================================================================================================

  //-----------------------------------------------------------------------------------------------------------
  this.encodings = {
    //.........................................................................................................
    dbcs2: `⓪①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳㉑㉒㉓㉔㉕㉖㉗㉘㉙㉚㉛
㉜！＂＃＄％＆＇（）＊＋，－．／０１２３４５６７８９：；＜＝＞？
＠ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ［＼］＾＿
｀ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ｛｜｝～㉠
㉝㉞㉟㊱㊲㊳㊴㊵㊶㊷㊸㊹㊺㊻㊼㊽㊾㊿㋐㋑㋒㋓㋔㋕㋖㋗㋘㋙㋚㋛㋜㋝
㋞㋟㋠㋡㋢㋣㋤㋥㋦㋧㋨㋩㋪㋫㋬㋭㋮㋯㋰㋱㋲㋳㋴㋵㋶㋷㋸㋹㋺㋻㋼㋽
㋾㊊㊋㊌㊍㊎㊏㊐㊑㊒㊓㊔㊕㊖㊗㊘㊙㊚㊛㊜㊝㊞㊟㊠㊡㊢㊣㊤㊥㊦㊧㊨
㊩㊪㊫㊬㊭㊮㊯㊰㊀㊁㊂㊃㊄㊅㊆㊇㊈㊉㉈㉉㉊㉋㉌㉍㉎㉏⓵⓶⓷⓸⓹〓`,
    //.........................................................................................................
    aleph: `БДИЛЦЧШЭЮƆƋƏƐƔƥƧƸψŐőŒœŊŁłЯɔɘɐɕəɞ
␣!"#$%&'()*+,-./0123456789:;<=>?
@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_
\`abcdefghijklmnopqrstuvwxyz{|}~ω
ΓΔΘΛΞΠΣΦΨΩαβγδεζηθικλμνξπρςστυφχ
Ж¡¢£¤¥¦§¨©ª«¬Я®¯°±²³´µ¶·¸¹º»¼½¾¿
ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞß
àáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ`,
    //.........................................................................................................
    rdctn: `∇≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡
␣!"#$%&'()*+,-./0123456789:;<=>?
@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_
\`abcdefghijklmnopqrstuvwxyz{|}~≡
∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃
∃∃¢£¤¥¦§¨©ª«¬Я®¯°±²³´µ¶·¸¹º»¼½¾¿
ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞß
àáâãäåæçèéêëìíîïðñò≢≢≢≢≢≢≢≢≢≢≢≢Δ`
  };

  //-----------------------------------------------------------------------------------------------------------
  this.rpr_of_buffer = function(buffer, encoding = 'rdctn') {
    return (rpr(buffer)) + ' ' + this._encode_buffer(buffer, encoding);
  };

  //-----------------------------------------------------------------------------------------------------------
  this._encode_buffer = function(buffer, encoding = 'rdctn') {
    var idx;
    if (!isa.list(encoding)) {
      encoding = this.encodings[encoding];
    }
    return ((function() {
      var j, ref, results;
      results = [];
      for (idx = j = 0, ref = buffer.length; (0 <= ref ? j < ref : j > ref); idx = 0 <= ref ? ++j : --j) {
        results.push(encoding[buffer[idx]]);
      }
      return results;
    })()).join('');
  };

  //-----------------------------------------------------------------------------------------------------------
  this._compile_encodings = function() {
    var chrs_of, encoding, length, name, ref;
    //.........................................................................................................
    chrs_of = function(text) {
      var chr;
      text = text.split(/([\ud800-\udbff].|.)/);
      return (function() {
        var j, len, results;
        results = [];
        for (j = 0, len = text.length; j < len; j++) {
          chr = text[j];
          if (chr !== '') {
            results.push(chr);
          }
        }
        return results;
      })();
    };
    ref = this.encodings;
    //.........................................................................................................
    for (name in ref) {
      encoding = ref[name];
      encoding = chrs_of(encoding.replace(/\n+/g, ''));
      if ((length = encoding.length) !== 256) {
        throw new Error(`µ69198 expected 256 characters, found ${length} in encoding ${rpr(name)}`);
      }
      this.encodings[name] = encoding;
    }
    return null;
  };

  this._compile_encodings();

  //-----------------------------------------------------------------------------------------------------------
  this.as_sortline = function(key, settings) {
    var bare, base, buffer, buffer_txt, idx, joiner, ref, ref1, ref2, ref3, stringify;
    joiner = (ref = settings != null ? settings['joiner'] : void 0) != null ? ref : ' ';
    base = (ref1 = settings != null ? settings['base'] : void 0) != null ? ref1 : 0x2800;
    stringify = (ref2 = settings != null ? settings['stringify'] : void 0) != null ? ref2 : JSON.stringify;
    bare = (ref3 = settings != null ? settings['bare'] : void 0) != null ? ref3 : false;
    buffer = this.encode(key);
    buffer_txt = ((function() {
      var j, ref4, results;
      results = [];
      for (idx = j = 0, ref4 = buffer.length - 1; (0 <= ref4 ? j < ref4 : j > ref4); idx = 0 <= ref4 ? ++j : --j) {
        results.push(String.fromCodePoint(base + buffer[idx]));
      }
      return results;
    })()).join('');
    if (bare) {
      return buffer_txt;
    }
    return buffer_txt + joiner + stringify(key);
  };

}).call(this);

//# sourceMappingURL=main.js.map