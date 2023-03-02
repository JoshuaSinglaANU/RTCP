(function() {
  'use strict';
  var CND, badge, debug, echo, help, info, isa, jr, rpr, type_of, urge, validate, warn, whisper,
    splice = [].splice;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'STEAMPIPES/PULL-REMIT';

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  info = CND.get_logger('info', badge);

  urge = CND.get_logger('urge', badge);

  help = CND.get_logger('help', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  ({jr} = CND);

  //...........................................................................................................
  ({isa, validate, type_of} = require('./types'));

  //===========================================================================================================

  //-----------------------------------------------------------------------------------------------------------
  /* Signals are special values that, when sent down the pipeline, may alter behavior: */
  this.signals = Object.freeze({
    last: Symbol.for('steampipes/last'), // Used to signal last data item
    end: Symbol.for('steampipes/end') // Request stream to terminate
  });

  
  //-----------------------------------------------------------------------------------------------------------
  /* Marks are special values that identify types, behavior of pipeline elements etc: */
  this.marks = Object.freeze({
    steampipes: Symbol.for('steampipes/steampipes'), // Marks steampipes objects
    validated: Symbol.for('steampipes/validated'), // Marks a validated sink
    isa_duct: Symbol.for('steampipes/isa_duct'), // Marks a duct as such
    isa_pusher: Symbol.for('steampipes/isa_pusher'), // Marks a push source as such
    isa_wye: Symbol.for('steampipes/isa_wye'), // Marks an intermediate source
    send_last: Symbol.for('steampipes/send_last'), // Marks transforms expecting a certain value before EOS
    async: Symbol.for('steampipes/async') // Marks transforms as asynchronous (experimental)
  });

  
  //===========================================================================================================

  //-----------------------------------------------------------------------------------------------------------
  this.remit = this.$ = function(...modifications) {
    var arity, ref, sink, transform;
    ref = modifications, [...modifications] = ref, [transform] = splice.call(modifications, -1);
    validate.function(transform);
    if ((arity = transform.length) !== 2) {
      throw new Error(`^steampipes/pullremit@7000^ transform arity ${arity} not implemented`);
    }
    if ((sink = transform.sink) == null) {
      transform.sink = sink = [];
    }
    transform.send = sink.push.bind(sink);
    if (modifications.length > 0) {
      return this.modify(...modifications, transform);
    }
    return transform;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$async = function(transform) {
    var R, arity, done, resolve, send, sink;
    /* TAINT incomplete implementation: surround, leapfrog arguments missing */
    if (arguments.length !== 1) {
      throw new Error("^steampipes/pullremit@7001^ modifications not yet implemented");
    }
    if ((arity = transform.length) !== 3) {
      throw new Error(`^steampipes/pullremit@7002^ transform arity ${arity} not implemented`);
    }
    resolve = null;
    R = (d, send) => {
      return new Promise(async(r_) => {
        resolve = r_;
        return (await transform(d, send, done));
      });
    };
    R.sink = sink = [];
    R.send = send = sink.push;
    R.done = done = function() {
      return resolve();
    };
    R[this.marks.async] = this.marks.async;
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  this._classify_sink = function(transform) {
    var R;
    if (transform[this.marks.validated] == null) {
      this._$drain(transform);
    }
    return R = {
      type: 'sink'
    };
  };

  //-----------------------------------------------------------------------------------------------------------
  this._classify_transform = function(transform) {
    var R;
    R = (() => {
      var type;
      if (transform[this.marks.isa_duct] != null) {
        return {
          type: transform.type
        };
      }
      if (transform[this.marks.isa_pusher] != null) {
        return {
          type: 'source',
          isa_pusher: true
        };
      }
      if (transform[this.marks.isa_wye] != null) {
        return {
          type: 'wye'
        };
      }
      if (transform[Symbol.iterator] != null) {
        return {
          type: 'source'
        };
      }
      if ((isa.object(transform)) && (transform.sink != null)) {
        return this._classify_sink(transform);
      }
      switch (type = type_of(transform)) {
        case 'function':
          return {
            type: 'through'
          };
        case 'generatorfunction':
          return {
            type: 'source',
            must_call: true
          };
        case 'asyncgenerator':
          transform[this.marks.async] = true;
          return {
            type: 'source',
            must_call: false
          };
      }
      throw new Error(`^steampipes/pullremit@7003^ expected an iterable, a function, a generator function or a sink, got a ${type}`);
    })();
    R.mode = transform[this.marks.async] != null ? 'async' : 'sync';
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  this._flatten_transforms = function(transforms, R = null) {
    var i, j, len, len1, ref, t, transform;
    if (R == null) {
      R = [];
    }
    for (i = 0, len = transforms.length; i < len; i++) {
      transform = transforms[i];
      /* TAINT how can `undefined` end up in `transforms`??? */
      // continue unless transform?
      if (transform[this.marks.isa_duct] != null) {
        ref = transform.transforms;
        for (j = 0, len1 = ref.length; j < len1; j++) {
          t = ref[j];
          /* TAINT necessary to do this recursively? */
          R.push(t);
        }
      } else {
        R.push(transform);
      }
    }
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  this._new_duct = function(transforms) {
    var R, b, blurbs, i, idx, key, ref, ref1, ref2, transform;
    transforms = this._flatten_transforms(transforms);
    blurbs = (function() {
      var i, len, results;
      results = [];
      for (i = 0, len = transforms.length; i < len; i++) {
        transform = transforms[i];
        results.push(this._classify_transform(transform));
      }
      return results;
    }).call(this);
    R = {[ref = this.marks.steampipes]: ref, [ref1 = this.marks.isa_duct]: ref1, transforms, blurbs};
    R.mode = (blurbs.some(function(blurb) {
      return blurb.mode === 'async';
    })) ? 'async' : 'sync';
    if (transforms.length === 0) {
      R.is_empty = true;
      return R;
    }
    //.........................................................................................................
    R.first = blurbs[0];
    if (transforms.length === 1) {
      R.is_single = true;
      R.last = R.first;
      R.type = R.first.type;
    } else {
      R.last = blurbs[transforms.length - 1];
      switch (key = `${R.first.type}/${R.last.type}`) {
        case 'source/through':
          R.type = 'source';
          break;
        case 'through/sink':
          R.type = 'sink';
          break;
        case 'through/through':
          R.type = 'through';
          break;
        case 'source/sink':
          R.type = 'circuit';
          break;
        default:
          throw new Error(`^steampipes/pullremit@7004^ illegal duct configuration ${rpr(key)}`);
      }
      for (idx = i = 1, ref2 = blurbs.length - 1; i < ref2; idx = i += +1) {
        switch ((b = blurbs[idx]).type) {
          case 'through':
          case 'wye':
            null;
            break;
          default:
            throw new Error(`^steampipes/pullremit@7005^ illegal duct configuration at transform index ${idx}: ${rpr(b)}`);
        }
      }
    }
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  this._pull = function(...transforms) {
    var buckets, drain, duct, exhaust_async_pipeline, exhaust_pipeline, has_local_sink, idx, last, last_transform_idx, local_sink, local_source, original_source, send, source, tf_idxs;
    duct = this._new_duct(transforms);
    ({transforms} = duct);
    original_source = null;
    if (duct.last.type === 'source') {
      throw new Error("^steampipes/pullremit@7006^ source as last transform not yet supported");
    }
    if (duct.first.type === 'sink') {
      throw new Error("^steampipes/pullremit@7007^ sink as first transform not yet supported");
    }
    //.........................................................................................................
    if (duct.first.type === 'source') {
      if (duct.first.must_call) {
        transforms[0] = transforms[0]();
      }
      source = transforms[0];
    }
    if (duct.type !== 'circuit') {
      //.........................................................................................................
      return duct;
    }
    //.........................................................................................................
    drain = transforms[transforms.length - 1];
    duct.buckets = buckets = (function() {
      var i, ref, results;
      results = [];
      for (idx = i = 1, ref = transforms.length - 1; (1 <= ref ? i < ref : i > ref); idx = 1 <= ref ? ++i : --i) {
        results.push(transforms[idx].sink);
      }
      return results;
    })();
    if (drain.use_sink) {
      duct.buckets.push(drain.sink);
    }
    duct.has_ended = false;
    local_sink = null;
    local_source = null;
    has_local_sink = null;
    last = this.signals.last;
    last_transform_idx = buckets.length - (drain.use_sink ? 2 : 1);
    tf_idxs = (function() {
      var results = [];
      for (var i = 0; 0 <= last_transform_idx ? i <= last_transform_idx : i >= last_transform_idx; 0 <= last_transform_idx ? i++ : i--){ results.push(i); }
      return results;
    }).apply(this);
    //.........................................................................................................
    send = (d) => {
      if (d === this.signals.end) {
        return duct.has_ended = true;
      }
      if (has_local_sink) {
        local_sink.push(d);
      }
      return null;
    };
    send.end = () => {
      return duct.has_ended = true;
    };
    //.........................................................................................................
    exhaust_pipeline = () => {
      var d, data_count, i, len, transform;
      while (true) {
        data_count = 0;
        for (i = 0, len = tf_idxs.length; i < len; i++) {
          idx = tf_idxs[i];
          if ((local_source = buckets[idx]).length === 0) {
            continue;
          }
          transform = transforms[idx + 1];
          local_sink = buckets[idx + 1];
          has_local_sink = local_sink != null;
          d = local_source.shift();
          data_count += local_source.length;
          if (d === last) {
            if (transform[this.marks.send_last] != null) {
              transform(d, send);
            }
            if (idx !== last_transform_idx) {
              send(last);
            }
          } else {
            transform(d, send);
          }
        }
        if (data_count === 0) {
          break;
        }
      }
      return null;
    };
    //.........................................................................................................
    exhaust_async_pipeline = async() => {
      var d, data_count, i, len, transform;
      while (true) {
        data_count = 0;
// for transform, idx in transforms
        for (i = 0, len = tf_idxs.length; i < len; i++) {
          idx = tf_idxs[i];
          if ((local_source = buckets[idx]).length === 0) {
            continue;
          }
          transform = transforms[idx + 1];
          local_sink = buckets[idx + 1];
          has_local_sink = local_sink != null;
          d = local_source.shift();
          data_count += local_source.length;
          if (transform[this.marks.async] != null) {
            if (d === last) {
              if (transform[this.marks.send_last] != null) {
                await transform(d, send);
              }
              if (idx !== last_transform_idx) {
                send(last);
              }
            } else {
              await transform(d, send);
            }
          } else {
            if (d === last) {
              if (transform[this.marks.send_last] != null) {
                transform(d, send);
              }
              if (idx !== last_transform_idx) {
                send(last);
              }
            } else {
              transform(d, send);
            }
          }
        }
        if (data_count === 0) {
          break;
        }
      }
      return null;
    };
    //.........................................................................................................
    duct.send = send;
    duct.exhaust_pipeline = exhaust_pipeline;
    duct.exhaust_async_pipeline = exhaust_async_pipeline;
    //.........................................................................................................
    return duct;
  };

  //-----------------------------------------------------------------------------------------------------------
  this._integrate_wye = function(transforms, wye_idx) {
    var A_has_ended, B_has_ended, duct_A, duct_B, duct_C, end_source_C, last, pipeline_A, pipeline_B, pipeline_C, source_A, source_B, source_C;
    throw new Error("not yet implemented");
    last = Symbol('last');
    //.........................................................................................................
    source_A = probe_A;
    A_has_ended = false;
    B_has_ended = false;
    pipeline_A = [];
    pipeline_A.push(source_A);
    pipeline_A.push($watch(function(d) {
      return help('A', jr(d));
    }));
    pipeline_A.push($({last}, function(d, send) {
      if (d === last) {
        A_has_ended = true;
        return end_source_C();
      }
      return source_C.send(d);
    }));
    pipeline_A.push($drain(function() {
      return whisper('A');
    }));
    //.........................................................................................................
    source_B = probe_B;
    pipeline_B = [];
    pipeline_B.push(source_B);
    pipeline_B.push($watch(function(d) {
      return urge('B', jr(d));
    }));
    pipeline_B.push($({last}, function(d, send) {
      if (d === last) {
        B_has_ended = true;
        return end_source_C();
      }
      return source_C.send(d);
    }));
    pipeline_B.push($drain(function() {
      return whisper('B');
    }));
    //.........................................................................................................
    source_C = SP.new_push_source();
    pipeline_C = [];
    pipeline_C.push(source_C);
    pipeline_C.push($watch(function(d) {
      return info('C', jr(d));
    }));
    pipeline_C.push($drain(function(Σ) {
      whisper('C', jr(Σ));
      return resolve(Σ.join(''));
    }));
    //.........................................................................................................
    end_source_C = function() {
      if (!(A_has_ended && B_has_ended)) {
        return;
      }
      return source_C.end();
    };
    //.........................................................................................................
    // pipeline_A.push wye
    duct_C = SP.pull(...pipeline_C);
    duct_A = SP.pull(...pipeline_A);
    return duct_B = SP.pull(...pipeline_B);
  };

  // #-----------------------------------------------------------------------------------------------------------
  // @_integrate_wyes = ( transforms... ) ->
  //   # debug '^776665^', transforms
  //   # for transform, wye_idx in transforms
  //   #   if transform[ @marks.isa_wye ]
  //   #     return @_integrate_wye transforms, wye_idx
  //   return null

  //-----------------------------------------------------------------------------------------------------------
  this.pull = function(...transforms) {
    var d, drain, duct, first_bucket, on_end, ref;
    // return duct if ( duct = @_integrate_wyes transforms... )?
    duct = this._pull(...transforms);
    //.........................................................................................................
    if (isa.function(duct.transforms[0].start)) {
      duct.transforms[0].start();
    }
    if (duct.type !== 'circuit') {
      // else if isa.asyncfunction duct.transforms[ 0 ].start  then  await duct.transforms[ 0 ].start()
      //.........................................................................................................
      return duct;
    }
    if (duct.mode === 'async') {
      return this._pull_async(duct);
    }
    if (duct.transforms[0][this.marks.isa_pusher] != null) {
      return this._push(duct);
    }
    first_bucket = duct.buckets[0];
    ref = duct.transforms[0];
    //.........................................................................................................
    for (d of ref) {
      if (duct.has_ended) {
        break;
      }
      first_bucket.push(d);
      duct.exhaust_pipeline();
    }
    //.........................................................................................................
    first_bucket.push(this.signals.last);
    duct.exhaust_pipeline();
    drain = duct.transforms[duct.transforms.length - 1];
    if ((on_end = drain.on_end) != null) {
      if (drain.call_with_datoms) {
        drain.on_end(drain.sink);
      } else {
        drain.on_end();
      }
    }
    return duct;
  };

  //-----------------------------------------------------------------------------------------------------------
  this._pull_async = async function(duct) {
    var d, drain, first_bucket, on_end, ref;
    if (duct.type !== 'circuit') {
      return duct;
    }
    if (duct.transforms[0][this.marks.isa_pusher] != null) {
      return this._push(duct);
    }
    first_bucket = duct.buckets[0];
    ref = duct.transforms[0];
    //.........................................................................................................
    for await (d of ref) {
      if (duct.has_ended) {
        break;
      }
      first_bucket.push(d);
      await duct.exhaust_async_pipeline();
    }
    //.........................................................................................................
    first_bucket.push(this.signals.last);
    await duct.exhaust_async_pipeline();
    drain = duct.transforms[duct.transforms.length - 1];
    if ((on_end = drain.on_end) != null) {
      if (drain.call_with_datoms) {
        drain.on_end(drain.sink);
      } else {
        drain.on_end();
      }
    }
    return duct;
  };

  //-----------------------------------------------------------------------------------------------------------
  this._push = async function(duct) {
    /* copy buffered data (from before when `pull()` was called) to `source`: */
    /* Make `duct` available from the POV of the push source: */
    var drain, first_bucket, on_end, source;
    source = duct.transforms[0];
    source.duct = duct;
    first_bucket = duct.buckets[0];
    first_bucket.splice(first_bucket.length, 0, ...source.buffer);
    /* Process any data as may have accumulated at this point: */
    if (duct.mode === 'async') {
      await duct.exhaust_async_pipeline();
    } else {
      duct.exhaust_pipeline();
    }
    // debug '^333121^', 'duct', duct
    // debug '^333121^', 'duct.has_ended', duct.has_ended
    // debug '^45899^', 'source.has_ended', duct.has_ended or source.has_ended
    /* TAINT code duplication */
    if (duct.has_ended || source.has_ended) {
      drain = duct.transforms[duct.transforms.length - 1];
      if ((on_end = drain.on_end) != null) {
        if (drain.call_with_datoms) {
          drain.on_end(drain.sink);
        } else {
          drain.on_end();
        }
      }
    }
    return null;
  };

}).call(this);

//# sourceMappingURL=pull-remit.js.map