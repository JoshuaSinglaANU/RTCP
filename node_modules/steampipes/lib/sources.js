(function() {
  'use strict';
  var CND, assign, badge, debug, defaults, echo, help, info, isa, jr, rpr, type_of, urge, validate, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'STEAMPIPES/SOURCES';

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
  ({isa, validate, defaults, type_of} = require('./types'));

  //-----------------------------------------------------------------------------------------------------------
  this.new_value_source = function*(x) {
    return (yield* x);
  };

  //-----------------------------------------------------------------------------------------------------------
  this.new_push_source = function() {
    var R, end, ref, send;
    send = (d) => {
      if (R.duct == null) {
        return R.buffer.push(d);
      }
      R.buffer = null;
      if (d === this.signals.end) {
        return end();
      }
      R.duct.buckets[0].push(d);
      R.duct.exhaust_pipeline();
      return null;
    };
    end = () => {
      var drain, on_end;
      R.has_ended = true;
      if (R.duct == null) {
        return;
      }
      /* NOTE: ensuring that multiple calls to `end()` will be OK */      R.duct.buckets[0].push(this.signals.last);
      R.duct.exhaust_pipeline();
      drain = R.duct.transforms[R.duct.transforms.length - 1];
      if ((on_end = drain.on_end) != null) {
        if (drain.call_with_datoms) {
          drain.on_end(drain.sink);
        } else {
          drain.on_end();
        }
      }
      return R.duct = null;
    };
    R = {
      [ref = this.marks.isa_pusher]: ref,
      send,
      end,
      buffer: [],
      duct: null,
      has_ended: false
    };
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.new_wye = function(settings, source) {
    var arity, ref;
    switch (arity = arguments.length) {
      case 1:
        [settings, source] = [null, settings];
        break;
      case 2:
        null;
        break;
      default:
        throw new Error(`µ44578 expected 1 or 2 arguments, got ${arity}`);
    }
    settings = {...defaults.steampipes_new_wye_settings, ...settings};
    validate.steampipes_new_wye_settings(settings);
    return {[ref = this.marks.isa_wye]: ref, settings, source};
  };

  //-----------------------------------------------------------------------------------------------------------
  this.source_from_child_process = async function*(cp, settings) {
    var JFEE, ref, x;
    JFEE = require('jfee');
    ref = JFEE.Receiver.from_child_process(cp, settings);
    /* TAINT should wait until pipeline pulled? */
    for await (x of ref) {
      yield x;
    }
    return null;
  };

  /* TAINT we should use this implementation but fails in hengist/dev/steampipes/src/nodejs-eventemitter-as-stream-source.coffee
  #-----------------------------------------------------------------------------------------------------------
  @source_from_child_process_2 = ( cp, settings ) ->
    JFEE = require 'jfee'
    R = @new_push_source()
    R.start = ->
      setImmediate =>
        for await x from JFEE.Receiver.from_child_process cp, settings
          R.send x
        R.end()
      return null
    return R
   */
  //-----------------------------------------------------------------------------------------------------------
  this.source_from_readstream = function(readstream, settings) {
    var JFEE, R;
    JFEE = require('jfee');
    R = this.new_push_source();
    R.start = function() {
      setImmediate(async() => {
        var ref, x;
        ref = JFEE.Receiver.from_readstream(readstream, settings);
        for await (x of ref) {
          R.send(x);
        }
        return R.end();
      });
      return null;
    };
    return R;
  };

}).call(this);

//# sourceMappingURL=sources.js.map