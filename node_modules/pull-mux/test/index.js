var test = require('tape')
var S = require('pull-stream')
var mux = require('../index')
var demux = require('../demux')
var manifest = require('../manifest')

test('all together', function (t) {
    t.plan(4)
    var demuxed = {
        a: S.values([1,2]),
        b: S.values([3,4])
    }
    var muxed = mux(demuxed)
    var dx = demux(muxed, manifest(demuxed))

    S(dx.a, S.collect(function (err, res) {
        t.error(err)
        t.deepEqual(res, [1,2], 'should mux and demux')
    }))
    S(dx.b, S.collect(function (err, res) {
        t.error(err)
        t.deepEqual(res, [3,4], 'should mux and demux')
    }))
})
