(function() {
  'use strict';
  var _copy, fix, freeze, lets, thaw;

  //-----------------------------------------------------------------------------------------------------------
  freeze = function(x) {
    var error;
    try {
      return _copy(x);
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
    return x;
  };

  //-----------------------------------------------------------------------------------------------------------
  _copy = function(x) {
    var R, key, value;
    //.........................................................................................................
    if (Array.isArray(x)) {
      return (function() {
        var i, len, results;
        results = [];
        for (i = 0, len = x.length; i < len; i++) {
          value = x[i];
          results.push(_copy(value));
        }
        return results;
      })();
    }
    //.........................................................................................................
    if (typeof x === 'object') {
      R = {};
      for (key in x) {
        value = x[key];
        R[key] = _copy(value);
      }
      return R;
    }
    //.........................................................................................................
    return x;
  };

  //-----------------------------------------------------------------------------------------------------------
  lets = function(original, modifier) {
    var draft;
    draft = _copy(original);
    if (modifier != null) {
      modifier(draft);
    }
    return draft;
  };

  //-----------------------------------------------------------------------------------------------------------
  fix = function(target, name, value) {
    target[name] = value;
    return target;
  };

  //-----------------------------------------------------------------------------------------------------------
  module.exports = {lets, freeze, thaw, _copy, fix};

}).call(this);
