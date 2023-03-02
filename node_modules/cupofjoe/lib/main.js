(function() {
  'use strict';
  var CND, Cupofjoe, MAIN, Multimix, alert, badge, debug, help, info, isa, jr, log, remove_notgiven, rpr, type_of, urge, validate, warn, whisper,
    splice = [].splice;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr.bind(CND);

  badge = 'CUPOFJOE';

  log = CND.get_logger('plain', badge);

  info = CND.get_logger('info', badge);

  whisper = CND.get_logger('whisper', badge);

  alert = CND.get_logger('alert', badge);

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  //...........................................................................................................
  this.types = new (require('intertype')).Intertype();

  ({isa, validate, type_of} = this.types.export());

  //...........................................................................................................
  ({jr} = CND);

  Multimix = require('multimix');

  //-----------------------------------------------------------------------------------------------------------
  remove_notgiven = function(list) {
    return list.filter(function(e) {
      return e != null;
    });
  };

  // return ( e for e in list when e? ) ### non-mutating variant ###

  //-----------------------------------------------------------------------------------------------------------
  /* mutating variant */  MAIN = this;

  Cupofjoe = (function() {
    class Cupofjoe extends Multimix {
      //---------------------------------------------------------------------------------------------------------
      constructor(settings = null) {
        super();
        this.settings = {...this._defaults, ...settings};
        this._crammed = false;
        this.clear();
        return this;
      }

      //---------------------------------------------------------------------------------------------------------
      expand() {
        var R;
        if (this.settings.flatten) {
          this.collector = this.collector.flat(2e308);
        }
        R = this.collector;
        this.clear();
        return R;
      }

      //---------------------------------------------------------------------------------------------------------

        //---------------------------------------------------------------------------------------------------------
      cram(...x) {
        var i, idx, len, p, prv_collector, ref, rvalue;
        for (idx = i = 0, len = x.length; i < len; idx = ++i) {
          p = x[idx];
          if (isa.function(p)) {
            prv_collector = this.collector;
            this.collector = [];
            this._crammed = false;
            rvalue = p();
            if (this._crammed) {
              splice.apply(x, [idx, idx - idx + 1].concat(ref = this.collector)), ref;
            } else if (rvalue != null) {
              splice.apply(x, [idx, idx - idx + 1].concat(rvalue)), rvalue;
            }
            this.collector = prv_collector;
          }
        }
        x = remove_notgiven(x);
        if (x.length !== 0) {
          this.collector.push(x);
        }
        this._crammed = true;
        return null;
      }

      //---------------------------------------------------------------------------------------------------------
      clear() {
        this.collector = [];
        return null;
      }

    };

    Cupofjoe.include(MAIN, {
      overwrite: false
    });

    // @extend MAIN, { overwrite: false, }
    Cupofjoe.prototype._defaults = {
      flatten: false
    };

    return Cupofjoe;

  }).call(this);

  //-----------------------------------------------------------------------------------------------------------
  module.exports = {Cupofjoe};

  //###########################################################################################################
  if (module === require.main) {
    (() => {
      return null;
    })();
  }

}).call(this);

//# sourceMappingURL=main.js.map