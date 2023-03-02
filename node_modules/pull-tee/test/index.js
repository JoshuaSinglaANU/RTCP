
var test = require('tape')
var pull = require('pull-stream')
var tee  = require('../')

test('tee', function (t) {
  var a, b

  pull(
    pull.values([1, 2, 3, 4, 5]),
    tee(
      pull.collect(function (err, _a) {
        a = _a
        if(b && a) next()
      })
    ),
    pull.collect(function (err, _b) {
      b = _b
      if(b && a) next()
    })

  )

  function next () {
    t.deepEqual(a, b)
    t.end()
  }
})

function randAsync () {
  return pull.asyncMap(function (data, cb) {
    setTimeout(function () {
      cb(null, data)
    }, Math.random()*20)
  })
}

test('tee-async', function (t) {
  var a, b

  pull(
    pull.values([1, 2, 3, 4, 5]),
    tee(pull(
        randAsync(),
        pull.collect(function (err, _a) {
          a = _a
          if(b && a) next()
        })
      )
    ),
    randAsync(),
    pull.collect(function (err, _b) {
      b = _b
      if(b && a) next()
    })
  )

  function next () {
    t.deepEqual(a, b)
    t.end()
  }
})



