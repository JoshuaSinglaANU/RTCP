var test = require('tape')
var S = require('pull-stream')
var SS = require('../pipe')

test('demuxed pipe', function (t) {
    t.plan(4)
    var demuxed = {
        a: S.values([1,2]),
        b: S.values([3,4]),
    }
    var sink = {
        a: S.collect(function (err, res) {
            t.error(err)
            t.deepEqual(res, [1,2], 'should pipe by key')
        }),
        b: S.collect(function (err, res) {
            t.error(err)
            t.deepEqual(res, [3,4], 'should pipe by key')
        })
    }
    SS( demuxed, sink )
})

test('invalid demuxed streams', function (t) {
    t.plan(1)
    var demuxed = {
        a: S.values([1,2]),
        b: S.values([3,4]),
    }
    var sink = {
        b: S.collect(function (err, res) {
            t.fail('should not stream this')
        })
    }
    function pipe () {
        SS( demuxed, sink )
    }
    t.throws(pipe, 'should throw if the sink does\'t have all keys')
})

test("it's ok if through objects don't have all keys", function (t) {
    t.plan(4)
    var demuxed = {
        a: S.values([1,2]),
        b: S.values([3,4]),
    }
    var map = {
        a: S.map(function (n) { return n + 10 })
    }
    var sink = {
        a: S.collect(function (err, res) {
            t.error(err)
            t.deepEqual(res, [11,12], 'should map one key')
        }),
        b: S.collect(function (err, res) {
            t.error(err)
            t.deepEqual(res, [3,4], 'should not map this key')
        })
    }
    SS( demuxed, map, sink )
})

test('return a new source', function (t) {
    t.plan(4)
    var demuxed = {
        a: S.values([1,2]),
        b: S.values([3,4]),
    }
    var map = {
        a: S.map(function (n) { return n + 10 }),
        b: S.map(function (n) { return n + 1 })
    }
    var sink = {
        a: S.collect(function (err, res) {
            t.error(err)
            t.deepEqual(res, [11,12], 'should return new source')
        }),
        b: S.collect(function (err, res) {
            t.error(err)
            t.deepEqual(res, [4,5], 'should return new source')
        })
    }
    var newSource = SS( demuxed, map )
    SS( newSource, sink )
})

