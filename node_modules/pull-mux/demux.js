var S = require('pull-stream/pull')
var filter = require('pull-stream/throughs/filter')
var map = require('pull-stream/throughs/map')
var tee = require('pull-tee')
var pair = require('pull-pair')
var Event = require('./event')

// demux one level (not recursive)
function demux (source, keys) {
    var pairs = keys.map(function (k) {
        var p = pair()
        return { key: k, source: p.source, sink: p.sink }
    })

    var t = tee(pairs.map(function (p) {
        return S(
            filter(function (ev) {
                return Event.type(ev) === p.key
            }),
            map(function (ev) {
                return Event.data(ev)
            }),
            p.sink
        )
    }))

    var newSource = pairs.reduce(function (acc, p) {
        acc[p.key] = p.source
        return acc
    }, {})

    S(source, t, S.drain())
    return newSource
}

module.exports = demux
