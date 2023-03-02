
### Comparison with NodeJS Streams, Pull-Streams

> Note: Whatever is said here about [PipeDreams
> (https://github.com/loveencounterflow/pipedreams)](https://github.com/loveencounterflow/pipedreams)
> applies *only* to versions < 7.0.0 of that library (for which see
> https://github.com/loveencounterflow/pipedreams/tree/v6.3.0), *not* to newer
> ones, which are built on top of
> [PipeStreams](https://github.com/loveencounterflow/pipestreams) and are a
> different beast altogether. To clarify that, I write 'Old PipeDreams' in the
> below.

Here are a few points that highlight the reasons why I wrote the PipeStreams
library on top of [pull-stream](https://github.com/pull-stream/pull-stream)s
(after writing [Old PipeDreams](https://github.com/loveencounterflow/pipedreams/tree/v6.3.0)
which were built on top of [NodeJS
Streams](https://nodejs.org/api/stream.html)):

* The [basic API ideas of Old
  PipeDreams](https://github.com/loveencounterflow/pipedreams#the-remit-and-remit-async-methods)
  turned out to be a highly useful and effective tool to create not-so-small
  data processing assemblies. Before pipelines, such assemblies tended to be
  ad-hoc messes of synchronous and asynchronous pieces of code calling each
  other; after pipelines, assemblies could be written as linear sequences of
  named functions.

* The Old PipeDreams stream transform call convention—where a transform is
  (produced from) a function `( data, send ) ->` that accepts a piece of `data`
  and a `send` method that is used to send data downstream—proved to be the main
  enabling aspect of said library. All of a sudden you could just dump [all that
  is wrong with NodeJS
  streams](http://dominictarr.com/post/145135293917/history-of-streams) and
  forget about all their [Byzantine
  complexities](https://nodejs.org/api/stream.html): just write a function that
  `( data, send ) -> ... send data ...` and bang, you're good to go.

* Old PipeDreams had some downsides, though; apart from some of the
  *complexities* of NodeJS streams that could not be entirely hidden, it also
  suffered from their inherently mediocre
  [*performance*](https://github.com/loveencounterflow/basic-stream-benchmarks)
  characteristics: the architecture of NodeJS streams is such that adding a
  transform to a pipeline incurs a non-trivial run-time performance penalty, so
  much that **the performance of NodejS streams pipelines with more than a very
  few steps will be dominated by the number of steps, even if those steps are
  no-ops**; this at least used to be the case at the time when I abandoned
  NodeJS streams and turned to Pull-Streams. The whole idea of streams is to do
  one little thing at a time and have those many little steps co-operate to
  accomplish a bigger goal; an implementation with an unreasonable cost on
  adding steps ruins that picture.

* The underlying implementation of Pull-Streams is [hugely
  simpler](http://dominictarr.com/post/149248845122/pull-streams-pull-streams-are-a-very-simple)
  than that of NodeJS streams. To [quote another
  guy](https://github.com/ipfs/js-ipfs/issues/362#issuecomment-237597850) who
  thinks so:

  > pull streams' # 1 superpower is their simplicity (in the Rich Hickey sense
  > of the word): anyone can write a full pull stream implementation from
  > scratch in a few minutes, from first principles. This is not true of node
  > streams in the slightest. Simplicity brings transparency with it, meaning
  > debugging and reasoning about implementation gets easier.

  So while 'simple' doesn't equal 'easy' (in the [Rich
  Hickey](https://www.youtube.com/watch?v=rI8tNMsozo0) sense of the word) it's
  still true that simpler concepts, a simpler implementation and a simpler API
  are to be preferred over a convoluted implementation (and API) that suffers
  from backward-compatibility pressures and maintains several parallel, mutually
  exclusive and ultimately superfluous modes of operation. In the case of NodeJS
  streams, you have 'new style' vs 'old style' mode of operation, a switch that
  is done transparently based on what seemingly unrelated parts of the API you
  employ in what order. Next, you must decide whether you're dealing with
  'objects' or 'binary' data, a completely gratuitous difference: it's just
  data. Lastly, you can structure your streaming app to do things the
  `.pipe()`ing way, or, alternatively, the `EventEmitter` way—inheriting [all
  that is wrong with the `EventEmitter` API and
  implementation](https://github.com/sindresorhus/emittery#how-is-this-different-than-the-built-in-eventemitter-in-nodejs).
  To top it off, [you still don't get proper error handling with NodeJS
  streams](https://stackoverflow.com/a/22389498/7568091).

  > I'm not saying that using the event handling model to process streams is
  > wrong, I just claim that having NodeJS do both piping and events where
  > either would have sufficed is what contributes to the rather sad performance
  > story they deliver.

**I'm really sorry that these points amount to what can be perceived as bashing
on the NodeJS folks who have given us the great piece of software that is
NodeJS**. But frankly, as much as I like NodeJS, I nowadays try to stay away
from using the standard library's streams and event emitters. Let's just say not
everything in the Nodejs stdlib that *could* conceivably be used in userland
software *should* be used.

With that off the chest, let's move on to what PipeStreams claims to provide.

[WIP]

* **The `remit` methods, `$()` and `$async()`**

* **Convenience stream transforms**

* **Circular pipelines**

* **Push sources**

* **Bridge to NodeJS streams**

* **An (optional) convention for data events**

* **Tees: diverting into multiple sinks**



