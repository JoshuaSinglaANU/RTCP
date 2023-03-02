

# SteamPipes


<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Motivation](#motivation)
- [How to Construct Sources, Transforms, and Sinks](#how-to-construct-sources-transforms-and-sinks)
  - [Sources](#sources)
  - [Transforms](#transforms)
  - [Modifiers and `$before_first()`, `$after_last()`](#modifiers-and-before_first-after_last)
  - [Sinks](#sinks)
- [Asynchronous Sources and Transforms](#asynchronous-sources-and-transforms)
- [Ducts](#ducts)
  - [Duct Configurations](#duct-configurations)
- [Behavior for Ending Streams](#behavior-for-ending-streams)
- [Aborting Streams](#aborting-streams)
- [Updates](#updates)
- [To Do](#to-do)
  - [Future: JS Pipeline Operator](#future-js-pipeline-operator)
  - [To Do: Railway-Oriented Programming](#to-do-railway-oriented-programming)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




**Fast, simple data pipelines** built from first principles. Basically, [datomic
transducers](https://www.youtube.com/watch?v=6mTbuzafcII).

SteamPipes is the successor to [PipeStreams](https://github.com/loveencounterflow/pipestreams) and
[PipeDreams](https://github.com/loveencounterflow/pipedreams). PipeStreams was originally built on top of
[NodeJS streams](X███████████████) and [through](X███████████████); from version X███████████████ on, I
switched to [pull-streams](https://pull-stream.github.io).

## Motivation

* Performance, X███████████████ insert benchmarks
* Simplicity of implementation, no recursion
* Observability, the data pipeline is an array of arrays that one may inspect


## How to Construct Sources, Transforms, and Sinks

### Sources

Valid SteamPipes sources include all JS values for which either

```
CS                            │ JS
──────────────────────────────┼─────────────────────────────────────
for d from source             │ for ( d of source ) {
  ...                         │   ... }
──────────────────────────────┴─────────────────────────────────────
```

or

```
CS                            │ JS
──────────────────────────────┼─────────────────────────────────────
for await d from source       │ for await ( d of source ) {
  ...                         │   ... }
──────────────────────────────┴─────────────────────────────────────
```

is valid.

In addition, synchronous and asynchronous functions that, when called without arguments, return a value for
which one of the iteration modes (sync or async) works correctly are allowed. Such a function will be called
as late as possible, that is, not at pipeline definition time, but only when a pipeline with a source and a
drain has been constructed and is started with `pull()`.


### Transforms

* Functions that take 2 arguments `d` and `send` (includes `send.end()`);
* must/should/may have a list (`Array`) that acts as so-called 'local sink' (this is where data send with
  `send d` is stored before being passed to the next transform);
* property to indicate whether transform is asynchronous.

* transforms have a property `sink`, which must be a list (at least have a `shift()` method);
* TF may add (ordinarily `push()`) values to the sink at any time (but processing only guaranteed when this
  happens, in TFs marked synchronous, before the main body of the function completed, and in TFs marked
  asynchronous, before `done()` has been called).
* conceivable to use *same* TF, same `sink` in two or more pipelines simultaneously; conceivable to accept
  values from other sources than the TF which is directly upstream; hence possible to construct wyes (i.e.
  data sources that appear in mid-stream).

* Calling `$ whatever..., ( d, send ) -> ...` is always equivalent to calling `modify whatever..., $ ( d,
  send ) -> ...`; calling `modify t` without any further arguments is equivalent to `t` (the transform
  itself).

* **`@chunkify_*()`**—cut stream by observing boundaries. Depending on whether to keep or toss datoms
  recognbized by the `filter` function as boundaries, use either
  * **`@$chunkify_keep = ( filter, postprocess = null ) ->`** or
  * **`@$chunkify_toss = ( filter, postprocess = null ) ->`**
  The second, optional `postprocess` argument must be a function when given; it will receive a list of
  datoms and may return any value which will then be sent on. Sample application:

  ```coffee
  filter      = ( d ) -> d in [ '(', ')', ]
  postprocess = ( chunk ) -> chunk.join '|'
  pipeline    = []
  pipeline.push 'ab(cdefg)'
  pipeline.push SP.$chunkify_keep filter, postprocess
  pipeline.push SP.$show()
  pipeline.push SP.$drain -> resolve()
  SP.pull pipeline...
  ```

  will print

  ```
  'a|b|('
  'c|d|e|f|g|)'
  ```

  Had we used `SP.$chunkify_toss filter, postprocess` instead, the output would have been

  ```
  'a|b'
  'c|d|e|f|g'
  ```

  So if one just wanted to collect all stream items into a single list, one would use either `SP.$collect()`
  or else an argument to the drain transform, as in `SP.$drain ( collector ) -> resolve collector`; if one
  wanted to collect all stream items into multiple lists, then `SP.$chunkify_{keep|toss} filter, ...` is the
  way to go.

### Modifiers and `$before_first()`, `$after_last()`

* `{ first, last, before, after, between, }`
* `$before_first()`
* `$after_last()`
* `$async_before_first()`
* `$async_after_last()`


### Sinks

Arbitrary objects can act as sinks provided they have a `sink` property; this property must be either set to
`true` for a generic sink or else be an object that has `push()` method (such as a list). A sink may,
furthermore, also have an `on_end()` method which, if set, must be a function that takes zero or one
argument.

If the `sink` property is a list, then it will receive all data items that arrive through the pipeline (the
resultant data of the pipeline); if it is `true`, then those data items will be discarded.

The `on_end()` method will be called when streaming has terminated (since the source was exhausted or a
transform called `send.end()`); if it takes one argument, then that will be the list of resultant data. If
both the `sink` property has been set to a list and `on_end()` takes an argument, then that value will be
the `sink` property (you probably only want the one or the other in most cases).

```coffee
{ sink: true, }
{ sink: true, on_end: ( -> do_something() ), }
{ sink: true, on_end: ( ( result ) -> do_something result ), }
{ sink: x,    on_end: ( ( result ) -> do_something result ### NB result is x ### ), }
```

The only SteamPipes method that produces a sink is `$drain()` (it should really be called `sink()` but for
compatibility with PipeStreams the name has been kept as a holdover from `pull-stream`). `$drain()` takes
zero, one or two arguments:

```coffee
$drain()                              is equiv. to   { sink: true, }
$drain                     -> ...     is equiv. to   { sink: true, on_end: (       -> ... ), }
$drain               ( x ) -> ...     is equiv. to   { sink: true, on_end: ( ( x ) -> ... ), }
$drain { sink: x, },       -> ...     is equiv. to   { sink: x,    on_end: (       -> ... ), }
$drain { sink: x, }, ( x ) -> ...     is equiv. to   { sink: x,    on_end: ( ( x ) -> ... ), }
```

## Asynchronous Sources and Transforms

Asynchronous transforms can be constructed using the 'asynchronous remit' method, `$async()`. The method
passed into `$async()` must accept three arguments, namely `d` (the data item coming down the pipeline),
`send` (the method to send data down the pipeline), and, in addition to synchronous transforms, `done`,
which is a callback function used to signal completion (it is analogous to the `resulve` argument of
promises, `new Promise ( resulve, reject ) ->` and indeed implemented as such). An example:

```coffee
X███████████████
X███████████████
X███████████████
X███████████████
```



## Ducts


### Duct Configurations

**I. Special Arities**

There are two special duct arities, empty and single. An empty pipeline producers a duct marked with
`is_empty: true`; it is always a no-op, hence discardable. The duct does not have a `type` property.

A pipeline with a single element produces a duct with the property `is_single: true`; it is always
equivalent to its sole transform, and its `type` property is that of its sole element.

```coffee
SHAPE OF PIPELINE                     SHAPE OF DUCT                   REMARKS
⋆ []                                  ⇨ { is_empty:  true,       } # equiv. to a no-op
⋆ [ x, ]                              ⇨ { is_single: true,       } # equiv. to its single member
```

**II. Open Ducts**

Open ducts may always take the place of a non-composite element of the same type; this is what makes
pipelines composable. As one can always replace a sequence like `( x += a ); ( x += b );` by a
non-composed equivalent `( x += a + b )`, so can one replace a non-composite through (i.e. a single
function that transforms values) with a composite one (i.e. a list of throughs), and so on:

```coffee
SHAPE OF PIPELINE                     SHAPE OF DUCT                   REMARKS
⋆ [ source, transforms...,        ]   ⇨ { type:      'source',   } # equiv. to a non-composite source
⋆ [         transforms...,        ]   ⇨ { type:      'through',  } # equiv. to a non-composite transform
⋆ [         transforms..., sink,  ]   ⇨ { type:      'sink',     } # equiv. to a non-composite sink
```

**III. Closed Ducts**

Closed ducts are pipelines that have both a source and a sink (plus any number of throughs). They are like a
closed electric circuit and will start running when being passed to the `pull()` method (but note that
actual data flow may be indefinitely postponed in case the source does not start delivering immediately).

```coffee
SHAPE OF PIPELINE                     SHAPE OF DUCT                   REMARKS
⋆ [ source, transforms..., sink,  ]   ⇨ { type:      'circuit',  } # ready to run
```

## Behavior for Ending Streams

Two ways to end a stream from inside a transform: either

1)  call `send.end()`, or
2)  `send SP.symbols.end`.

The two methods are 100% identical. In SteamPipes, 'ending a stream' means 'to break from the loop that
iterates over the data source'.

Note that when the `pull` method receives an `end` signal, it will not request any further data from the
source, *but* it *will* allow all data that is already in the pipeline to reach the sink just as in regular
operation, and it will also supply all transforms that have requested a `last` value with such a terminal
value.

Any of these actions may cause any of the transforms to issue an unlimited number of further values, so
that, in the general case, `end`ing a stream is not guaranteed to actually stop processing at any point in
time; this is only true for properly coöperating transforms.



## Aborting Streams

There's no API to abort a stream—i.e. make the stream and all transforms stop processing immediately—but one
can always wrap the `pull pipeline...` invocation into a `try`/`catch` clause and throw a custom symbolic
value:

```coffee
pipeline = []
...
pipeline.push $ ( d, send ) ->
  ...
  throw 'abort'
  ...
...
try
  pull pipeline...
catch error
  throw error if error isnt 'abort'
  warn "the stream was aborted"
...
```


## Updates

* If source has a method `start()`, it will be called when `SP.pull pipeline...` is called; this enables
  push sources to delay issuing data until the pipeline is ready to consume it



## To Do

* [ ] cf `### TAINT how can `undefined` end up in `transforms`??? ###` in `pull-remit.coffee`: Fix bug
* [ ] somehow notify sources (especiall push sources) that pipeline has been pulled (so data may start to
  flow); otherwise, if ultimate source is e.g. NodeJS connected via event handlers, those underlying sources
  will start on definition, not on pipeline completion, and will spill arbitrary amounts of data into
  SteamPipe buffers.
* [ ] consider to adapt [Rich Hickey's terminology](https://youtu.be/6mTbuzafcII?t=878) and call transforms
  'transducers' (it's the more pipestreamy word)
* [ ] compare:
  ```coffee
  source      = SP.new_push_source()
  source.send 1
  source.send 2
  pipeline    = []
  pipeline.push source
  pipeline.push SP.$show()
  pipeline.push $drain ->
    urge '^2262^', "demo_stream ended"
    resolve()
  source.end() # (1)
  SP.pull pipeline...
  # source.end() # (2)
  ```
  With `(1)`, the drain condition never triggers; only `(2)` works as intended; i.o.w. `source.end()` must
  not be called before `SP.pull()`. This is not acceptable.
* [ ] consider whether `$drain()` should allow to appear mid-stream (it would then pull data from upstream,
  downstream must rely on own `$drain()` to obtain data).
* [ ] reflect once more about depth-first vs. breadth-first **doling mode**: (all sources and, so) async
  sources (, too,) wait before doling out the next item until it has been **transduced** (dealt with)
  completely; shouldn't asynchronous transforms behave likewise? Async transforms do have a `done()` method
  to signal finishing, synchronous transforms don't have that, so it is not clear how to deal with a
  situation where a transform happens to decide it doesn't want to `send()` anything (although, the
  transform does return (stop running), so that might be a way)
* [ ] explain why using only `yield` instead of `send()` is not a good idea
* [ ] make `$split()` work with both streams and buffers
<!-- * [ ] implement `window` modifier as in, `$ { window: { width: 2, fallback: null,}, }, ( d, send ) -> -->
* [ ] implement `send.skip n` (or `send.drop n`) to drop next n datoms
* [ ] fix reading from, writing to files
* [ ] implement `$split_tsv()`
* [ ] implement
  * `$once_before_first()`
  * `$once_after_last()`
  * `$once_async_before_first()`
  * `$once_async_after_last()`
  * `$once_with_first()`
  * `$once_async_with_first()`
  * `$once_with_last()`
  * `$once_async_with_last()`
  * `$once_with_nth()`
  * `$once_async_with_nth()`
  using modifiers instead (`$ { once: [ 'first', 'last', ], }, transform (d, send ) ->`) to avoid API bloat
* [x] implement tees which are like branching tracks that lead to their own sinks
* [ ] there should also be parallel tracks that are rejoined later on
* [x] should tees accept single transforms (and implicitly build a pipeline with a sink)? [NO]
* [ ] obscure bug: when a transform with `{ first, last, }` modifiers is used and uses the `$`/`remit`
  method of *another* instance of the SteamPipes library, then that transform will get to see the `first`
  value, but *not the `last`*; presumably, this is caused by the buckets not being shared between the
  pipeline at large and the transform?
* [X] obscure bug: when a push source is used with a stream that comes from another instance of the
  SteamPipes library (as in, `( require 'pathA/steampipes' ).new_push_source()` is used in a pipeline that
  is activated by) `( require 'pathB/steampipes' ).pull pipeline...`) and error with message
  `^steampipes/pullremit@7003^ expected an iterable, a function, a generator function or a sink, got a
  object` results. The message should at least hint point at the probable error cause or be avoided at all.
  **FIXED in v6.2**: replaced `Symbol 'xy'` with `Symbol.from 'steampipes/xy'` in `SP.marks`.
* [ ] bug: async functions passed into `$drain()`, attached to `push_source.start` and possibly other places
  are not called or not called with `await`, thus causing silent failures. Must always reject loudly where
  detected or be handled appropriately.
* [X] implement `$chunkify()` (as configurable variant of `$collect()`?); see code comment in standard
  transforms
* [ ] implement file tailing using e.g. https://github.com/lucagrulla/node-tail
* [ ] implement reading from Unix FIFOs, see https://stackoverflow.com/a/18226566/7568091
* [ ] replace current implementation of `$split()` with one based on `intertext-splitlines`
* [ ] implement `$batch size`

### Future: JS Pipeline Operator

see [Breaking Chains with Pipelines in Modern
JavaScript](https://www.wix.engineering/post/breaking-chains-with-pipelines-in-modern-javascript)

```js
const result3 = numbers
  |> filter(#, v => v % 2 === 0)
  |> map(#, v => v + 1)
  |> slice(#, 0, 3)
  |> Array.from;
```

* Lazy evaluation, no backpressure (?), built into the language.
* Already usable with Babel.
* Article discusses a number of alternatives with merits and demerits, must read.


### To Do: Railway-Oriented Programming

* https://zohaib.me/railway-programming-pattern-in-elixir/
* https://fsharpforfunandprofit.com/rop/
* https://github.com/zorbash/opus

Transform categorization: functions may

* acc. to result arity
  * give back exactly one value for each input that we do care about (-> `$map()`)
  * give back exactly one value for each input that we do not care about (-> `$watch()`)
  * give back any number of values (-> `$`/`remit()`)
  * never give back any value (-> `$watch()`)

* acc. to iterability
  * yield
  * return

* acc. to synchronicity
  * be synchronous
  * be asynchronous

* acc. to happiness
  * give back sad value on failure
  * always give back happy failure, using `throw` for sad results
  * return a sentinel value / error code (like JS `[].indexOf()`)

* pipeline definition may take on this form:

  ```coffee
  ¶ = ( pipeline = [] ).push.bind pipeline
  ¶ tee       other_pipeline, ( d ) -> 110 <= d <= 119    # optional filter, all `d`s stay in this pipeline, some also in other
  ¶ switch    other_pipeline, ( d ) -> 110 <= d <= 119    # obligatory filter, each `d` in only one pipeline
  ¶ watch     ( d ) -> ...                                # return value thrown away (does that respect async functions?)
  ¶ guard     -1, $indexOf 'helo'                         # guard with filter value, saddens value when `true <- CND.equals(...)`
  ¶ guard     ( ( d ) -> ... ), indexOf 'helo'            # guard with filter function, saddens value when `true <- filter()`
  ¶ trycatch  map ( d       ) -> throw new Error "whaat" if d % 2 is 0; return d * 3 + 1
  ¶ trycatch  $   ( d, send ) -> throw new Error "whaat" if d % 2 is 0; send d; send d * 3 + 1
  ¶ if_sad $show_warning()
  ¶ if_sad $ignore()
  ¶ drain()
  pull ¶
  ```
* pipe processing never calls any transform with sad value (except for those explicitly configured to accept
  those)
* but all sad values are still passed on, cause errors at pipeline end (near drain) when not being filtered
  out
* must **not** swallow exceptions implicitly as that would promote silent failures
* benefit: simplify logic a great deal
* benefit: may record errors and try to move on, then complain with summary of everything that went wrong



