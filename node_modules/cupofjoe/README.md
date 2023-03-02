
# &#x2615; CupOfJoe &#x2615;


<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Motivation](#motivation)
- [Sample Applications](#sample-applications)
- [Notes](#notes)
    - [(Almost) A Two-Dimensional Syntax (in a way)](#almost-a-two-dimensional-syntax-in-a-way)
    - [Building Structures with Derived Crammers](#building-structures-with-derived-crammers)
- [Legacy](#legacy)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

**Work in Progress**

# Motivation

* Provide a straightforward way to leverage CoffeeScript syntax to build templates for languages like HTML
* without the magic involved in earlier approaches
* building on generic structures
* that are adaptable to a number of usages
* for example, to output a particular flavor of HTML
* own syntaxes may be defined by subclassing `CupOfJoe`

# Sample Applications

* https://github.com/loveencounterflow/datom#cup-of-datom

# Notes

* Three steps:
  * structure building
  * structure expansion
  * structure formatting
* good strategy to rather build one or more dedicated structure builders ('crammers') than to put too much
  logic into structure formatting
* structure expansion will elide all `null`s and `undefined`s
* may not use async functions, promises; everything is synchronous
* basic idea is building a list of nested lists
* any argument to a call to `cram()` may be a function which will be called w/out arguments; if that
  function returns w/out having `cram()`med anything, its return value will be crammed unless it is `null`
  or `undefined` (**Note:** might allow `null`s in the future)

* do not write

  ```coffee
  # (A)
    c.cram 'p', ->
  # ^^^^^^ 1
      c.cram null, "It is very ", ( c.cram 'em', "convenient" ), " to write"
  #   ^^^^^^ 3                      ^^^^^^ 2
  ```

  do write

  ```coffee
  # (B)
    c.cram 'p', ->
  # ^^^^^^ 1
      c.cram null, "It is very ", ( -> c.cram 'em', "convenient" ), " to write"
  #   ^^^^^^ 2                      ^^^^^^ 3
  ```

  This is because in order to call a function, its arguments must first be evaluated, so calling order is
  (as indicated by the numbers in `(A)`) not in the order the function calls appear in the text (maybe a
  good argument *[pun intended]* in favor of Reverse Polish Notation).



### (Almost) A Two-Dimensional Syntax (in a way)



```coffee
cupofjoe          = new ( require 'cupofjoe' ).Cupofjoe()
{ cram, expand }  = cupofjoe.export()

cram 'two', 'three', 'four'
expand()
# => [ [ 'two', 'three', 'four', ], ]
```


```coffee
cupofjoe          = new ( require 'cupofjoe' ).Cupofjoe()
{ cram, expand }  = cupofjoe.export()
cram 'two', ->
  cram 'three'
  cram 'four'

expand()
# => [ [ 'two', 'three', 'four', ], ]
```

### Building Structures with Derived Crammers


```coffee
cupofjoe          = new ( require 'cupofjoe' ).Cupofjoe { flatten: true, }
{ cram, expand }  = cupofjoe.export()

h = ( tagname, content... ) ->
  return cram content...      if ( not tagname? ) or ( tagname is 'text' )
  return cram "<#{tagname}/>" if content.length is 0
  return cram "<#{tagname}>", content..., "</#{tagname}>"

h 'paper', ->
  h 'article', ->
    h 'title', "Some Thoughts on Nested Data Structures"
    h 'par', ->
      h 'text',   "An interesting "
      h 'em',     "fact"
      h 'text',   " about CupOfJoe is that you "
      h 'em',     "can"
      h 'text',   " nest with both sequences and function calls."
  h 'conclusion', ->
    h 'text',   "With CupOfJoe, you don't need brackets."

html = expand().join ''
```

Output (reformatted for readability):

```html
<paper>
  <article>
    <title>Some Thoughts on Nested Data Structures</title>
    <par>
      An interesting <em>fact</em> about CupOfJoe is that you
      <em>can</em> nest with both sequences and function calls.
      </par>
    </article>
  <conclusion>With CupOfJoe, you don't need brackets.</conclusion>
  </paper>
```

# Legacy

```
         Markaby
            ⇓
         CoffeeKup
            ⇓
  CoffeeCup    DryKup  =>  kup
            ⇓
          Teacup
            ⇓
     CoffeNode-Teacup
            ⇓
         CupOfJoe
```

* kup
  * https://github.com/snd/kup
  * forget underpowered template languages - build HTML with the full power of coffeescript

* DryKup
  * https://github.com/mark-hahn/drykup
  * A CoffeScript html generator compatible with CoffeeKup but without the magic.
