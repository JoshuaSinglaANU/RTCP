(function() {
  'use strict';
  var base, is_function, k, njs_util, ref, ref1, rpr, v, σ_cnd;

  //###########################################################################################################
  njs_util = require('util');

  rpr = njs_util.inspect;

  //...........................................................................................................
  σ_cnd = Symbol.for('cnd');

  if (global[σ_cnd] == null) {
    global[σ_cnd] = {};
  }

  if ((base = global[σ_cnd]).t0 == null) {
    base.t0 = Date.now();
  }

  is_function = function(x) {
    return (Object.prototype.toString.call(x)) === '[object Function]';
  };

  ref = require('./TRM');
  for (k in ref) {
    v = ref[k];
    //===========================================================================================================
    // ACQUISITION
    //-----------------------------------------------------------------------------------------------------------
    (this[k] = is_function(v) ? v.bind(this) : v);
  }

  ref1 = require('./BITSNPIECES');
  for (k in ref1) {
    v = ref1[k];
    (this[k] = is_function(v) ? v.bind(this) : v);
  }

}).call(this);
