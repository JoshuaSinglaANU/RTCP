'use strict'
assert                    = ( require 'assert' ).strict
log                       = console.log
jr                        = JSON.stringify
{ type_of, }              = require './helpers'


#-----------------------------------------------------------------------------------------------------------
@[ "freeze, modify object copy" ] = ->
  { lets, freeze, thaw, fix, } = require '..'
  d = lets { foo: 'bar', nested: [ 2, 3, 5, 7, ], u: { v: { w: 'x', }, }, }
  e = lets d, ( d ) -> d.nested.push 11
  assert.deepEqual d, ( { foo: 'bar', nested: [ 2, 3, 5, 7 ], u: { v: { w: 'x', }, }, }     ), '^lft@1^'
  assert.deepEqual e, ( { foo: 'bar', nested: [ 2, 3, 5, 7, 11 ], u: { v: { w: 'x', }, }, } ), '^lft@2^'
  assert.ok ( d isnt e                                                        ), '^lft@3^'
  assert.ok ( Object.isFrozen d                                               ), '^lft@4^'
  assert.ok ( Object.isFrozen d.nested                                        ), '^lft@5^'
  assert.ok ( Object.isFrozen d.u                                             ), '^lft@6^'
  assert.ok ( Object.isFrozen d.u.v                                           ), '^lft@7^'
  assert.ok ( Object.isFrozen d.u.v.w                                         ), '^lft@8^'
  assert.ok ( Object.isFrozen e                                               ), '^lft@9^'
  assert.ok ( Object.isFrozen e.nested                                        ), '^lft@10^'
  assert.ok ( Object.isFrozen e.u                                             ), '^lft@11^'
  assert.ok ( Object.isFrozen e.u.v                                           ), '^lft@12^'
  assert.ok ( Object.isFrozen e.u.v.w                                         ), '^lft@13^'
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "null, primitive values are kept as-is" ] = ->
  { lets, freeze, thaw, fix, } = require '..'
  ### from SQLite File Mirror: ###
  defaults = lets
    mirrors:
      read_method: 'batches_of_sql_literals_async'
    source:
      one:          1
      a:            'A'
      nothing:      null
  assert.deepEqual defaults.source.one,     1,    '^lft@14^'
  assert.deepEqual defaults.source.a,       'A',  '^lft@15^'
  assert.deepEqual defaults.source.nothing, null, '^lft@16^'
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "use nofreeze option for speedup" ] = ->
  { lets, freeze, thaw, fix, } = ( require '..' ).nofreeze
  d = lets { foo: 'bar', nested: [ 2, 3, 5, 7, ], }
  e = lets d, ( d ) -> d.nested.push 11
  assert.deepEqual d, ( { foo: 'bar', nested: [ 2, 3, 5, 7 ] }                ), '^lft@17^'
  assert.deepEqual e, ( { foo: 'bar', nested: [ 2, 3, 5, 7, 11 ] }            ), '^lft@18^'
  assert.ok ( d isnt e                                                        ), '^lft@19^'
  assert.ok ( not Object.isFrozen d                                           ), '^lft@20^'
  assert.ok ( not Object.isFrozen d.nested                                    ), '^lft@21^'
  assert.ok ( not Object.isFrozen e                                           ), '^lft@22^'
  assert.ok ( not Object.isFrozen e.nested                                    ), '^lft@23^'
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "circular references cause custom error" ] = ->
  { lets, freeze, thaw, fix, } = require '..'
  d = { a: 42, }
  assert.throws ( -> d = lets d, ( d ) -> d.d = d ), { message: /unable to freeze circular/ }, '^lft@24^'
  d = [ 4, 8, 16, ]
  # d = lets d, ( d ) -> d.push d
  assert.throws ( -> d = lets d, ( d ) -> d.push d ), { message: /unable to freeze circular/ }, '^lft@25^'
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "fix select attributes" ] = ->
  { lets, freeze, thaw, fix, } = require '..'
  d   = { foo: 'bar', }
  e   = fix d, 'sql', { query: "select * from main;", }
  assert.ok ( d is e ),                                                       '^lft@26^'
  assert.ok ( not Object.isFrozen d ),                                        '^lft@27^'
  assert.deepEqual ( Object.keys d  ), [ 'foo', 'sql', ],                     '^lft@28^'
  assert.deepEqual d, { foo: 'bar', sql: { query: 'select * from main;' } },  '^lft@29^'
  assert.throws ( -> d.sql       = 'other' ), { message: /Cannot assign to read only property/,   }, '^lft@30^'
  assert.throws ( -> d.sql.query = 'other' ), { message: /Cannot assign to read only property/, }, '^lft@31^'
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "use partial freezing (1/3)" ] = ->
  ### Pretest: Ensure invariant behavior for non-special attributes (copy of first test, above): ###
  { lets, freeze, thaw, fix, } = ( require '..' ).partial
  is_readonly = ( d, key ) ->
    descriptor = Object.getOwnPropertyDescriptor d, key
    return ( not descriptor.writable ) and ( not descriptor.configurable )
  #.........................................................................................................
  matcher_a = { foo: 'bar',   nested: [ 2, 3, 5, 7,          ], u: { v: { w: 'x',     }, }, }
  matcher_b = { foo: 'bar',   nested: [ 2, 3, 5, 7, 11,      ], u: { v: { w: 'x',     }, }, }
  matcher_c = { foo: 'other', nested: [ 2, 3, 5, 7, 'other', ], u: { v: { w: 'other', }, }, blah: 'other', }
  d         = lets matcher_a
  e         = lets d, ( d ) -> d.nested.push 11
  assert.ok ( d isnt e                      ), '^lft@32^'
  assert.ok ( d isnt matcher_a              ), '^lft@33^'
  assert.deepEqual d, matcher_a,               '^lft@34^'
  assert.deepEqual e, matcher_b,               '^lft@35^'
  assert.ok ( is_readonly d,      'nested'  ), '^lft@36^'
  assert.ok ( is_readonly d,      'u'       ), '^lft@37^'
  assert.ok ( is_readonly d.u,    'v'       ), '^lft@38^'
  assert.ok ( is_readonly d.u.v,  'w'       ), '^lft@39^'
  assert.ok ( Object.isSealed d             ), '^lft@40^'
  assert.ok ( Object.isSealed d.nested      ), '^lft@41^'
  assert.ok ( Object.isSealed d.u           ), '^lft@42^'
  assert.ok ( Object.isSealed d.u.v         ), '^lft@43^'
  assert.ok ( Object.isSealed e             ), '^lft@44^'
  assert.ok ( Object.isSealed e.nested      ), '^lft@45^'
  assert.ok ( Object.isSealed e.u           ), '^lft@46^'
  assert.ok ( Object.isSealed e.u.v         ), '^lft@47^'
  assert.throws ( -> d.nested.push 'other' ), { message: /Cannot add property/,             }, '^lft@48^'
  assert.throws ( -> d.foo  = 'other' ), { message: /Cannot assign to read only property/,  }, '^lft@49^'
  assert.throws ( -> d.blah = 'other' ), { message: /Cannot add property/,                  }, '^lft@50^'
  #.........................................................................................................
  d2 = lets d, ( d_copy ) ->
    assert.ok ( d isnt d_copy ),  '^lft@51^'
    assert.ok ( not is_readonly d_copy,      'nested'  ), '^lft@52^'
    assert.ok ( not is_readonly d_copy,      'u'       ), '^lft@53^'
    assert.ok ( not is_readonly d_copy.u,    'v'       ), '^lft@54^'
    assert.ok ( not is_readonly d_copy.u.v,  'w'       ), '^lft@55^'
    assert.ok ( not Object.isSealed d_copy             ), '^lft@56^'
    assert.ok ( not Object.isSealed d_copy.nested      ), '^lft@57^'
    assert.ok ( not Object.isSealed d_copy.u           ), '^lft@58^'
    assert.ok ( not Object.isSealed d_copy.u.v         ), '^lft@59^'
    try d_copy.nested.push 'other' catch e then throw new Error '^lft@60^ ' + e.message
    try d_copy.foo  = 'other'      catch e then throw new Error '^lft@61^ ' + e.message
    try d_copy.blah = 'other'      catch e then throw new Error '^lft@62^ ' + e.message
    try d_copy.u.v.w = 'other'     catch e then throw new Error '^lft@63^ ' + e.message
  assert.ok ( d2 isnt d ), '^lft@64^'
  assert.deepEqual d,  matcher_a,               '^lft@65^'
  assert.deepEqual d2, matcher_c,               '^lft@66^'
  #.........................................................................................................
  d_thawed = thaw d
  assert.deepEqual d_thawed, d,                           '^lft@67^'
  assert.ok ( d isnt d_thawed ),                          '^lft@68^'
  assert.ok ( not is_readonly d_thawed,      'nested'  ), '^lft@69^'
  assert.ok ( not is_readonly d_thawed,      'u'       ), '^lft@70^'
  assert.ok ( not is_readonly d_thawed.u,    'v'       ), '^lft@71^'
  assert.ok ( not is_readonly d_thawed.u.v,  'w'       ), '^lft@72^'
  assert.ok ( not Object.isSealed d_thawed             ), '^lft@73^'
  assert.ok ( not Object.isSealed d_thawed.nested      ), '^lft@74^'
  assert.ok ( not Object.isSealed d_thawed.u           ), '^lft@75^'
  assert.ok ( not Object.isSealed d_thawed.u.v         ), '^lft@76^'
  try d_thawed.nested.push 'other' catch e then throw new Error '^lft@77^ ' + e.message
  try d_thawed.foo  = 'other'      catch e then throw new Error '^lft@78^ ' + e.message
  try d_thawed.blah = 'other'      catch e then throw new Error '^lft@79^ ' + e.message
  try d_thawed.u.v.w = 'other'     catch e then throw new Error '^lft@80^ ' + e.message
  assert.deepEqual d_thawed, matcher_c,               '^lft@81^'
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "use partial freezing (2/3)" ] = ->
  ### Pretest: test approximate 'manual' implementation of partial freezing, implemented using object
  sealing and selective `fix()`ing of attributes: ###
  { lets, freeze, thaw, fix, } = ( require '..' ).partial
  #.........................................................................................................
  counter = 0
  d       = { foo: 'bar', nested: [ 2, 3, 5, 7, ], u: { v: { w: 'x', }, }, }
  e       = d.nested.push 11
  open_vz = { a: 123, }
  Object.defineProperty d, 'foo',    { enumerable: true, writable: false, configurable: false, value: freeze d.foo }
  Object.defineProperty d, 'nested', { enumerable: true, writable: false, configurable: false, value: freeze d.nested }
  Object.defineProperty d, 'count',
    enumerable:     true
    configurable:   false
    get:            -> ++counter
    set:            ( value ) -> counter = value
  Object.defineProperty d, 'open_vz',
    enumerable:     true
    configurable:   false
    get:            -> open_vz
  # log Object.getOwnPropertyDescriptors d
  Object.seal d
  #.........................................................................................................
  assert.ok ( ( type_of ( Object.getOwnPropertyDescriptor d, 'count' ).set ) is 'function' ),   '^lft@82^'
  assert.ok ( Object.isSealed d ),                                                              '^lft@83^'
  assert.deepEqual ( Object.keys d ), [ 'foo', 'nested', 'u', 'count', 'open_vz', ],            '^lft@84^'
  assert.ok ( d.count is 1                  ), '^lft@85^'
  assert.ok ( d.count is 2                  ), '^lft@86^'
  assert.ok ( ( d.count = 42 ) is 42        ), '^lft@87^'
  assert.ok ( d.count is 43                 ), '^lft@88^'
  assert.throws ( -> d.blah = 'other' ), { message: /Cannot add property blah, object is not extensible/, }, '^lft@89^'
  assert.throws ( -> d.foo  = 'other' ), { message: /Cannot assign to read only property/,                }, '^lft@90^'
  try d.open_vz.new_property = 42 catch e then throw new Error '^lft@91^ ' + e.message
  assert.deepEqual d.open_vz.new_property, 42, '^lft@92^'
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "use partial freezing (3/3)" ] = ->
  { lets, freeze, thaw, fix, lets_compute, } = ( require '..' ).partial
  #.........................................................................................................
  counter = 0
  open_vz = { a: 123, }
  d       = lets { foo: 'bar', nested: [ 2, 3, 5, 7, ], u: { v: { w: 'x', }, }, }
  e       = lets d, ( d ) -> d.nested.push 11
  d       = lets_compute d, 'count', ( -> ++counter ), ( ( x ) -> counter = x )
  d       = lets_compute d, 'open_vz', ( -> open_vz )
  assert.ok ( ( type_of ( Object.getOwnPropertyDescriptor d, 'count' ).set ) is 'function' ),   '^lft@93^'
  assert.ok ( d.count is 1                  ), '^lft@94^'
  assert.ok ( d.count is 2                  ), '^lft@95^'
  assert.ok ( ( d.count = 42 ) is 42        ), '^lft@96^'
  assert.ok ( d.count is 43                 ), '^lft@97^'
  assert.ok ( d.open_vz is open_vz          ), '^lft@98^'
  try d.open_vz.new_property = 'new value' catch e then throw new Error '^lft@99^ ' + e.message
  assert.ok ( d.open_vz is open_vz          ), '^lft@100^'
  assert.deepEqual open_vz, { a: 123, new_property: 'new value', }, '^lft@101^'
  assert.throws ( -> d.blah = 'other' ), { message: /Cannot add property blah, object is not extensible/, }, '^lft@102^'
  assert.throws ( -> d.foo  = 'other' ), { message: /Cannot assign to read only property/,                }, '^lft@103^'
  lets d, ( d ) ->
    dsc = Object.getOwnPropertyDescriptor d, 'count'
    assert.deepEqual dsc.configurable, true, '^lft@104^'
  lets d, ( d ) ->
    dsc = Object.getOwnPropertyDescriptor d, 'open_vz'
    assert.deepEqual dsc.configurable, true, '^lft@105^'
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "may pass in null to lets_compute as getter, setter" ] = ->
  { lets, lets_compute, } = ( require '..' ).partial
  # log '^!!!!!!!!!!!!!!!!!!!!!!!!!!^'; return
  #.........................................................................................................
  counter = 0
  d       = lets { foo: 'bar', }
  d       = lets_compute d, 'count', ( -> ++counter )
  assert.ok ( d.count is 1                  ), '^lft@106^'
  assert.ok ( d.count is 2                  ), '^lft@107^'
  #.........................................................................................................
  counter = 0
  d       = lets { foo: 'bar', }
  d       = lets_compute d, 'count', ( -> ++counter ), null
  assert.ok ( d.count is 1                  ), '^lft@108^'
  assert.ok ( d.count is 2                  ), '^lft@109^'
  #.........................................................................................................
  counter = 0
  d       = lets { foo: 'bar', }
  d       = lets_compute d, 'count', null, ( -> ++counter )
  #.........................................................................................................
  counter = 0
  d       = lets { foo: 'bar', }
  assert.throws ( -> lets_compute d, 'count', null, null ), /must define getter or setter/, '^lft@110^'

#-----------------------------------------------------------------------------------------------------------
@[ "functions are kept as functions" ] = ->
  #.........................................................................................................
  do =>
    { lets, freeze, thaw, lets_compute, } = ( require '..' ).partial
    d = lets { e: { f: ( ( x ) -> x ** 2 ) } }
    assert.deepEqual ( type_of d.e.f ), 'function', '^lft@111^'
    assert.deepEqual ( d.e.f 42 ), 42 * 42
  #.........................................................................................................
  do =>
    { lets, freeze, thaw, lets_compute, } = ( require '..' ).nofreeze
    d = lets { e: { f: ( ( x ) -> x ** 2 ) } }
    assert.deepEqual ( type_of d.e.f ), 'function', '^lft@112^'
    assert.deepEqual ( d.e.f 42 ), 42 * 42
  #.........................................................................................................
  do =>
    { lets, freeze, thaw, lets_compute, } = ( require '..' )
    d = lets { e: { f: ( ( x ) -> x ** 2 ) } }
    assert.deepEqual ( type_of d.e.f ), 'function', '^lft@113^'
    assert.deepEqual ( d.e.f 42 ), 42 * 42
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "lets_compute keeps object identity" ] = ->
  { lets, freeze, thaw, lets_compute, } = ( require '..' ).partial
  #.........................................................................................................
  class Otherclass
    constructor: ->
      @this_is_otherclass = true
    g: -> ( 'Otherclass.' + k for k of @ )
  #.........................................................................................................
  class Someclass extends Otherclass
    constructor: ->
      super()
      @this_is_someclass = true
    f: -> ( 'Someclass.' + k for k of @ )
  #.........................................................................................................
  test_something_ok = ( x, n ) ->
    tests = [
      -> assert.ok ( ( ( require 'util' ).inspect x ).startsWith 'Someclass' ), '^lft@114^' + "(##{n})"
      -> assert.deepEqual ( Object.getOwnPropertyNames x ), [ 'this_is_otherclass', 'this_is_someclass' ], '^lft@115^' + "(##{n})"
      -> assert.ok     x.hasOwnProperty 'this_is_otherclass',  '^lft@116^' + "(##{n})"
      -> assert.ok     x.hasOwnProperty 'this_is_someclass',   '^lft@117^' + "(##{n})"
      -> assert.ok not x.hasOwnProperty 'f',                   '^lft@118^' + "(##{n})"
      -> assert.ok not x.hasOwnProperty 'g',                   '^lft@119^' + "(##{n})"
      -> assert.deepEqual x.g(), [ 'Otherclass.this_is_otherclass', 'Otherclass.this_is_someclass' ], '^lft@120^' + "(##{n})"
      -> assert.deepEqual x.f(), [ 'Someclass.this_is_otherclass', 'Someclass.this_is_someclass' ], '^lft@121^' + "(##{n})"
      ]
    error_count = 0
    for test, idx in tests
      # log test.toString()
      try
        test()
      catch error
        error_count++
        log '^lft@122^', "ERROR:", error.message
    if error_count > 0
      assert.ok false, "^lft@123^(##{n}) #{error_count} tests failed"
    return null
  #.........................................................................................................
  tests = [
    #.......................................................................................................
    ->
      something = new Someclass
      test_something_ok something, '1'
    #.......................................................................................................
    ->
      something = new Someclass
      d = lets {}
      d = lets_compute d, 'something', ( -> something )
      test_something_ok d.something, '2'
    #.......................................................................................................
    ->
      something = new Someclass
      d = lets {}
      d = lets_compute d, 'something', ( -> something )
      d = freeze d
      test_something_ok d.something, '3'
    #.......................................................................................................
    ->
      something = new Someclass
      d = lets {}
      d = lets_compute d, 'something', ( -> something )
      d = thaw d
      test_something_ok d.something, '4'
    #.......................................................................................................
    ->
      something = new Someclass
      d = lets {}
      d = lets_compute d, 'something', ( -> something )
      d = lets d, ( d ) -> d.other = 42
      test_something_ok d.something, '5'
    ]
  #.........................................................................................................
  do =>
    error_count = 0
    for test in tests
      try
        test()
      catch error
        error_count++
        log '^lft@124^', "ERROR:", error.message
    if error_count > 0
      assert.ok false, "^lft@125^ #{error_count} tests failed"
    return null
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "breadboard mode" ] = ->
  { lets, freeze, thaw, lets_compute, } = ( require '..' ).breadboard
  e = {}
  d = { e, }
  Object.preventExtensions d
  assert.throws ( -> d.x = 42 ), { message: /object is not extensible/ }, '^lft@126^'
  Object.defineProperty d, 'e', { writable: true, }
  #.........................................................................................................
  to  = { x: 42, }
  tp  = new Proxy to,
    get: ( target, key ) -> return if ( R = target[ key ] )? then R else 'NOTFOUND'
    defineProperty: ( target, key, descriptor ) ->
      log '^887^', "define property #{jr key}"
      Object.defineProperty target, key, descriptor
  #.........................................................................................................
  log '^4776^', to
  log '^4776^', tp
  assert.ok to isnt tp, '@'
  log '^4776^', tp.x
  log '^4776^', tp.y
  Object.defineProperty tp, 'y', { value: 'Y!', writable: false, configurable: false, }
  log '^4776^', to
  log '^4776^', tp
  log '^4776^', to.y
  log '^4776^', tp.y
  log '^4776^', tp.z
  return null




############################################################################################################
if require.main is module then do =>
  error_count = 0
  for name, test of @
    log name
    try
      await test.call @
    catch error
      log "ERROR:", error.message
      error_count++
  if error_count isnt 0
    log "there were errors"
    process.exit 1
  log "ok"


