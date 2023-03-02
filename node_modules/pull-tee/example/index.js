var pull = require('pull-stream')
var tee  = require('../')
var assert = require('assert')

var a, b

pull(
  pull.values([1, 2, 3, 4, 5]),
  tee(
    pull.collect(function (err, _a) {
      a = _a
      if (b && a) assert.deepEqual(a, b)
    })
  ),
  pull.collect(function (err, _b) {
    b = _b
    if (b && a) assert.deepEqual(a, b)
  })
)

console.log(a, b)

