<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [ICQL](#icql)
  - [ICQL Installation](#icql-installation)
  - [ICQL Usage](#icql-usage)
    - [Instantiation](#instantiation)
    - [Querying](#querying)
    - [`db.$`, the 'Special' Attribute](#db-the-special-attribute)
    - [Writing ICQL Statements](#writing-icql-statements)
    - [SQL Fragments](#sql-fragments)
      - [Definition Types](#definition-types)
      - [Query Modifiers](#query-modifiers)
  - [A Short Intro to YeSQL](#a-short-intro-to-yesql)
    - [Aside: Why You Don't Want to Use an ORM](#aside-why-you-dont-want-to-use-an-orm)
  - [Todo](#todo)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




# ICQL

**YeSQL meets SQLite: A SQLite Adapter built with InterCourse and BetterSQLite**

ICQL is a module written in the spirit of [YeSQL](https://duckduckgo.com/?q=YeSQL&t=lm&ia=software). For
those readers who are unaware of YeSQL, there is a short [Intro to YeSQL](#a-short-intro-to-yesql); others
may want to dive right into the sections on [ICQL Installation](#icql-installation) and [ICQL
Usage](#icql-usage).

ICQL is implemented on top of [InterCourse](https://github.com/loveencounterflow/intercourse) which is an
SQL-agnostic library that does the parsing and cataloguing of 'functionality hunks' (i.e. named blocks of
code that define how to accomplish tasks).

ICQL takes **three pieces**: **(1) a database adapter** (which currently must be
[`better-sqlite3`](https://github.com/JoshuaWise/better-sqlite3) or something with a compatible API), **(2)
a path to an SQLite DB file**, and **(3) a path to an ICQL source file** with statement definitions; it then
binds together these three pieces to produce an object where the statement definitions have been turned into
methods that perform queries against the DB.


## ICQL Installation

```bash
npm install icql
```

## ICQL Usage

### Instantiation

ICQL is specifically geared towards using **(1)** [the SQLite Relational DB](http://sqlite.org/) by way of
**(2)** [the `better-sqlite3`](https://github.com/JoshuaWise/better-sqlite3) library for NodeJS. While it
should be not too difficult to (fork and) adapt ICQL to work with other DB engines such as PostgreSQL, no
concrete plans exist at the time of this writing. Understand that ICQL is still in its inceptive stage and,
as such, may lack important features, contain bugs and experience breaking changes in the future.

> FTTB all code examples below will be given in CoffeeScript. JavaScript users will have to mentally supply
> some parentheses and semicolons.

To use ICQL in your code, import the library and instantiate a `db` object:

```coffee
ICQL = require 'icql'

settings = {
  connector:    require 'better-sqlite3'  # must give a `better-sqlite3`-compatible object
  db_path:      'path/to/my.sqlitedb'     # must indicate where your database file is / will be created
  icql_path:    'path/to/my.icql' }       # must indicate where your SQL statements file is

db = ICQL.bind settings                   # create an object with methods to query against your SQLite DB
```

### Querying

After doing `db = ICQL.bind settings` the new `db` object contains all the methods you defined in your
`*icql` file. Each method will be either a `procedure` or a `query`, the difference being that

* **procedures consists of any number of SQL statements that do not produce any output**; these may be used
  to create, modify and drop tables and views, insert and delete data and so on; on the other hand,

* **queries consist of a single SQL `select` statement with any number of resulting records**.

Here are two simple ICQL definitions:

```sql
procedure drop_tables:
  drop table if exists foo;
  drop table if exists bar;

query fetch_products( price_max ):
  select * from products where price <= $price_max;

query fetch_products( price_min, price_max ):
  select * from products where price between price_min and $price_max;
```

Owing to the [synchronous nature of
BetterSQLite](https://github.com/JoshuaWise/better-sqlite3#why-should-i-use-this-instead-of-node-sqlite3),
**all procedures and queries are synchronous**; that means you can simply write stuff like

```coffee
db = ...
db.drop_tables()
db.create_table_bar()
db.populate_table_bar()
```

without promises / callbacks / whatever async. That's great (and works out fine because SQLite is a
single-thread, in-process DB engine, so asynchronicity doesn't buy you anything within a single-threaded
event-based VM like NodeJS).

Queries return an iterator, so you can use a `for`/`of` loop in JavaScript or a `for`/`from` loop in
CoffeeScript to iterate over all results:

```js
// JS
for ( row of db.fetch_products { price_max: 400, } ) {
  do_something_with( row ); }
```

```coffee
# CS
for row from db.fetch_products { price_max: 400, }
  do_something_with row
```

Under the hood, the equivalent of the following is performed:

```coffee
query_entry = db.$.sql.fetch_products[ 'price_max' ]
query_text  = query_entry.text
#............................................................
# In case of statements without results:
db.$.execute query_text
#............................................................
# In case of statements with results:
statement   = db.$.prepare query_text
iterator    = statement.iterate { price_max: 400, }
for row from iterator: ...
```


### `db.$`, the 'Special' Attribute

The `db` object as constructed above will have a an attribute, `db.$`, called 'special', which in turn
contains a number of members that are used internally and may be occasionally be useful for the user:

* `db.$.limit()`, `db.$.single_row()`, `db.$.first_row()`, `db.$.single_value()`, `db.$.first_value()`,
  `db.$.all_rows()`, `db.$.all_first_values()` and `db.$.first_values()` are discussed in [Query
  Modifiers](#query-modifiers), below.

* **`db.$.load    path`**—load an extension.
* **`db.$.read    path`**—execute SQL statements in a file.
* **`db.$.prepare sql`**—prepare a statement. Returns a `better-sqlite3` `statement` instance.
* **`db.$.execute sql`**—execute any number of SQL statements.
* **`db.$.query   sql, P...`**—perform a single `select` statement. Returns an iterator over the result set's
  rows. When the `sql` text has placeholders, accepts additional values.
* **`db.$.settings`**—the settings that the `db` object was instantiated with.
* **`db.$.db`**—the underlying `better-sqlite3` object that is used to implement all functionality.
* **`db.$.sql`**—an object with metadata that describes the result of parsing the definition source file.
* **`db.$.as_identifier  text`**—format a string so that it can be used as an identifier in an SQL statement
  (even when it contains spaces or quotes).
* **`db.$.catalog()`**—return an iterator over all entries in `sqlite_master`; allows to inspect the
  database for all tables, views, and indexes.
* **`db.$.clear()`**—drop all tables, views and indexes from the database.

* **`db.$.escape_text   x`**—turn text `x` into an SQL string literal.
* **`db.$.list_as_json  x`**—turn list `x` into a JSON array literal.
* **`db.$.as_sql        x`**—express value `x` as SQL literal.
* **`db.$.interpolate   sql, Q`**—interpolate values found in object `Q` into string `sql`.
* **`db.$.close()`**—close DB.


### Writing ICQL Statements

TBW; see [the demo]() and the [InterCourse docs](https://github.com/loveencounterflow/intercourse).

### SQL Fragments

Possible to define fragments, i.e. possibly incomplete SQL snippets that may contain placeholders. For each
fragment, a namesake method will be created that accepts an object with named values where applicable; when
called, method does not execute a statement but returns that SQL snippet with values filled out as literals.
Observe that the SQL interpolation routine differs a little from what `better-sqlite3` offers; in
particular, booleans `true`, `false` will be turned into integers `0`, `1`, and lists will be expressed as
JSON array literals. In the future, we will try to align ICQL and Sqlite3 value interpolation and allow to
define custom conversions.


#### Definition Types

* **`procedure`**—does not return anything and may contain any number of SQL statements.

* **`query`**—returns a [JS
  iterator](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Iterators_and_Generators) (to be
  used in a JS `for`/`of` or CS `for`/`from` loop). These can be used with any kind of `select` statement
  (trivially including those statements that return no rows at all).

<!-- * **`single_row`**—returns a single row (not wrapped in an array). An error is thrown in case query did not
  return any rows.

* **`single_value`**—returns a single value (not wrapped in an array). An error is thrown in case query did
  not return any rows.
 -->

#### Query Modifiers

Query modifiers are convenience methods to transform the result set. Because they exhaust the iterator
that is returned from a `query`, only a single method may be used; if you have to iterate more than once
over a given result set, use `db.$.all_rows db.my_query ...`.

* **`db.$.limit             n, iterator`**—returns an iterator over the first `n` rows;
* **`db.$.all_rows          iterator`**—returns a list of all rows;
* **`db.$.single_row        iterator`**—like `first_row`, but throws on `undefined`;
* **`db.$.first_row         iterator`**—returns first row, or `undefined`;
* **`db.$.single_value      iterator`**—like `first_value`, but throws on `undefined`;
* **`db.$.first_value       iterator`**—returns first field of first row, or `undefined`.
* **`db.$.first_values      iterator`**—returns an iterator over the first field of all rows.
* **`db.$.all_first_values  iterator`**—returns a list with the values of the first field of each row.
  Useful to turn queries like `select product_id from products order by price desc limit 100` into a flat
  list of values.

## A Short Intro to YeSQL

YeSQL originated, I believe, at some point in time in the 2010s as a reaction on the then-viral
[NoSQL](https://duckduckgo.com/?q=NoSQL&t=lm&ia=software) fad (see [the `yesql` library for Clojure from
2013 which may or may not have started the 'YeSQL' meme](https://github.com/krisajenkins/yesql)). The claims
of the NoSQL people basically was (and is) that classical (read 'mainframe', 'dinosaur', 'dusty') Relational
Database Management Systems (RDBMSs) (and the premises they were built on) is outmoded in a day and age
where horizontal scaling of data sources and agility is everything (I'm shortcutting this a lot, but this is
not a primer on the Relational Model or NoSQL).

Where NoSQL was right is where they claimed that **(1)** key/value stores are not necessarily best
implemented on top of a relational DB, and **(2)** one popular responses to the [Object-Relational Impedance
Mismatch](http://wiki.c2.com/?ObjectRelationalImpedanceMismatch), namely [Object/Relational Mappers
(ORMs)](https://en.wikipedia.org/wiki/Object-relational_mapping), are often a pain to work with, especially
when queries grow beyond the level of complexity of `select * from products order by price limit 10;`.


### Aside: Why You Don't Want to Use an ORM

Anyone who has tried an ORM before knows that **an ORM will not save you from having to know and to write
SQL; instead, you will have to learn a new dialect of SQL that comes with significantly more punctuation to
write, more edge cases to be aware of, and more complexities in setting up, configuring and using it** when
compared to the traditional sending-strings-of-SQL-to-the-DB approach. For those who insist that 'but I want
to write my queries in my day-to-day programming language' I say that sure, you can totally do that, but
then you'll have to use the syntax of that language as a matter of course, too. Turns out it's hard to come
up with a way to express SQL-ish statements in C-like syntaxes in a way that does not look like willfully
obfuscated code. Below is one (I find: typical) example from [a leading ORM project for
Python](https://www.sqlalchemy.org). If you insist on using an ORM, you will have to turn this simple SQL
statement ...

```sql
select
    users.fullname || ', ' || addresses.email_address as title
  from
    users,
    addresses
    where true
      and ( users.id = addresses.user_id )
      and ( users.name between 'm' and 'z' )
      and ( addresses.email_address like '%@aol.com' or addresses.email_address like '%@msn.com' );
```

... into this contraption:

```py
select([(users.c.fullname + ", " + addresses.c.email_address).
    label('title')]).\
  where(
    and_(
      users.c.id == addresses.c.user_id,
      users.c.name.between('m', 'z'),
      or_(
        addresses.c.email_address.like('%@aol.com'),
        addresses.c.email_address.like('%@msn.com')
        )
      )
    )
```

Observe how all those `A and B` terms have to be re-written as `and_( A, B )`, how the SQL keywords
`between` and `like` get suddenly turned into method calls on columns (wat?). In this particular framework,
you will have to dot-chain every term to the preceding one, producing one long spaghetti of code. Frankly,
no gains to be seen, and it only gets worse and worse from down here. For this particular query, the SQL
`from` clause is proudly auto-supplied by the ORM; in case you have to make that it explicit, though, you
have to tack on something like

```py
(...).select_from(table('users')).select_from(table('addresses'))
```

How this is any better than `from users, addresses` totally escapes me.


## Todo

* [ ] provide a way to use JS arrays for SQL values tuples, as in `select * from t where x in ( 2, 3, 5 );`
* [ ] provide a way to notate formats, use raw SQL strings with placeholders, ex. `select * from t where x
  in $tuple:mylist;`, `select * from $name:mytable;`. This could also be used to provide special behavior
  e.g. for the `limit` clause: in PostgreSQL, when `$x` in `select + from t limit $x` is `null`, no limit is
  enforced; however, in SQLite, one has to provide `-1` (or another negative integer) to achieve the same.
  Likewise, `true` and `false` have to be converted to `1` and `0` in SQLite, names in dynamic queries have
  to be quoted and escaped, &c. See https://www.npmjs.com/package/puresql for some ideas for formats; we'll
  probably favor English names over symbols since so many SQLish dialects already use so many conflicting
  sigils like `@` and so on. Named formats could also be provided by user.
* [ ] user defined functions?
* [ ] pragmas?
* [ ] services like the not-entirely obvious way to get table names with columns out of SQLite (which
  relies on `join`ing rows from `sqlite_master` with rows from `pragma_table_info(...)`)?
* [ ] provide a path to build dynamic SQL; see https://github.com/ianstormtaylor/pg-sql-helpers for some
  ideas.
* [ ] ??? introduce single-level namespaces for constructs ???
* [ ] allow default values for parameters so we can avoid to always having to define 1 method for a query
  *with* a `$limit` and another 1 method for another query that looks exactly the same except for the
  missing `$limit`.—How does that work with method overloading as implemented, if at all? Any precedences in
  existing languages?
* [ ] reduce boilerplate for `insert` procedures and fragments, etc.
* [ ] implement inheritance for ICQL declarations
* [ ] remove `better-sqlite3` dependency, consumers will have to pass in a DB instance
* [ ] introduce syntax to distinguish between compile-time and run-time interpolated parameters, ex.:
  `select * from $META:schema.$META:table where length > $min_length;`
* [ ] refactor returned object, `_local_methods` with MultiMix



