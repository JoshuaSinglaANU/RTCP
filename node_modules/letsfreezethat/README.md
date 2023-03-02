

![let's keep calm and freeze that](./artwork/letskeepcalmandfreezethat.png)

# Let's Freeze That!

[LetsFreezeThat](https://github.com/loveencounterflow/letsfreezethat) is an unapologetically minimal library
to make working with immutable objects in JavaScript less of a chore.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Installation](#installation)
- [Usage](#usage)
  - [Using `lets()`](#using-lets)
  - [Using `thaw()` and `freeze()`](#using-thaw-and-freeze)
  - [`get()` and `set()`](#get-and-set)
  - [API, and Moving to Production](#api-and-moving-to-production)
- [Notes](#notes)
- [Implementation](#implementation)
- [Benchmarks](#benchmarks)
- [Other Libraries](#other-libraries)
- [To Do](#to-do)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Installation

```sh
npm install letsfreezethat
```

## Usage

`require`ing the module imports a method `lets()`:

```coffee
lets = require 'letsfreezethat'
```

This method is best explained by having a look at its definition which is in essence approximately three
lines long: it takes an `original` value (a JS object or array) and an optional `modifier` callback
function. It then `thaw()`s that value, which entails making a deep copy of it. Next, it calls the
`modifier()` (if given), ignoring the return value of that call. Step 3 consists of freezing the draft
version (in-place, i.e. without copying it) and returning it:

```coffee
lets = ( original, modifier = null ) ->
  draft = freeze_lets.thaw original
  modifier draft if modifier?
  return deep_freeze draft
```

### Using `lets()`

The way this is intended to simplify your life is as follows: you have a function that accepts and returns
an object (or array). Within that function, you want to perform some computation and update the object the
functional way (no side effects, no mutations). In order to be on the safe side, you want to work with
deep-frozen objects (at least in development, but we'll come to that) to prevent any slipups. LetsFreezeThat
gives you two styles to accomplish that goal, the 'safer' variant being `lets()`, like in the below:

```coffee
lets = require 'letsfreezethat'

set_balance = ( account, amount ) ->
  account = lets account, ( d ) ->
    d.balance += amount
    return null # <- just for clarity but recommended to avoid accidental return value
  return account
```

At the point in time `account` is set to the return value of the `lets()` call, it becomes bound to a
faithful copy of the value passed in to `set_balance()`. Whatever you name the second argument to `lets()`
(I chose `d` here for `draft`, `data` or `datom`, whichever you prefer)—that name (binding) cannot leak out
of the modifier function, so you're pretty much on the safe side here. And that's it. No new API to learn
and nothing (well, less) to worry about. Keep calm and `lets()` freeze that!

### Using `thaw()` and `freeze()`

Using `lets()` is fine but the act of calling a function only to get called back adds a bit of computational
overhead. You can shave off a few percent (maybe 10% or so) by using `thaw()` and `freeze()` expöicitly,
like so (using `d` as name for the business data object):

```coffee
{ thaw, freeze, } = require 'letsfreezethat'

set_balance = ( d, amount ) ->
  d = thaw d
  d.balance += amount
  return freeze d
```

And that's it, a little bit simpler than the code for `lets()` if you will but also a little bit more open
to accidental slips. YMMV.

### `get()` and `set()`

`get()` and `set()` are available FTTB but not necessarily recommended. `set()` takes a data object, a key,
and a value; it will produce a draft copy of the data object, set the key to the value given, freeze the
data object and return it. If you have a single attribute to set, that's one way to do it:

```coffee
{ thaw, freeze, get, set, } = require 'letsfreezethat'
d = freeze d
d = set d, 'key', value
w = get d, 'key'
```

### API, and Moving to Production

LetsFreezeThat comes in two configurable flavors, one that does indeed freeze and thaw (and, thereby,
implicitly copies) objects, and one that skips the freezing and thawing (but not the copying).
`require()`ing either flavor returns a method `lets()` as discussed above:

* `lets = require 'letsfreezethat'` which indeed deep-freezes objects and arrays, and
* `lets = ( require 'letsfreezethat' ).nofreeze` which forgoes freezing (but not copying).

The `nofreeze` flavor is around 3 to 4 times faster on `freeze()`.

The `lets()` method has a number of attributes which are callable by themselves (no JS tear-off /
`this`-juggling here):

* **`lets   = ( d, modifier = null ) ->`**—copy of the same method.
* **`assign = ( d, P... ) ->`**—bulk-assign, semantics like `Object.assign()`, returns copy of `d`.
* **`freeze = ( d ) ->`**—deep-freeze in-place; a no-op with `nofreeze`.
* **`thaw   = ( d ) ->`**—return a deep copy of `d` (thereby un-freezing it).
* **`get    = ( d, key ) ->`**—return value of an attribute of `d`. Equivalent to `d[ key ]` and just there
  to complement `set()`.
* **`set    = ( d, key, value ) ->`**—make a deep copy of `d`, set attribute `key` to `value`, and return
  the (frozen or unfrozen depending on flavor) copy. Prefer to use `assign()`, `thaw()`/`freeze()`, or
  `lets()` whenever you want to modify more than a single attribute as `set()` will deep-copy and
  deep-freeze# on each call.

## Notes

* LetsFreezeThat does not copy objects on explicit or implicit `freeze()`. That should be fine for most use
  cases since what one usually wants to do is either create or thaw a given value (which implies making a
  copy), manipulate (i.e. mutate) it, and then freeze it prior to passing it on. As long as manipulations
  are local to a single function, chances of screwing up are limited, so we can safely forgo the added
  overhead of making an additional copy when either `freeze()` is called or a call to `lets d, ( d ) -> ...`
  has finished. Observe that when being given a value `d` it is not necessarily safe to `freeze()` it since
  another party may still hold a reference to `d` and assume mutability. When in doubt, use `freeze thaw d`
  to freeze a deep copy of `d`.

* Observe that the `thaw()` method will always make a copy even with the `nofreeze` flavor;
  otherwise it is hardly conceivable how an application could switch from the slower `{ freeze: true, }`
  configuration to the faster `{ freeze: false, }` without breaking.

* In the case a list or an object originates from the outside and other places might still hold references
  to that value or one of its properties, one can use `thaw()` to make sure any mutations will not be
  visible from the outside. In this regard, `thaw()` could have been called `deep_copy()`.


## Implementation

The performance gains seen when going from LetsFreezeThat v2 to v3 are almost entirely due to the code used
by the [`klona`](https://github.com/lukeed/klona) library, specifically its
[JSON](https://github.com/lukeed/klona/blob/master/src/json.js) module. The code is simple, straightforward,
and fast—mostly because it's a well-written piece that does something very specific, name only concerning
itself with (JSON, JS) objects and arrays.

LetsFreezeThat has a similar focus and forgoes freezing `RegExp`s, `Date`s, `Int32Array`s or anything but
plain `Object`s and `Array`s, so that's a perfect fit. I totally just copied the code of the linked module
to avoid the dependency on whatever else it is that `klona` has in store (it's a lot got check it out).

## Benchmarks

**where to find the code**—The code that produced the below benchmarks is available in
[𐌷𐌴𐌽𐌲𐌹𐍃𐍄](https://github.com/loveencounterflow/hengist/tree/master/dev/letsfreezethat/src) (which is my
workbench of sorts to develop, test and benchmark my software). In each case, thousands of small-ish JS
objects were frozen, manipulated, and thawed, as the case may be, using a number of approaches and a number
of software packages.

**how to read the tags**—`letsfreezethat_v{2|3}_f{0|1}` is to be read as: '`letsfreezethat` using { legacy
v2.2.5 | code for upcoming v3 in the present state } with freezing turned { off | on }'.

**how to understand the numbers**—Absolute numbers are cycles per second (Hz) where mulling through the
tasks for a single object is counted as one cycle, and the number and nature of tasks is identical for all
libraries tested, as far as possible. To obtain a baseline for comparison, JavaScript's `Object.freeze()`
have been used for freezing and `Object.assign()` for thawing, but keep in mind that both methods are
shallow in the sense that neither method would affect the nested list in a value like `{ x: [ 1, 2, 3, ],
}`. LetsFreezeThat does do deep freezing and deep thawing, though (and some of the other libraries do so
too; others don't), so the comparison is slightly in favor of JavaScript native methods (because they get as
much credit for each cycle although less gets done).

**why native JS looks slow in comparison**—One would fully expect JS native methods to be always on top of
the scores but this is not the case. For one thing `letsfreezethat.nofreeze.freeze()` does not actually do
anything, its literally just the `id()` function: `nofreeze_lets.freeze = ( me ) -> me`, bam. Deep freezing
without the part where you deep-freeze is indeed faster than shallow freezing, of course. Also, although
care has been taken to run garbage collection explicitly and to perform any computation that is external to
each test such that it does not affect the timings, there's always an observable and, sadly, unavoidable
jitter in performance which can add up to as much as 10 or even 20 per cent of the figures shown. Each test
case has been run with hundreds or thousands of values and a few (3 to 5) repeated runs, some of them in
shuffled order, to minimize such effects. I hope to provide error bars in future editions but for now please
understand that `100,00Hz` means something close to `between 80,000Hz and 120,000Hz` and `50%` is really
`maybe something around 40% to 60%` of the best performing solution.

**only temporal, no spatial benchmarks**—So far I have not looked at RAM consumption figures for the various
test cases. This is in part because the intended use case for LetsFreezeThat is in passing around lots of
small-ish objects that are not very deeply nested ([`datom`s to be more
precise](https://github.com/loveencounterflow/datom)). I do not expect any copy-on-write (COW)
implementation to be very space- and time-efficient in JavaScript *for this particular use cae* except for
the hypothetical case where we have something like [Hash Array Mapped Tries
(HAMTs)](https://en.wikipedia.org/wiki/Hash_array_mapped_trie) built right into the language like Clojure
has. The story might well be different in the case where you have deeply nested, larg-ish objects where once
in while you want to modify-but-not-mutate this or that attribute in a tree. I did not test for that in the
current iteration. Since the memory consumption of each individual piece of data is so small, just making a
copy as fast as you can without asking questions turns out to be quite efficient time-wise, and I just
assume that it will be somehow-acceptable space-wise, too, because garbage collection. It would still be
nice to have some memory consumption for the various libraries, so maybe sometime.

**what to learn from the benchmarks**—The overall trend is clear. Barring any dumb blunders in my
benchmarking code what clearly stands out is that structural sharing (as provided by `immutable.js`,
`immer`, `HAMT`, and `mori`) does not pay out *in terms of time costs* and *provided you have many
small-ish, flat-tish objects*. It's just not worth the trouble. These are well thought-out, tested and honed
libraries that go a long way to prevent unwarranted duplication of data, yet their demands in terms of CPU
cycles is non-trivial when compared to stupid copying.

```
# hengist/dev/letsfreezethat/src/lft-deepfreeze.benchmarks.coffee

  thaw_____shallow_native                          829,171 Hz   100.0 % │████████████▌│
  thaw_____klona                                   347,483 Hz    41.9 % │█████▎       │
█ thaw_____letsfreezethat_v3_f0                    330,089 Hz    39.8 % │█████        │
█ thaw_____letsfreezethat_v3_f1                    242,111 Hz    29.2 % │███▋         │
  thaw_____fast_copy                               176,418 Hz    21.3 % │██▋          │
  thaw_____letsfreezethat_v2                        93,441 Hz    11.3 % │█▍           │
  thaw_____deepfreezer                              50,249 Hz     6.1 % │▊            │
  thaw_____deepcopy                                 31,608 Hz     3.8 % │▌            │
  thaw_____fast_copy_strict                         17,539 Hz     2.1 % │▎            │
———————————————————————————————————————————————————————————————————————————————————————————
█ freeze___letsfreezethat_v3_f0                    745,781 Hz    89.9 % │███████████▎ │
  freeze___shallow_native                          665,340 Hz    80.2 % │██████████   │
█ freeze___letsfreezethat_v3_f1                    201,651 Hz    24.3 % │███          │
  freeze___letsfreezethat_v2                        70,091 Hz     8.5 % │█            │
  freeze___deepfreeze                               59,320 Hz     7.2 % │▉            │
  freeze___deepfreezer                              37,352 Hz     4.5 % │▋            │
```

```
# hengist/dev/letsfreezethat/src/usecase1.benchmarks.coffee

  plainjs_mutable                                    8,268 Hz   100.0 % │████████████▌│
  plainjs_immutable                                  4,933 Hz    59.7 % │███████▌     │
█ letsfreezethat_v3_thaw_freeze_f0                   4,682 Hz    56.6 % │███████▏     │
  letsfreezethat_v2_standard                         4,464 Hz    54.0 % │██████▊      │
█ letsfreezethat_v3_lets_f0                          4,444 Hz    53.8 % │██████▊      │
█ letsfreezethat_v3_lets_f1                          4,213 Hz    51.0 % │██████▍      │
█ letsfreezethat_v3_thaw_freeze_f1                   4,034 Hz    48.8 % │██████▏      │
  letsfreezethat_v2_nofreeze                         2,143 Hz    25.9 % │███▎         │
  immutable                                          1,852 Hz    22.4 % │██▊          │
  mori                                               1,779 Hz    21.5 % │██▊          │
  hamt                                               1,752 Hz    21.2 % │██▋          │
  immer                                              1,352 Hz    16.3 % │██           │
```

```
# hengist/dev/letsfreezethat/src/main.benchmarks.coffee

█ letsfreezethat_v3_f0_freezethaw                  116,513 Hz   100.0 % │████████████▌│
█ letsfreezethat_v3_f1_freezethaw                   97,101 Hz    83.3 % │██████████▍  │
█ letsfreezethat_v3_f0_lets                         93,101 Hz    79.9 % │██████████   │
█ letsfreezethat_v3_f1_lets                         76,045 Hz    65.3 % │████████▏    │
  plainjs_mutable                                   28,035 Hz    24.1 % │███          │
  letsfreezethat_v2_f0_lets                         22,410 Hz    19.2 % │██▍          │
  letsfreezethat_v2_f0_freezethaw                   16,854 Hz    14.5 % │█▊           │
  letsfreezethat_v2_f1_freezethaw                   16,443 Hz    14.1 % │█▊           │
  letsfreezethat_v2_f1_lets                         13,648 Hz    11.7 % │█▌           │
  immutable                                          8,359 Hz     7.2 % │▉            │
  mori                                               7,845 Hz     6.7 % │▉            │
  hamt                                               7,449 Hz     6.4 % │▊            │
  immer                                              4,943 Hz     4.2 % │▌            │
```

## Other Libraries

Libraries that do deep freezing and/or deep copying and/or provide copy-on-write semantics that are
available on [npm](http://npmjs.org) include [`immer`](https://immerjs.github.io/immer/docs/introduction),
[`HAMT`](https://github.com/mattbierner/hamt), [`mori`](https://swannodette.github.io/mori/),
[`immutable.js`](https://immutable-js.github.io/immutable-js/),
[`fast-copy`](https://github.com/planttheidea/fast-copy),
[`deepfreeze`](https://github.com/serapath/deepfreeze), and [`deepfreezer` (a.k.a.
DeepFreezerJS)](https://github.com/TOGoS/DeepFreezerJS).

**`immer` provided the inspiration**—The key idea of `immer` is that in order to achieve immutability in
JavaScript, instead of inventing one's own data structures and APIs, it is much simpler to just recursively
make use of `Object.freeze()` and `Object.assign()` and give the programmer a convenience function—in
LetsFreezeThat: `lets()`; in `immer`: `produce()`—that allows to perform mutation within the confines of a
callback function. `immer` aims at reducing memory usage by providing structural sharing. I have not looked
into its implementation and did not collect any figures on RAM consumption, so I'll leave the reader with
the [benchmarks](#benchmarks).

**`mori` is tempting, but not convincing for my use case**—`mori` is a standalone library that brings some
ClojureScript goodness to JS programs. Its API is a bit un-JS-ish but does provide some interesting
functionality. On the downside, it cannot initialize `HashMap`s from plain JS objects, only from sequence of
key/value pairs, and when doing so, must explicitly take care of nested objects and lists. What you then get
is data structures that internally look very unlike plain JS objects so even to get a meaningful ouput when
debugging you can never just `console.log( myvalue )`, you must always convert back to plain JS. These two
considerations pretty much precluded using `mori` under the hood; also, the [benchmarks](#benchmarks).

**most deep-copy algos too slow**—In search for a fast solution that would only provide deep-copying (i.e.
no copy-on-write / structural sharing) and/or deep-freezing capabilities I found
[`klona`](https://github.com/lukeed/klona), [`fast-copy`](https://github.com/planttheidea/fast-copy),
[`deepfreeze`](https://github.com/serapath/deepfreeze), and [`deepfreezer` (a.k.a.
DeepFreezerJS)](https://github.com/TOGoS/DeepFreezerJS). Of these, [benchmarks](#benchmarks) convinced me
that only `klona` was likely to bring speedups to the next version of LetsFreezeThat so I did not consider
the rest any more. Deep-freezing nested compound values in-place is almost exactly the same as deep-copying
nested compound values so I used `klona`'s approach for both chores. Be it said though that I did not
evaluate other possibly interesting aspects of any of these packages, so if your use cases involves copying
or freezing JS `Date` objects, `Int32Array`s, `RegExp`s, I encourage you to have a second look at any of
these.

**Should I COW?**—Copy-On-Write is a technique to eschew 'speculative', avoidable memory consumption. Phil
Bagwell suggested how to efficiently leverage structural sharing for trees of data in [a paper titled *Ideal
Hash Trees* (Lausanne, 2000)](http://infoscience.epfl.ch/record/64398/files/idealhashtrees.pdf);
subsequentially, his approach was implemented by the [Clojure](https://clojure.org/) community to get more
memory-efficient and performant COW semantics into the language. Alas, according to my benchmarks HAMT is
still not fast enough in JS to justify the effort when your data items are small as you'll only get 5%—25%
of the performance that you'd get with naive copying.

## To Do

* [ ] preserve symbol attributes when freezing
* [ ] consider to offer an implementation of HAMT
  (https://blog.mattbierner.com/persistent-hash-tries-in-javavascript/, https://github.com/mattbierner/hamt,
  https://github.com/mattbierner/hamt_plus (? https://github.com/mattbierner/hashtrie)) for the frequent use
  case of immutable maps
* [ ] consider to optionally detect multiple object instances, circular references
