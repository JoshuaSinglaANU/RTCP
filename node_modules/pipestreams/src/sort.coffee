
'use strict'

############################################################################################################
CND                       = require 'cnd'

#-----------------------------------------------------------------------------------------------------------
@$sort = ( settings ) ->
  ### https://github.com/mziccard/node-timsort ###
  TIMSORT   = require 'timsort'
  direction = 'ascending'
  sorter    = null
  key       = null
  switch arity = arguments.length
    when 0 then null
    when 1
      direction = settings[ 'direction' ] ? 'ascending'
      sorter    = settings[ 'sorter'    ] ? null
      key       = settings[ 'key'       ] ? null
    else throw new Error "µ33893 expected 0 or 1 arguments, got #{arity}"
  #.........................................................................................................
  unless direction in [ 'ascending', 'descending', ]
    throw new Error "µ34658 expected 'ascending' or 'descending' for direction, got #{rpr direction}"
  #.........................................................................................................
  unless sorter?
    #.......................................................................................................
    type_of = ( x ) =>
      ### NOTE for the purposes of magnitude comparison, `Infinity` can be treated as a number: ###
      R = CND.type_of x
      return if R is 'infinity' then 'number' else R
    #.......................................................................................................
    validate_type = ( type_a, type_b, include_list = no ) =>
      unless type_a is type_b
        throw new Error "µ35423 unable to compare a #{type_a} to a #{type_b}"
      if include_list
        unless type_a in [ 'number', 'date', 'text', 'list', ]
          throw new Error "µ36188 unable to compare values of type #{type_a}"
      else
        unless type_a in [ 'number', 'date', 'text', ]
          throw new Error "µ36953 unable to compare values of type #{type_a}"
      return null
    #.......................................................................................................
    if key?
      sorter = ( a, b ) =>
        a = a[ key ]
        b = b[ key ]
        validate_type ( type_of a ), ( type_of b ), no
        return +1 if ( if direction is 'ascending' then a > b else a < b )
        return -1 if ( if direction is 'ascending' then a < b else a > b )
        return  0
    #.......................................................................................................
    else
      sorter = ( a, b ) =>
        validate_type ( type_a = type_of a ), ( type_b = type_of b ), yes
        if type_a is 'list'
          a = a[ 0 ]
          b = b[ 0 ]
          validate_type ( type_of a ), ( type_of b ), no
        return +1 if ( if direction is 'ascending' then a > b else a < b )
        return -1 if ( if direction is 'ascending' then a < b else a > b )
        return  0
  #.........................................................................................................
  $sort = =>
    collector = []
    return @$ { last: null, }, ( data, send ) =>
      if data?
        collector.push data
      else
        TIMSORT.sort collector, sorter
        send x for x in collector
        collector.length = 0
      return null
  #.........................................................................................................
  return $sort()
