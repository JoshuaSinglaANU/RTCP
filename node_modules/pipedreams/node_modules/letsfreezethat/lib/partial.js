(function() {
  'use strict';
  var _freeze, _thaw, fix, freeze, is_descriptor_of_computed_value, lets, lets_compute, set_computed_value, set_readonly_value, set_writable_value, thaw, type_of;

  //-----------------------------------------------------------------------------------------------------------
  ({type_of, is_descriptor_of_computed_value, set_writable_value, set_readonly_value, set_computed_value} = require('./helpers'));

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
    var R, descriptor, key, ref, ref1, type, value;
    switch (type = type_of(x)) {
      //.......................................................................................................
      case 'array':
        return Object.seal((function() {
          var i, len, results;
          results = [];
          for (i = 0, len = x.length; i < len; i++) {
            value = x[i];
            results.push(_freeze(value));
          }
          return results;
        })());
      //.......................................................................................................
      case 'object':
        R = {};
        ref = Object.getOwnPropertyDescriptors(x);
        for (key in ref) {
          descriptor = ref[key];
          if (is_descriptor_of_computed_value(descriptor)) {
            Object.defineProperty(R, key, descriptor);
          } else {
            if ((ref1 = type_of(descriptor.value)) === 'object' || ref1 === 'array') {
              descriptor.value = _freeze(descriptor.value);
            }
            descriptor.configurable = false;
            descriptor.writable = false;
            Object.defineProperty(R, key, descriptor);
          }
        }
        return Object.seal(R);
    }
    //.........................................................................................................
    return x;
  };

  //-----------------------------------------------------------------------------------------------------------
  _thaw = function(x) {
    var R, descriptor, key, ref, ref1, type, value;
    switch (type = type_of(x)) {
      //.......................................................................................................
      case 'array':
        return (function() {
          var i, len, results;
          results = [];
          for (i = 0, len = x.length; i < len; i++) {
            value = x[i];
            results.push(_thaw(value));
          }
          return results;
        })();
      //.......................................................................................................
      case 'object':
        R = {};
        ref = Object.getOwnPropertyDescriptors(x);
        for (key in ref) {
          descriptor = ref[key];
          descriptor.configurable = true;
          if (is_descriptor_of_computed_value(descriptor)) {
            Object.defineProperty(R, key, descriptor);
          } else {
            if ((ref1 = type_of(descriptor.value)) === 'object' || ref1 === 'array') {
              descriptor.value = _thaw(descriptor.value);
            }
            descriptor.writable = true;
            Object.defineProperty(R, key, descriptor);
          }
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
  lets_compute = function(original, key, get = null, set = null) {
    var draft;
    draft = thaw(original);
    set_computed_value(draft, key, get, set);
    return freeze(draft);
  };

  //-----------------------------------------------------------------------------------------------------------
  fix = function(target, key, value) {
    set_readonly_value(target, key, freeze(value));
    return target;
  };

  //-----------------------------------------------------------------------------------------------------------
  module.exports = {
    lets,
    freeze,
    thaw,
    fix,
    lets_compute,
    nofreeze: require('./nofreeze'),
    partial: require('./partial')
  };

}).call(this);
