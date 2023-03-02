

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/LOGGING'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND
#...........................................................................................................
after                     = ( dts, f ) -> setTimeout  f, dts * 1000
every                     = ( dts, f ) -> setInterval f, dts * 1000
defer                     = setImmediate
{ jr
  is_empty }              = CND
#...........................................................................................................
# PS                        = require '../..'
# { $, $async, }            = PS.export()
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }
#...........................................................................................................
STACKTRACE                = require 'stack-trace' ### https://github.com/felixge/node-stack-trace ###
get_source                = require 'get-source' ### https://github.com/xpl/get-source ###


#-----------------------------------------------------------------------------------------------------------
@_get_source_ref = ( delta, prefix, color ) ->
  trace           = STACKTRACE.get()[ delta + 1 ]
  js_filename     = trace.getFileName()
  js_line_nr      = trace.getLineNumber()
  js_column_nr    = trace.getColumnNumber()
  target          = ( get_source js_filename ).resolve { line: js_line_nr, column: js_column_nr, }
  target_column   = target.column
  target_line     = target.sourceLine[ target_column .. ]
  target_line     = target_line.replace /^\s*(.*?)\s*$/g, '$1'
  target_path     = target.sourceFile.path
  display_path    = target_path.replace /\.[^.]+$/, ''
  display_path    = '...' + display_path[ display_path.length - 10 .. ]
  target_line_nr  = target.line
  ### TAINT use tabular as in old pipedreams ###
  R               = "#{CND.gold prefix} #{CND.grey display_path} #{CND.white target_line_nr} #{CND[ color ] target_line}"
  return R.padEnd 150, ' '

#-----------------------------------------------------------------------------------------------------------
@get_logger = ( letter, color ) ->
  transform_nr = 0
  return ( transform ) =>
    transform_nr   += +1
    prefix          = "#{CND[ color ] CND.reverse '  '} #{CND[ color ] letter + transform_nr}"
    source_ref      = @_get_source_ref 1, prefix, color
    pipeline        = []
    leader          = '  '.repeat transform_nr
    echo source_ref
    if transform.source? and transform.sink?
      throw new Error "unable to use logging with duplex stream"
    switch transform.length
      when 0
        pipeline.push transform
        pipeline.push @$watch ( d ) -> echo "#{prefix}#{leader}#{xrpr d}"
      when 1
        if transform_nr is 1
          pipeline.push @$watch ( d ) -> echo '-'.repeat 108
        pipeline.push @$watch ( d ) -> echo "#{prefix}#{leader}#{CND[ color ] CND.reverse '  '} #{xrpr d}"
        pipeline.push transform
        pipeline.push @$watch ( d ) -> echo "#{prefix}#{leader}#{CND[ color ] CND.reverse '  '} #{xrpr d}"
    return @pull pipeline...




############################################################################################################
unless module.parent?
  null
  # test @
  # test @[ "circular pipeline 1" ], { timeout: 5000, }
  # test @[ "circular pipeline 2" ], { timeout: 5000, }
  # test @[ "duplex" ]
  # @[ "_duplex 1" ]()
  # @[ "_duplex 2" ]()

