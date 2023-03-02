
# InterType

A JavaScript type checker with helpers to implement own types and do object shape validation.


<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Concepts](#concepts)
- [Usage](#usage)
- [Declaring New Types](#declaring-new-types)
- [Typed Value Casting](#typed-value-casting)
- [Checks](#checks)
  - [Concatenating Checks](#concatenating-checks)
- [Formal Definition of the Type Concept](#formal-definition-of-the-type-concept)
- [`value` and `nowait`](#value-and-nowait)
- [To Do](#to-do)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




# Concepts

* what is a type
* fundamental types vs. domain types
* `isa`
* `validate`
* `type_of`
* `types_of`

* Types are defined using an ordered set of (one or more) named boolean test functions known as 'aspects'.
  In order for a value `x` to be of type `T`, all aspects—when called in their defined order with `x` (and
  possibly other arguments, see below)—have to return `true`. Aspect satisfication tests are done in a lazy
  fashion, so that no tests are performed after one has failed. Likewise for type validation, the difference
  being that the first failing aspect will cause an error to thrown that quotes the aspect's name.

* Types may be parametrized. For example, there's a 'partial' type `multiple_of` which needs a module (a
  number to be a multiple of) as extra parameters; thus, we can test `isa.multiple_of 121, 11`.

* In InterType, a 'type' is, on the one hand, essentially an ordered set of aspects; on the other hand,
  since within the context of a given InterType instance, each type corresponds to exactly one type name (a
  nonempty text), a 'type' can be identified with a string. Thus, the type of, say, `[]` *is* `'list'` (i.e.
  the string that spells its name).

  Conversely, any list of functions that **1)**&nbsp;can be called with a value as first arguments (possibly
  plus a number of extra parameters), that **2)**&nbsp;never throws an error and **3)**&nbsp;always returns
  a Boolean value can be regarded as a list of aspects, hence defining a (possibly empty) set of values.


# Usage

[WIP]

One usage pattern for InterType is to make it so that one (sub-) project gets a module—call it `types`—that
is dedicated to type declarations; `require`ing that `types` module then makes type checking and type
validation methods available. Say we have:

```coffee
# in module `types.coffee`

# instantiate InterType instance, export its methods to `module.exports` in one go:
intertype = new ( require 'intertype' ) module.exports

# now you can call methods of InterType instance as *module* methods:
@declare 'mytype', ( x ) -> ( @isa number ) and ( x > 12 ) and ( x <= 42 )
```

In another module:

```coffee
# now use the declared types:
{ isa, type_of, validate, } = require './types'

console.log isa.integer     100   # true
console.log isa.mytype      20    # true
console.log isa.mytype      100   # false
console.log type_of         20    # 'number'
console.log validate.mytype 20    # true
console.log validate.mytype 100   # throws "not a valid mytype"
```

# Declaring New Types

`intertype.declare()` allows to add new type specifications to `intertype.specs`. It may be called with one
to three arguments. The three argument types are:

* `type` is the name of the new type. It is often customary to call `intertype.declare 'mytype', { ... }`,
  but it is also possible to name the type within the spec and forego the first argument, as in
  `intertype.declare { type: 'mytype', ... }`.

* `spec` is an object that describes the type. It is essentially what will end up in `intertype.specs`, but
  it will get copied and possibly rewritten in the process, depending on its content and the other
  arguments. The `spec` object may have a property `type` that names the type to be added, and a property
  `tests` which, where present, must be an object with one or more (duh) tests. It is customary but not
  obligatory to name a single test `'main'`. In any event, *the ordering in which tests are executed is the
  ordering of the properties of `spec.tests`* (which corresponds to the ordering in which those tests got
  attached to `spec.tests`). The `spec` may also have further attributes, for which see below.

* `test` is an optional boolean function that accepts one or more arguments (a value `x` to be tested and
  any number of additional parameters `P` where applicable; together these are symbolized as `xP`) and
  returns whether its arguments satisfy a certain condition. The `test` argument, where present, will be
  registered as the 'main' (and only) test for the new type, `spec.tests.main`. The rule of thumb is that
  when one wants to declare a type that can be characterized by a single, concise test, then giving a single
  anonymous one-liner (typically an arrow function) is OK; conversely, when a complex type (think:
  structured objects) needs a number of tests, then it will be better to write a suite of named tests (most
  of them typically one-liners) and pass them in as properties of `spec.tests`.

The call signatures are:

* `intertype.declare spec`—In this form, `spec` must have a `type` property that names the new type, as well
  as a `tests` property.

* `intertype.declare type, spec`—This form works like the above, except that, if `spec.type` is set, it must
  equal the `type` argument. It is primarily implemented for syntactical reasons (see examples).

* `intertype.declare type, test`—This form is handy for declaring types without any further details: you
  just name it, define a test, done. For example, to declare a type for positive numbers: `@declare
  'positive', ( x ) => ( @isa.number x ) and ( x > 0 )`. Also see the next.

* `intertype.declare type, spec, test`—This form is handy for declaring types with a minimal set of details
  and a short test. For example, to define a type for NodeJS buffers: `@declare 'buffer', { size: 'length',
  },  ( x ) => Buffer.isBuffer x` (here, the `size` spec defines how InterType's `size_of()` method should
  deal with buffers).

# Typed Value Casting

**XXX TBW XXX**


# Checks

**WIP**

* `validate.t x, ...`—returns `true` on success, throws error otherwise
* `isa.t      x, ...`—returns `true` on success, `false` otherwise
* `check.t    x, ...`—returns any kind of happy value on success, a sad value otherwise
<!-- * `is.t       x, ...`—short for `not is_sad check.t x, ...` (???) -->

Distinguish between

* `isa.t x` with *single* argument: this tests for *constant* types (including `isa.even x` which tests
  against remainder of constant `n = 2`). `isa` methods always return a boolean value.

* `check.t x, ...` with *variable* number of arguments (which may include previously obtained results for
  better speed, consistency); this includes `check.multiple_of x, 2` which is equivalent to `isa.even x`
  but parametrizes `n`. Checks return arbitrary values; this also holds for failed checks since even a
  failed check may have collected some potentially expensive data. A check has failed when its return
  value is sad (i.e. when `is_sad check.t x, ...` or equivalently `not is_happy check.t x, ...` is
  `true`), and vice versa.

Checks will never throw except when presented with an unknown type or check name.

Checks and types share a common namespace; overwriting or shadowing is not allowed.

`sad` is the JS symbol `intertype.sad`; it has the property that it 'is sad', i.e. `is_sad intertype.sad`
returns `true`.

`is_sad x` is `true` for
* `sad` itself,
* instances of `Error`s
* all objects that have an attribute `x[ sad ]` whose value is `true`.

Conversely, `is_sad x` is `false`
* all primitive values except `sad` itself,
* for all objects `x` except those where `x[ sad ] === true`.

One should never use <strike>`r is sad`</strike> to test for a bad result, as that will only capture cases
where a checker returned the `sad` symbol; instead, always use `is_sad r`.

There is an equivalence (invariance) between checks, isa-tests and validations such that it is always
possible to express one in terms of the other, e.g.

```
check_integer     = ( x ) -> return try x if ( validate.integer x ) catch error then error
isa_integer       = ( x ) -> is_happy check_integer x
validate_integer  = ( x ) -> if is_happy ( R = check_integer x ) then return R else throw R
```

## Concatenating Checks

Since checks never throw the programmer must be aware to check for sad results themself. It's advantageous
to not use nested `if/then/else` statements as that would quickly grow to a mess; instead, put related
checks into a function on their own and return as soon as any intermediate result is sad, then return the
result of the last check.

Another idiom is to use a `loop` (or `wjhile ( true ) { ... }`) construct and break as soon as a sad
intermediate result is encountered; not to be forgotten is the final `break` statement that is needed to
keep the code from looping indefinetly:

```
R     = null
loop
  break if ( R = check_fso_exists    path, R ) is sad
  break if ( R = check_is_file       path, R ) is sad
  break if is_sad ( R = check_is_json_file  path, R )
  break
if is_sad R then  warn "fails with", ( rpr R )[ ... 80 ]
else              help "is JSON file; contents:", ( jr R )[ ... 100 ]
```

# Formal Definition of the Type Concept

For the purposes of InterType, **a 'type' is reified as (given by, defined by, represented as) a pure, named
function `t = ( x ) -> ...` that accepts exactly one argument `x` and always returns `true` or `false`**.
Then, the set of all `x` that are of type `t` are those where `t x` returns `true`, and the set of all `x`
that are not of type `t` are those where `t x` returns `false`; this two sets will always be disjunct.

Two trivial functions are the set of all members of all types, `any = ( x ) -> true`, and the set of values
(in the loose sense, but see [`value` and `nowait`](#value-and-nowait)) that have no type at all, `none = (
x ) -> false`; the former set contains anything representable by the VM at all, while the latter is the
empty set (i.e. all values have at least one type, `any`).

# `value` and `nowait`

A maybe surprising type is `value` (in the strict sense), which is a type defined to contain all values `x`
for which `isa.promise x` returns `false` (this includes all native promises and all 'thenables').

The `value` type has been defined as a convenient way to ensure that a given synchronous function call was
actually synchronous, i.e. did not return a promise; this may be done as

```coffee
validate.value r = my_sync_function 'foo', 'bar', 'baz'
```

Observe that 'values' in the strict sense do comprise `NaN`, `null`, `undefined`, `false` and anything else
except for promises, so `x?` is distinct from `isa.value x`; therefore, even when `my_sync_function()`
'doesn't return any value' (i.e. returns `undefined`), that is a value in this sense, too.

Equivalently and more succinctly, the validation step can be written with `nowait()`:

```coffee
nowait r = my_sync_function 'foo', 'bar', 'baz'
```

`nowait x` will always either throw a validation error (when `x` is a promise) or else return `x` itself,
which means that we can write equivalently:

```coffee
r = nowait my_sync_function 'foo', 'bar', 'baz'
```

At least in languages with optional parentheses like CoffeeScript, this looks exactly parallel to

```coffee
r = await my_async_function 'foo', 'bar', 'baz'
```

hence the name.


# To Do

* [x] Allow to pass in target object at instantiation, so e.g. `new intertype @` will cause all InterType
  methods to become available on target as `@isa()`, `@validate` and so on.

* [x] Rename `export_modules()` to `export()`, allow target object (e.g. `module.exports`) to be passed in.

* [ ] Add types `empty`, `nonempty`, ...

* [ ] Implement method to iterate over type names, specs.

* [ ] Catch errors that originate in type checking clauses

* [ ] Trace cause for failure in recursive type checks

* [ ] Allow to declare additional casts after type has been declared

* [ ] Unify registration of checks and types; rename `declare()` to `declare_type()`

* [ ] disallow extra arguments to `isa()`: all typechecks must use exactly one argument (`x`)

* [ ] should `undefined` be an inherently sad (like errors) or happy (like `null`) value?

* [ ] implement generic checks like `equals()`

* [ ] all checks should be usable with `validate`, `isa`

* [ ] implement `panic()`-like function that throws on sad values (keeping exceptions as such, unwrapping
  saddened values)

* [ ] consider whether to return type as intermediate happy value for type checks like `if is_happy ( type =
  check.object x ) then ...`

* [ ] implement custom error messages for types and/or hints what context should be provided on failure in
  validations, checks; this in an attempt to cut down on the amount of individual error messages one has to
  write (ex.: `validate.number 42, { name, foo, bar }` could quote second argument in error messages to
  provide contextual values `name`, `foo`, `bar`)

* [X] implement `validate.value x` to check `x` is anything but a promise; also offer as `nowait` method
  (the counterpart to `await`)



