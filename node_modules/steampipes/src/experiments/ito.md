



# Transforms


Objects with three properties `{ i, t, o, }`, hence called I.T.O. or ITO objects:

* `i` (for **i**nput)
* `t` (for **t**ransform)
* `o` (for **o**utput)

Mnemnonic 糸 (いと)

**use `{ i: -> }`, `{ i: ( c ) -> }` for sinks?**—i.e. put function into input position

|    | i                      | t            | o                    |                                        |
|:---|:-----------------------|:-------------|:---------------------|:---------------------------------------|
|    |                        |              |                      | **Sources**                            |
| #1 |                        |              | `[]`<sup>**i**</sup> | Plain Source                           |
| #2 |                        |              | `f()`                | (Generator or Iterator) Source         |
|    |                        |              |                      | **Transforms**                         |
| #4 | (`[]`)<sup>**a**</sup> | `f(d,send)`  | `[]`                 | Transform                              |
| #9 |                        | `f(d)`       |                      | Observer                               |
|    |                        |              |                      | **Drains**                             |
| #5 | `[]`                   |              |                      | (Collecting) Drain                     |
| #6 | `true`                 |              |                      | (Non-Collecting) Drain                 |
| #7 | `[]` or `true`         | `f() / f(Σ)` |                      | Drain w/ On-End Handler                |
|    |                        |              |                      | **Illegal/Meaningless Configurations** |
| #9 |                        | `f(d,send)`  |                      | No target for `send()` given           |
| #8 |                        |              |                      | NOP                                    |
| #3 | (`[]`)<sup>**a**</sup> |              | `[]`                 | Pass-Through                           |

<sup>**i**</sup>) any **iterable** will work<br>

<sup>**a**</sup>) will be set **automatically** to the output of the preceding ITO<br>

`f() / f(Σ)` signifies a function (an on-end handler) that takes zero or one arguments; it will be called
once the pipeline is exhausted. If it takes an argument, that will be set to the list of all values that
have arrived at that point during processing; if it has its **i**nput property set, then that value will be
used as collector. Observe that in the case of an infinite stream, a collector will eventually grow
arbitrarily big and the on-end handler will never be called.

If there are transforms in the pipeline *after* a drain, they will receive values as if the drain wasn't
there. If there are several drains in a pipeline, each will be called in order of their appearance. If no
drain is present, data will not be collected. Generally speaking, one can always


The inputs marked **a** in the above will generally **not** be set explicitly by the user; instead, they will
be assigned proper values right before the pipeline is opened.

* **Sources** are objects that have only an output, ex.: `{ o: [] }`
* **Throughs** are objects that have an input and an output
* **Sinks** are objects that have an input (which may be `true` for a non-collecting sink)

A list of ITO objects is called a pipeline; a duct is a pipeline that has been preprocessed (configuration
of ITO objects is sanity-checked, missing inputs (above marked **a**) supplied, nested pipelines/ducts are
unpacked (flattened)). A pipeline is started with `SP.open()`.

```coffee
collector_1 = []
collector_2 = []
pipeline    = []
pipeline.push [ 1, 2, 3, ]
pipeline.push 'abc'
pipeline.push ( d ) -> log d # 1 -> 'a' -> 2 -> 'b' -> 3 -> 'c'
pipeline.push ( d, send ) -> send if ( isa.number d ) then ( d * 2 ) else d
pipeline.push collector_1
pipeline.push ( d, send ) -> send if ( isa.text d   ) then d.toUpperCase() else d
pipeline.push collector_2
SP.open pipeline
log collector_1 # [ 2, 'a', 4, 'b', 6, 'c', ]
log collector_2 # [ 2, 'A', 4, 'B', 6, 'C', ]
```

* Three signatures:

  <!-- * `->` no arguments: functions to be called on each data item -->
  * `( d ) ->` one argument: for observers
  * `( d, send ) ->` two arguments: for synchronous transforms
  * `( d, send, done ) ->` three arguments: for asynchronous transforms











