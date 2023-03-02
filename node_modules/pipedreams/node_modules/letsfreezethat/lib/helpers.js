(function() {
  'use strict';
  //-----------------------------------------------------------------------------------------------------------
  this.type_of = function(x) {
    var R;
    if ((R = ((Object.prototype.toString.call(x)).slice(8, -1)).toLowerCase()) === 'object') {
      return x.constructor.name.toLowerCase();
    }
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.is_computed = function(d, key) {
    return this.is_descriptor_of_computed_value(Object.getOwnPropertyDescriptor(d, key));
  };

  //-----------------------------------------------------------------------------------------------------------
  this.is_descriptor_of_computed_value = function(descriptor) {
    var keys;
    return ((keys = Object.keys(descriptor)).includes('set')) || (keys.includes('get'));
  };

  //-----------------------------------------------------------------------------------------------------------
  this.set_writable_value = function(d, key, value) {
    /* Acc to MDN `defineProperty`, a 'writable data descriptor'. */
    return Object.defineProperty(d, key, {
      enumerable: true,
      writable: true,
      configurable: true,
      value
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.set_readonly_value = function(d, key, value) {
    /* Acc to MDN `defineProperty`, a 'readonly data descriptor'. */
    return Object.defineProperty(d, key, {
      enumerable: true,
      writable: false,
      configurable: false,
      value
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.set_computed_value = function(d, key, get = null, set = null) {
    /* Acc to MDN `defineProperty`, an 'accessor descriptor'. */
    var descriptor, type_of_get, type_of_set;
    descriptor = {
      enumerable: true,
      configurable: false
    };
    type_of_get = get != null ? this.type_of(get) : null;
    type_of_set = set != null ? this.type_of(set) : null;
    if (!((type_of_get != null) || (type_of_set != null))) {
      throw new Error("^lft@h1^ must define getter or setter");
    }
    if (type_of_get != null) {
      if (type_of_get !== 'function') {
        throw new Error(`^lft@h2^ expected a function, got a ${type}`);
      }
      descriptor.get = get;
    }
    if (type_of_set != null) {
      if (type_of_set !== 'function') {
        throw new Error(`^lft@h3^ expected a function, got a ${type}`);
      }
      descriptor.set = set;
    }
    return Object.defineProperty(d, key, descriptor);
  };

  (() => {    //###########################################################################################################
    var k, ref, results, v;
    ref = this;
    results = [];
    for (k in ref) {
      v = ref[k];
      results.push(this[k] = v.bind(this));
    }
    return results;
  })();

}).call(this);
