
# Let's Freeze Tha{t|w}!

[LetsFreezeThat](https://github.com/loveencounterflow/letsfreezethat) is an unapologetically minimal library
to make working with immutable objects in JavaScript less of a chore.

```
npm install letsfreezethat
```

```coffee
{ lets, freeze, thaw, } = require 'letsfreezethat'

d = lets { foo: 'bar', nested: [ 2, 3, 5, 7, ], }                    # create object
e = lets d, ( d ) -> d.nested.push 11                                # modify copy in callback
console.log 'd                          ', d                         # { foo: 'bar', nested: [ 2, 3, 5, 7 ] }
console.log 'e                          ', e                         # { foo: 'bar', nested: [ 2, 3, 5, 7, 11 ] }
console.log 'd is e                     ', d is e                    # false
console.log 'Object.isFrozen d          ', Object.isFrozen d         # true
console.log 'Object.isFrozen d.nested   ', Object.isFrozen d.nested  # true
console.log 'Object.isFrozen e          ', Object.isFrozen e         # true
console.log 'Object.isFrozen e.nested   ', Object.isFrozen e.nested  # true
```

LetsFreezeThat copies the core functionality of [immer](https://github.com/immerjs/immer) (also see
[here](https://hackernoon.com/introducing-immer-immutability-the-easy-way-9d73d8f71cb3)); the basic
insight being that

* deeply immutable objects are a great idea for quite a few reasons;
* working with immutable objects—especially to obtain copies with deeply nested updates—can be a pain in
  JavaScript since the language does zilch to support you;
* JavaScript does have lexical scopes and lightweight function syntax;
* so let's use callbacks that demarcate the scope where modification of object graphs is acceptable.

Now `immer` does a lot more than that as it also allows you to track changes and so on. It also allows
you to improve performance by foregoing `object.freeze()` altogether (something that I may implement
in LetsFreezeThat at a later point in time).

What I wanted was a library so small that performance was probably optimal; turns out 50 LOC is generous
for a functional subset of `immer`.

## Let's `fix()` That!

As of version 2, there's also a `fix()` method that allows to hammer down a particular attribute of
a given target object:

```
{ fix, } = require 'letsfreezethat'
d = { foo: 'bar', }
fix d, 'sql', { query: "select * from main;", }
console.log ( k for k of d ) # [ 'foo', 'sql' ]
try d.sql       = 'other' catch error then console.log error.message # Cannot assign to read only property 'sql' of object '#<Object>'
try d.sql.query = 'other' catch error then console.log error.message # Cannot assign to read only property 'query' of object '#<Object>'
```

`fix()` takes three arguments: the `target` object, a `name`, and a `value`. After calling `fix target,
name, value`, `target[ name ]` will equal `value`, as if one had used assignment, as in `target[ name ] =
value`. However, the attribute will be tacked onto `target` using `Object.defineProperty` with a descriptor
`{ enumerable: true, writable: false, configurable: false, value: ( freeze value ), }`, so it cannot (in
strict mode) be altered itself (because it is frozen), nor can `target[ name ]` be re-assigned or modified
(because it is not writable and not configurable).

Thus, `fix()` covers a middle ground between all-out freezing and having everything mutable, all the time.
It is suitable for those situation where some parts of a given state object have to remain updatable when
other parts are not meant to be fiddled with.

Observe that the `nofreeze` version of `fix()` uses plain assignment and no attribute configuration, so
`nofreeze.fix target, name, value` is just a fancy way of writing `target[ name ] = value`. This detail may
change in the future.


## Usage

You can use the `lets()`, `freeze()` and `thaw()` methods by `require`ing them as in `{ lets, freeze, thaw,
} = require 'letsfreezethat'`, but *probably* you only want `lets()`. `lets()` is similar to `immer`'s
`produce()`, except simpler.

`lets()` takes a value to start with, call it `d`, and an optional callback function to modify `d`.

Where the callback is not given, `lets d` is equivalent to `freeze d` which returns a copy of `d` with all
properties recursively frozen.

Where the callback *is* given, that's where you can modify a temporary copy of the first argument `d`. I've
come to always name those copies the same—`d` most of the time—but that *can* be confusing at first.

You should think of

```coffee
d = lets { key: 'word', value: 'OMG', }
d = lets d, ( d ) -> d.size = 3
```

as though it was written more like this:

```coffee
frozen_data_v1 = lets { key: 'word', value: 'OMG', }
frozen_data_v2 = lets frozen_data_v1, ( draft ) -> draft.size = 3
```

The second style has the advantage of being more explicit about the identity of the various values involved;
also, it is sometimes important to be able to reference back to some property of `frozen_data_v1` after the
changes, so there's nothing wrong with writing it the more eloquent way.

Observe you can also use `freeze()` and `thaw()` to the same effect:

```coffee
{ lets
  freeze
  thaw }        = require 'letsfreezethat'

...

original_data   = { key: 'word', value: 'OMG', }
frozen_data_v1  = freeze original_data

...

draft           = thaw frozen_data_v1
draft.size      = 3
frozen_data_v2  = freeze draft

...

```

This is more explicit but also more repetitive.


## Performance And `nofreeze` Option

According to my highly scientific tests, LetsFreezeThat is roughly around 3 times as fast as `immer`. When
your software works to plan and you made sure you used `'use strict'` so JavaScript would have throw an
error if you had accidentally tried to modify a frozen value, you can get some extra miles for free by
replacing `{ lets, freeze, thaw, } = require 'letsfreezethat'` with `{ lets, freeze, thaw, } = ( require
'letsfreezethat' ).nofreeze`. These methods avoid to call `Object.freeze()` and run about twice as fast as
the freezing versions: `thaw()` just returns its only argument, making it a no-op; `freeze()` just performs
a deep copy; `lets()` will likewise make a deep copy, and the value that you can modify in the callback will
be the return value of the method.

```
# as of LetsFreezeThat v2.2.3, immer v3.3.0
# calls to `lets()`, `produce()` per second, changing one property at a time
00:00 BENCHMARKS  ▶  using_letsfreezethat_nofreeze                    565,727 Hz   100.0 % │████████████▌│
00:00 BENCHMARKS  ▶  using_letsfreezethat_standard                    185,332 Hz    32.8 % │████▏        │
00:00 BENCHMARKS  ▶  using_immer                                       50,839 Hz     9.0 % │█▏           │
00:00 BENCHMARKS  ▶  using_letsfreezethat_partial                      30,216 Hz     5.3 % │▋            │
```

## What it Does, and What it Doesn't

* LetsFreezeThat always gives back a copy of the value passed in, no matter whether you use `lets()`,
  `freeze()`, or `thaw()`; this means that even when you don't manipulate a value, the old reference will
  remain untouched:

  ```coffee
  d = lets d, ( d ) -> # do nothing
  ```

  This is different from `immer`'s `produce()`, which will give you back the original object in case no
  modification was made.

* LetsFreezeThat does *not* do structural sharing or copy-on-write (COW), nor will it do so in the future.
  Both structural sharing and COW are great techniques to drive down memory requirements, enhance cache
  locality and save on garbage collection cycles, but they do come with additional complexities.

  The intended use case for LetsFreezeThat are situations where you have many rather small, rather shallow
  objects, which offer little opportunity for the benefits of structural sharing and COW to kick in.

* LetsFreezeThat does *not* track changes; if you need a report on what properties were affected by some
  part of your program, use `immer` instead. While having a change manifest may be potentially useful when,
  say, persisting an object to a DB, those benefits will diminish with smaller object size, same as with
  structural sharing.


## Partial Freezing (Experimental)

> “[...] when there are disputes among persons, we can simply say: Let's compute!, without further ado, to
> see who is right”—Gottfried Wilhelm Leibniz, 1685

It is sometimes desirable to freeze as many properties of a given object as possible and still keep some
properties in a mutable state; this is often the case when a custom object contains other objects from
libraries one has no control over.

For example, I recently ran into that conundrum when writing a library that accepts an object representing a
database and some configuration in order to read from and write to the DB. That library will construct an
object `{ foo: 42, bar: [...], db, }` to represent both the configuration and the DB instance; naturally, I
would very much like to freeze the configurational part of that object, but I can't do that with that
3rd-party DB instance which might rely on being mutable.

This is where `(require 'letsfreezethat' ).partial` comes in. It offers the same methods as the standard
version of LetsFreezeThat, but they are implemented (with `Object.seal()`) in such a way that *dynamic
properties that use getters and/or setters will not be frozen*. Such properties can be defined by
JavaScript's `Object.defineProperty()` method; because that is a bit cumbersome, LetsFreezeThat/partial
implements a method

```coffee
lets_compute = ( original, name, get, set = null ) -> ...
```

to simplify the process.

As a trivial example, let's define a dynamic property `time` to always reflect
the current time in milliseconds; first the approach that won't work:

```coffee
d = { foo: 'bar', }
Object.defineProperty d, 'time', { get: ( -> Date.now() ), }
d.time # 1569337726
...
d.time # 1569337738
```

OK, great. But when you `d = freeze d`, then that `time` attribute gets frozen, too:

```coffee
{ freeze, } = require 'letsfreezethat'
d = freeze d
d.time # 1569337742
...
d.time # 1569337742
...
d.time # 1569337742
```

To make this work as intended, use LetsFreezeThat/partial:

```coffee
{ freeze, } = ( require 'letsfreezethat' ).partial
d = freeze d
d.time # 1569337742
...
d.time # 1569337744
...
d.time # 1569337900
```

Here is how one would typically use partial freezing and `lets_compute()`:

```coffee
{ lets, lets_compute, } = ( require 'letsfreezethat' ).partial
d = lets { foo: 'bar', }                        # d.foo can't be changed, can't add attributes to d
d = lets_compute d, 'time', ( -> Date.now() )   # as above, but time keeps changing:
d.time # 1569337742
...
d.time # 1569337744
```

---------------------------------------------------------------

**BELOW IS WIP NOT READY FOR CONSUMPTION**

---------------------------------------------------------------

## BreadBoard Mode (Experimental)

BreadBoard mode is an exploration into a form of 'mild immutability' that can (partially) preserve object
identity while allowing controlled modification of attributes.

### What is BreadBoard good for?

The problem with immutability as used by LetsFreezeThat/standard is, of course, that object identity cannot
be preserved across object manipulations. This is the desired effect which offers the guarantees we as
programmers want to have—most of the time: Whenever I call `foo = lets { ... }; foo fancy, 42` I can be sure
that `fancy` still has the same value—indeed, be the same unmodified object—before and after the call to
`foo()`.

But there's a catch: What if I want to have a method, call it `is_frobbed ( d ) -> ...`, that returns, say,
a Boolean to see whether `d` has some derived quality `frobbed` that is computationally expensive? Because
it is expensive, we would very much like to cache its result, and the most straightforward way to do so is
by storing results on the object (`d`) itself. Of course, modification means duplication in
LetsFreezeThat/standard, so we must return a copy of `d` XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

1)  do not use API `if ( boolean = is_QUALITY d ) then ...`, use `d = update_QUALITY d; if d.QUALITY then
    ...` instead; this is slightly more verbose but does the job.

2)  alternatively, use a cache `c = {}` to store transient results as `c[ id ]`. This way, we can have `if (
    boolean = is_QUALITY d ) then ...` and still retrieve the cached value as `c[ d.id ].QUALITY`.


### Some Points

* Root must be an object; this is called 'the breadboard'

* identity *of the breadboard* is kept (so no copying when doing `lets bb, ( d ) ->`), but identity *of
  its properties* may change

* root will be locked to extensions with `Object.preventExtensions()`—this is final in the sense that it
  cannot be undone without copying the object

* computed properties are treated as in LetsFreezeThat/partial

* ??????????????? the descriptors of all other properties will be set to unwritable and unconfigurable





