var test = require('tape')
var createManifest = require('../manifest')

test('create manifest', function (t) {
    t.plan(1)
    var manifest = createManifest({
        eatMoreVegetables: function () {},
        foo: {
            get: function () {},
            update: function () {},
            fetch: function () {}
        },
        bar: {
            edit: function () {},
            goCrazy: function () {}
        },
        c: {
            d: {
                e: function () {}
            }
        }
    })

    t.deepEqual(manifest, [
        'eatMoreVegetables',
        ['foo', ['get', 'update', 'fetch']],
        ['bar', ['edit', 'goCrazy']],
        ['c', [['d', ['e']]]]
    ], 'should serialize the tree')
})

