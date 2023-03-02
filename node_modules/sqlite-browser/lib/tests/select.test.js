(function() {
  'use strict';
  var CND, PD, badge, debug, echo, help, info, jr, rpr, test, urge, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'SQLITE-BROWSER/TESTS/SELECT';

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  info = CND.get_logger('info', badge);

  urge = CND.get_logger('urge', badge);

  help = CND.get_logger('help', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  test = require('guy-test');

  jr = JSON.stringify;

  //...........................................................................................................
  // L                         = require '../select'
  PD = require('../..');

  // { $, $async, }            = PD

  //-----------------------------------------------------------------------------------------------------------
  this["to be written"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    T.fail("no test");
    return done();
    probes_and_matchers = [[[null, '^number'], false], [[123, '^number'], false]];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve, reject) {
          var d, selector;
          [d, selector] = probe;
          try {
            resolve(PD.select(d, selector));
          } catch (error1) {
            error = error1;
            return resolve(error.message);
          }
          return null;
        });
      });
    }
    done();
    return null;
  };

  //###########################################################################################################
  if (module.parent == null) {
    test(this);
  }

  // test @[ "selector keypatterns" ]
// test @[ "select 2" ]

}).call(this);
