var test = require('tape')
var S = require('pull-stream')
var mux = require('../')

test('create a namespaced stream from an object', function (t) {
    t.plan(2)
    var streams = {
        a: S.values([1,2,3]),
        b: S.values([4,5,6])
    }
    var stream = mux(streams)

    S(
        stream,
        S.collect(function (err, res) {
            t.error(err)
            t.deepEqual(res, [
                ['a', 1],
                ['b', 4],
                ['a', 2],
                ['b', 5],
                ['a', 3],
                ['b', 6]
            ], 'should namespace the events')
        })
    )
})


test('pass in a mux function', function (t) {
    t.plan(2)
    var streams = {
        a: S.values([1,2]),
        b: S.values([3,4])
    }
    var stream = mux(streams, function muxer (type, ev) {
        return { type: type, data: ev }
    })

    S(
        stream,
        S.collect(function (err, res) {
            t.error(err)
            t.deepEqual(res, [
                { type: 'a', data: 1 },
                { type: 'b', data: 3 },
                { type: 'a', data: 2 },
                { type: 'b', data: 4 },
            ], 'should use the given map function')
        })
    )
})

// test('nested object', function (t) {
//     t.plan(2)
//     var dx = {
//         a: S.values([1]),
//         b: {
//             c: S.values([2])
//         }
//     }
//     var muxed = mux(dx)
//     S(
//         muxed,
//         S.collect(function (err, res) {
//             t.error(err)
//             t.deepEqual(res, [
//                 ['a', 1],
//                 ['b', ['c', 2]]
//             ], 'should mux nested object')
//         })
//     )
// })

// test('mux streams that have children', function (t) {
//     t.plan(2)
//     var b = S.values([2])
//     b.c = S.values([3])
//     var dx = {
//         a: S.values([1]),
//         b: b
//     }
//     var muxed = mux(dx)
//     S(
//         muxed,
//         S.collect(function (err, res) {
//             t.error(err)
//             t.deepEqual(res, [
//                 ['a', 1],
//                 ['b', 2],
//                 ['b', ['c', 3]]
//             ], 'should mux functions with keys')
//         })
//     )
// })


