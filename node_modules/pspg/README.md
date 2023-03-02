

# pspg

A NodeJS command line pager for tabular content which respects wide characters (important for mixed
Latin/CJK output), built on [Pavel Stehule's great PostgreSQL pager](https://github.com/okbob/pspg).

## Screenshots

(TBD)

## Installation

```sh
npm install pspg
```

## Usage

(TBD)

## Dependencies (and, How It Works)

Some of the more pertinent dependencies of this project:

**[Pavel Stehule's `pspg` PostgreSQL pager](https://github.com/okbob/pspg)**—When Pavel first announced his
command line pager some two years ago, it was an immediate success with me. The combination of

* (`more` or `less`-like) paged output tailored to fit PostgreSQL&nbsp;/&nbsp;`psql` (the PostgreSQL
  interactive terminal and script-runner),
* cursor- and mouse-based scrolling,
* search functionality,
* pleasent color themes,
* very swift performance
  that scales to at least ten thousands of rows,
* CJK / wide character support,
* and—just to top it off—**the display of fixed headers and a customizable number of fixed leftmost
  columns**

is something no other software that I'm aware of does (please prove me wrong).

**Turns out you can use `pspg` even if you're not using PostgreSQL**; the important thing is the data
format. If you `echo` or `cat` lines that look like this:

```
  a  | b        | c        | d        | e
-----+----------+----------+----------+----------
   1 |        2 |        3 |        4 |        5
   6 |        7 |        8 |        9 |       10
  11 |       12 |       13 |       14 |       15
  16 |       17 |       18 |       19 |       20
  21 |       22 |       23 |       24 |       25
  26 |       27 |       28 |       29 |       30
(eof)
```

and pipe them into `pspg` (as, say, `cat myfile.txt | path/to/pspg -s17 --force-uniborder`) you'll get a
nicely formatted, vertically and horizontally scrollable, tabular display. Hit `q` or `F10` and you're back
to the usual command line (superficially, `pspg` works more or less the same as `more` and `less`).

**[Dominic Tarr's pager module for NodeJS](https://github.com/dominictarr/default-pager)**—Yadda yadda yadda
yadda yadda yadda yadda yadda yadda yadda yadda.

(TBD)

**[The `pipestreams` module](https://github.com/loveencounterflow/pipestreams)**—Yadda yadda yadda yadda
yadda yadda yadda yadda yadda yadda yadda.

(TBD)

**[The `to-width` module](https://github.com/loveencounterflow/to-width)**—Yadda yadda yadda yadda yadda
yadda yadda yadda yadda yadda yadda.

(TBD)


## References

* https://stackoverflow.com/a/53190286/7568091
* https://github.com/jprichardson/node-kexec

