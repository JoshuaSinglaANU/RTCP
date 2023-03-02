(function() {
  'use strict';
  var _freeze, _thaw, fix, freeze, lets, thaw, type_of;

  //-----------------------------------------------------------------------------------------------------------
  ({type_of} = require('./helpers'));

  //-----------------------------------------------------------------------------------------------------------
  freeze = function(x) {
    var error;
    try {
      return _freeze(x);
    } catch (error1) {
      error = error1;
      if (error.name === 'RangeError' && error.message === 'Maximum call stack size exceeded') {
        throw new Error("µ45666 unable to freeze circular objects");
      }
      throw error;
    }
  };

  //-----------------------------------------------------------------------------------------------------------
  thaw = function(x) {
    var error;
    try {
      return _thaw(x);
    } catch (error1) {
      error = error1;
      if (error.name === 'RangeError' && error.message === 'Maximum call stack size exceeded') {
        throw new Error("µ45667 unable to thaw circular objects");
      }
      throw error;
    }
  };

  //-----------------------------------------------------------------------------------------------------------
  _freeze = function(x) {
    var R, key, value;
    //.........................................................................................................
    if (Array.isArray(x)) {
      return Object.freeze((function() {
        var i, len, results;
        results = [];
        for (i = 0, len = x.length; i < len; i++) {
          value = x[i];
          results.push(_freeze(value));
        }
        return results;
      })());
    }
    //.........................................................................................................
    /* kludge to avoid `null` being mistaken as object; should use `type_of` instead of quirky `typeof`,
    but that breaks some tests in myterious ways, so hotfixing it like this FTTB: */
    if ((x !== null) && typeof x === 'object') {
      R = {};
      for (key in x) {
        value = x[key];
        R[key] = _freeze(value);
      }
      return Object.freeze(R);
    }
    //.........................................................................................................
    return x;
  };

  //-----------------------------------------------------------------------------------------------------------
  _thaw = function(x) {
    var R, key, value;
    //.........................................................................................................
    if (Array.isArray(x)) {
      return (function() {
        var i, len, results;
        results = [];
        for (i = 0, len = x.length; i < len; i++) {
          value = x[i];
          results.push(_thaw(value));
        }
        return results;
      })();
    }
    //.........................................................................................................
    if ((type_of(x)) === 'object') {
      R = {};
      for (key in x) {
        value = x[key];
        R[key] = _thaw(value);
      }
      return R;
    }
    //.........................................................................................................
    return x;
  };

  //-----------------------------------------------------------------------------------------------------------
  lets = function(original, modifier) {
    var draft;
    draft = thaw(original);
    if (modifier != null) {
      modifier(draft);
    }
    return freeze(draft);
  };

  //-----------------------------------------------------------------------------------------------------------
  fix = function(target, name, value) {
    Object.defineProperty(target, name, {
      enumerable: true,
      writable: false,
      configurable: false,
      value: freeze(value)
    });
    return target;
  };

  //-----------------------------------------------------------------------------------------------------------
  module.exports = {
    lets,
    freeze,
    thaw,
    fix,
    nofreeze: require('./nofreeze'),
    partial: require('./partial'),
    breadboard: require('./breadboard')
  };

}).call(this);
