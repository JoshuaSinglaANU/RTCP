(function() {
  'use strict';
  var assign, deep_copy, deep_freeze, freeze_lets, frozen, lets, log, nofreeze_lets, shallow_copy, shallow_freeze;

  //###########################################################################################################
  log = console.log;

  frozen = Object.isFrozen;

  assign = Object.assign;

  shallow_freeze = Object.freeze;

  shallow_copy = function(x, ...P) {
    return assign((Array.isArray(x) ? [] : {}), x, ...P);
  };

  //===========================================================================================================
  deep_copy = function(d) {
    var R, k, v;
    if ((!d) || d === true) {
      /* TAINT code duplication */
      /* immediately return for zero, empty string, null, undefined, NaN, false, true: */
      return d;
    }
    /* thx to https://github.com/lukeed/klona/blob/master/src/json.js */
    switch (Object.prototype.toString.call(d)) {
      case '[object Array]':
        k = d.length;
        R = [];
        while (k--) {
          if (((v = d[k]) != null) && ((typeof v) === 'object')) {
            R[k] = deep_copy(v);
          } else {
            R[k] = v;
          }
        }
        return R;
      case '[object Object]':
        R = {};
        for (k in d) {
          v = d[k];
          if ((v != null) && ((typeof v) === 'object')) {
            R[k] = deep_copy(v);
          } else {
            R[k] = v;
          }
        }
        return R;
    }
    return d;
  };

  //===========================================================================================================
  deep_freeze = function(d) {
    /* thx to https://github.com/lukeed/klona/blob/master/src/json.js */
    var is_first, k, v;
    if ((!d) || (d === true)) {
      /* TAINT code duplication */
      /* immediately return for zero, empty string, null, undefined, NaN, false, true: */
      return d;
    }
    is_first = true;
    switch (Object.prototype.toString.call(d)) {
      case '[object Array]':
        k = d.length;
        while (k--) {
          if (((v = d[k]) != null) && ((typeof v) === 'object') && (!frozen(v))) {
            if (is_first && (frozen(d))) {
              is_first = false;
              d = deep_copy(d);
            }
            d[k] = deep_freeze(v);
          }
        }
        return shallow_freeze(d);
      case '[object Object]':
        for (k in d) {
          v = d[k];
          if ((v != null) && ((typeof v) === 'object') && (!frozen(v))) {
            if (is_first && (frozen(d))) {
              is_first = false;
              d = deep_copy(d);
            }
            d[k] = deep_freeze(v);
          }
        }
        return shallow_freeze(d);
    }
    return d;
  };

  //===========================================================================================================

  //-----------------------------------------------------------------------------------------------------------
  freeze_lets = lets = function(original, modifier = null) {
    var draft;
    draft = freeze_lets.thaw(original);
    if (modifier != null) {
      modifier(draft);
    }
    return deep_freeze(draft);
  };

  //-----------------------------------------------------------------------------------------------------------
  freeze_lets.lets = freeze_lets;

  freeze_lets.assign = function(me, ...P) {
    return deep_freeze(deep_copy(shallow_copy(me, ...P)));
  };

  freeze_lets.freeze = function(me) {
    return deep_freeze(me);
  };

  freeze_lets.thaw = function(me) {
    return deep_copy(me);
  };

  freeze_lets.get = function(me, k) {
    return me[k];
  };

  freeze_lets.set = function(me, k, v) {
    var R;
    R = shallow_copy(me);
    R[k] = v;
    return shallow_freeze(R);
  };

  freeze_lets._deep_copy = deep_copy;

  freeze_lets._deep_freeze = deep_freeze;

  //===========================================================================================================

  //-----------------------------------------------------------------------------------------------------------
  lets.nofreeze = nofreeze_lets = function(original, modifier = null) {
    var draft;
    draft = nofreeze_lets.thaw(original);
    if (modifier != null) {
      modifier(draft);
    }
    /* TAINT do not copy */
    return deep_copy(draft);
  };

  //-----------------------------------------------------------------------------------------------------------
  nofreeze_lets.lets = nofreeze_lets;

  nofreeze_lets.assign = function(me, ...P) {
    return deep_copy(shallow_copy(me, ...P));
  };

  nofreeze_lets.freeze = function(me) {
    return me;
  };

  nofreeze_lets.thaw = function(me) {
    return deep_copy(me);
  };

  nofreeze_lets.get = freeze_lets.get;

  nofreeze_lets.set = function(me, k, v) {
    var R;
    R = shallow_copy(me);
    R[k] = v;
    return R;
  };

  nofreeze_lets._deep_copy = deep_copy;

  nofreeze_lets._deep_freeze = deep_freeze;

  //===========================================================================================================

  //-----------------------------------------------------------------------------------------------------------
  module.exports = {freeze_lets, nofreeze_lets};

}).call(this);

//# sourceMappingURL=main.js.map