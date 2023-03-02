

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'STEAMPIPES/TESTS/TEE'
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
PATH                      = require 'path'
FS                        = require 'fs'
OS                        = require 'os'
test                      = require 'guy-test'
#...........................................................................................................
SP                        = require '../../..'
{ $, $async, }            = SP
#...........................................................................................................
read                      = ( path ) -> FS.readFileSync path, { encoding: 'utf-8', }


# #-----------------------------------------------------------------------------------------------------------
# @[ "tee and stop events" ] = ( T, done ) ->
#   sink_0_path       = '/tmp/pipestreams-test-tee-0.txt'
#   sink_1_path       = '/tmp/pipestreams-test-tee-1.txt'
#   sink_2_path       = '/tmp/pipestreams-test-tee-2.txt'
#   #.........................................................................................................
#   sink_0_finished   = false
#   sink_1_finished   = false
#   sink_2_finished   = false
#   #.........................................................................................................
#   sink_0 = SP.write_to_file sink_0_path, ( error ) =>
#     throw error if error
#     sink_0_finished = true
#     finish()
#   #.........................................................................................................
#   sink_1 = SP.write_to_file sink_1_path, ( error ) =>
#     throw error if error
#     sink_1_finished = true
#     finish()
#   #.........................................................................................................
#   sink_2 = SP.write_to_file sink_2_path, ( error ) =>
#     throw error if error
#     sink_2_finished = true
#     finish()
#   #.........................................................................................................
#   $link       = ( linker )  -> SP.$map    ( value  ) -> ( JSON.stringify value ) + linker
#   $keep_odd   =             -> SP.$filter ( number ) -> number % 2 isnt 0
#   $keep_even  =             -> SP.$filter ( number ) -> number % 2 is   0
#   #.........................................................................................................
#   finish = ->
#     if sink_0_finished then help "sink_0 finished" else warn "waiting for sink_0"
#     if sink_1_finished then help "sink_1 finished" else warn "waiting for sink_1"
#     if sink_2_finished then help "sink_2 finished" else warn "waiting for sink_2"
#     whisper '----------------------'
#     return unless sink_0_finished and sink_1_finished and sink_2_finished
#     T.ok CND.equals ( read sink_0_path ), '0-1-2-3-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-20-'
#     T.ok CND.equals ( read sink_1_path ), '1*3*5*7*9*11*13*15*17*19*'
#     T.ok CND.equals ( read sink_2_path ), '0+2+4+6+8+10+12+14+16+18+20+'
#     done()
#   #.........................................................................................................
#   pipeline_1  = []
#   pipeline_1.push $keep_odd()
#   pipeline_1.push $link '*'
#   pipeline_1.push sink_1
#   stream_1 = SP.pull pipeline_1...
#   #.........................................................................................................
#   pipeline_2  = []
#   pipeline_2.push $keep_even()
#   pipeline_2.push $link '+'
#   pipeline_2.push sink_2
#   stream_2 = SP.pull pipeline_2...
#   #.........................................................................................................
#   pipeline_0  = []
#   pipeline_0.push SP.new_value_source ( n for n in [ 0 .. 20 ] )
#   pipeline_0.push SP.$tee stream_1
#   pipeline_0.push SP.$tee stream_2
#   pipeline_0.push $link '-'
#   pipeline_0.push sink_0
#   #.........................................................................................................
#   stream_0 = SP.pull pipeline_0...
#   # SP.pull pipeline_1...
#   #.........................................................................................................
#   return null

#-----------------------------------------------------------------------------------------------------------
@[ "tee and stop events, 'collective' API" ] = ( T, done ) ->
  wait_count        = 3
  #.........................................................................................................
  sink_0_path       = '/tmp/pipestreams-test-tee-0.txt'
  sink_1_path       = '/tmp/pipestreams-test-tee-1.txt'
  sink_2_path       = '/tmp/pipestreams-test-tee-2.txt'
  #.........................................................................................................
  sink_0            = SP.write_to_file sink_0_path, ( error ) ->
    throw error if error?
    file_contents = read sink_0_path
    debug '77783-1', rpr file_contents
    T.ok CND.equals file_contents, '0-1-2-3-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-20-'
    wait_count += -1
    done() if wait_count <= 0
  #.........................................................................................................
  sink_1            = SP.write_to_file sink_1_path, ( error ) ->
    throw error if error?
    file_contents = read sink_1_path
    debug '77783-2', rpr file_contents
    T.ok CND.equals file_contents, '1*3*5*7*9*11*13*15*17*19*'
    wait_count += -1
    done() if wait_count <= 0
  #.........................................................................................................
  sink_2            = SP.write_to_file sink_2_path, ( error ) ->
    throw error if error?
    file_contents = read sink_2_path
    debug '77783-3', rpr file_contents
    T.ok CND.equals file_contents, '0+2+4+6+8+10+12+14+16+18+20+'
    wait_count += -1
    done() if wait_count <= 0
  #.........................................................................................................
  $link       = ( linker )  -> SP.$map    ( value  ) -> ( JSON.stringify value ) + linker
  $keep_odd   =             -> SP.$filter ( number ) -> number % 2 isnt 0
  $keep_even  =             -> SP.$filter ( number ) -> number % 2 is   0
  #.........................................................................................................
  pipeline_1  = []
  pipeline_1.push $keep_odd()
  pipeline_1.push $link '*'
  pipeline_1.push sink_1
  stream_1 = SP.pull pipeline_1...
  #.........................................................................................................
  pipeline_2  = []
  pipeline_2.push $keep_even()
  pipeline_2.push $link '+'
  pipeline_2.push sink_2
  stream_2 = SP.pull pipeline_2...
  #.........................................................................................................
  pipeline_0  = []
  pipeline_0.push SP.new_value_source ( n for n in [ 0 .. 20 ] )
  pipeline_0.push SP.$tee stream_1
  pipeline_0.push SP.$tee stream_2
  pipeline_0.push $link '-'
  pipeline_0.push sink_0
  #.........................................................................................................
  SP.pull pipeline_0...
  return null

############################################################################################################
unless module.parent?
  test @

