
# InterText SplitLines

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [What It Does](#what-it-does)
- [How to Use It](#how-to-use-it)
  - [One-Off Call](#one-off-call)
  - [Iterators](#iterators)
  - [Settings](#settings)
- [Revisions](#revisions)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## What It Does

InterText SplitLines facilitates splitting and assembling buffers into neat, decoded lines of text.

## How to Use It

### One-Off Call

In case you have one or more buffers with textual content, the simplest way to use InterText SplitLines
is to use the `splitlines()` method which will return a list of strings, each representing one line:


```coffee
# For demonstration, let's assemble a number of buffers with lines
# randomly spread all over the place:
buffers = [
  "helo"
  " there!\nHere "
  "come\na few lines\n"
  "of text that are\nquite unevenly "
  "spread over several\n"
  "buffers.", ]
buffers = ( Buffer.from d for d in buffers )


# Now that we have a number of buffers, let's split them into text lines:
SL    = require 'intertext-splitlines'
lines = SL.splitlines buffers
# lines = SL.splitlines buffers... # can call with list or spread out, as seen fit
# lines = SL.splitlines buffer_1, buffer_2, buffer_3

# lines now contains:

[ 'helo there!',
  'Here come',
  'a few lines',
  'of text that are',
  'quite unevenly spread over several',
  'buffers.', ]
```

Observe that newline characters will be removed from the output so there's no way to determine whether
the last line did or did not end with a newline; this should be the desired result most of the time. In
the event that a trailing newline should be detectable, pass in an explicit setting:

```coffee
lines = SL.splitlines { skip_empty_last: false, }, buffers
```

### Iterators

* whenever you receive a buffer from a stream or other source (such as a NodeJS stream's `data` event),
  call `SL.walk_lines ctx, buffer` with that data; this returns an iterator over the decoded complete lines
  in the buffer, if any
* when the stream has ended, there may still be buffered data with any number of lines, so don't forget to
  call `SL.flush ctx` to receive another iterator over the last line, if any

In JavaScript:

```js
// for each buffer received, do:
for ( line of SL.walk_lines( ctx, buffer ) )
  { do_something_with( line ) };
// after the last buffer has been received, do:
for ( line of SL.flush( ctx ) )
  { do_something_with( line ) };
```

In CoffeeScript:

```coffee
# for each buffer received, do:
for line from SL.walk_lines ctx, buffer
  do_something_with line
# after the last buffer has been received, do:
for line from SL.flush ctx
  do_something_with line
```

### Settings

* **`?splitter <nonempty ( text | buffer )> = '\n'`**—the sequence of characters that mark linebreaks
* **`?decode <boolean> = true`**—whether or not to decode buffers as UTF-8. NOTE to be replaced by
  `encoding`.
* **`?skip_empty_last <boolean> = true`**—whether to emit an emtpy string as last item when the source ended
  in `splitter`.
* **`?keep_newlines <boolean> = false`**—whether to return strings or buffers that end in whatever
  `splitter` is set to. That is `abc/def` with settings `{ splitter: '/', keep_newlines: false, }` would
  split into `[ 'abc', 'def', ]`, wheras with `{ keep_newlines: true, }`, the result would be `[ 'abc/',
  'def', ]`

## Revisions

* [X] throw out `find_first_match()`, replace by `buffer.indexOf()`
* [X] do not return lists but iterators
* publish v1.0.0
---------------------------------------------------------------------
* [X] implement `splitlines()`
* [X] implement setting `skip_empty_last`
* publish v1.1.0

* [X] fix treatment of last line when emitting buffers
* publish v1.1.1
---------------------------------------------------------------------
* [X] implement setting `keep_newlines`
* publish v1.2.0
---------------------------------------------------------------------
* [ ] implement `encoding`
* [ ] make keeping of newlines configurable
* [ ] make sure all relevant line ending conventions are properly honored
* [ ] allow custom line splitter



