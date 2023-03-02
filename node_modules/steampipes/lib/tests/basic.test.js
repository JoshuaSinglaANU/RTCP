(function() {
  //###########################################################################################################
  var $, $async, $show, $watch, CND, FS, OS, PATH, SP, alert, badge, debug, defer, echo, help, info, inspect, jr, log, read, rpr, test, urge, warn, whisper, xrpr,
    modulo = function(a, b) { return (+a % (b = +b) + b) % b; };

  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'STEAMPIPES/TESTS/BASIC';

  log = CND.get_logger('plain', badge);

  info = CND.get_logger('info', badge);

  whisper = CND.get_logger('whisper', badge);

  alert = CND.get_logger('alert', badge);

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  PATH = require('path');

  FS = require('fs');

  OS = require('os');

  test = require('guy-test');

  //...........................................................................................................
  SP = require('../..');

  ({$, $async, $watch, $show} = SP.export());

  //...........................................................................................................
  read = function(path) {
    return FS.readFileSync(path, {
      encoding: 'utf-8'
    });
  };

  defer = setImmediate;

  ({inspect} = require('util'));

  xrpr = function(x) {
    return inspect(x, {
      colors: true,
      breakLength: 2e308,
      maxArrayLength: 2e308,
      depth: 2e308
    });
  };

  jr = JSON.stringify;

  // #-----------------------------------------------------------------------------------------------------------
  // @[ "test line assembler" ] = ( T, done ) ->
  //   text = """
  //   "　2. 纯；专：专～。～心～意。"
  //   !"　3. 全；满：～生。～地水。"
  //   "　4. 相同：～样。颜色不～。"
  //   "　5. 另外!的：蟋蟀～名促织。!"
  //   "　6. 表示动作短暂，或是一次，或具试探性：算～算。试～试。"!
  //   "　7. 乃；竞：～至于此。"
  //   """
  //   # text = "abc\ndefg\nhijk"
  //   chunks    = text.split '!'
  //   text      = text.replace /!/g, ''
  //   collector = []
  //   assembler = SP._new_line_assembler { extra: true, splitter: '\n', }, ( error, line ) ->
  //     throw error if error?
  //     if line?
  //       collector.push line
  //       info rpr line
  //     else
  //       # urge rpr text
  //       # help rpr collector.join '\n'
  //       # debug collector
  //       if CND.equals text, collector.join '\n'
  //         T.succeed "texts are equal"
  //       done()
  //   for chunk in chunks
  //     assembler chunk
  //   assembler null

  // #-----------------------------------------------------------------------------------------------------------
  // @[ "test throughput (1)" ] = ( T, done ) ->
  //   # input   = @new_stream PATH.resolve __dirname, '../test-data/guoxuedashi-excerpts-short.txt'
  //   input   = SP.new_stream PATH.resolve __dirname, '../../test-data/Unicode-NamesList-tiny.txt'
  //   output  = FS.createWriteStream '/tmp/output.txt'
  //   lines   = []
  //   input
  //     .pipe SP.$split()
  //     # .pipe SP.$show()
  //     .pipe SP.$succeed()
  //     .pipe SP.$as_line()
  //     .pipe $ ( line, send ) ->
  //       lines.push line
  //       send line
  //     .pipe output
  //   ### TAINT use PipeStreams method ###
  //   input.on 'end', -> outpudone()
  //   output.on 'close', ->
  //     # if CND.equals lines.join '\n'
  //     T.succeed "assuming equality"
  //     done()
  //   return null

  // #-----------------------------------------------------------------------------------------------------------
  // @[ "test throughput (2)" ] = ( T, done ) ->
  //   # input   = @new_stream PATH.resolve __dirname, '../test-data/guoxuedashi-excerpts-short.txt'
  //   input   = SP.new_stream PATH.resolve __dirname, '../../test-data/Unicode-NamesList-tiny.txt'
  //   output  = FS.createWriteStream '/tmp/output.txt'
  //   lines   = []
  //   p       = input
  //   p       = p.pipe SP.$split()
  //   # p       = p.pipe SP.$show()
  //   p       = p.pipe SP.$succeed()
  //   p       = p.pipe SP.$as_line()
  //   p       = p.pipe $ ( line, send ) ->
  //       lines.push line
  //       send line
  //   p       = p.pipe output
  //   ### TAINT use PipeStreams method ###
  //   input.on 'end', -> outpudone()
  //   output.on 'close', ->
  //     # if CND.equals lines.join '\n'
  //     # debug '12001', lines
  //     T.succeed "assuming equality"
  //     done()
  //   return null

  // #-----------------------------------------------------------------------------------------------------------
  // @[ "read with pipestreams" ] = ( T, done ) ->
  //   matcher       = [
  //     '01 ; charset=UTF-8',
  //     '02 @@@\tThe Unicode Standard 9.0.0',
  //     '03 @@@+\tU90M160615.lst',
  //     '04 \tUnicode 9.0.0 final names list.',
  //     '05 \tThis file is semi-automatically derived from UnicodeData.txt and',
  //     '06 \ta set of manually created annotations using a script to select',
  //     '07 \tor suppress information from the data file. The rules used',
  //     '08 \tfor this process are aimed at readability for the human reader,',
  //     '09 \tat the expense of some details; therefore, this file should not',
  //     '10 \tbe parsed for machine-readable information.',
  //     '11 @+\t\t© 2016 Unicode®, Inc.',
  //     '12 \tFor terms of use, see http://www.unicode.org/terms_of_use.html',
  //     '13 @@\t0000\tC0 Controls and Basic Latin (Basic Latin)\t007F',
  //     '14 @@+'
  //     ]
  //   # input_path    = '../../test-data/Unicode-NamesList-tiny.txt'
  //   input_path    = '/home/flow/io/basic-stream-benchmarks/test-data/Unicode-NamesList-tiny.txt'
  //   # output_path   = '/dev/null'
  //   output_path   = '/tmp/output.txt'
  //   input         = SP.new_stream input_path
  //   output        = FS.createWriteStream output_path
  //   collector     = []
  //   S             = {}
  //   S.item_count  = 0
  //   S.byte_count  = 0
  //   p             = input
  //   p             = p.pipe $ ( data, send ) -> whisper '20078-1', rpr data; send data
  //   p             = p.pipe SP.$split()
  //   p             = p.pipe $ ( data, send ) -> help '20078-1', rpr data; send data
  //   #.........................................................................................................
  //   p             = p.pipe SP.$ ( line, send ) ->
  //     S.item_count += +1
  //     S.byte_count += line.length
  //     debug '22001-0', rpr line
  //     collector.push line
  //     send line
  //   #.........................................................................................................
  //   p             = p.pipe $ ( data, send ) -> urge '20078-2', rpr data; send data
  //   p             = p.pipe SP.$as_line()
  //   p             = p.pipe output
  //   #.........................................................................................................
  //   ### TAINT use PipeStreams method ###
  //   output.on 'close', ->
  //     # debug '88862', S
  //     # debug '88862', collector
  //     if CND.equals collector, matcher
  //       T.succeed "collector equals matcher"
  //     done()
  //   #.........................................................................................................
  //   ### TAINT should be done by PipeStreams ###
  //   input.on 'end', ->
  //     outpudone()
  //   #.........................................................................................................
  //   return null

  // #-----------------------------------------------------------------------------------------------------------
  // @[ "remit without end detection" ] = ( T, done ) ->
  //   pipeline = []
  //   pipeline.push $values Array.from 'abcdef'
  //   pipeline.push $ ( data, send ) ->
  //     send data
  //     send '*' + data + '*'
  //   pipeline.push SP.$show()
  //   pipeline.push $pull_drain()
  //   SP.pull pipeline...
  //   T.succeed "ok"
  //   done()

  //-----------------------------------------------------------------------------------------------------------
  this["remit 1"] = function(T, done) {
    var pipeline, result;
    result = [];
    pipeline = [];
    pipeline.push([1, 2, 3]);
    // debug 'µ20922', t = $ ( d, send ) -> info 'µ1', d; send d + 10
    // debug 'µ20922', ( k for k of t )
    pipeline.push($(function(d, send) {
      info('µ1', d);
      return send(d + 10);
    }));
    pipeline.push($(function(d, send) {
      info('µ2', d);
      send(d);
      return send(d + 10);
    }));
    pipeline.push($(function(d, send) {
      info('µ3', d);
      result.push(d);
      return send(d);
    }));
    pipeline.push(SP.$drain(function() {
      // debug 'µ11121', jr result
      T.eq(result, [11, 21, 12, 22, 13, 23]);
      return done();
    }));
    return SP.pull(...pipeline);
  };

  //-----------------------------------------------------------------------------------------------------------
  this["drain with result"] = function(T, done) {
    var duct, pipeline;
    pipeline = [];
    pipeline.push([1, 2, 3]);
    pipeline.push($(function(d, send) {
      info('µ1', d);
      return send(d + 10);
    }));
    pipeline.push($(function(d, send) {
      info('µ2', d);
      send(d);
      return send(d + 10);
    }));
    pipeline.push(SP.$drain(function(result) {
      // debug 'µ1112-1', duct
      // debug 'µ1112-2', jr result
      T.eq(result, [11, 21, 12, 22, 13, 23]);
      return done();
    }));
    return duct = SP.pull(...pipeline);
  };

  //-----------------------------------------------------------------------------------------------------------
  this["drain with sink 1"] = function(T, done) {
    var duct, pipeline, sink;
    sink = [];
    pipeline = [];
    pipeline.push([1, 2, 3]);
    pipeline.push($(function(d, send) {
      info('µ1', d);
      return send(d + 10);
    }));
    pipeline.push($(function(d, send) {
      info('µ2', d);
      send(d);
      return send(d + 10);
    }));
    pipeline.push(SP.$drain({sink}, function(result) {
      // debug 'µ1112-1', duct
      // debug 'µ1112-2', jr result
      T.ok(result === sink);
      T.eq(result, [11, 21, 12, 22, 13, 23]);
      return done();
    }));
    return duct = SP.pull(...pipeline);
  };

  //-----------------------------------------------------------------------------------------------------------
  this["drain with sink 2"] = function(T, done) {
    var duct, pipeline, sink;
    sink = [];
    pipeline = [];
    pipeline.push([1, 2, 3]);
    pipeline.push($(function(d, send) {
      info('µ1', d);
      return send(d + 10);
    }));
    pipeline.push($(function(d, send) {
      info('µ2', d);
      send(d);
      return send(d + 10);
    }));
    pipeline.push(SP.$drain({sink}, function() {
      T.eq(sink, [11, 21, 12, 22, 13, 23]);
      return done();
    }));
    return duct = SP.pull(...pipeline);
  };

  //-----------------------------------------------------------------------------------------------------------
  this["remit 2"] = function(T, done) {
    var pipeline, result;
    result = [];
    pipeline = [];
    pipeline.push(Array.from('abcd'));
    pipeline.push(SP.$map(function(d) {
      return d.toUpperCase();
    }));
    pipeline.push(SP.$pass());
    pipeline.push($(function(d, send) {
      send(d);
      return send(`(${d})`);
    }));
    pipeline.push(SP.$show());
    pipeline.push($watch(function(d) {
      return result.push(d);
    }));
    pipeline.push(SP.$drain(function() {
      result = result.join('');
      T.eq(result, "A(A)B(B)C(C)D(D)");
      return done();
    }));
    return SP.pull(...pipeline);
  };

  //-----------------------------------------------------------------------------------------------------------
  this["remit with end detection 1"] = function(T, done) {
    var last, pipeline, result;
    last = Symbol('last');
    result = [];
    pipeline = [];
    pipeline.push(Array.from('abcd'));
    pipeline.push(SP.$map(function(d) {
      return d.toUpperCase();
    }));
    pipeline.push(SP.$show({
      title: 'x1'
    }));
    pipeline.push($({last}, function(d, send) {
      if (d === last) {
        return send('ok');
      }
      send(d);
      return send(`(${d})`);
    }));
    // pipeline.push SP.$show { title: 'x2', }
    pipeline.push($watch(function(d) {
      return result.push(d);
    }));
    pipeline.push(SP.$drain(function() {
      result = result.join('');
      T.eq(result, "A(A)B(B)C(C)D(D)ok");
      return done();
    }));
    return SP.pull(...pipeline);
  };

  //-----------------------------------------------------------------------------------------------------------
  this["remit with end detection 2"] = function(T, done) {
    var last, pipeline, result;
    last = Symbol('last');
    result = [];
    pipeline = [];
    pipeline.push(Array.from('abcdefg'));
    pipeline.push(SP.$map(function(d) {
      return d.toUpperCase();
    }));
    pipeline.push($(function(d, send) {
      if (d === 'E') {
        return send.end();
      } else {
        return send(d);
      }
    }));
    pipeline.push(SP.$show());
    pipeline.push($({last}, function(d, send) {
      if (d === last) {
        return send('ok');
      }
      send(d);
      return send(`(${d})`);
    }));
    pipeline.push($watch(function(d) {
      return result.push(d);
    }));
    pipeline.push(SP.$drain(function() {
      result = result.join('');
      T.eq(result, "A(A)B(B)C(C)D(D)ok");
      return done();
    }));
    return SP.pull(...pipeline);
  };

  //-----------------------------------------------------------------------------------------------------------
  this["remit with surrounds"] = function(T, done) {
    var after, before, between, first, last, pipeline, result;
    first = '[';
    before = '(';
    between = '|';
    after = ')';
    last = ']';
    result = [];
    pipeline = [];
    pipeline.push(Array.from('abcd'));
    pipeline.push(SP.$show());
    pipeline.push($({first, before, between, after, last}, function(d, send) {
      return send(d.toUpperCase());
    }));
    pipeline.push($watch(function(d) {
      return result.push(d);
    }));
    pipeline.push(SP.$drain(function() {
      result = result.join('');
      T.eq(result, '[(A)|(B)|(C)|(D)]');
      return done();
    }));
    return SP.pull(...pipeline);
  };

  //-----------------------------------------------------------------------------------------------------------
  this["watch with end detection 1"] = async function(T, done) {
    var error, matcher, probe;
    [probe, matcher, error] = ["abcd", '[(A)|(B)|(C)|(D)]', null];
    await T.perform(probe, matcher, error, function() {
      return new Promise(function(resolve, reject) {
        var after, before, between, collector, first, last, pipeline;
        first = '[';
        before = '(';
        between = '|';
        after = ')';
        last = ']';
        collector = [];
        pipeline = [];
        pipeline.push(Array.from(probe));
        pipeline.push(SP.$watch({first, before, between, after, last}, function(d) {
          // debug '44874', xrpr d
          return collector.push(d.toUpperCase());
        }));
        pipeline.push(SP.$drain(function() {
          collector = collector.join('');
          return resolve(collector);
        }));
        return SP.pull(...pipeline);
      });
    });
    //.........................................................................................................
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["end push source (1)"] = async function(T, done) {
    var error, matcher, probe;
    // The proper way to end a push source is to call `source.end()`.
    [probe, matcher, error] = [["what", "a", "lot", "of", "little", "bottles"], ["what", "a", "lot", "of", "little", "bottles"], null];
    await T.perform(probe, matcher, error, function() {
      return new Promise(function(resolve, reject) {
        var R, i, len, pipeline, source, word;
        R = [];
        source = SP.new_push_source();
        pipeline = [];
        pipeline.push(source);
        pipeline.push(SP.$watch(function(d) {
          return info(xrpr(d));
        }));
        pipeline.push(SP.$collect({
          collector: R
        }));
        pipeline.push(SP.$watch(function(d) {
          return info(xrpr(d));
        }));
        pipeline.push(SP.$drain(function() {
          help('ok');
          return resolve(R);
        }));
        SP.pull(...pipeline);
        for (i = 0, len = probe.length; i < len; i++) {
          word = probe[i];
          source.send(word);
        }
        source.end();
        return null;
      });
    });
    //.........................................................................................................
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["end push source (2)"] = async function(T, done) {
    var error, matcher, probe;
    [probe, matcher, error] = [["what", "a", "lot", "of", "little", "bottles"], ["what", "a", "lot", "of", "little", "bottles"], null];
    await T.perform(probe, matcher, error, function() {
      return new Promise(function(resolve, reject) {
        var R, i, len, pipeline, source, word;
        R = [];
        source = SP.new_push_source();
//.......................................................................................................
        for (i = 0, len = probe.length; i < len; i++) {
          word = probe[i];
          source.send(word);
        }
        source.end();
        //.......................................................................................................
        pipeline = [];
        pipeline.push(source);
        pipeline.push(SP.$watch(function(d) {
          return info(xrpr(d));
        }));
        pipeline.push(SP.$collect({
          collector: R
        }));
        pipeline.push(SP.$watch(function(d) {
          return info(xrpr(d));
        }));
        pipeline.push(SP.$drain(function() {
          help('ok');
          return resolve(R);
        }));
        SP.pull(...pipeline);
        return null;
      });
    });
    //.........................................................................................................
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["duct_from_transforms"] = function(T, done) {
    (() => {
      var r, ref;
      r = SP._new_duct([]);
      T.eq(r[SP.marks.isa_duct], SP.marks.isa_duct);
      T.eq(r.is_empty, true);
      T.eq((ref = r.is_single) != null ? ref : false, false);
      T.eq(r.first, void 0);
      T.eq(r.last, void 0);
      T.eq(r.transforms, []);
      return T.eq(r.type, void 0);
    })();
    (() => {      //.........................................................................................................
      var r, ref, ref1, source;
      r = SP._new_duct([source = SP.new_push_source()]);
      T.eq(r[SP.marks.isa_duct], SP.marks.isa_duct);
      T.eq(r.first, r.last);
      T.eq((ref = r.is_empty) != null ? ref : false, false);
      T.eq(r.is_single, true);
      T.eq(r.transforms.length, 1);
      T.eq(r.first.type, 'source');
      T.eq(r.type, 'source');
      return T.eq((ref1 = r.first.isa_pusher) != null ? ref1 : false, true);
    })();
    (() => {      //.........................................................................................................
      var drain, on_end, r, sink;
      r = SP._new_duct([sink = SP.$drain(on_end = (function() {}))]);
      drain = r.transforms[r.transforms.length - 1];
      T.eq(r.first, r.last);
      T.eq(r.is_single, true);
      T.eq(r.first.type, 'sink');
      return T.eq(r.type, 'sink');
    })();
    (() => {      // T.eq r.last.on_end,                               on_end
      // T.eq r.transforms[ 0 ][ SP.marks.steampipes ],    SP.marks.steampipes
      // T.eq r.transforms[ 0 ].type,                      'sink'
      //.........................................................................................................
      var r, through;
      r = SP._new_duct([through = SP.$((function(d, send) {}))]);
      T.eq(r.first, r.last);
      T.eq(r.is_single, true);
      T.eq(r.first.type, 'through');
      T.eq(r.type, 'through');
      return T.eq(r.transforms[0], through);
    })();
    (() => {      //.........................................................................................................
      var r, ref, ref1;
      r = SP._new_duct([SP.new_value_source([]), SP.$(function(d, send) {})]);
      T.eq((ref = r.is_empty) != null ? ref : false, false);
      T.eq((ref1 = r.is_single) != null ? ref1 : false, false);
      T.eq(r.first.type, 'source');
      return T.eq(r.type, 'source');
    })();
    (() => {      //.........................................................................................................
      var f;
      f = function() {
        return SP._new_duct([SP.new_value_source([]), SP.new_value_source([]), SP.$(function(d, send) {})]);
      };
      return T.throws(/illegal duct configuration/, f);
    })();
    (() => {      //.........................................................................................................
      var r;
      r = SP._new_duct([SP.new_value_source([]), SP.$(function(d, send) {}), SP.$drain()]);
      return T.eq(r.type, 'circuit');
    })();
    //.........................................................................................................
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["composability (through)"] = async function(T, done) {
    var error, matcher, probe;
    [probe, matcher, error] = [["what", "a", "lot", "of", "little", "bottles"], ["what", "a", "lot", "of", "little", "bottles"], null];
    await T.perform(probe, matcher, error, function() {
      return new Promise(function(resolve, reject) {
        var R, duct_A, duct_B, length_of_A, length_of_B, pipeline_A, pipeline_B, source;
        R = [];
        source = probe;
        //.......................................................................................................
        pipeline_A = [];
        pipeline_A.push(SP.$watch(function(d) {
          return info(xrpr(d));
        }));
        pipeline_A.push(SP.$collect({
          collector: R
        }));
        length_of_A = pipeline_A.length;
        duct_A = SP.pull(...pipeline_A);
        T.eq(duct_A.transforms.length, length_of_A);
        T.eq(duct_A.type, 'through');
        //.......................................................................................................
        pipeline_B = [];
        pipeline_B.push(source);
        pipeline_B.push(duct_A);
        pipeline_B.push(SP.$watch(function(d) {
          return info(xrpr(d));
        }));
        pipeline_B.push(SP.$drain(function() {
          return help('ok');
        }));
        length_of_B = pipeline_B.length - 1 + length_of_A;
        duct_B = SP.pull(...pipeline_B);
        T.eq(duct_B.transforms.length, length_of_B);
        T.eq(duct_B.type, 'circuit');
        resolve(R);
        return null;
      });
    });
    //.........................................................................................................
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["composability (source)"] = async function(T, done) {
    var error, matcher, probe;
    [probe, matcher, error] = ["𦇻𦑛𦖵𦩮𦫦𧞈", Array.from('𦇻𦑛𦖵𦩮𦫦𧞈'), null];
    await T.perform(probe, matcher, error, function() {
      return new Promise(function(resolve, reject) {
        var R, duct_A, duct_B, length_of_A, length_of_B, pipeline_A, pipeline_B, source;
        R = [];
        source = probe;
        //.......................................................................................................
        pipeline_A = [];
        pipeline_A.push(source);
        pipeline_A.push(SP.$watch(function(d) {
          return info(xrpr(d));
        }));
        pipeline_A.push(SP.$collect({
          collector: R
        }));
        length_of_A = pipeline_A.length;
        duct_A = SP.pull(...pipeline_A);
        T.eq(duct_A.transforms.length, length_of_A);
        T.eq(duct_A.type, 'source');
        //.......................................................................................................
        pipeline_B = [];
        pipeline_B.push(duct_A);
        pipeline_B.push(SP.$watch(function(d) {
          return info(xrpr(d));
        }));
        pipeline_B.push(SP.$drain(function() {
          return help('ok');
        }));
        length_of_B = pipeline_B.length - 1 + length_of_A;
        duct_B = SP.pull(...pipeline_B);
        T.eq(duct_B.transforms.length, length_of_B);
        T.eq(duct_B.type, 'circuit');
        resolve(R);
        return null;
      });
    });
    //.........................................................................................................
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["composability (sink)"] = async function(T, done) {
    var error, matcher, probe;
    [probe, matcher, error] = ["𦇻𦑛𦖵𦩮𦫦𧞈", Array.from('𦇻𦑛𦖵𦩮𦫦𧞈'), null];
    await T.perform(probe, matcher, error, function() {
      return new Promise(function(resolve, reject) {
        var R, duct_A, duct_B, length_of_A, length_of_B, pipeline_A, pipeline_B, source;
        R = [];
        source = probe;
        //.......................................................................................................
        pipeline_A = [];
        pipeline_A.push(SP.$watch(function(d) {
          return info(xrpr(d));
        }));
        pipeline_A.push(SP.$collect({
          collector: R
        }));
        pipeline_A.push(SP.$drain(function() {
          return help('ok');
        }));
        length_of_A = pipeline_A.length;
        duct_A = SP.pull(...pipeline_A);
        T.eq(duct_A.transforms.length, length_of_A);
        T.eq(duct_A.type, 'sink');
        //.......................................................................................................
        pipeline_B = [];
        pipeline_B.push(source);
        pipeline_B.push(SP.$watch(function(d) {
          return info(xrpr(d));
        }));
        pipeline_B.push(duct_A);
        length_of_B = pipeline_B.length - 1 + length_of_A;
        duct_B = SP.pull(...pipeline_B);
        T.eq(duct_B.transforms.length, length_of_B);
        T.eq(duct_B.type, 'circuit');
        // debug 'µ11124', duct_B
        resolve(R);
        return null;
      });
    });
    //.........................................................................................................
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["$filter"] = async function(T, done) {
    var error, matcher, probe;
    [probe, matcher, error] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9], [1, 3, 5, 7, 9], null];
    await T.perform(probe, matcher, error, function() {
      return new Promise(function(resolve, reject) {
        var R, pipeline, source;
        R = [];
        source = probe;
        //.......................................................................................................
        pipeline = [];
        pipeline.push(source);
        pipeline.push(SP.$filter(function(d) {
          return (modulo(d, 2)) === 1;
        }));
        // pipeline.push SP.$watch ( d ) -> info xrpr d
        pipeline.push(SP.$drain(function(values) {
          // urge values
          return resolve(values);
        }));
        SP.pull(...pipeline);
        return null;
      });
    });
    //.........................................................................................................
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["$chunkify_keep no postprocessing"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    probes_and_matchers = [[[], [], null], ['abcdefg', [['a', 'b', 'c', 'd', 'e', 'f', 'g']], null], ['ab(cdefg)', [['a', 'b', '('], ['c', 'd', 'e', 'f', 'g', ')']], null]];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      //.......................................................................................................
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve, reject) {
          var pipeline;
          pipeline = [];
          pipeline.push(probe);
          pipeline.push(SP.$chunkify_keep(function(d) {
            return d === '(' || d === ')';
          }));
          pipeline.push(SP.$drain(function(collector) {
            return resolve(collector);
          }));
          SP.pull(...pipeline);
          //.....................................................................................................
          return null;
        });
      });
    }
    //.........................................................................................................
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["$chunkify_toss no postprocessing"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    probes_and_matchers = [[[], [], null], ['abcdefg', [['a', 'b', 'c', 'd', 'e', 'f', 'g']], null], ['ab(cdefg)', [['a', 'b'], ['c', 'd', 'e', 'f', 'g']], null]];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      //.......................................................................................................
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve, reject) {
          var pipeline;
          pipeline = [];
          pipeline.push(probe);
          pipeline.push(SP.$chunkify_toss(function(d) {
            return d === '(' || d === ')';
          }));
          pipeline.push(SP.$drain(function(collector) {
            return resolve(collector);
          }));
          SP.pull(...pipeline);
          //.....................................................................................................
          return null;
        });
      });
    }
    //.........................................................................................................
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["$chunkify_toss with postprocessing"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    probes_and_matchers = [[[], [], null], ['abcdefg', ['a|b|c|d|e|f|g'], null], ['ab(cdefg)', ['a|b', 'c|d|e|f|g'], null]];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      //.......................................................................................................
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve, reject) {
          var pipeline;
          pipeline = [];
          pipeline.push(probe);
          pipeline.push(SP.$chunkify_toss((function(d) {
            return d === '(' || d === ')';
          }), function(chunk) {
            return chunk.join('|');
          }));
          pipeline.push(SP.$drain(function(collector) {
            return resolve(collector);
          }));
          SP.pull(...pipeline);
          //.....................................................................................................
          return null;
        });
      });
    }
    //.........................................................................................................
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["$chunkify_keep with postprocessing"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    probes_and_matchers = [[[], [], null], ['abcdefg', ['a|b|c|d|e|f|g'], null], ['ab(cdefg)', ['a|b|(', 'c|d|e|f|g|)'], null]];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      //.......................................................................................................
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve, reject) {
          var pipeline;
          pipeline = [];
          pipeline.push(probe);
          pipeline.push(SP.$chunkify_keep((function(d) {
            return d === '(' || d === ')';
          }), function(chunk) {
            return chunk.join('|');
          }));
          pipeline.push(SP.$drain(function(collector) {
            return resolve(collector);
          }));
          SP.pull(...pipeline);
          //.....................................................................................................
          return null;
        });
      });
    }
    //.........................................................................................................
    done();
    return null;
  };

  /*

  #-----------------------------------------------------------------------------------------------------------
  @[ "end push source (3)" ] = ( T, done ) ->
   * The proper way to end a push source is to call `source.end()`; `send.end()` is largely equivalent.
    [ probe, matcher, error, ] = [["what","a","lot","of","little","bottles","stop"],["what","a","lot","of","little","bottles"],null]
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      R         = []
      drainer   = -> help 'ok'; resolve R
      source    = SP.new_push_source()
      pipeline  = []
      pipeline.push source
      pipeline.push SP.$watch ( d ) -> info xrpr d
      pipeline.push $ ( d, send ) -> if d is 'stop' then send.end() else send d
      pipeline.push SP.$collect { collector: R, }
      pipeline.push SP.$watch ( d ) -> info xrpr d
      pipeline.push SP.$drain drainer
      pull pipeline...
      for word in probe
        source.send word
      return null
    #.........................................................................................................
    done()
    return null

  #-----------------------------------------------------------------------------------------------------------
  @[ "end push source (4)" ] = ( T, done ) ->
   * A stream may be ended by using an `$end_if()` (alternatively, `$continue_if()`) transform.
    [ probe, matcher, error, ] = [["what","a","lot","of","little","bottles","stop"],["what","a","lot","of","little","bottles"],null]
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      R         = []
      drainer   = -> help 'ok'; resolve R
      source    = SP.new_push_source()
      pipeline  = []
      pipeline.push source
      pipeline.push SP.$watch ( d ) -> info xrpr d
      pipeline.push SP.$end_if ( d ) -> d is 'stop'
      pipeline.push SP.$collect { collector: R, }
      pipeline.push SP.$watch ( d ) -> info xrpr d
      pipeline.push SP.$drain drainer
      pull pipeline...
      for word in probe
        source.send word
      return null
    #.........................................................................................................
    done()
    return null

  #-----------------------------------------------------------------------------------------------------------
  @[ "wrap FS object for sink" ] = ( T, done ) ->
    output_path   = '/tmp/pipestreams-test-output.txt'
    output_stream = FS.createWriteStream output_path
    sink          = SP.write_to_nodejs_stream output_stream #, ( error ) -> debug '37783', error
    pipeline      = []
    pipeline.push $values Array.from 'abcdef'
    pipeline.push SP.$show()
    pipeline.push sink
    pull pipeline...
    output_stream.on 'finish', =>
      T.ok CND.equals 'abcdef', read output_path
      done()

  #-----------------------------------------------------------------------------------------------------------
  @[ "function as pull-stream source" ] = ( T, done ) ->
    random = ( n ) =>
      return ( end, callback ) =>
        if end?
          debug '40998', rpr callback
          debug '40998', rpr end
          return callback end
        #only read n times, then stop.
        n += -1
        if n < 0
          return callback true
        callback null, Math.random()
        return null
    #.........................................................................................................
    pipeline  = []
    Ø         = ( x ) => pipeline.push x
    Ø random 10
   * Ø random 3
    Ø SP.$collect()
    Ø $ { last: null, }, ( data, send ) ->
      if data?
        T.ok data.length is 10
        debug data
        send data
      else
        T.succeed "function works as pull-stream source"
        done()
        send null
    Ø SP.$show()
    Ø SP.$drain()
    #.........................................................................................................
    SP.pull pipeline...
    return null

  #-----------------------------------------------------------------------------------------------------------
  @[ "$surround" ] = ( T, done ) ->
    [ probe, matcher, error, ] = [null,"first[(1),(2),(3),(4),(5)]last",null]
    await T.perform probe, matcher, error, ->
      return new Promise ( resolve, reject ) ->
        R         = null
        drainer   = -> help 'ok'; resolve R
        pipeline  = []
        pipeline.push SP.new_value_source [ 1 .. 5 ]
        #.........................................................................................................
        pipeline.push SP.$surround { first: '[', last: ']', before: '(', between: ',', after: ')' }
        pipeline.push SP.$surround { first: 'first', last: 'last', }
   * pipeline.push SP.$surround { first: 'first', last: 'last', before: 'before', between: 'between', after: 'after' }
   * pipeline.push SP.$surround { first: '[', last: ']', }
        #.........................................................................................................
        pipeline.push SP.$collect()
        pipeline.push $ ( d, send ) -> send ( x.toString() for x in d ).join ''
        pipeline.push SP.$watch ( d ) -> R = d
        pipeline.push SP.$drain drainer
        SP.pull pipeline...
        return null
    #.........................................................................................................
    done()
    return null

  #-----------------------------------------------------------------------------------------------------------
  @[ "$surround async" ] = ( T, done ) ->
    [ probe, matcher, error, ] = [null,"[first|1|2|3|4|5|last]",null]
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      R         = null
      drainer   = -> help 'ok'; resolve R
      pipeline  = []
      pipeline.push SP.new_value_source [ 1 .. 5 ]
      #.........................................................................................................
      pipeline.push SP.$surround { first: 'first', last: 'last', }
      pipeline.push $async { first: '[', last: ']', between: '|', }, ( d, send, done ) =>
        defer ->
   * debug '22922', jr d
          send d
          done()
      #.........................................................................................................
      pipeline.push SP.$collect()
      pipeline.push $ ( d, send ) -> send ( x.toString() for x in d ).join ''
      pipeline.push SP.$watch ( d ) -> R = d
      pipeline.push SP.$drain drainer
      SP.pull pipeline...
      return null
    #.........................................................................................................
    done()
    return null

  #-----------------------------------------------------------------------------------------------------------
  @[ "end random async source" ] = ( T, done ) ->
    [ probe, matcher, error, ] = [["what","a","lot","of","little","bottles"],["what","a","lot","of","little","bottles"],null]
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      R         = []
      drainer   = -> help 'ok'; resolve R
      source    = SP.new_random_async_value_source probe
      pipeline  = []
      pipeline.push source
      pipeline.push SP.$watch ( d ) -> info xrpr d
      pipeline.push SP.$collect { collector: R, }
      pipeline.push SP.$watch ( d ) -> info xrpr d
      pipeline.push SP.$drain drainer
      pull pipeline...
      return null
    #.........................................................................................................
    done()
    return null

  #-----------------------------------------------------------------------------------------------------------
  @[ "read file chunks" ] = ( T, done ) ->
    [ probe, matcher, error, ] = [ __filename, null, null, ]
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      R         = []
      drainer   = -> help 'ok'; resolve null
      source    = SP.read_chunks_from_file probe, 50
      count     = 0
      pipeline  = []
      pipeline.push source
      pipeline.push $ ( d, send ) -> send d.toString 'utf-8'
      pipeline.push SP.$watch ->
        count += +1
        source.end() if count > 3
      pipeline.push SP.$collect { collector: R, }
      pipeline.push SP.$watch ( d ) -> info xrpr d
      pipeline.push SP.$drain drainer
      pull pipeline...
      return null
    #.........................................................................................................
    done()
    return null

  #-----------------------------------------------------------------------------------------------------------
  @[ "demo watch pipeline on abort 2" ] = ( T, done ) ->
   * through = require 'pull-through'
    probes_and_matchers = [
      [[false,[1,2,3,null,5]],[1,1,1,2,2,2,3,3,3,null,null,null,5,5,5],null]
      [[true,[1,2,3,null,5]],[1,1,1,2,2,2,3,3,3,null,null,null,5,5,5],null]
      [[false,[1,2,3,"stop",25,30]],[1,1,1,2,2,2,3,3,3],null]
      [[true,[1,2,3,"stop",25,30]],[1,1,1,2,2,2,3,3,3],null]
      [[false,[1,2,3,null,"stop",25,30]],[1,1,1,2,2,2,3,3,3,null,null,null],null]
      [[true,[1,2,3,null,"stop",25,30]],[1,1,1,2,2,2,3,3,3,null,null,null],null]
      [[false,[1,2,3,undefined,"stop",25,30]],[1,1,1,2,2,2,3,3,3,undefined,undefined,undefined,],null]
      [[true,[1,2,3,undefined,"stop",25,30]],[1,1,1,2,2,2,3,3,3,undefined,undefined,undefined,],null]
      [[false,["stop",25,30]],[],null]
      [[true,["stop",25,30]],[],null]
      ]
    #.........................................................................................................
    aborting_map = ( use_defer, mapper ) ->
      react = ( handler, data ) ->
        if data is 'stop' then  handler true
        else                    handler null, mapper data
   * a sink function: accept a source...
      return ( read ) ->
   * ...but return another source!
        return ( abort, handler ) ->
          read abort, ( error, data ) ->
   * if the stream has ended, pass that on.
            return handler error if error
            if use_defer then  defer -> react handler, data
            else                        react handler, data
            return null
          return null
        return null
    #.........................................................................................................
    for [ probe, matcher, error, ] in probes_and_matchers
      await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
        #.....................................................................................................
        [ use_defer
          values ]  = probe
        source      = SP.new_value_source values
        collector   = []
        pipeline    = []
        pipeline.push source
        pipeline.push aborting_map use_defer, ( d ) -> info '22398-1', xrpr d; return d
        pipeline.push SP.$ ( d, send ) -> info '22398-2', xrpr d; collector.push d; send d
        pipeline.push SP.$ ( d, send ) -> info '22398-3', xrpr d; collector.push d; send d
        pipeline.push SP.$ ( d, send ) -> info '22398-4', xrpr d; collector.push d; send d
   * pipeline.push SP.$map ( d ) -> info '22398-2', xrpr d; collector.push d; return d
   * pipeline.push SP.$map ( d ) -> info '22398-3', xrpr d; collector.push d; return d
   * pipeline.push SP.$map ( d ) -> info '22398-4', xrpr d; collector.push d; return d
        pipeline.push SP.$drain ->
          help '44998', xrpr collector
          resolve collector
        pull pipeline...
    #.........................................................................................................
    done()
    return null

  #-----------------------------------------------------------------------------------------------------------
  @[ "$mark_position" ] = ( T, done ) ->
   * through = require 'pull-through'
    probes_and_matchers = [
      [["a"],[{"is_first":true,"is_last":true,"d":"a"}],null]
      [[],[],null]
      [[1,2,3],[{"is_first":true,"is_last":false,"d":1},{"is_first":false,"is_last":false,"d":2},{"is_first":false,"is_last":true,"d":3}],null]
      [["a","b"],[{"is_first":true,"is_last":false,"d":"a"},{"is_first":false,"is_last":true,"d":"b"}],null]
      ]
    #.........................................................................................................
    collector = []
    for [ probe, matcher, error, ] in probes_and_matchers
      await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
        #.....................................................................................................
        source      = SP.new_value_source probe
        collector   = []
        pipeline    = []
        pipeline.push source
        pipeline.push SP.$mark_position()
        pipeline.push SP.$collect { collector, }
        pipeline.push SP.$drain -> resolve collector
        pull pipeline...
    #.........................................................................................................
    done()
    return null

  #-----------------------------------------------------------------------------------------------------------
  @[ "$scramble" ] = ( T, done ) ->
    probes_and_matchers = [
      [[[],0.5,42],[],null]
      [[[1],0.5,42],[1],null]
      [[[1,2],0.5,42],[1,2],null]
      [[[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40],0.5,42],[1,4,2,5,3,6,7,14,12,9,13,8,16,10,15,11,17,18,19,20,21,22,24,26,23,25,27,28,29,30,32,31,33,34,35,37,36,38,39,40],null]
      [[[1,2,3,4,5,6,7,8,9,10],1,2],[9,2,7,5,8,4,10,1,3,6],null]
      [[[1,2,3,4,5,6,7,8,9,10],0.1,2],[1,2,3,4,5,6,7,8,9,10],null]
      [[[1,2,3,4,5,6,7,8,9,10],0,2],[1,2,3,4,5,6,7,8,9,10],null]
      ]
    #.........................................................................................................
    for [ probe, matcher, error, ] in probes_and_matchers
      #.......................................................................................................
      await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
        [ values
          p
          seed ]    = probe
        cache       = {}
        collector   = []
        pipeline    = []
        pipeline.push SP.new_value_source values
        pipeline.push SP.$scramble p, { seed, }
        pipeline.push SP.$collect { collector, }
        pipeline.push SP.$drain -> resolve collector
        SP.pull pipeline...
        #.....................................................................................................
        return null
    #.........................................................................................................
    done()
    return null
   */
  //###########################################################################################################
  if (module.parent == null) {
    // test @[ "$chunkify 1"                       ]
    // test @[ "$chunkify_keep no postprocessing"  ]
    // test @[ "$chunkify_toss no postprocessing"  ]
    // test @[ "$chunkify_toss with postprocessing"  ]
    test(this["$chunkify_keep with postprocessing"]);
  }

  // test @, 'timeout': 30000
// test @[ "$filter" ]
// test @[ "end push source (2)"             ]
// test @[ "remit 1"                         ]
// test @[ "drain with result"               ]
// test @[ "remit 2"                         ]
// test @[ "remit with end detection 1"      ]
// test @[ "duct_from_transforms"            ]
// test @[ "composability (through)"                 ]
// test @[ "composability (source)"                 ]
// test @[ "composability (sink)" ]
// test @[ "remit with end detection 2"      ]
// test @[ "remit with surrounds"            ]
// test @[ "watch with end detection 1"      ]
// test @[ "watch with end detection 2"      ]
// test @[ "end push source (1)"             ]
// test @[ "end push source (3)"             ]
// test @[ "end push source (4)"             ]
// test @[ "wrap FS object for sink"         ]
// test @[ "function as pull-stream source"  ]
// test @[ "$surround"                       ]
// test @[ "$surround async"                 ]
// test @[ "end random async source"         ]
// test @[ "read file chunks"                ]
// test @[ "demo watch pipeline on abort 2"  ]
// test @[ "$mark_position"                  ]
// test @[ "leapfrog 1"                      ]
// test @[ "leapfrog 2"                      ]
// test @[ "$scramble"                       ]

}).call(this);
