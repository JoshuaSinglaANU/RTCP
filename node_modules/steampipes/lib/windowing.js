(function() {
  'use strict';
  var CND, assign, badge, debug, echo, help, info, isa, jr, misfit, rpr, type_of, types, urge, validate, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'STEAMPIPES/WINDOWING';

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
  types = require('./types');

  ({isa, validate, type_of} = types);

  misfit = Symbol('misfit');

  //-----------------------------------------------------------------------------------------------------------
  types.declare('pipestreams_$window_settings', {
    tests: {
      "x is an object": function(x) {
        return this.isa.object(x);
      },
      "x.width is a positive": function(x) {
        return this.isa.positive(x.width);
      }
    }
  });

  //-----------------------------------------------------------------------------------------------------------
  types.declare('pipestreams_$lookaround_settings', {
    tests: {
      "x is an object": function(x) {
        return this.isa.object(x);
      },
      "x.delta is a cardinal": function(x) {
        return this.isa.cardinal(x.delta);
      }
    }
  });

  //-----------------------------------------------------------------------------------------------------------
  this.$window = function(settings) {
    /* Moving window over data items in stream. Turns stream of values into stream of
     lists each `width` elements long. */
    var _, buffer, defaults, fallback, had_value, last;
    defaults = {
      width: 3,
      fallback: null
    };
    settings = assign({}, defaults, settings);
    validate.pipestreams_$window_settings(settings);
    //.........................................................................................................
    if (settings.leapfrog != null) {
      throw new Error("µ77871 setting 'leapfrog' only valid for PS.window(), not PS.$window()");
    }
    //.........................................................................................................
    if (settings.width === 1) {
      return this.$((d, send) => {
        return send([d]);
      });
    }
    //.........................................................................................................
    last = Symbol('last');
    had_value = false;
    fallback = settings.fallback;
    buffer = (function() {
      var i, ref, results;
      results = [];
      for (_ = i = 1, ref = settings.width; (1 <= ref ? i <= ref : i >= ref); _ = 1 <= ref ? ++i : --i) {
        results.push(fallback);
      }
      return results;
    })();
    //.........................................................................................................
    return this.$({last}, (d, send) => {
      var i, ref;
      if (d === last) {
        if (had_value) {
          for (_ = i = 1, ref = settings.width; (1 <= ref ? i < ref : i > ref); _ = 1 <= ref ? ++i : --i) {
            buffer.shift();
            buffer.push(fallback);
            send(buffer.slice(0));
          }
        }
        return null;
      }
      had_value = true;
      buffer.shift();
      buffer.push(d);
      send(buffer.slice(0));
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$lookaround = function(settings) {
    /* Turns stream of values into stream of lists of values, each `( 2 * delta ) + 1` elements long;
     unlike `$window()`, will send exactly as many lists as there are values in the stream. Default
     is `delta: 1`, i.e. you get to see lists `[ prv, d, nxt, ]` where `prv` is the previous value
     (or the fallback which itself defaults to `null`), `d` is the current value, and `nxt` is the
     upcoming value (or `fallback` in case the stream will end after this value). */
    var center, defaults, delta, fallback, pipeline;
    defaults = {
      delta: 1,
      fallback: null
    };
    settings = assign({}, defaults, settings);
    validate.pipestreams_$lookaround_settings(settings);
    //.........................................................................................................
    if (settings.leapfrog != null) {
      throw new Error("µ77872 setting 'leapfrog' only valid for PS.lookaround(), not PS.$lookaround()");
    }
    //.........................................................................................................
    if (settings.delta === 0) {
      return this.$((d, send) => {
        return send([d]);
      });
    }
    //.........................................................................................................
    fallback = settings.fallback;
    delta = center = settings.delta;
    pipeline = [];
    pipeline.push(this.$window({
      width: 2 * delta + 1,
      fallback: misfit
    }));
    pipeline.push(this.$((d, send) => {
      var x;
      if (d[center] === misfit) {
        // debug 'µ11121', rpr d
        // debug 'µ11121', rpr ( ( if x is misfit then fallback else x ) for x in d )
        return null;
      }
      send((function() {
        var i, len, results;
        results = [];
        for (i = 0, len = d.length; i < len; i++) {
          x = d[i];
          results.push(x === misfit ? fallback : x);
        }
        return results;
      })());
      return null;
    }));
    return this.pull(...pipeline);
    //.........................................................................................................
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.window = function(settings, transform) {
    var R, arity, leapfrog, pipeline;
    switch (arity = arguments.length) {
      case 1:
        [settings, transform] = [null, settings];
        break;
      case 2:
        null;
        break;
      default:
        throw new Error(`µ23111 expected 1 or 2 arguments, got ${arity}`);
    }
    //.........................................................................................................
    if ((leapfrog = settings != null ? settings.leapfrog : void 0) != null) {
      throw new Error("µ65532 leapfrogging with windowing not yet implemented");
      delete settings.leapfrog;
    }
    //.........................................................................................................
    pipeline = [];
    pipeline.push(this.$window(settings));
    pipeline.push(transform);
    R = this.pull(...pipeline);
    //.........................................................................................................
    // if leapfrog?
    //   return @leapfrog leapfrog, R
    // #.........................................................................................................
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.lookaround = function(settings, transform) {
    var R, arity, leapfrog, pipeline;
    switch (arity = arguments.length) {
      case 1:
        [settings, transform] = [null, settings];
        break;
      case 2:
        null;
        break;
      default:
        throw new Error(`µ23112 expected 1 or 2 arguments, got ${arity}`);
    }
    //.........................................................................................................
    if ((leapfrog = settings != null ? settings.leapfrog : void 0) != null) {
      throw new Error("µ65533 leapfrogging with lookaround not yet implemented");
      delete settings.leapfrog;
    }
    //.........................................................................................................
    pipeline = [];
    pipeline.push(this.$lookaround(settings));
    pipeline.push(transform);
    R = this.pull(...pipeline);
    //.........................................................................................................
    if (leapfrog != null) {
      return this.leapfrog(leapfrog, R);
    }
    //.........................................................................................................
    return R;
  };

}).call(this);

//# sourceMappingURL=windowing.js.map