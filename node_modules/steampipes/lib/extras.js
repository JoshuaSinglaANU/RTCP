(function() {
  'use strict';
  var CND, SL, badge, debug, echo, freeze, help, info, isa, rpr, types, urge, validate, validate_optional, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'STEAMPIPES-EXTRA';

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  info = CND.get_logger('info', badge);

  urge = CND.get_logger('urge', badge);

  help = CND.get_logger('help', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  types = new (require('intertype')).Intertype();

  ({isa, validate, validate_optional} = types.export());

  SL = require('intertext-splitlines');

  freeze = Object.freeze;

  //-----------------------------------------------------------------------------------------------------------
  this.$split_lines = function(settings = null) {
    var ctx, last;
    ctx = SL.new_context(settings);
    last = Symbol('last');
    return this.$({last}, (d, send) => {
      var line, ref, ref1;
      if (d === last) {
        ref = SL.flush(ctx);
        for (line of ref) {
          send(line);
        }
        return null;
      }
      if (d == null) {
        return;
      }
      if (!isa.buffer(d)) {
        return;
      }
      ref1 = SL.walk_lines(ctx, d);
      for (line of ref1) {
        send(line);
      }
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$split_channels = function() {
    var last, splitliners;
    splitliners = {};
    last = Symbol('last');
    return this.$({last}, (d, send) => {
      var $key, $value, ctx, ref, ref1;
      ({$key, $value} = d);
      if ((ctx = splitliners[$key]) == null) {
        ctx = splitliners[$key] = SL.new_context();
      }
      if (d === last) {
        ref = SL.flush(ctx);
        for ($value of ref) {
          send(freeze({$key, $value}));
        }
        return null;
      }
      if ((d == null) || (!types.isa.buffer(d.$value))) {
        return send(d);
      }
      ref1 = SL.walk_lines(ctx, $value);
      for ($value of ref1) {
        send(freeze({$key, $value}));
      }
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$batch = function(size, transform) {
    var collector, last;
    validate.positive_integer(size);
    validate_optional.function(transform);
    collector = null;
    last = Symbol('last');
    return this.$({last}, function(d, send) {
      if (d === last) {
        if (collector != null) {
          send(collector);
          collector = null;
        }
        return;
      }
      (collector != null ? collector : collector = []).push(d);
      if (collector.length >= size) {
        send(transform != null ? transform(collector) : collector);
        return collector = null;
      }
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$sample = function(p = 0.5, settings) {
    var headers, is_first, ref, ref1, rnd, seed;
    validate.nonnegative(p);
    if (p === 1) {
      // validate_optional.positive settings.seed
      //.........................................................................................................
      return $(function(d, send) {
        return send(d);
      });
    }
    if (p === 0) {
      return $(function(d, send) {
        return null;
      });
    }
    //.........................................................................................................
    headers = (ref = settings != null ? settings['headers'] : void 0) != null ? ref : false;
    seed = (ref1 = settings != null ? settings['seed'] : void 0) != null ? ref1 : null;
    is_first = headers;
    rnd = seed != null ? CND.get_rnd(seed) : Math.random;
    //.........................................................................................................
    return this.$((d, send) => {
      if (is_first) {
        is_first = false;
        return send(d);
      }
      if (rnd() < p) {
        return send(d);
      }
    });
  };

}).call(this);

//# sourceMappingURL=extras.js.map