

'use strict'



############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'cndxh'
log                       = CND.get_logger 'plain',     badge
debug                     = CND.get_logger 'debug',     badge
info                      = CND.get_logger 'info',      badge
warn                      = CND.get_logger 'warn',      badge
alert                     = CND.get_logger 'alert',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
stackman                  = ( require 'stackman' )()
# require                   'longjohn'
FS                        = require 'fs'
PATH                      = require 'path'
{ isa_text
  red
  green
  steel
  grey
  cyan
  bold
  gold
  reverse
  white
  yellow
  reverse }               = CND


#-----------------------------------------------------------------------------------------------------------
get_context = ( path, linenr ) ->
  ### TAINT use stackman.sourceContexts() instead ###
  try
    lines     = ( FS.readFileSync path, { encoding: 'utf-8' } ).split '\n'
    delta     = 1
    first_idx = Math.max 0, linenr - 1 - delta
    last_idx  = Math.min lines.length - 1, linenr - 1 + delta
    R         = []
    for line, idx in lines[ first_idx .. last_idx ]
      this_linenr = first_idx + idx + 1
      lnr = ( this_linenr.toString().padStart 4 ) + '│ '
      if this_linenr is linenr  then  R.push  "#{grey lnr}#{cyan line}"
      else                            R.push  "#{grey lnr}#{grey line}"
    # R = R.join '\n'
  catch error
    throw error unless error.code is 'ENOENT'
    return [ ( grey './.' ), ]
  return R

#-----------------------------------------------------------------------------------------------------------
show_error_with_source_context = ( error ) ->
  stackman.callsites error, ( error, callsites ) ->
    throw error if error?
    callsites.forEach ( callsite ) ->
      unless isa_text ( path = callsite.getFileName() )
        alert grey '—'.repeat 108
        return null
      relpath   = PATH.relative process.cwd(), path
      linenr    = callsite.getLineNumber()
      if path.startsWith 'internal/'
        alert grey "#{relpath} ##{linenr}"
        return null
      alert()
      # alert steel bold reverse ( "#{relpath} ##{linenr}:" ).padEnd 108
      alert gold ( "#{bold relpath} ##{linenr}:" ).padEnd 108
      source = get_context path, linenr
      alert line for line in source
      return null
    return null
  return null

#-----------------------------------------------------------------------------------------------------------
@exit_handler = ( exception ) ->
  print               = alert
  message             = ' EXCEPTION: ' + ( exception?.message ? "an unrecoverable condition occurred" )
  if exception?.where?
    message += '\n--------------------\n' + exception.where + '\n--------------------'
  [ head, tail..., ]  = message.split '\n'
  print reverse ' ' + head + ' '
  warn line for line in tail
  if exception?.stack?
    show_error_with_source_context exception
  else
    whisper exception?.stack ? "(exception undefined, no stack)"
  process.exitCode = 1
@exit_handler = @exit_handler.bind @


############################################################################################################
unless global[ Symbol.for 'cnd-exception-handler' ]?
  global[ Symbol.for 'cnd-exception-handler' ] = true
  if process.type is 'renderer'
    window.addEventListener 'error', ( event ) =>
      # event.preventDefault()
      message = ( event.error?.message ? "(error without message)" ) + '\n' + ( event.error?.stack ? '' )[ ... 500 ]
      OPS.log message
      # @exit_handler event.error
      OPS.open_devtools()
      return true

    window.addEventListener 'unhandledrejection', ( event ) =>
      # event.preventDefault()
      message = ( event.reason?.message ? "(error without message)" ) + '\n' + ( event.reason?.stack ? '' )[ ... 500 ]
      OPS.log message
      # @exit_handler event.reason
      OPS.open_devtools()
      return true
  else
    process.on 'uncaughtException',  @exit_handler
    process.on 'unhandledRejection', @exit_handler

