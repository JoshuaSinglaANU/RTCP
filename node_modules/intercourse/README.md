


# InterCourse

InterCourse (IC) is YeSQL-like utlity to treat files as archives of hunks of functionality descriptions,
IOW, it is a tool that lets you collect named snippets of arbitrary code—e.g. SQL queries and statements—in
text files. These snippets can then be retrieved and, for example, turned into functions that execute
queries against a database. InterCourse itself does a single job: it takes the path to an existing file and
returns a data structure that describes the definitions it found. It's up to users of InterCourse (the
'consumer') to bring those definitions to life (e.g. parse them to turn them into JS fiunctions, or wrap
them in JS functions and send the hunks to a database for execution, as does
[`icql`](https://github.com/loveencounterflow/icql)).

## Usage

You can either parse a string synchronously, or else read file contents synchronously or asynchronously by
giving a path:

```coffee
IC = require 'intercourse'

IC.definitions_from_text        text      #  synchronous
IC.definitions_from_path_sync   path      #  synchronous
await IC.definitions_from_path  path      # asynchronous
```

## Format

The format is whitespace-sensitive and super-simple:

* **Each line that does not start with whitespace and is not a top-level comment is considered an IC
  directive** (or a syntax error in case it fails to parse).

* A directive consists of a **type annotation** (that can be freely chosen), a **name** (that may not contain
  whitespace or round brackets), an **optional signature**, and a **source text** (the 'hunk').

* A definition is either a **one-liner** as in

  ```
  mytype myname(): myhunk
  ```

  or else a **multi-liner** as in

  ```
  mytype myname():
    first line
    second line
    ...
  ```

  Observe that **blank lines within hunks are kept, but blank lines between definitions are discarded**.
  Relative ordering of definitions has no effect whatsover on processing (except for the wording of
  potential error messages).

* **Each line in the hunk of a multi-liner must start with the same whitespace characters** (or else be
  blank); this indentation is called the 'plinth' and will be subtracted from each line. Currently, each
  block may have its own plinth, but that may change in the future (and it's probably a good idea never to
  mix tabs and spaces in a single file anyway).

* **IC itself puts no limit on definition types** and does not do anything with it except that it stores the
  (names of the types) in the returned description. It's up to InterCourse consumers to make sense of
  definition types, spot unknown ones, error out in the case of types and so on. In the case of
  [`icql`](https://github.com/loveencounterflow/icql), the allowed types are `query` for SQL statements that
  do return results (i.e. `SELECT`), and `procedure` for (series of) statements that do not return results
  (i.e. `CREATE`, `DROP`, `INSERT`).

* The elements of the signature (i.e. the parameters) are not further validated; instead, we just look for
  intermittent commas and remove surrounding whitespace. These details may change in the future so it's best
  to restrict oneself to anything that would be a valid JavaScript function signature without type
  annotations and without default values (e.g. you could write `def f( x = 42 )` but you'd probably best
  not).

* When giving multiple definitions for the same name, **each definition must have a unique set of named
  parameters**. Order of appearance is discarded. More precisely, the parameter names of the signature are
  sorted (using JS `Array.prototype.sort()`), joined with commas and wrapped with round brackets to obtain a
  unique key (which is called the 'kenning' of the definition); it is this key that must turn out be unique.

  So when you have already a definition `def foo( bar ): ...` you can add a definition `def foo( baz )`
  (other name) and a definition `def foo( bar, baz )` (other number of parameters), but `def foo( baz, bar
  )` would be considered as equivalent to `def foo( bar, baz )` and will throw an error.

* Signatures of **definition without round brackets** (as in `def myname: ...`) are known as 'null
  signatures' and may be interpreted as a catch-all definitions that won't get signature-checked. Signatures
  of **definitions with round brackets but no parameters inside** are called 'empty signatures' and will be
  taken to symbolize to allow for function calls with no arguments. The signatures of all other definitions
  (i.e. those with parameters) are called 'full signatures'.

  **One can only either give a single null-signature definition or else any number of empty- and
  full-signature definitions under the same name**. Thus use of `def f: ...` on the hand and `def f(): ...`
  and / or `def f( x ): ...` etc is mutually exclusive.

* As it stands, **all definitions with the same name must be of the same nominal type**. This restriction
  may be lifted or made optional in the future.

* The above three rules serve to ensure that the definitions as returned by InterCourse lend themselves to
  implement conflict-free **function overloading**. When you turn IC hunks into JS functions *that take, as
  their sole argument, a JS object*, then you will always be able to tell which definition will be used from
  the names that appear in the call. For example, when, in your app, you call `myfunc( { a: 42, b: true, }
  )`, the above rules ensure there must either be a definition like `... myfunc( a, b ):
  ...` (exactly as in the call) or `... myfunc( b, a ): ...` (same names but different order) or `...
  myfunc: ...` (a catch-all that precludes any other definitions with explicit signatures).

* Each source text (i.e. the hunk) will be **partitioned** based on its relative indentation with the hunk.
  This is done so that consumers of SQL have a chance to run each statement separately (because many DB
  adaptors prohibit executing more than one statement per call). This entails that authors be aware that
  *each line of source text that starts at the top level will start a new part*. For example, this text:

  ```
  procedure foo:
    update mytable
    set x = 1 where y = 42;
    select *
    from mytable
    where x > 0;
  ```

  will get split wrongly into five parts, with one line per part. Instead, always write hunks so that each
  line that does not start a new statement is indented (it also looks better):

  ```
  procedure foo:
    update mytable
      set x = 1 where y = 42;
    select *
      from mytable
      where x > 0;
  ```

  In case your application can do without partitioning, call InterCourse's `definitions_from_path()`,
  `definitions_from_path_sync()` or `definitions_from_text()` with a settings object as second argument that
  sets `{ partition: false, }`; allowed values are `null`, `false` (no partitioning), and `'indent'` (the
  default).

Here's an example:

```sql

-- ---------------------------------------------------------------------------------------------------------
-- A block defined without brackets will result in a description without a `signature` member:
procedure import_table_texnames:
  drop table if exists texnames;
  create virtual table texnames using csv( filename='texnames.csv' );

-- ---------------------------------------------------------------------------------------------------------
-- A block defined with empty brackets will result in `{ signature: [], }`:
procedure create_snippet_table():
  drop table if exists snippets;
  create table snippets (
      id      integer primary key,
      snippet text not null );

-- ---------------------------------------------------------------------------------------------------------
procedure populate_snippets():
  insert into snippets ( snippet ) values
    ( 'iota' ),
    ( 'Iota' ),
    ( 'alpha' ),
    ( 'Alpha' ),
    ( 'beta' ),
    ( 'Beta' );

-- ---------------------------------------------------------------------------------------------------------
-- Here we define a `query` that needs exactly one parameter:
query match_snippet( probe ):
  select id, snippet from snippets where snippet like $probe

-- ---------------------------------------------------------------------------------------------------------
-- one-liners and overloading are possible, too:
query fetch_texnames():                   select * from texnames;
query fetch_texnames( limit ):            select * from texnames limit $limit;
query fetch_texnames( pattern ):          select * from texnames where texname like pattern;
query fetch_texnames( pattern, limit ):   select * from texnames where texname like pattern limit $limit;

-- ---------------------------------------------------------------------------------------------------------
-- everything under an `ignore` heading will be ignored (duh):
ignore:
  This text will be ignored
```

The above will be turned into a JS object (here shown using YAML / CoffeeScript notation):

```yaml
import_table_texnames:
  type:   'procedure'
  'null':
    parts: [
      'drop table if exists texnames;'
      'create virtual table texnames using csv( filename='texnames.csv' );'
      ]
    kenning:      'null'
    type:         'procedure'
    location:     { line_nr: 4, }

create_snippet_table: {
  type:   'procedure'
  '()':
    parts: [
      'drop table if exists snippets;'
      'create table snippets (\n    id      integer primary key,\n    snippet text not null );\n'
      ]
    kenning:      '()'
    type:         'procedure'
    location:     { line_nr: 10, }
    signature:    []

populate_snippets:
  type:   'procedure'
  '()':
    parts: [
      'insert into snippets ( snippet ) values\n  ( 'iota' ),\n  ( 'Iota' ),\n  ( 'alpha' ),\n  ( 'Alpha' ),\n  ( 'beta' ),\n  ( 'Beta' );\n'
      ]
    kenning:      '()'
    type:         'procedure'
    location:     { line_nr: 17, }
    signature:    []

match_snippet:
  type:   'query'
  '(probe)':
    kenning:      '(probe)'
    parts: [
      'select id, snippet from snippets where snippet like $probe\n'
      ]
    type:         'query'
    location:     { line_nr: 28, }
    signature:    [ 'probe', ]

fetch_texnames:
  type:   'query'
  '()':
    kenning:      '()'
    parts:        [ 'select * from texnames;\n', ]
    type:         'query'
    location:     { line_nr: 33, }
    signature:    []
  '(limit)':
    kenning:      '(limit)'
    parts:        [ 'select * from texnames limit $limit;\n', ]
    type:         'query'
    location:     { line_nr: 34, }
    signature:    [ 'limit', ]
  '(pattern)':
    kenning:      '(pattern)'
    parts:        [ 'select * from texnames where texname like pattern;\n', ]
    type:         'query'
    location:     { line_nr: 34, }
    signature:    [ 'pattern', ]
  '(limit,pattern)':
    kenning:      '(limit,pattern)'
    parts:        [ 'select * from texnames where texname like pattern limit $limit;\n', ]
    type:         'query'
    location:     { line_nr: 34, }
    signature:    [ 'limit', 'pattern', ]
```


In the above, observe how `description.fetch_texnames[ '(limit,pattern)' ]` has been normalized from the
original definition, `query fetch_texnames( pattern, limit ):`. Null signatures are indexed under `'null'`
and lack a `signature` entry, while empty signatures are indexed under `()` and have an empty list as
`signature`. The source texts are either empty strings (in the case no hunk has been given) or else end in a
single newline.


## What's Missing

Since InterCourse is pretty much still in the experimental phase, it's straightforward to come up
with a number of very useful features that are not yet implemented:

* [ ] **Parametrized Types**—definition types could take arguments to indicate behavioral variants. For
  example, `query( collect: true ) foo(): select * from products;` could be used to define a query that
  returns an array of result rows instead of returning an iterator.

* [ ] **Recursive Definitions**—definitions should be allowed to refer to other definitions.

* [ ] **Parameters with Default Values**—not quite sure how to square this with definition overloading, but
  a definition like `t f( x, y: v ): ...` could rule out a definition `t f( x ): ...` as the former
  signature already covers the domain of the latter.

* [ ] **Multiple Source Files**—as it stands, IC accepts and requires exactly one definition source file;
  this should be generalized to accept an entire directory of sources, a list of file paths and so on.

<!-- * [ ] **Meta-Parameters**—as it stands, the definition will be handed to the consumer as-is, and the
  consumer is responsible for interpolating the named arguments into the definition as seen appropriate. In
  the case of SQL, this precludes using variables for table and column names, since DB connectors and DB
  engines will typically not allow to parametrize the structural ('compile-time') parts of queries.
  InterCourse couldn't really fill that gap as it is intended to remain taerget-language agnostic (so it
  can't know how to ensure against syntax errors and injection attacks when unsafe strings are handed in),
  but at least it could prepare the definition strings
 -->