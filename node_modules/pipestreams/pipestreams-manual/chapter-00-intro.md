

## PipeStreams: Pipelines and Streams

### Terminology

* **Sources** (a.k.a. 'readables') do not take inputs from the stream, but
  provide data to 'flow downstream'. Sources may be constructed from values
  (e.g. a text may be converted into a source of text lines or a series of
  characters), from files (reading files and processing their contents being a
  frequent application of streams), or using functions that sit around until
  they are called with pieces of data they then send downstream.

* **Sinks** (a.k.a. 'writables') do not provide outputs to the stream, but
  accept all data that is funnelled to them by way of the pipeline. There are
  two important subclasses of sinks: on the one hand, sinks may be used to write
  to a file, an outgoing HTTP connection, or a database; so that would be sinks
  with targets. Target-less sinks may seem pointless but they are needed to
  provide a writable endpoint to a pipeline. The function used to represent such
  a sink is known as `$drain` in PipeStreams, so 'a drain' just means that, a
  generic target-less sink required by the API.

* **Pipelines** are lists of **stream transforms**. As we will shortly see,
  pipelines represent the central constructional element in the PipeStreams way
  of doing things. They start out as generic lists (i.e. Javascript `Array`s)
  that transforms—functions—are being inserted to, and they end up representing,
  in the ordering of their elements, the ordering of transformational steps that
  each piece of data fed into their top end has to undergo before coming out at
  the other end. A well-written pipeline combines a simple conceptual model with
  a highly readable list of things to do, with each station along the assembly
  line doing just one specific thing.

* **Transforms** (symbolized as `$f()`) are synchronous or asynchronous
  functions that accept one data item *d*<sub>*i*</sub> (a.k.a. events) from
  upstream and pass zero or more data items *d*<sub>*1*</sub>,
  *d*<sub>*2*</sub>,&nbsp;... down the stream, consecutively.

In short one can say that in each stream, data comes out of a source, flows
through a number of transforms `$f(), $g(), ...`, and goes into some kind of
sink. A **complete pipeline** has at least a source and a sink.

* By **streams** we mean the activity that occurs when a complete pipeline has
  been 'activated', that is made start to process data. So, technically, a
  'stream' (a composite algorithm at work) is what a 'pipeline', once activated,
  does. In practice, the distinction is often blurred, and one can, for example,
  just as well say that a particular event is 'coming down the stream' or
  'coming down the pipeline'.

### Equivalence Rules

The power of streams—and by streams I mean primarily
[`pull-stream`](http://pull-stream.github.io/)s on which PipeStreams is
built—comes from the abstractions they provide. In programming, *functions* are
such powerful abstractions because when you take a chunk of code and make it a
function with a name and a call signature, all of a sudden you have not only a
piece of code that you can pass around and invoke, you can also put that
invocation into *another* named function and so on. So, a building block made
from smaller building blocks remains a building block, albeit a more complex
one.

Likewise, when building processing pipelines from stream transforms, you start
out with pipelines built from stream primitives, and then you can go and put
entire pipelines into other pipelines, taking advantage of the compositional
powers afforded by the equivalence rules (invariants) that streams guarantee. In
the below, we use an arrow `a -> b` to symbolize '`a` is equivalent to `b`',
i.e. '`b` acts like an `a`'. `pull` represents the PipeStreams `pull` method
(basically `pull-stream`'s `pull` method); `$f()`, `$g()` represent stream
transforms (see *API Naming and Conventions* for the leading dollar sign); the
ellipsis notation `$f(), ...` represents 'any number of transforms'.

* A pipeline with a source and any number of transforms is equivalent to a
  source:

`pull [ source_1, $f(), ..., ] -> source`

* A pipeline with any number of transforms and a sink is equivalent to a sink:

`pull [ $f(), ..., sink_1 ] -> sink`

* A pipeline with any number of transforms is equivalent to a (more complex)
  transform:

`pull [ $f(), ..., ] -> $g()`

* In particular, a pipeline with no elements is equivalent to the empty (no-op)
  transform that passes all data through (and that can be omitted in any
  pipeline except for a smallish penalty in performance):

`pull [] -> PS.$pass()`

* A pipeline with a source, any number of transforms and a sink is equivalent to
  a stream:

`pull [ source, $f(), ..., sink, ] -> stream`


### API Naming and Conventions



`PS.pull pipeline...`

### Simple Examples

**Ex. 1**

```coffee
PS  = require 'pipestreams'
log = console.log
p   = []
p.push PS.new_value_source [ 'foo', 'bar', 'baz', ]
p.push PS.$show()
p.push PS.$drain -> log 'done'
PS.pull p...
```

**Ex. 2**

```coffee
PS              = require 'pipestreams'
{ $, $async, }  = PS

$double = ->
  return $ ( d, send ) -> send 2 * d

source  = PS.new_push_source()
p       = []
p.push source
p.push $double()
p.push PS.$show()
p.push PS.$drain()
PS.pull p...
source.push 42
```




