var S = require('pull-stream/pull')
var map = require('pull-stream/throughs/map')
var many = require('pull-many')
var Event = require('./event')

// take a hash of streams and return a namespaced stream
function muxObj (streams, muxer) {
    var _muxer = muxer || Event
    var names = Object.keys(streams)
    var namespaced = names.map(function (n) {
        var stream = streams[n]
        return S(
            stream,
            map(function (ev) {
                return _muxer(n, ev)
            })
        )
    })
    return many(namespaced)
}

module.exports = muxObj

