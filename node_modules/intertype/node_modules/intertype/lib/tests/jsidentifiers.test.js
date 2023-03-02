(function() {
  'use strict';
  var CND, INTERTYPE, Intertype, alert, assign, badge, debug, echo, flatten, help, info, intersection_of, jr, js_type_of, log, njs_path, praise, rpr, test, urge, warn, whisper, xrpr;

  //###########################################################################################################
  // njs_util                  = require 'util'
  njs_path = require('path');

  // njs_fs                    = require 'fs'
  //...........................................................................................................
  CND = require('cnd');

  rpr = CND.rpr.bind(CND);

  badge = 'INTERTYPE/tests/main';

  log = CND.get_logger('plain', badge);

  info = CND.get_logger('info', badge);

  whisper = CND.get_logger('whisper', badge);

  alert = CND.get_logger('alert', badge);

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  praise = CND.get_logger('praise', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  test = require('guy-test');

  INTERTYPE = require('../..');

  ({Intertype} = INTERTYPE);

  ({assign, jr, flatten, xrpr, intersection_of, js_type_of} = require('../helpers'));

  // thx to https://shkspr.mobi/blog/2018/11/domain-hacks-with-unusual-unicode-characters/
  /*
   * ™ = 42
   * ℠ = 42
   * ℞ = 42
   * ℡ = 42
   * № = 42
  ℰ𝒳𝒜ℳ𝓟ℒℰ = 42
  𝐞𝐱𝐚𝐦𝐩𝐥𝐞 = 42
  𝖊𝖝𝖆𝖒𝖕𝖑𝖊 = 42
  𝒆𝒙𝒂𝒎𝒑𝒍𝒆 = 42
  𝓮𝔁𝓪𝓶𝓹𝓵𝓮 = 42
  𝕖𝕩𝕒𝕞𝕡𝕝𝕖 = 42
  𝚎𝚡𝚊𝚖𝚙𝚕𝚎 = 42
  ᵉˣᵃᵐᵖˡᵉ = 42
  ₑₓₐₘₚₗₑ = 42
  𝗲𝘅𝗮𝗺𝗽𝗹𝗲 = 42
  𝙚𝙭𝙖𝙢𝙥𝙡𝙚 = 42
  𝘦𝘹𝘢𝘮𝘱𝘭𝘦 = 42
   * 🄴🅇🄰🄼🄿🄻🄴 = 42
   * ⓔⓧⓐⓜⓟⓛⓔ = 42

   * \u0061 = 42

   * // Invalid in ES5, but valid in ES2015:
   * \u{61} = 42
   */
  //-----------------------------------------------------------------------------------------------------------
  this["jsidentifier"] = async function(T, done) {
    var all_keys_of, declare, error, i, intertype, isa, len, matcher, probe, probes_and_matchers, sad, sadden, size_of, type_of, types_of, validate;
    //.........................................................................................................
    INTERTYPE = require('../..');
    ({Intertype} = INTERTYPE);
    intertype = new Intertype();
    ({isa, validate, type_of, types_of, size_of, declare, sad, sadden, all_keys_of} = intertype.export());
    //.........................................................................................................
    probes_and_matchers = [
      [
        '™',
        false // Trade Mark
      ],
      [
        '℠',
        false // Service Mark
      ],
      [
        '℞',
        false // Prescriptions
      ],
      [
        '℡',
        false // Telephone symbol
      ],
      [
        '№',
        false // Numero Sign
      ],
      [
        '🄴🅇🄰🄼🄿🄻🄴',
        false // Math Squared
      ],
      [
        'ⓔⓧⓐⓜⓟⓛⓔ',
        false // Circled
      ],
      [
        'ℰ𝒳𝒜ℳ𝓟ℒℰ',
        true // Script
      ],
      [
        '𝐞𝐱𝐚𝐦𝐩𝐥𝐞',
        true // Math Bold
      ],
      [
        '𝖊𝖝𝖆𝖒𝖕𝖑𝖊',
        true // Fraktur
      ],
      [
        '𝒆𝒙𝒂𝒎𝒑𝒍𝒆',
        true // Math bold italic
      ],
      [
        '𝓮𝔁𝓪𝓶𝓹𝓵𝓮',
        true // Math bold script
      ],
      [
        '𝕖𝕩𝕒𝕞𝕡𝕝𝕖',
        true // Double struck
      ],
      [
        '𝚎𝚡𝚊𝚖𝚙𝚕𝚎',
        true // Monospace
      ],
      [
        'ᵉˣᵃᵐᵖˡᵉ',
        true // Super script
      ],
      [
        'ₑₓₐₘₚₗₑ',
        true // Sub script
      ],
      [
        '𝗲𝘅𝗮𝗺𝗽𝗹𝗲',
        true // Math sans bold
      ],
      [
        '𝙚𝙭𝙖𝙢𝙥𝙡𝙚',
        true // Math sans bold italic
      ],
      [
        '𝘦𝘹𝘢𝘮𝘱𝘭𝘦',
        true // Math sans italic
      ]
    ];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve, reject) {
          return resolve(isa.jsidentifier(probe));
        });
      });
    }
    done();
    return null;
  };

  //###########################################################################################################
  if (require.main === module) {
    (() => {
      return test(this);
    })();
  }

  // jsidentifier_pattern = /// ^
//   (?: [ $_ ]                    | \p{ID_Start}    )
//   (?: [ $ _ \u{200c} \u{200d} ] | \p{ID_Continue} )*
//   $ ///u
// debug /\p{Script=Katakana}/u.test 't'
// debug /\p{Script=Han}/u.test '谷'
// debug /\p{ID_Start}/u.test '谷'
// debug /\p{ID_Start}/u.test '5'
// debug jsidentifier_pattern.test 'a'
// debug jsidentifier_pattern.test '谷'
// debug jsidentifier_pattern.test '5'

}).call(this);
