var test = require('tape')
var S = require('pull-stream')
var demux = require('../demux')
var Event = require('../event')

test('demux', function (t) {
    t.plan(4)
    var muxed = S.values([Event('a', 1), Event('b', 2)])
    var dx = demux(muxed, ['a', 'b'])

    S(dx.a, S.collect(function (err, res) {
        t.error(err)
        t.deepEqual(res, [1], 'should demux')
    }))
    S(dx.b, S.collect(function (err, res) {
        t.error(err)
        t.deepEqual(res, [2], 'should demux')
    }))
})

test('demux async', function (t) {
    t.plan(4)
    var muxed = S(
        S.values([Event('a', 1), Event('b', 2)]),
        S.asyncMap(function (ev, cb) {
            process.nextTick(function () {
                cb(null, ev)
            })
        })
    )
    var dx = demux(muxed, ['a', 'b'])

    S(dx.a, S.collect(function (err, res) {
        t.error(err)
        t.deepEqual(res, [1], 'should demux')
    }))
    S(dx.b, S.collect(function (err, res) {
        t.error(err)
        t.deepEqual(res, [2], 'should demux')
    }))
})

