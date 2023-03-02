(function() {
  'use strict';
  var CND, IC, badge, debug, echo, help, info, inspect, jr, rpr, test, urge, warn, whisper, xrpr, xrpr2;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'INTERCOURSE/TESTS/MAIN';

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

  IC = require('../..');

  ({inspect} = require('util'));

  xrpr = function(x) {
    return inspect(x, {
      colors: true,
      breakLength: 2e308,
      maxArrayLength: 2e308,
      depth: 2e308
    });
  };

  xrpr2 = function(x) {
    return inspect(x, {
      colors: true,
      breakLength: 20,
      maxArrayLength: 2e308,
      depth: 2e308
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this["basic 1"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    probes_and_matchers = [
      [
        "procedure x:\n  foo bar",
        {
          "x": {
            "type": "procedure",
            "null": {
              "parts": ["foo bar"],
              "location": {
                "line_nr": 1
              },
              "kenning": "null",
              "type": "procedure"
            }
          }
        },
        null
      ],
      [
        "procedure x:\n  foo bar\n",
        {
          "x": {
            "type": "procedure",
            "null": {
              "parts": ["foo bar"],
              "location": {
                "line_nr": 1
              },
              "kenning": "null",
              "type": "procedure"
            }
          }
        },
        null
      ],
      [
        "procedure x:\n  foo bar\n\n",
        {
          "x": {
            "type": "procedure",
            "null": {
              "parts": ["foo bar"],
              "location": {
                "line_nr": 1
              },
              "kenning": "null",
              "type": "procedure"
            }
          }
        },
        null
      ],
      [
        "procedure x:\n  foo bar\n\nprocedure y:\n  foo bar\n\n",
        {
          "x": {
            "type": "procedure",
            "null": {
              "parts": ["foo bar"],
              "location": {
                "line_nr": 1
              },
              "kenning": "null",
              "type": "procedure"
            }
          },
          "y": {
            "type": "procedure",
            "null": {
              "parts": ["foo bar"],
              "location": {
                "line_nr": 4
              },
              "kenning": "null",
              "type": "procedure"
            }
          }
        },
        null
      ]
    ];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      await T.perform(probe, matcher, error, function() {
        return new Promise(async function(resolve, reject) {
          var result;
          // try
          result = (await IC.definitions_from_text(probe));
          // catch error
          //   return resolve error.message
          // debug '29929', xrpr2 result
          return resolve(result);
        });
      });
    }
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["signatures"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    probes_and_matchers = [
      [
        "procedure foobar:\n  some text",
        {
          "foobar": {
            "type": "procedure",
            "null": {
              "parts": ["some text"],
              "location": {
                "line_nr": 1
              },
              "kenning": "null",
              "type": "procedure"
            }
          }
        },
        null
      ],
      [
        "procedure foobar():\n  some text",
        {
          "foobar": {
            "type": "procedure",
            "()": {
              "parts": ["some text"],
              "location": {
                "line_nr": 1
              },
              "kenning": "()",
              "type": "procedure",
              "signature": []
            }
          }
        },
        null
      ],
      [
        "procedure foobar( first ):\n  some text",
        {
          "foobar": {
            "type": "procedure",
            "(first)": {
              "parts": ["some text"],
              "location": {
                "line_nr": 1
              },
              "kenning": "(first)",
              "type": "procedure",
              "signature": ["first"]
            }
          }
        },
        null
      ],
      [
        "procedure foobar(first):\n  some text",
        {
          "foobar": {
            "type": "procedure",
            "(first)": {
              "parts": ["some text"],
              "location": {
                "line_nr": 1
              },
              "kenning": "(first)",
              "type": "procedure",
              "signature": ["first"]
            }
          }
        },
        null
      ],
      [
        "procedure foobar( first, ):\n  some text",
        {
          "foobar": {
            "type": "procedure",
            "(first)": {
              "parts": ["some text"],
              "location": {
                "line_nr": 1
              },
              "kenning": "(first)",
              "type": "procedure",
              "signature": ["first"]
            }
          }
        },
        null
      ],
      [
        "procedure foobar(first,):\n  some text",
        {
          "foobar": {
            "type": "procedure",
            "(first)": {
              "parts": ["some text"],
              "location": {
                "line_nr": 1
              },
              "kenning": "(first)",
              "type": "procedure",
              "signature": ["first"]
            }
          }
        },
        null
      ],
      [
        "procedure foobar( first, second ):\n  some text",
        {
          "foobar": {
            "type": "procedure",
            "(first,second)": {
              "parts": ["some text"],
              "location": {
                "line_nr": 1
              },
              "kenning": "(first,second)",
              "type": "procedure",
              "signature": ["first",
        "second"]
            }
          }
        },
        null
      ],
      [
        "procedure foobar( first, second, ):\n  some text",
        {
          "foobar": {
            "type": "procedure",
            "(first,second)": {
              "parts": ["some text"],
              "location": {
                "line_nr": 1
              },
              "kenning": "(first,second)",
              "type": "procedure",
              "signature": ["first",
        "second"]
            }
          }
        },
        null
      ],
      [
        "procedure foobar( first, second, ): some text\nprocedure foobar( first ): other text\nprocedure foobar(): blah\n",
        {
          "foobar": {
            "type": "procedure",
            "(first,second)": {
              "parts": ["some text"],
              "location": {
                "line_nr": 1
              },
              "kenning": "(first,second)",
              "type": "procedure",
              "signature": ["first",
        "second"]
            },
            "(first)": {
              "parts": ["other text"],
              "location": {
                "line_nr": 2
              },
              "kenning": "(first)",
              "type": "procedure",
              "signature": ["first"]
            },
            "()": {
              "parts": ["blah"],
              "location": {
                "line_nr": 3
              },
              "kenning": "()",
              "type": "procedure",
              "signature": []
            }
          }
        },
        null
      ]
    ];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      await T.perform(probe, matcher, error, function() {
        return new Promise(async function(resolve, reject) {
          var result;
          // try
          result = (await IC.definitions_from_text(probe));
          // catch error
          //   return resolve error.message
          // debug '29929', xrpr2 result
          return resolve(result);
        });
      });
    }
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["oneliners"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    probes_and_matchers = [
      [
        // ["procedure foobar:  some text\n  illegal line",null,'illegal follow-up after one-liner']
        "procedure foobar: some text",
        {
          "foobar": {
            "type": "procedure",
            "null": {
              "parts": ["some text"],
              "location": {
                "line_nr": 1
              },
              "kenning": "null",
              "type": "procedure"
            }
          }
        },
        null
      ],
      [
        "procedure foobar(): some text",
        {
          "foobar": {
            "type": "procedure",
            "()": {
              "parts": ["some text"],
              "location": {
                "line_nr": 1
              },
              "kenning": "()",
              "type": "procedure",
              "signature": []
            }
          }
        },
        null
      ],
      [
        "procedure foobar( first ): some text",
        {
          "foobar": {
            "type": "procedure",
            "(first)": {
              "parts": ["some text"],
              "location": {
                "line_nr": 1
              },
              "kenning": "(first)",
              "type": "procedure",
              "signature": ["first"]
            }
          }
        },
        null
      ],
      [
        "procedure foobar(first): some text",
        {
          "foobar": {
            "type": "procedure",
            "(first)": {
              "parts": ["some text"],
              "location": {
                "line_nr": 1
              },
              "kenning": "(first)",
              "type": "procedure",
              "signature": ["first"]
            }
          }
        },
        null
      ],
      [
        "procedure foobar( first, ): some text",
        {
          "foobar": {
            "type": "procedure",
            "(first)": {
              "parts": ["some text"],
              "location": {
                "line_nr": 1
              },
              "kenning": "(first)",
              "type": "procedure",
              "signature": ["first"]
            }
          }
        },
        null
      ],
      [
        "procedure foobar(first,): some text",
        {
          "foobar": {
            "type": "procedure",
            "(first)": {
              "parts": ["some text"],
              "location": {
                "line_nr": 1
              },
              "kenning": "(first)",
              "type": "procedure",
              "signature": ["first"]
            }
          }
        },
        null
      ],
      [
        "procedure foobar( first, second ): some text",
        {
          "foobar": {
            "type": "procedure",
            "(first,second)": {
              "parts": ["some text"],
              "location": {
                "line_nr": 1
              },
              "kenning": "(first,second)",
              "type": "procedure",
              "signature": ["first",
        "second"]
            }
          }
        },
        null
      ],
      [
        "procedure foobar( first, second, ): some text",
        {
          "foobar": {
            "type": "procedure",
            "(first,second)": {
              "parts": ["some text"],
              "location": {
                "line_nr": 1
              },
              "kenning": "(first,second)",
              "type": "procedure",
              "signature": ["first",
        "second"]
            }
          }
        },
        null
      ]
    ];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      await T.perform(probe, matcher, error, function() {
        return new Promise(async function(resolve, reject) {
          var result;
          // try
          result = (await IC.definitions_from_text(probe));
          // catch error
          //   return resolve error
          // debug '29929', xrpr2 result
          return resolve(result);
        });
      });
    }
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["definitions_from_path_sync"] = async function(T, done) {
    var FS, PATH, error, matcher, path, probe;
    PATH = require('path');
    FS = require('fs');
    path = PATH.join(__dirname, '../../demos/sqlite-demo.icql');
    probe = null;
    matcher = IC.definitions_from_text(FS.readFileSync(path));
    error = null;
    //.........................................................................................................
    await T.perform(probe, matcher, error, function() {
      return new Promise(function(resolve, reject) {
        var result;
        result = IC.definitions_from_path_sync(path);
        return resolve(result);
      });
    });
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["definitions_from_path"] = async function(T, done) {
    var FS, PATH, error, matcher, path, probe;
    PATH = require('path');
    FS = require('fs');
    path = PATH.join(__dirname, '../../demos/sqlite-demo.icql');
    probe = null;
    matcher = IC.definitions_from_text(FS.readFileSync(path));
    error = null;
    //.........................................................................................................
    await T.perform(probe, matcher, error, function() {
      return new Promise(async function(resolve, reject) {
        var result;
        result = (await IC.definitions_from_path(path));
        return resolve(result);
      });
    });
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["_parse demo"] = async function(T, done) {
    var PATH, path;
    PATH = require('path');
    path = PATH.join(__dirname, '../../demos/sqlite-demo.icql');
    debug(xrpr2((await IC.read_definitions(path))));
    done();
    return null;
  };

  //###########################################################################################################
  if (module.parent == null) {
    test(this);
  }

  // test @[ "definitions_from_path_sync" ]
// test @[ "definitions_from_path" ]
// test @[ "basic 1" ]
// test @[ "signatures" ]
// test @[ "oneliners" ]
// test @[ "_parse demo" ]

}).call(this);

//# sourceMappingURL=main.test.js.map