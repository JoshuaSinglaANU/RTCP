<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [hollerith-codec](#hollerith-codec)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->



- [hollerith-codec](#hollerith-codec)

> **Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*


# hollerith-codec

Binary encoding for Hollerith that provides a total ordering for primitive
datatypes and lists of those. Used by
[Hollerith](https://github.com/loveencounterflow/hollerith2) and
[KWIC](https://github.com/loveencounterflow/kwic).


**Breaking Change** in v2.x: Prior to v2.x, when comparing two lists `a`, `b` where `a` is a prefix of `b`
used to be sorted with `a` first, then `b`, i.o.w. a shorter word always precedes a longer word that starts
out the same (as in an alphabetically sorted dictionary).

Starting with v2, however, this has been changed such that when comparing two lists `a`, `b` where `a` is a
prefix of `b`, `b` will be sorted *before* `a` if the first 'extra' element of `b` (i.e. `b[ a.length ]`) is
a *negative number*. By way of example, sorting now looks like this (with hexadecimal byte values):

```
[ -10,               ] ... 4b bfdbffffffffffff  4c
[  -1,               ] ... 4b c00fffffffffffff  4c
[                    ] ... 4c
[   0,               ] ... 4d 0000000000000000  4c
[   1,   -1,         ] ... 4d 3ff0000000000000  4b c00fffffffffffff  4c
[   1,               ] ... 4d 3ff0000000000000  4c
[   1,    0,         ] ... 4d 3ff0000000000000  4d 0000000000000000  4c
[   1,    1,         ] ... 4d 3ff0000000000000  4d 3ff0000000000000  4c
[  10,   -2,         ] ... 4d 4024000000000000  4b bfffffffffffffff  4c
[  10,   -2,   3,    ] ... 4d 4024000000000000  4b bfffffffffffffff  4d 4008000000000000 4c
[  10,   -1,         ] ... 4d 4024000000000000  4b c00fffffffffffff  4c
[  10,   -1,   3,    ] ... 4d 4024000000000000  4b c00fffffffffffff  4d 4008000000000000 4c
[  10,               ] ... 4d 4024000000000000  4c
[  10,    0,         ] ... 4d 4024000000000000  4d 0000000000000000  4c
[  10,    0,    3,   ] ... 4d 4024000000000000  4d 0000000000000000  4d 4008000000000000 4c
[  10,    1,         ] ... 4d 4024000000000000  4d 3ff0000000000000  4c
[  10,    1,    3,   ] ... 4d 4024000000000000  4d 3ff0000000000000  4d 4008000000000000 4c
[  10,    2,         ] ... 4d 4024000000000000  4d 4000000000000000  4c
[  10,    2,    3,   ] ... 4d 4024000000000000  4d 4000000000000000  4d 4008000000000000 4c
[  10,    4,   -2,   ] ... 4d 4024000000000000  4d 4010000000000000  4b bfffffffffffffff 4c
[  10,    4,   -1,   ] ... 4d 4024000000000000  4d 4010000000000000  4b c00fffffffffffff 4c
[  10,    4,         ] ... 4d 4024000000000000  4d 4010000000000000  4c
[  10,    4,    0,   ] ... 4d 4024000000000000  4d 4010000000000000  4d 0000000000000000 4c
[  10,    4,    1,   ] ... 4d 4024000000000000  4d 4010000000000000  4d 3ff0000000000000 4c
[  10,    4,    2,   ] ... 4d 4024000000000000  4d 4010000000000000  4d 4000000000000000 4c
```




