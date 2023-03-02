(function() {
  'use strict';
  var CND, FS, badge, debug, defer, isa, jr, type_of, types, validate, warn;

  //###########################################################################################################
  CND = require('cnd');

  badge = 'STEAMPIPES/NJS-STREAMS-AND-FILES';

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  FS = require('fs');

  // TO_PULL_STREAM            = require 'stream-to-pull-stream'
  // TO_NODE_STREAM            = require '../deps/pull-stream-to-stream-patched'
  // TO_NODE_STREAM            = require 'pull-stream-to-stream'
  defer = setImmediate;

  ({jr} = CND);

  types = require('./types');

  ({isa, validate, type_of} = types);

  //===========================================================================================================
  // READ FROM, WRITE TO FILES, NODEJS STREAMS
  //-----------------------------------------------------------------------------------------------------------
  this.read_from_file = function(path, byte_count = 65536) {
    var pfy, source;
    /* TAINT use settings object */
    validate.positive_integer(byte_count);
    pfy = (require('util')).promisify;
    source = this.new_push_source();
    //.........................................................................................................
    defer(async() => {
      var buffer, bytes_read, fd, read;
      fd = (await (pfy(FS.open))(path, 'r'));
      read = pfy(FS.read);
      while (true) {
        buffer = Buffer.alloc(byte_count);
        bytes_read = ((await read(fd, buffer, 0, byte_count, null))).bytesRead;
        if (bytes_read === 0) {
          break;
        }
        source.send(bytes_read < byte_count ? buffer.slice(0, bytes_read) : buffer);
      }
      source.end();
      return null;
    });
    //.........................................................................................................
    return source;
  };

  //-----------------------------------------------------------------------------------------------------------
  this._KLUDGE_file_as_buffers = function(path, byte_count = 65536) {
    return new Promise((resolve) => {
      var pipeline;
      pipeline = [];
      pipeline.push(this.read_from_file(path, byte_count));
      pipeline.push(this.$pass());
      pipeline.push(this.$drain((buffers) => {
        return resolve(buffers);
      }));
      this.pull(...pipeline);
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$split = function(splitter = '\n', decode = true) {
    var buffered, find_first_match, is_buffer, last, matcher;
    /* thx to https://github.com/maxogden/binary-split/blob/master/index.js */
    validate.nonempty_text(splitter);
    validate.boolean(decode);
    is_buffer = Buffer.isBuffer;
    matcher = Buffer.from(splitter);
    buffered = null;
    last = Symbol('last');
    //.........................................................................................................
    find_first_match = function(buffer, offset) {
      var fullMatch, i, j, k, l, ref, ref1;
      if (offset >= buffer.length) {
        return -1;
      }
      for (i = l = ref = offset, ref1 = buffer.length; l < ref1; i = l += +1) {
        if (buffer[i] === matcher[0]) {
          if (matcher.length > 1) {
            fullMatch = true;
            j = i;
            k = 0;
            while (j < i + matcher.length) {
              if (buffer[j] !== matcher[k]) {
                fullMatch = false;
                break;
              }
              j++;
              k++;
            }
            if (fullMatch) {
              return j - matcher.length;
            }
          } else {
            break;
          }
        }
      }
      return i + matcher.length - 1;
    };
    //.........................................................................................................
    return this.$({last}, function(d, send) {
      var e, idx, lastMatch, offset;
      if (d === last) {
        if (buffered != null) {
          send(decode ? buffered.toString('utf-8') : buffered);
        }
        return;
      }
      if (!is_buffer(d)) {
        throw new Error(`µ23211 expected a buffer, got a ${type_of(d)}`);
      }
      offset = 0;
      lastMatch = 0;
      if (buffered != null) {
        d = Buffer.concat([buffered, d]);
        offset = buffered.length;
        buffered = null;
      }
      while (true) {
        idx = find_first_match(d, offset - matcher.length + 1);
        if (idx >= 0 && idx < d.length) {
          e = d.slice(lastMatch, idx);
          send(decode ? e.toString('utf-8') : e);
          offset = idx + matcher.length;
          lastMatch = offset;
        } else {
          buffered = d.slice(lastMatch);
          break;
        }
      }
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.tee_write_to_file = function(path, options) {
    /* TAINT consider to abandon all sinks except `$drain()` and use throughs with writers instead */
    /* TAINT consider using https://pull-stream.github.io/#pull-write-file instead */
    /* TAINT code duplication */
    var arity, stream;
    switch ((arity = arguments.length)) {
      case 1:
        stream = FS.createWriteStream(path);
        break;
      case 2:
        stream = FS.createWriteStream(path, options);
        break;
      default:
        throw new Error(`µ9983 expected 1 to 3 arguments, got ${arity}`);
    }
    return this.tee_write_to_nodejs_stream(stream);
  };

  //-----------------------------------------------------------------------------------------------------------
  this.tee_write_to_file_sync = function(path, options) {
    return this.$watch(function(d) {
      return FS.appendFileSync(path, d);
    });
  };

  // #-----------------------------------------------------------------------------------------------------------
  // @read_from_nodejs_stream = ( stream ) ->
  //   switch ( arity = arguments.length )
  //     when 1 then null
  //     else throw new Error "µ9983 expected 1 argument, got #{arity}"
  //   #.........................................................................................................
  //   return TO_PULL_STREAM.source stream, ( error ) -> finish error

  //-----------------------------------------------------------------------------------------------------------
  this.tee_write_to_nodejs_stream = function(stream) {
    var arity, last;
    /* TAINT code duplication */
    // throw new Error "µ76644 method `tee_write_to_nodejs_stream()` not yet implemented"
    switch ((arity = arguments.length)) {
      case 1:
        null;
        break;
      default:
        throw new Error(`µ9983 expected 1 argument, got ${arity}`);
    }
    last = Symbol('last');
    //.........................................................................................................
    stream.on('close', function() {
      return debug('µ55544', 'close');
    });
    stream.on('error', function() {
      throw error;
    });
    //.........................................................................................................
    return this.$({last}, (d, send) => {
      if (d === last) {
        warn("µ87876 closing stream");
      }
      if (d === last) {
        return stream.close();
      }
      warn("µ87876 writing", jr(d));
      stream.write(d);
      return send(d);
    });
  };

  // #-----------------------------------------------------------------------------------------------------------
// @tee_write_to_nodejs_stream = ( stream, on_end ) ->
//   ### TAINT code duplication ###
//   switch ( arity = arguments.length )
//     when 1, 2 then null
//     else throw new Error "µ9983 expected 1 or 2 arguments, got #{arity}"
//   validate.function on_end if on_end?
//   has_finished  = false
//   last          = Symbol 'last'
//   #.........................................................................................................
//   finish = ( error ) ->
//     if error?
//       has_finished = true
//       throw error if error?
//     if not has_finished
//       has_finished = true
//       on_end() if on_end?
//     return null
//   #.........................................................................................................
//   stream.on 'close', -> finish()
//   stream.on 'error', -> finish error
//   # description = { [@marks.isa_sink], type: 'tee_write_to_nodejs_stream', stream, on_end, }
//   #.........................................................................................................
//   pipeline = []
//   pipeline.push @$watch { last, }, ( d ) ->
//     return stream.close() if d is last
//     stream.write d
//   pipeline.push @$drain finish
//   #.........................................................................................................
//   return @pull pipeline...

  // #-----------------------------------------------------------------------------------------------------------
// @node_stream_from_source = ( source ) -> TO_NODE_STREAM.source source

  // #-----------------------------------------------------------------------------------------------------------
// @node_stream_from_sink = ( sink ) ->
//   ### TAINT consider to abandon all sinks except `$drain()` and use throughs with writers instead ###
//   R           = TO_NODE_STREAM.sink sink
//   description = { type: 'node_stream_from_sink', sink, }
//   return @mark_as_sink R, description

}).call(this);

//# sourceMappingURL=njs-streams-and-files.js.map