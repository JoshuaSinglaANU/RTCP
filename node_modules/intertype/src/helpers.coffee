

'use strict'

#-----------------------------------------------------------------------------------------------------------
CND           = require 'cnd'
rpr           = CND.rpr.bind CND
{ inspect, }  = require 'util'
@assign       = Object.assign
@jr           = JSON.stringify
@flatten      = CND.flatten
_xrpr         = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }
@xrpr         = ( x ) -> ( _xrpr x )[ .. 1024 ]
@js_type_of   = ( x ) -> ( ( Object::toString.call x ).slice 8, -1 ).toLowerCase()

#-----------------------------------------------------------------------------------------------------------
@get_rprs_of_tprs = ( tprs ) ->
  ### `tprs: test parameters, i.e. additional arguments to type tester, as in `multiple_of x, 4` ###
  rpr_of_tprs = switch tprs.length
    when 0 then ''
    when 1 then "#{rpr tprs[ 0 ]}"
    else "#{rpr tprs}"
  srpr_of_tprs = switch rpr_of_tprs.length
    when 0 then ''
    else ' ' + rpr_of_tprs
  return { rpr_of_tprs, srpr_of_tprs, }

#-----------------------------------------------------------------------------------------------------------
@intersection_of = ( a, b ) -> ( x for x in a when x in b ).sort()
