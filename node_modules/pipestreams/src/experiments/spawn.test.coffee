

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/TESTS/SPAWN'
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
TAP                       = require 'tap'
# TAP                       = require 'tape'
#...........................................................................................................
PS                        = require '../..'
{ $, $async, }            = PS.export()
#...........................................................................................................
jr                        = JSON.stringify
# { step, }                 = require 'coffeenode-suspend'


#-----------------------------------------------------------------------------------------------------------
TAP.test "spawn 1", ( T ) ->
# do ->
  # new_pushable              = require 'pull-pushable'
  # source            = new_pushable()
  #.........................................................................................................
  on_error = ( error ) ->
    warn '20191', error.message
      # throw error
  #.........................................................................................................
  command           = 'ls -AlF'
  source            = PS.spawn command, { on_error, cwd: '/tmp', }
  on_stop           = PS.new_event_collector 'stop', -> T.end()
  #.........................................................................................................
  pipeline = []
  pipeline.push source
  pipeline.push PS.$watch   ( data ) -> whisper '10901-1', rpr data
  pipeline.push PS.$filter  ( data ) -> data[ 0 ] is 'stdout'
  pipeline.push $           ( data, send ) -> send data[ 1 ]
  # pipeline.push PS.$split()
  # pipeline.push PS.$show title: '==='
  pipeline.push PS.$collect()
  pipeline.push PS.$watch ( lines ) -> help '10901-2', lines
  pipeline.push on_stop.add PS.$drain()
  #.........................................................................................................
  PS.pull pipeline...
  return null

#-----------------------------------------------------------------------------------------------------------
TAP.test "spawn 2", ( T ) ->
  probes_and_matchers = [
    ["xxx ; echo \"helo\" && exit 1","CDDX",{"code":1,"signal":null,"comment":"error"},"helo","/bin/sh: xxx: command not found"]
    ["xxx ; echo \"helo\" && exit 0","CDDX",{"code":0,"signal":null,"comment":"ok"},"helo","/bin/sh: xxx: command not found"]
    ["xxx ; echo \"helo\"","CDDX",{"code":0,"signal":null,"comment":"ok"},"helo","/bin/sh: xxx: command not found"]
    ["xxx && echo \"helo\"","CDX",{"code":127,"signal":null,"comment":"command not found"},"","/bin/sh: xxx: command not found"]
    ["exit 111","CX",{"code":111,"signal":null,"comment":"error"},"",""]
    ["ls package.json && echo_to_stderr() { cat <<< \"$@\" 1>&2; }; echo_to_stderr what","CDDX",{"code":0,"signal":null,"comment":"ok"},"package.json","what"]
    ["( >&2 echo \"error\" )","CDX",{"code":0,"signal":null,"comment":"ok"},"","error"]
    ["echo_to_stderr() { cat <<< \"$@\" 1>&2; }; echo_to_stderr what; echo else; sleep 1; kill -9 $$","CDDX",{"code":137,"signal":"SIGKILL","comment":"SIGKILL"},"else","what"]
    ["kill -2 $$","CX",{"code":130,"signal":"SIGINT","comment":"SIGINT"},"",""]
    ["/dev/null","CDX",{"code":126,"signal":null,"comment":"permission denied"},"","/bin/sh: /dev/null: Permission denied"]
    ["exit 130","CX",{"code":130,"signal":null,"comment":"error"},"",""]
    ["bonkers","CDX",{"code":127,"signal":null,"comment":"command not found"},"","/bin/sh: bonkers: command not found"]
    ["bonkers 2>&1; exit 0","CDX",{"code":0,"signal":null,"comment":"ok"},"/bin/sh: bonkers: command not found",""]
    ["bonkers; echo \"success!\"; exit 0","CDDX",{"code":0,"signal":null,"comment":"ok"},"success!","/bin/sh: bonkers: command not found"]
    ["bonkers; echo \"success!\"; kill -27 $$","CDDX",{"code":155,"signal":"SIGPROF","comment":"SIGPROF"},"success!","/bin/sh: bonkers: command not found"]
    ["echo helo","CDX",{"code":0,"signal":null,"comment":"ok"},"helo",""]
    [["echo","helo"],"CDX",{"code":0,"signal":null,"comment":"ok"},"helo",""]
    ["bonkers","CDX",{"code":127,"signal":null,"comment":"command not found"},"","/bin/sh: bonkers: command not found"]
    [["bonkers"],"CDX",{"code":127,"signal":null,"comment":"command not found"},"","/bin/sh: bonkers: command not found"]
    [["exit","2"],"CX",{"code":2,"signal":null,"comment":"error"},"",""]
    ]
  #.........................................................................................................
  tasks = []
  next  = ->
    tasks.shift()
    return T.end() if tasks.length is 0
    tasks[ 0 ]()
    # tasks[ 13 ]()
  #.........................................................................................................
  for probe_and_matcher in probes_and_matchers
    do ( probe_and_matcher ) ->
      [ command, shape_matcher, exit_matcher, out_matcher, err_matcher, ] = probe_and_matcher
      tasks.push ->
        # echo '-----------------------------------------------------------------'
        shape       = []
        out         = []
        err         = []
        exit        = undefined
        command_ok  = no
        #...................................................................................................
        on_stop = PS.new_event_collector 'stop', ->
          shape   = shape.join ''
          out     = out.join '\n'
          err     = err.join '\n'
          T.ok command_ok
          T.equal shape,  shape_matcher,  "shape,  shape_matcher"
          T.ok ( CND.equals  exit, exit_matcher ), "exit,   exit_matcher"
          T.equal out,    out_matcher,    "out,    out_matcher"
          T.equal err,    err_matcher,    "err,    err_matcher"
          # urge '20911', jr [ command, shape, exit, out, err, ]
          next()
        #...................................................................................................
        source    = PS.spawn command
        pipeline  = []
        pipeline.push source
        pipeline.push PS.$watch ( [ key, value, ] ) ->
          switch key
            when 'command'          then  shape.push 'C'
            when 'stdout', 'stderr' then  shape.push 'D'
            when 'exit'             then  shape.push 'X'
            else                          shape.push '?'
        pipeline.push PS.$watch ( [ key, value, ] ) -> command_ok = yes if key is 'command' and value is command
        pipeline.push PS.$watch ( [ key, value, ] ) ->
          switch key
            when 'stdout' then  out.push value
            when 'stderr' then  err.push value
            when 'exit'   then  exit = value
        # pipeline.push PS.$show()
        pipeline.push PS.$collect()
        pipeline.push on_stop.add PS.$drain()
        PS.pull pipeline...
  #.........................................................................................................
  tasks[ 0 ]()
  # tasks[ 13 ]()
  return null

#-----------------------------------------------------------------------------------------------------------
TAP.test "spawn 3", ( T ) ->
  probes_and_matchers = [
    ["bonkers; echo \"success!\"; kill -27 $$","CDX",{"code":155,"signal":"SIGPROF","comment":"SIGPROF","error":"/bin/sh: bonkers: command not found"},"success!",""]
    ["echo \"success!\"; kill -27 $$","CDX",{"code":155,"signal":"SIGPROF","comment":"SIGPROF","error":null},"success!",""]
    ["echo \"success!\"; exit 1","CDX",{"code":1,"signal":null,"comment":"error","error":null},"success!",""]
    ["echo \"success!\"; exit 0","CDX",{"code":0,"signal":null,"comment":"ok","error":null},"success!",""]
    ["1>&2 echo 'problem!'","CX",{"code":0,"signal":null,"comment":"ok","error":"problem!"},"",""]
    ]
  #.........................................................................................................
  tasks = []
  next  = ->
    tasks.shift()
    return T.end() if tasks.length is 0
    tasks[ 0 ]()
    # tasks[ 13 ]()
  #.........................................................................................................
  for probe_and_matcher in probes_and_matchers
    do ( probe_and_matcher ) ->
      [ command, shape_matcher, exit_matcher, out_matcher, err_matcher, ] = probe_and_matcher
      tasks.push ->
        shape       = []
        out         = []
        err         = []
        exit        = undefined
        #...................................................................................................
        on_stop   = PS.new_event_collector 'stop', ->
          shape = shape.join ''
          out   = out.join '\n'
          err   = err.join '\n'
          T.equal shape,  shape_matcher,          "shape,  shape_matcher"
          T.ok ( CND.equals exit, exit_matcher ), "exit,   exit_matcher"
          T.equal out,    out_matcher,    "out,    out_matcher"
          T.equal err,    err_matcher,    "err,    err_matcher"
          # debug jr [ command, shape, exit, out, err, ]
          next()
        #...................................................................................................
        source    = PS.spawn command, { error_to_exit: yes, }
        pipeline  = []
        pipeline.push source
        pipeline.push PS.$watch ( [ key, value, ] ) ->
          switch key
            when 'command'          then  shape.push 'C'
            when 'stdout', 'stderr' then  shape.push 'D'
            when 'exit'             then  shape.push 'X'
            else                          shape.push '?'
        pipeline.push PS.$watch ( [ key, value, ] ) ->
          switch key
            when 'stdout' then  out.push value
            when 'stderr' then  err.push value
            when 'exit'   then  exit = value
        # pipeline.push PS.$collect()
        # pipeline.push PS.$show()
        pipeline.push on_stop.add PS.$drain()
        PS.pull pipeline...
  #.........................................................................................................
  tasks[ 0 ]()
  # tasks[ 13 ]()
  return null

#-----------------------------------------------------------------------------------------------------------
TAP.test "spawn_collect 1", ( T ) ->
  probes_and_matchers = [
    ["bonkers; echo \"success!\"; kill -27 $$",{"command":"bonkers; echo \"success!\"; kill -27 $$","stdout":["success!"],"stderr":["/bin/sh: bonkers: command not found"],"code":155,"signal":"SIGPROF","comment":"SIGPROF"}]
    ["echo \"success!\"; kill -27 $$",{"command":"echo \"success!\"; kill -27 $$","stdout":["success!"],"stderr":[],"code":155,"signal":"SIGPROF","comment":"SIGPROF"}]
    ["echo \"success!\"; exit 1",{"command":"echo \"success!\"; exit 1","stdout":["success!"],"stderr":[],"code":1,"signal":null,"comment":"error"}]
    ["echo \"success!\"; bonkers",{"command":"echo \"success!\"; bonkers","stdout":["success!"],"stderr":["/bin/sh: bonkers: command not found"],"code":127,"signal":null,"comment":"command not found"}]
    ["1>&2 echo 'problem!'",{"command":"1>&2 echo 'problem!'","stdout":[],"stderr":["problem!"],"code":0,"signal":null,"comment":"ok"}]
    ]
  #.........................................................................................................
  tasks = []
  next  = ->
    tasks.shift()
    return T.end() if tasks.length is 0
    tasks[ 0 ]()
    # tasks[ 13 ]()
  #.........................................................................................................
  for probe_and_matcher in probes_and_matchers
    do ( probe_and_matcher ) ->
      [ probe, matcher, ] = probe_and_matcher
      tasks.push ->
        #...................................................................................................
        step ( resume ) ->
          #.................................................................................................
          result = yield PS.spawn_collect probe, resume
          T.ok ( CND.equals result, matcher ), "result and matcher"
          # urge jr [ probe, result, ]
          next()
  #.........................................................................................................
  tasks[ 0 ]()
  # tasks[ 13 ]()
  return null

#-----------------------------------------------------------------------------------------------------------
TAP.test "spawn_collect with data callback", ( T ) ->
  probes_and_matchers = [
    ["bonkers; echo \"success!\"; kill -27 $$",{"command":"bonkers; echo \"success!\"; kill -27 $$","stdout":[],"stderr":[],"code":155,"signal":"SIGPROF","comment":"SIGPROF"},[["stderr","/bin/sh: bonkers: command not found"],["stdout","success!"]]]
    ["echo \"success!\"; kill -27 $$",{"command":"echo \"success!\"; kill -27 $$","stdout":[],"stderr":[],"code":155,"signal":"SIGPROF","comment":"SIGPROF"},[["stdout","success!"]]]
    ["echo \"success!\"; exit 1",{"command":"echo \"success!\"; exit 1","stdout":[],"stderr":[],"code":1,"signal":null,"comment":"error"},[["stdout","success!"]]]
    ["echo \"success!\"; bonkers",{"command":"echo \"success!\"; bonkers","stdout":[],"stderr":[],"code":127,"signal":null,"comment":"command not found"},[["stderr","/bin/sh: bonkers: command not found"],["stdout","success!"]]]
    ["1>&2 echo 'problem!'",{"command":"1>&2 echo 'problem!'","stdout":[],"stderr":[],"code":0,"signal":null,"comment":"ok"},[["stderr","problem!"]]]
    ]
  #.........................................................................................................
  tasks = []
  next  = ->
    return T.end() if tasks.length < 1
    tasks.shift()()
  #.........................................................................................................
  for probe_and_matcher in probes_and_matchers
    do ( probe_and_matcher ) ->
      [ probe, reply_matcher, events_matcher, ] = probe_and_matcher
      tasks.push ->
        #...................................................................................................
        # echo '---------------------------------------------------------------------------'
        step ( resume ) ->
          events = []
          on_data = ( event ) -> events.push event
          reply   = yield PS.spawn_collect probe, { on_data, }, resume
          events.sort()
          T.ok ( CND.equals reply,  reply_matcher   ), "reply and reply_matcher"
          T.ok ( CND.equals events, events_matcher  ), "events and events_matcher"
          # urge jr [ probe, reply, events, ]
          next()
  #.........................................................................................................
  next()
  # tasks[ 0 ]()
  return null



