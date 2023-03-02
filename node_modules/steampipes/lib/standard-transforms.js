(function() {
  'use strict';
  var CND, assign, badge, debug, echo, help, info, isa, jr, rpr, type_of, urge, validate, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'STEAMPIPES/STANDARD-TRANSFORMS';

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  info = CND.get_logger('info', badge);

  urge = CND.get_logger('urge', badge);

  help = CND.get_logger('help', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  ({jr} = CND);

  assign = Object.assign;

  //...........................................................................................................
  ({isa, validate, type_of} = require('./types'));

  //-----------------------------------------------------------------------------------------------------------
  this.$map = function(method) {
    return this.$(function(d, send) {
      return send(method(d));
    });
  };

  this.$pass = function() {
    return this.$(function(d, send) {
      return send(d);
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$drain = function(settings = null, on_end = null) {
    var arity;
    switch ((arity = arguments.length)) {
      case 0:
        null;
        break;
      case 2:
        null;
        break;
      case 1:
        if (isa.function(settings)) {
          [settings, on_end] = [null, settings];
        }
        break;
      default:
        throw new Error(`expected 0 to 2 arguments, got ${arity}`);
    }
    if (settings == null) {
      settings = {};
    }
    if (on_end != null) {
      settings.on_end = on_end;
    }
    return this._$drain(settings);
  };

  //-----------------------------------------------------------------------------------------------------------
  this._$drain = function(settings) {
    var R, arity, call_with_datoms, on_end, ref, ref1, sink, use_sink;
    sink = (ref = settings != null ? settings.sink : void 0) != null ? ref : true;
    if ((on_end = settings.on_end) != null) {
      validate.function(on_end);
      switch ((arity = on_end.length)) {
        case 0:
          null;
          break;
        case 1:
          if (sink === true) {
            sink = [];
          }
          break;
        default:
          throw new Error(`expected 0 to 1 arguments, got ${arity}`);
      }
    }
    use_sink = (sink != null) && (sink !== true);
    call_with_datoms = (on_end != null) && on_end.length === 1;
    R = {[ref1 = this.marks.validated]: ref1, sink, on_end, call_with_datoms, use_sink};
    if (on_end != null) {
      R.on_end = on_end;
    }
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$show = function(settings) {
    var ref, title;
    title = ((ref = settings != null ? settings.title : void 0) != null ? ref : 'steampipes ➔') + ' ';
    return this.$((d, send) => {
      echo((CND.grey(title)) + (CND.blue(rpr(d))));
      return send(d);
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$watch = function(settings, method) {
    /* If any `surround` feature is called for, wrap all surround values so that we can safely
         distinguish between them and ordinary stream values; this is necessary to prevent them from leaking
         into the regular stream outside the `$watch` transform: */
    var arity, key, take_second, value;
    switch (arity = arguments.length) {
      case 1:
        method = settings;
        return this.$((d, send) => {
          method(d);
          return send(d);
        });
      //.......................................................................................................
      case 2:
        if (settings == null) {
          return this.$watch(method);
        }
        take_second = Symbol('take-second');
        settings = assign({}, settings);
        for (key in settings) {
          value = settings[key];
          settings[key] = [take_second, value];
        }
        //.....................................................................................................
        return this.$(settings, (d, send) => {
          if ((isa.list(d)) && (d[0] === take_second)) {
            method(d[1]);
          } else {
            method(d);
            send(d);
          }
          return null;
        });
    }
    //.........................................................................................................
    throw new Error(`µ18244 expected one or two arguments, got ${arity}`);
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$filter = function(filter) {
    var type;
    if ((type = type_of(filter)) !== 'function') {
      throw new Error(`^steampipes/$filter@5663^ expected a function, got a ${type}`);
    }
    return this.$((data, send) => {
      if (filter(data)) {
        return send(data);
      }
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$as_text = function(settings) {
    return (d, send) => {
      var ref, serialize;
      serialize = (ref = settings != null ? settings['serialize'] : void 0) != null ? ref : JSON.stringify;
      return this.$map((data) => {
        return serialize(data);
      });
    };
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$collect = function(settings) {
    var collector, last, ref;
    collector = (ref = settings != null ? settings.collector : void 0) != null ? ref : [];
    last = Symbol('last');
    return this.$({last}, (d, send) => {
      if (d === last) {
        return send(collector);
      }
      collector.push(d);
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$chunkify_keep = function(filter, postprocess = null) {
    return this._$chunkify(filter, postprocess, true);
  };

  this.$chunkify_toss = function(filter, postprocess = null) {
    return this._$chunkify(filter, postprocess, false);
  };

  //-----------------------------------------------------------------------------------------------------------
  this._$chunkify = function(filter, postprocess, keep) {
    var collector, last;
    if (postprocess == null) {
      postprocess = function(x) {
        return x;
      };
    }
    validate.function(filter);
    validate.function(postprocess);
    collector = null;
    last = Symbol('last');
    //.........................................................................................................
    return this.$({last}, function(d, send) {
      if (d === last) {
        if (collector != null) {
          send(postprocess(collector));
          collector = null;
        }
        return null;
      }
      if (filter(d)) {
        if (keep) {
          (collector != null ? collector : collector = []).push(d);
        }
        if (collector != null) {
          send(postprocess(collector));
          collector = null;
        }
        return null;
      }
      (collector != null ? collector : collector = []).push(d);
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  /* Given a `settings` object, add values to the stream as `$ settings, ( d, send ) -> send d` would do,
  e.g. `$surround { first: 'first!', between: 'to appear in-between two values', }`. */
  this.$surround = function(settings) {
    return this.$(settings, (d, send) => {
      return send(d);
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.leapfrog = function(jumper, transform) {
    return this.$({
      leapfrog: jumper
    }, transform);
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$once_before_first = function(transform) {
    /* Call transform once before any data item comes down the stream (if any). Transform must only accept
     a single `send` argument and can send as many data items down the stream which will be prepended
     to those items coming from upstream. */
    var arity, first, sink;
    if ((arity = transform.length) !== 1) {
      throw new Error(`^steampipes/pullremit@7033^ transform arity ${arity} not implemented`);
    }
    sink = [];
    first = Symbol('first');
    return this.$({first}, (d, send) => {
      var d_, i, len;
      if (d !== first) {
        return send(d);
      }
      /* TAINT missing `send.end()` method */
      transform(sink.push.bind(sink));
      for (i = 0, len = sink.length; i < len; i++) {
        d_ = sink[i];
        send(d_);
      }
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$once_with_first = function(transform) {
    /* Call transform once with the first data item (if any). */
    var is_first;
    is_first = true;
    return this.$((d, send) => {
      if (!is_first) {
        return send(d);
      }
      is_first = false;
      transform(d, send);
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$once_after_last = function(transform) {
    /* Call transform once after any data item comes down the stream (if any). Transform must only accept
     a single `send` argument and can send as many data items down the stream which will be appended
     to those items coming from upstream. */
    var arity, last, sink;
    if ((arity = transform.length) !== 1) {
      throw new Error(`^steampipes/pullremit@7033^ transform arity ${arity} not implemented`);
    }
    sink = [];
    last = Symbol('last');
    return this.$({last}, (d, send) => {
      var d_, i, len;
      if (d !== last) {
        return send(d);
      }
      /* TAINT missing `send.end()` method */
      transform(sink.push.bind(sink));
      for (i = 0, len = sink.length; i < len; i++) {
        d_ = sink[i];
        send(d_);
      }
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$once_async_before_first = function(transform) {
    /* Call transform once before any data item comes down the stream (if any). Transform must only accept
     a single `send` argument and can send as many data items down the stream which will be prepended
     to those items coming from upstream. */
    var arity, first, pipeline, sink;
    if ((arity = transform.length) !== 2) {
      throw new Error(`^steampipes/pullremit@7033^ transform arity ${arity} not implemented`);
    }
    sink = [];
    pipeline = [];
    first = Symbol('first');
    pipeline.push(this.$({first}, (d, send) => {
      return send(d);
    }));
    pipeline.push(this.$async(async(d, send, done) => {
      if (d !== first) {
        send(d);
        return done();
      }
      /* TAINT missing `send.end()` method */
      await transform(sink.push.bind(sink), () => {
        var d_, i, len;
        for (i = 0, len = sink.length; i < len; i++) {
          d_ = sink[i];
          send(d_);
        }
        return done();
      });
      return null;
    }));
    return this.pull(...pipeline);
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$once_async_after_last = function(transform) {
    /* Call transform once before any data item comes down the stream (if any). Transform must only accept
     a single `send` argument and can send as many data items down the stream which will be prepended
     to those items coming from upstream. */
    var arity, last, pipeline, sink;
    if ((arity = transform.length) !== 2) {
      throw new Error(`^steampipes/pullremit@7034^ transform arity ${arity} not implemented`);
    }
    sink = [];
    pipeline = [];
    last = Symbol('last');
    pipeline.push(this.$({last}, (d, send) => {
      return send(d);
    }));
    pipeline.push(this.$async(async(d, send, done) => {
      if (d !== last) {
        send(d);
        return done();
      }
      /* TAINT missing `send.end()` method */
      await transform(sink.push.bind(sink), () => {
        var d_, i, len;
        for (i = 0, len = sink.length; i < len; i++) {
          d_ = sink[i];
          send(d_);
        }
        return done();
      });
      return null;
    }));
    return this.pull(...pipeline);
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$tee = function(bystream) {
    var last, pipeline, source;
    source = this.new_push_source();
    last = Symbol('last');
    pipeline = [];
    pipeline.push(source);
    pipeline.push(bystream);
    this.pull(...pipeline);
    return this.$({last}, (d, send) => {
      if (d === last) {
        return source.end();
      }
      source.send(d);
      return send(d);
    });
  };

  //===========================================================================================================
  // SELECT
  //-----------------------------------------------------------------------------------------------------------
  this.$select = function(selector, callback) {
    /* Call `callback` function when `DATOM.select d, selector` returns `true`. Callback can have zero or
     one argument in which case it will be a passive `$watch()`er; if it has two arguments as in
     `( d, send ) ->` then the callback is responsible for sending data on into the pipeline. In any event
     all events that do *not* match `selector` will be sent on to downstream. */
    var DATOM, arity;
    DATOM = require('datom');
    validate.function(callback);
    //.........................................................................................................
    switch (arity = callback.length) {
      //.......................................................................................................
      case 0:
        return this.$watch((d) => {
          if (DATOM.select(d, selector)) {
            return callback();
          }
        });
      //.......................................................................................................
      case 1:
        return this.$watch((d) => {
          if (DATOM.select(d, selector)) {
            return callback(d);
          }
        });
      //.......................................................................................................
      case 2:
        return this.$((d, send) => {
          if (DATOM.select(d, selector)) {
            callback(d, send);
          } else {
            send(d);
          }
          return null;
        });
      default:
        //.......................................................................................................
        throw new Error(`expected callback with up to 2 arguments, got one with ${arity}`);
    }
    return null;
  };

}).call(this);

//# sourceMappingURL=standard-transforms.js.map