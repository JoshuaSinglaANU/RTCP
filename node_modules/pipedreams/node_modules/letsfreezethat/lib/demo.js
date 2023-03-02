(function() {
  'use strict';
  var d, e, error, fix, freeze, k, lets, log, thaw;

  log = console.log;

  ({lets, freeze, thaw, fix} = require('..'));

  d = lets({
    foo: 'bar',
    nested: [2, 3, 5, 7]
  });

  e = lets(d, function(d) {
    return d.nested.push(11);
  });

  console.log();

  console.log();

  console.log('d                          ', d); // { foo: 'bar', nested: [ 2, 3, 5, 7 ] }

  console.log('e                          ', e); // { foo: 'bar', nested: [ 2, 3, 5, 7, 11 ] }

  console.log('d is e                     ', d === e); // false

  console.log('Object.isFrozen d          ', Object.isFrozen(d)); // true

  console.log('Object.isFrozen d.nested   ', Object.isFrozen(d.nested)); // true

  console.log('Object.isFrozen e          ', Object.isFrozen(e)); // true

  console.log('Object.isFrozen e.nested   ', Object.isFrozen(e.nested)); // true

  d = {
    foo: 'bar'
  };

  console.log();

  console.log('d                          ', d);

  fix(d, 'sql', {
    query: "select * from main;"
  });

  console.log('d                          ', d);

  console.log((function() {
    var results;
    results = [];
    for (k in d) {
      results.push(k);
    }
    return results;
  })());

  try {
    d.sql = 'other';
  } catch (error1) {
    error = error1;
    console.log(error.message); // Cannot assign to read only property 'sql' of object '#<Object>'
  }

  try {
    d.sql.query = 'other';
  } catch (error1) {
    error = error1;
    console.log(error.message); // Cannot assign to read only property 'query' of object '#<Object>'
  }

  console.log('d                          ', d);

  ({lets, freeze, thaw, fix} = (require('..')).nofreeze);

  d = lets({
    foo: 'bar',
    nested: [2, 3, 5, 7]
  });

  e = lets(d, function(d) {
    return d.nested.push(11);
  });

  console.log();

  console.log();

  console.log('d                          ', d); // { foo: 'bar', nested: [ 2, 3, 5, 7 ] }

  console.log('e                          ', e); // { foo: 'bar', nested: [ 2, 3, 5, 7, 11 ] }

  console.log('d is e                     ', d === e); // false

  console.log('Object.isFrozen d          ', Object.isFrozen(d)); // true

  console.log('Object.isFrozen d.nested   ', Object.isFrozen(d.nested)); // true

  console.log('Object.isFrozen e          ', Object.isFrozen(e)); // true

  console.log('Object.isFrozen e.nested   ', Object.isFrozen(e.nested)); // true

  d = {
    foo: 'bar'
  };

  console.log();

  console.log('d                          ', d);

  fix(d, 'sql', {
    query: "select * from main;"
  });

  console.log('d                          ', d);

  console.log((function() {
    var results;
    results = [];
    for (k in d) {
      results.push(k);
    }
    return results;
  })());

  try {
    d.sql = {};
  } catch (error1) {
    error = error1;
    console.log(error.message);
  }

  try {
    d.sql.query = 'other';
  } catch (error1) {
    error = error1;
    console.log(error.message);
  }

  console.log('d                          ', d);

  log('--------------------------------------------------------------------');

  ({lets, freeze, thaw, fix} = require('..'));

  d = {
    x: 'some value'
  };

  Object.defineProperty(d, 'time', {
    enumerable: true,
    configurable: false,
    get: function() {
      return process.hrtime();
    },
    set: function() {
      return log('set not implemented');
    }
  });

  log('^887-1', d);

  log('^887-2', d.time);

  log('^887-3', d.time);

  // d.x     = 'some other value'
  d.time = 42;

  log('Object.getOwnPropertyDescriptor', Object.getOwnPropertyDescriptor(d, 'time'));

  log('--------------------------------------------------------------------');

  d = lets(d);

  // log '^335-1', Object.isFrozen d
  Object.freeze(d);

  log('Object.getOwnPropertyDescriptor', Object.getOwnPropertyDescriptor(d, 'time'));

  log('^887-4', d);

  log('^887-5', d.time);

  log('^887-6', d.time);

  // d.x     = 'some third value'
  // d.time  = 42
  log('^887-7', d);

  log('^887-8', d.time);

}).call(this);
