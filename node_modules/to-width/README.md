## To-Width

**The essential building block for command line tables: truncate & pad strings
to given width, taking care of wide characters, accents and ANSI colors.**

![](https://github.com/loveencounterflow/to-width/raw/master/art/Screen%20Shot%202016-07-05%20at%2016.44.59.png)

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Usage](#usage)
- [Bugs](#bugs)
- [Why?](#why)
- [How?](#how)
- [Similar](#similar)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Usage

```coffee
{ to_width, width_of, } = require 'to-width'
```

`width_of` is provided by
[sindresorhus/string-width](https://github.com/sindresorhus/string-width); it provides a fairly
reliable way to determine the width of strings on character devices. All people who
deal with `string.length`, encodings and buffers in JavaScript will enjoy the
following table:


| `string`                              | `string.length` | `Buffer.byteLength string` | `width_of string` |
| --------:                            | :--------:      | :--------:          | :--------: |
| `'abcd'`                              | 4     ✅         | 4    ✅              | 4   ✅      |
| `'äöüß'`                              | 4     ✅         | 8    ❌              | 4   ✅      |
| `'äöüß'` (using combining diacritics) | 7     (✅)         | 11    ❌             | 7   ❌      |
| `'北京'`                              | 2     (✅)       | 6    ❌              | 4   ✅      |
| `'𪜀𪜁'`                                | 4   ❌           | 8  ❌                | 4 ✅        |

## Bugs

* `width_of` doesn't correctly count combining characters.
* 32bit Unicode glyphs (those from the 'Astral Planes') may be split by `to_width`, and combining
  diacritics may get lost:

```
'#' + ( to_width 'abcdabcd', 4 ) + '#' # --> #abc…#
'#' + ( to_width 'äöüßäöüß', 4 ) + '#' # --> #äöü…#
'#' + ( to_width 'äöüßäöüß', 4 ) + '#' # --> #äöu…#
'#' + ( to_width '北京北京', 4 ) + '#' # --> #北……#
'#' + ( to_width '𪜀𪜁𪜀𪜁', 4 ) + '#' # --> #𪜀�…#
```


## Why?

When I needed tabular data display on the command line, I got dissatisfied
with existing solutions. There are some promising modules for doing this on
[npm](https://www.npmjs.com/search?q=table), but nothing satisfied me in the end.

I realized that the key requirement for doing tables in the terminal is the
ability to format data so that each chunk of text (that you build table cells
with) has exactly the correct visual width. Actually, string length fitting
seems to have become quite the rage among people these days, at least judging by
the recent [left-pad](https://www.npmjs.com/package/left-pad) hype.

## How?

The core functionality of this module has been implemented using

* https://github.com/sindresorhus/string-width
* https://github.com/martinheidegger/wcstring

These two modules do the heavy lifting (looking for wide characters, combining characters, and
ANSI color codes); `to-width` does only a little bit of glueing (and <strike>fixing</strike>
providing a workaround for a minor bug in `wcstring`).


<!--
In programming languages and fixed-width displays, there are at least three meaningful measures of text 'length':

* **Length**—How many code units are used by a given programming language? In
  JavaScript, this measure is obtained by retrieving the value of `text.length`,
  and indeed, this is often used to implement simple-minded string truncation
  and padding when lines of constant length are desired. Be it said that the only two justifications for considering `text.length`

* **Size**—How long a string is under some special interpretation of its contents; for example, the string
`'a&#98x;c'` has a length of 8, but a size of 3 when NCRs are rendered as their corresponding code
points.

* **Width**—How wide does a given text appear on the screen? This is a tricky
  question, even if we reframe it a bit and try to answer, not "how many
  millimeters does this text take up", but, much more interestingly, "if I
  assume a monospaced (a.k.a fixed-width, non-proportional) font and a 'gauge' of
  (say) ten characters `0123456789`, then how many characters of a given text will
  fit into the exact same horizontal space?".


  Strictly speaking, we can only find out by this must ignore color codes and
  take CJK &c. into account; also, it should support [combining
  characters](https://en.wikipedia.org/wiki/Combining_character)
 -->


## Similar

These packages have also been considered:

* https://github.com/chalk/strip-ansi
* https://github.com/chalk/ansi-styles
* https://github.com/jbnicolai/ansi-256-colors
* https://github.com/nexdrew/ansi-align
* https://github.com/sindresorhus/boxen
* https://github.com/sindresorhus/string-length
* https://github.com/sindresorhus/cli-truncate
* https://github.com/chalk/wrap-ansi
* https://github.com/chalk/slice-ansi
* https://github.com/substack/fixed-width-float

