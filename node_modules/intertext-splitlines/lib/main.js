(function() {
  'use strict';
  var CND, badge, debug, decode, defaults, isa, type_of, urge, validate, validate_optional, warn;

  //###########################################################################################################
  CND = require('cnd');

  badge = 'INTERTEXT/SPLITLINES';

  debug = CND.get_logger('debug', badge);

  urge = CND.get_logger('urge', badge);

  warn = CND.get_logger('warn', badge);

  this.types = new (require('intertype')).Intertype();

  ({isa, validate, validate_optional, type_of} = this.types.export());

  //-----------------------------------------------------------------------------------------------------------
  this.types.declare('sl_settings', {
    tests: {
      'x is an object': function(x) {
        return this.isa.object(x);
      },
      'x.?splitter is a nonempty_text or a nonempty buffer': function(x) {
        if (x.splitter == null) {
          return true;
        }
        return (this.isa.nonempty_text(x.splitter)) || ((this.isa.buffer(x.splitter)) && x.length > 0);
      },
      /* TAINT use `encoding` for better flexibility */
      'x.?decode is a boolean': function(x) {
        return this.isa_optional.boolean(x.decode);
      },
      'x.?skip_empty_last is a boolean': function(x) {
        return this.isa_optional.boolean(x.skip_empty_last);
      },
      'x.?keep_newlines is a boolean': function(x) {
        return this.isa_optional.boolean(x.keep_newlines);
      }
    }
  });

  //-----------------------------------------------------------------------------------------------------------
  defaults = {
    splitter: '\n',
    decode: true,
    skip_empty_last: true,
    keep_newlines: false
  };

  //-----------------------------------------------------------------------------------------------------------
  this.new_context = function(settings) {
    validate_optional.sl_settings(settings);
    settings = {...defaults, ...settings};
    settings.offset = 0;
    settings.lastMatch = 0;
    if (isa.text(settings.splitter)) {
      settings.splitter = Buffer.from(settings.splitter);
    }
    return {
      collector: null,
      ...settings
    };
  };

  //-----------------------------------------------------------------------------------------------------------
  decode = function(me, data) {
    if (!me.decode) {
      return data;
    }
    return data.toString('utf-8');
  };

  //-----------------------------------------------------------------------------------------------------------
  this.walk_lines = function*(me, d) {
    var delta, idx;
    /* thx to https://github.com/maxogden/binary-split/blob/master/index.js */
    validate.buffer(d);
    me.offset = 0;
    me.lastMatch = 0;
    delta = me.keep_newlines ? me.splitter.length : 0;
    if (me.collector != null) {
      d = Buffer.concat([me.collector, d]);
      me.offset = me.collector.length;
      me.collector = null;
    }
    while (true) {
      idx = d.indexOf(me.splitter, me.offset - me.splitter.length + 1);
      if (idx >= 0 && idx < d.length) {
        yield decode(me, d.slice(me.lastMatch, idx + delta));
        me.offset = idx + me.splitter.length;
        me.lastMatch = me.offset;
      } else {
        me.collector = d.slice(me.lastMatch);
        break;
      }
    }
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.flush = function*(me) {
    var line;
    if (me.collector != null) {
      line = decode(me, me.collector);
      if (!(me.skip_empty_last && line.length === 0)) {
        yield line;
      }
      me.collector = null;
    }
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.splitlines = function(settings, ...buffers) {
    var R, buffer, ctx, i, len, line, ref, ref1, type;
    buffers = buffers.flat(2e308);
    switch (type = type_of(settings)) {
      case 'object':
      case 'null':
        null;
        break;
      case 'buffer':
        buffers.unshift(settings);
        settings = null;
        break;
      case 'list':
        buffers.splice(0, 0, ...(settings.flat(2e308)));
        settings = null;
        break;
      default:
        throw new Error(`^splitlines@26258^ expected null, an object, a buffer or a list, got a ${type}`);
    }
    ctx = this.new_context(settings);
    R = [];
    for (i = 0, len = buffers.length; i < len; i++) {
      buffer = buffers[i];
      ref = this.walk_lines(ctx, buffer);
      for (line of ref) {
        R.push(line);
      }
    }
    ref1 = this.flush(ctx);
    for (line of ref1) {
      R.push(line);
    }
    return R;
  };

}).call(this);

//# sourceMappingURL=main.js.map