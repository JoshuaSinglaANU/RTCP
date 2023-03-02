
const symbols = require( '../lib/_symbols' );

var looper = function (fun) {
  (function next () {
    var loop = true, returned = false, sync = false
    do {
      sync = true; loop = false
      fun.call(this, function () {
        if(sync) loop = true
        else     next()
      })
      sync = false
    } while(loop)
  })()
}

const pull_through = function (writer, ender) {
  return function (read) {
    var queue = [], ended, error

    function enqueue (data) {
      queue.push(data)
    }

    writer = writer || function (data) {
      this.queue(data)
    }

    ender = ender || function () {
      this.queue( symbols.end )
    }

    var emitter = {
      emit: function ( event, data ) {
        if ( event === 'data'   ) { enqueue(data); };
        if ( event === 'end'    ) { ended = true, enqueue( symbols.end ); };
        if ( event === 'error'  ) { error = data; };
      },
      queue: enqueue
    }
    var _cb
    return function (end, cb) {
      ended = ended || end
      if ( end ) {
        return read(end, function () {
          if(_cb) {
            var t = _cb; _cb = null; t(end)
          }
          cb(end)
        }) };

      _cb = cb
      const pull = function ( next ) {
        //if it's an error
        if ( !_cb ) { return; };
        cb = _cb;
        if ( error ) {
          _cb = null;
          cb( error ); }
        else if ( queue.length > 0 ) {
          var data  = queue.shift();
          _cb       = null;
          cb( data === symbols.end, data );
          }
        else {
          // ...............................................................................................
          read( ended, function ( end, data ) {
             // null has no special meaning for pull-stream
             // but now `Symbol.for( 'pipestreams:end' )` has
            if( end && end !== true ) {
              error = end;
              return next(); };
            // .............................................................................................
            if( ended = ended || data === symbols.end || end ) {
              ender.call( emitter ); }
            else if( data !== symbols.end ) {
              writer.call( emitter, data );
              if ( error || ended ) {
                return read( error || ended, function () {
                  _cb = null; cb( error || ended )
                }) };
              };
            next( pull );
          })
        }
      };

      looper( pull );
    }
  }
}

module.exports = pull_through;


