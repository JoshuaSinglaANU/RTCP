
'use strict'

############################################################################################################
CND                       = require 'cnd'
badge                     = 'STEAMPIPES/SORT'
debug                     = CND.get_logger 'debug',     badge
types                     = require './types'

# #-----------------------------------------------------------------------------------------------------------
# @$sort = ( settings ) ->
#   last      = Symbol 'last'
#   settings  = { key: null, settings..., }
#   collector = []
#   return @$ { last, }, ( d, send ) =>
#     if d is last
#       if ( key = settings.key )?
#         collector.sort ( a, b ) =>
#           return -1 if a[ key ] < b[ key ]
#           return +1 if a[ key ] > b[ key ]
#           return  0
#       else
#         collector.sort()
#       send d for d in collector
#       collector.length = 0
#       return null
#     collector.push d
#     return null

#-----------------------------------------------------------------------------------------------------------
@$sort = ( settings ) ->
  ### https://github.com/mziccard/node-timsort ###
  TIMSORT   = require 'timsort'
  direction = 'ascending'
  sorter    = null
  key       = null
  strict    = true
  switch arity = arguments.length
    when 0 then null
    when 1
      direction = settings[ 'direction' ] ? 'ascending'
      sorter    = settings[ 'sorter'    ] ? null
      key       = settings[ 'key'       ] ? null
      strict    = settings[ 'strict'    ] ? true
    else throw new Error "µ33893 expected 0 or 1 arguments, got #{arity}"
  #.........................................................................................................
  unless direction in [ 'ascending', 'descending', ]
    throw new Error "µ34658 expected 'ascending' or 'descending' for direction, got #{rpr direction}"
  #.........................................................................................................
  unless sorter?
    #.......................................................................................................
    type_of = ( x ) =>
      ### NOTE for the purposes of magnitude comparison, `Infinity` can be treated as a number: ###
      R = types.type_of x
      return if R is 'infinity' then 'float' else R
    #.......................................................................................................
    validate_type = ( type_a, type_b, include_list = no ) =>
      unless type_a is type_b
        throw new Error "µ35423 unable to compare a #{type_a} to a #{type_b}"
      if include_list
        unless type_a in [ 'float', 'date', 'text', 'list', ]
          throw new Error "µ36188 unable to compare values of type #{type_a}"
      else
        unless type_a in [ 'float', 'date', 'text', ]
          throw new Error "µ36953 unable to compare values of type #{type_a}"
      return null
    #.......................................................................................................
    if key?
      sorter = ( a, b ) =>
        a = a[ key ]
        b = b[ key ]
        if strict
          validate_type ( type_of a ), ( type_of b ), no
        return +1 if ( if direction is 'ascending' then a > b else a < b )
        return -1 if ( if direction is 'ascending' then a < b else a > b )
        return  0
    #.......................................................................................................
    else
      sorter = ( a, b ) =>
        if strict
          validate_type ( type_a = type_of a ), ( type_b = type_of b ), yes
        if type_a is 'list'
          a = a[ 0 ]
          b = b[ 0 ]
          if strict
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
