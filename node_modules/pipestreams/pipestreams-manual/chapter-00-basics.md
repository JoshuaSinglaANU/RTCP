

### Basics

#### Sources, Transforms, Sinks

#### Remit, the Fundamental Method to Make Transforms

```
PS = require 'pipestreams'
{ $, $async, } = PS

f = ->
	pipeline = []
	pipeline.push PS.new_value_source [ 1, 2, 3, ]
	pipeline.push $ ( d, send ) ->
		send d
		send d * 2
	pipeline.push PS.$show()
	pipeline.push PS.$drain -> console.log 'ok'

f()
```

#### Surround

The `$surround()` transform expects a JS object with one or more of the
following members, which are all optional:

* `first`, for a value to be prepended to the stream;
* `last`, for a value to be appended the stream;
* `between`, for a value to be inserted between each pair of data items;
* `after`, for a value to be inserted after each data item;
* `before`, for a value to be prepended to each data item.

A settings object with the same format may also be used as an optional first
argument to the `$()` (remit) and `$async()` (async remit) methods; therefore,

```
pipeline.push PS.$surround { first: 'F', last: 'L', }
pipeline.push $ ( d, send ) -> ...
```

is equivalent to

```
pipeline.push $ { first: 'F', last: 'L', }, ( d, send ) -> ...
```

Of course, it is possible to use more than one `$surround()` transform in
a row; in that case, the later ones act on the data they sey coming
down the pipeline as a matter of course. This means that when one constructs
a pipeline like this:

```
pipeline.push PS.new_value_source [ 1 .. 3 ]
pipeline.push PS.$surround { first: 'F', last: 'L', }
pipeline.push PS.$surround { first: '[', last: ']', between: '|', }
pipeline.push $ ( d, send ) -> ...
```

the result will start and end with square brackets (because they got added
later), and the `between` values will be put between the values inserted by the
uppermost `$surround()`'s `first` and `last` values, and all the data items that
were present in the stream prior to that:

```
"[F|1|2|3|L]"
```


