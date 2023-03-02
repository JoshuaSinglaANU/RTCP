
//TEE stream.
//this could be improved to allow streams to read ahead.
//this slows all streams to he slowest...

module.exports = function (sinks) {
  return function (read) {

    if(!Array.isArray(sinks))
      sinks = [sinks]
    sinks = sinks.filter(Boolean)

    var cbs = []
    var l = sinks.length + 1
    var i = l

    function _read(abort, cb) {
      cbs.push(cb)
      if(cbs.length < l)
        return

      read(null, function (err, data) {
        var _cbs = cbs
        cbs = []
        _cbs.forEach(function (cb) {
          cb(err, data)
        })
      })
    }

    sinks.forEach(function (sink) {
      sink(_read)
    })

    return _read

  }
}

