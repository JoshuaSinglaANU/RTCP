(function() {
  'use strict';
  var CND, INTERTYPE, Intertype, alert, assign, badge, debug, demo, demo_test_for_generator, echo, flatten, get_probes_and_matchers, help, info, js_type_of, log, njs_path, praise, rpr, test, type_of_v3, urge, warn, whisper;

  //###########################################################################################################
  // njs_util                  = require 'util'
  njs_path = require('path');

  // njs_fs                    = require 'fs'
  //...........................................................................................................
  CND = require('cnd');

  rpr = CND.rpr.bind(CND);

  badge = 'INTERTYPE/tests/es6classes';

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

  ({assign, flatten, js_type_of} = require('../helpers'));

  //-----------------------------------------------------------------------------------------------------------
  this["undeclared types can be used if known to `type_of()`"] = async function(T, done) {
    var all_keys_of, declare, error, i, intertype, isa, len, matcher, probe, probes_and_matchers, size_of, type_of, types_of, validate;
    //.........................................................................................................
    intertype = new Intertype();
    ({isa, validate, type_of, types_of, size_of, declare, all_keys_of} = intertype.export());
    //.........................................................................................................
    probes_and_matchers = [[[1n, 'bigint'], true, null], [[1n, 'XXXX'], false, "not a valid XXXX"]];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve, reject) {
          var result, type, value;
          [value, type] = probe;
          result = isa[type](value);
          validate[type](value);
          T.ok(true);
          return resolve(result);
        });
      });
    }
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  get_probes_and_matchers = function() {
    var FooObject, MyArrayClass, MyBareClass, MyObjectClass, OtherConstructor, SomeConstructor, probes_and_matchers;
    //.........................................................................................................
    // class Array
    MyBareClass = class MyBareClass {};
    MyObjectClass = class MyObjectClass extends Object {};
    MyArrayClass = class MyArrayClass extends Array {};
    SomeConstructor = function() {};
    OtherConstructor = function() {
      return 42;
    };
    //.........................................................................................................
    // thx to https://www.reddit.com/r/javascript/comments/gnbqoy/askjs_is_objectprototypetostringcall_the_best/fra7fg9?utm_source=share&utm_medium=web2x
    // toString  = Function.prototype.call.bind Object.prototype.toString
    FooObject = {};
    FooObject[Symbol.toStringTag] = 'Foo';
    // console.log(toString(FooObject)) // [object Foo]
    //.........................................................................................................
    return probes_and_matchers = [
      [Object.create(null),
      'nullobject'],
      [
        {
          constructor: 'Bob'
        },
        'object'
      ],
      [
        {
          CONSTRUCTOR: 'Bob'
        },
        'object'
      ],
      [MyBareClass,
      'class'],
      [MyObjectClass,
      'class'],
      [MyArrayClass,
      'class'],
      [Array,
      'function'],
      [SomeConstructor,
      'function'],
      [new MyBareClass(),
      'mybareclass'],
      [new MyObjectClass(),
      'myobjectclass'],
      [new MyArrayClass(),
      'myarrayclass'],
      [new SomeConstructor(),
      'someconstructor'],
      [new OtherConstructor(),
      'otherconstructor'],
      [null,
      'null'],
      [void 0,
      'undefined'],
      [Object,
      'function'],
      [Array,
      'function'],
      [{},
      'object'],
      [[],
      'list'],
      ['42',
      'text'],
      [42,
      'float'],
      [0/0,
      'nan'],
      [2e308,
      'infinity'],
      [
        (async function() {
          return (await f());
        }),
        'asyncfunction'
      ],
      [
        (async function*() {
          return (yield* (await f()));
        }),
        'asyncgeneratorfunction'
      ],
      [
        (function*() {
          return (yield 42);
        }),
        'generatorfunction'
      ],
      [
        (function*() {
          return (yield 42);
        })(),
        'generator'
      ],
      [/x/,
      'regex'],
      [new Date(),
      'date'],
      [Set,
      'function'],
      [new Set(),
      'set'],
      [Symbol,
      'function'],
      [Symbol('abc'),
      'symbol'],
      [Symbol.for('abc'),
      'symbol'],
      [new Uint8Array([42]),
      'uint8array'],
      [Buffer.from([42]),
      'buffer'],
      [12345678912345678912345n,
      'bigint'],
      [FooObject,
      'foo'],
      [new Promise(function(resolve) {}),
      'promise'],
      [new Number(42),
      'wrapper'],
      [new String('42'),
      'wrapper'],
      [new Boolean(true),
      'wrapper'],
      [new RegExp('x*'),
      'regex'],
      [new /* NOTE not functionally different */
      Function('a',
      'b',
      'return a + b'),
      'function'],
      [[]./* NOTE not functionally different */
      keys(),
      'arrayiterator'],
      [(new Set([])).keys(),
      'setiterator'],
      [(new Map([])).keys(),
      'mapiterator'],
      [new Array(),
      'list'],
      ['x'[Symbol.iterator](),
      'stringiterator']
    ];
  };

  //-----------------------------------------------------------------------------------------------------------
  type_of_v3 = function(...xP) {
    var R, x;
    if (xP.length !== 1) {
      /* TAINT this should be generalized for all Intertype types that split up / rename a JS type: */
      throw new Error(`^7746^ expected 1 argument, got ${arity}`);
    }
    switch (R = js_type_of(...xP)) {
      case 'uint8array':
        if (Buffer.isBuffer(...xP)) {
          R = 'buffer';
        }
        break;
      case 'number':
        [x] = xP;
        if (!Number.isFinite(x)) {
          R = (Number.isNaN(x)) ? 'nan' : 'infinity';
        }
        break;
      case 'regexp':
        R = 'regex';
        break;
      case 'string':
        R = 'text';
        break;
      case 'array':
        R = 'list';
        break;
      case 'arrayiterator':
        R = 'listiterator';
        break;
      case 'stringiterator':
        R = 'textiterator';
    }
    /* Refuse to answer question in case type found is not in specs: */
    // debug 'µ33332', R, ( k for k of @specs )
    // throw new Error "µ6623 unknown type #{rpr R}" unless R of @specs
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["es6classes type detection devices (prototype)"] = function(T, done) {
    var color, column_width, domenic_denicola_device, h, headers, i, idx, intertype, isa, j, last_idx, lc_result, len, len1, mark_miller_device, matcher, probe, raw_result, raw_results, ref, results, string_tag, type_of_v4, type_of_v4_type, validate;
    intertype = new Intertype();
    ({isa, validate} = intertype.export());
    type_of_v4 = intertype.export().type_of;
    ({domenic_denicola_device, mark_miller_device} = require('../helpers'));
    //.........................................................................................................
    debug();
    column_width = 25;
    //.........................................................................................................
    headers = [
      'probe',
      'typeof',
      // 'toString()'
      'string_tag',
      'miller',
      'type_of_v3',
      'denicola',
      'type_of_v4',
      'expected'
    ];
    headers = ((function() {
      var i, len, results1;
      results1 = [];
      for (i = 0, len = headers.length; i < len; i++) {
        h = headers[i];
        results1.push(h.slice(0, column_width).padEnd(column_width));
      }
      return results1;
    })()).join('|');
    echo(headers);
    ref = get_probes_and_matchers();
    //.........................................................................................................
    for (i = 0, len = ref.length; i < len; i++) {
      [probe, matcher] = ref[i];
      type_of_v4_type = type_of_v4(probe);
      string_tag = probe != null ? probe[Symbol.toStringTag] : './.';
      // toString        = if probe? then probe.toString?() ? './.'    else './.'
      raw_results = [
        rpr(probe),
        typeof probe,
        // toString
        string_tag,
        mark_miller_device(probe),
        type_of_v3(probe),
        domenic_denicola_device(probe),
        type_of_v4_type,
        matcher
      ];
      results = [];
      last_idx = raw_results.length - 1;
      for (idx = j = 0, len1 = raw_results.length; j < len1; idx = ++j) {
        raw_result = raw_results[idx];
        if (isa.text(raw_result)) {
          raw_result = raw_result.replace(/\n/g, '⏎');
          lc_result = raw_result.toLowerCase().replace(/\s/g, '');
        } else {
          raw_result = '';
          lc_result = null;
        }
        if ((idx === 0 || idx === last_idx)) {
          color = CND.cyan;
        } else {
          if (raw_result === matcher) {
            color = CND.green;
          } else if (lc_result === matcher) {
            color = CND.lime;
          } else {
            color = CND.red;
          }
        }
        results.push(color(raw_result.slice(0, column_width).padEnd(column_width)));
      }
      echo(results.join('|'));
      T.eq(type_of_v4_type, matcher);
    }
    // debug rpr ( ( -> yield 42 )()       ).constructor
    // debug rpr ( ( -> yield 42 )()       ).constructor.name
    // debug '^338-10^', mmd MyBareClass           # Function
    // debug '^338-11^', mmd MyObjectClass         # Function
    // debug '^338-12^', mmd MyArrayClass          # Function
    // debug '^338-13^', mmd new MyBareClass()     # Object
    // debug '^338-14^', mmd new MyObjectClass()   # Object
    // debug '^338-15^', mmd new MyArrayClass()    # Array
    // debug()                                     #
    // debug '^338-16^', ddd MyBareClass           # Function
    // debug '^338-17^', ddd MyObjectClass         # Function
    // debug '^338-18^', ddd MyArrayClass          # Function
    // debug '^338-19^', ddd new MyBareClass()     # MyBareClass
    // debug '^338-20^', ddd new MyObjectClass()   # MyObjectClass
    // debug '^338-21^', ddd new MyArrayClass()    # MyArrayClass
    return done();
  };

  //-----------------------------------------------------------------------------------------------------------
  this["_es6classes equals"] = function(T, done) {
    var check, equals, intertype, isa;
    intertype = new Intertype();
    ({isa, check, equals} = intertype.export());
    /* TAINT copy more extensive tests from CND, `js_eq`? */
    T.eq(equals(3, 3), true);
    T.eq(equals(3, 4), false);
    if (done != null) {
      return done();
    }
  };

  //-----------------------------------------------------------------------------------------------------------
  demo_test_for_generator = function() {
    var Generator, GeneratorFunction;
    GeneratorFunction = (function*() {
      return (yield 42);
    }).constructor;
    Generator = ((function*() {
      return (yield 42);
    })()).constructor;
    debug(rpr(GeneratorFunction.name === 'GeneratorFunction'));
    debug(rpr(Generator.name === ''));
    debug((function*() {
      return (yield 42);
    }).constructor === GeneratorFunction);
    debug((function*() {
      return (yield 42);
    }).constructor === Generator);
    debug(((function*() {
      return (yield 42);
    })()).constructor === GeneratorFunction);
    return debug(((function*() {
      return (yield 42);
    })()).constructor === Generator);
  };

  //-----------------------------------------------------------------------------------------------------------
  demo = function() {
    var O, X, arrayiterator, mapiterator, myfunction, setiterator, stringiterator, types;
    // ```
    // echo( 'helo' );
    // echo( rpr(
    //   ( function*() { yield 42; } ).constructor.name
    //   ) );
    // echo( rpr(
    //   ( function*() { yield 42; } )().constructor.name
    //   ) );
    // ```

    // node -p "require('util').inspect( ( function*() { yield 42; } ).constructor )"
    // node -p "require('util').inspect( ( function*() { yield 42; } ).constructor.name )"
    // node -p "require('util').inspect( ( function*() { yield 42; } )().constructor )"
    // node -p "require('util').inspect( ( function*() { yield 42; } )().constructor.name )"
    info(rpr((function*() {
      return (yield 42);
    }).constructor));
    info(rpr((function*() {
      return (yield 42);
    }).constructor.name));
    info(rpr((function*() {
      return (yield 42);
    })().constructor));
    info(rpr((function*() {
      return (yield 42);
    })().constructor.name));
    // info rpr NaN.constructor.name
    info(arrayiterator = [].keys().constructor);
    info(setiterator = (new Set([])).keys().constructor);
    info(mapiterator = (new Map([])).keys().constructor);
    info(stringiterator = 'x'[Symbol.iterator]().constructor);
    types = new Intertype();
    // debug types.all_keys_of Buffer.alloc 10
    // debug types.all_keys_of new Uint8Array 10

    // class X extends NaN
    // class X extends null
    // class X extends undefined
    // class X extends 1
    // class X extends {}
    myfunction = function() {};
    X = class X {};
    O = class O extends Object {};
    info('^87-1^', rpr(myfunction.prototype));
    info('^87-2^', rpr(myfunction.prototype.constructor));
    info('^87-3^', rpr(myfunction.prototype.constructor.name));
    info('^87-4^', rpr(X.prototype));
    info('^87-5^', rpr(X.prototype.constructor));
    info('^87-6^', rpr(X.prototype.constructor.name));
    info('^87-7^', rpr(O.prototype));
    info('^87-8^', rpr(O.prototype.constructor));
    info('^87-9^', rpr(O.prototype.constructor.name));
    info(Object.hasOwnProperty(X, 'arguments'));
    info(Object.hasOwnProperty((function() {}), 'arguments'));
    info(Object.hasOwnProperty((function(x) {}), 'arguments'));
    info(Object.hasOwnProperty((function() {}).prototype, 'arguments'));
    info(Object.hasOwnProperty((function(x) {}).prototype, 'arguments'));
    urge(Object.getOwnPropertyNames(X));
    urge(Object.getOwnPropertyNames((function() {})));
    return info(new Array());
  };

  //###########################################################################################################
  if (module === require.main) {
    (() => {
      // demo_test_for_generator()
      return test(this);
    })();
  }

  // test @[ "undeclared but implement types can be used" ]

}).call(this);
