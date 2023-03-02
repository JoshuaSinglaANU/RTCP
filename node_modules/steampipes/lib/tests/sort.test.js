(function() {
  'use strict';
  var $, $async, CND, SP, alert, assign, badge, copy, debug, echo, help, info, is_empty, jr, log, rpr, sort, test, urge, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'STEAMPIPES/TESTS/SORT';

  log = CND.get_logger('plain', badge);

  info = CND.get_logger('info', badge);

  whisper = CND.get_logger('whisper', badge);

  alert = CND.get_logger('alert', badge);

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  echo = CND.echo.bind(CND);

  ({is_empty, copy, assign, jr} = CND);

  //...........................................................................................................
  test = require('guy-test');

  //...........................................................................................................
  SP = require('../..');

  ({$, $async} = SP);

  //-----------------------------------------------------------------------------------------------------------
  sort = function(values) {
    return new Promise((resolve, reject) => {
      /* TAINT should handle errors (?) */
      var pipeline;
      pipeline = [];
      pipeline.push(SP.new_value_source(values));
      pipeline.push(SP.$sort());
      pipeline.push(SP.$drain(function(result) {
        return resolve(result);
      }));
      SP.pull(...pipeline);
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this["sort 1"] = async function(T, done) {
    var count, error, i, len, matcher, probe, probes_and_matchers, source;
    // debug jr ( key for key of SP ).sort(); xxx
    probes_and_matchers = [[[4, 9, 10, 3, 2], [2, 3, 4, 9, 10]], [['a', 'z', 'foo'], ['a', 'foo', 'z']]];
    count = probes_and_matchers.length;
    source = SP.new_push_source();
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      await T.perform(probe, matcher, error, function() {
        return new Promise(async function(resolve) {
          return resolve((await sort(probe)));
        });
      });
    }
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["sort 2"] = async function(T, done) {
    var count, error, i, len, matcher, probe, probes_and_matchers, source;
    // debug jr ( key for key of SP ).sort(); xxx
    probes_and_matchers = [[[4, 9, 10, 3, 2, null], [2, 3, 4, 9, 10], null], [[4, 9, 10, 3, 2, null], [2, 3, 4, 9, 10], null], [[4, 9, 10, "frob", 3, 2, null], null, "unable to compare a text to a float"], [["a", 1, "z", "foo"], null, "unable to compare a float to a text"]];
    count = probes_and_matchers.length;
    source = SP.new_push_source();
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve) {
          var pipeline;
          pipeline = [];
          pipeline.push(SP.new_value_source(probe));
          pipeline.push(SP.$sort());
          pipeline.push(SP.$drain(function(result) {
            return resolve(result);
          }));
          return SP.pull(...pipeline);
        });
      });
    }
    // resolve await sort probe
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["sort with permissive mode"] = async function(T, done) {
    var count, error, i, len, matcher, probe, probes_and_matchers, source;
    // debug jr ( key for key of SP ).sort(); xxx
    probes_and_matchers = [[[4, 9, 10, 3, 2, null], [2, 3, 4, 9, 10], null], [[4, 9, 10, 3, 2, null], [2, 3, 4, 9, 10], null], [[4, 9, 10, "frob", 3, 2, null], [2, 4, 9, 10, "frob", 3], null], [["a", 1, "z", "foo"], ["a", 1, "foo", "z"], null]];
    count = probes_and_matchers.length;
    source = SP.new_push_source();
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve) {
          var pipeline;
          pipeline = [];
          pipeline.push(SP.new_value_source(probe));
          pipeline.push(SP.$sort({
            strict: false
          }));
          pipeline.push(SP.$drain(function(result) {
            return resolve(result);
          }));
          return SP.pull(...pipeline);
        });
      });
    }
    // resolve await sort probe
    //.........................................................................................................
    done();
    return null;
  };

  //###########################################################################################################
  if (module === require.main) {
    (() => {
      return test(this);
    })();
  }

  // test @[ "sort with permissive mode" ]
// test @[ "sort 2" ]

}).call(this);

//# sourceMappingURL=sort.test.js.map