

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/EXPERIMENTS/SPAWN'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND



#===========================================================================================================
# SPAWN
#-----------------------------------------------------------------------------------------------------------
@spawn_collect = ( P..., handler ) ->
  #.........................................................................................................
  $on_data = =>
    command   = null
    stderr    = []
    stdout    = []
    return @$watch ( event ) =>
      [ key, value, ] = event
      switch key
        when 'command'  then  command = value
        when 'stdout'   then  stdout.push value
        when 'stderr'   then  stderr.push value
        when 'exit'     then  return handler null, Object.assign { command, stdout, stderr, }, value
        else throw new Error "µ37718 internal error 2201991"
      return null
  #.........................................................................................................
  source    = @spawn P...
  pipeline  = []
  #.........................................................................................................
  pipeline.push source
  pipeline.push $on_data()
  pipeline.push @$drain()
  #.........................................................................................................
  pull pipeline...
  return null

#-----------------------------------------------------------------------------------------------------------
@spawn = ( P... ) -> ( @_spawn P... )[ 1 ]

#-----------------------------------------------------------------------------------------------------------
@_spawn = ( command, settings ) ->
  #.........................................................................................................
  switch arity = arguments.length
    when 1, 2 then null
    else throw new Error "µ38483 expected 1 or 2 arguments, got #{arity}"
  #.........................................................................................................
  # throw new Error "µ39248 deprecated setting: error_to_exit" if ( pluck settings, 'error_to_exit',  null )?
  # stderr_target     = pluck settings, 'stderr', 'stderr'
  settings          = Object.assign { shell: yes, }, settings
  stdout_is_binary  = pluck settings, 'binary',         no
  comments          = pluck settings, 'comments',       {}
  on_data           = pluck settings, 'on_data',        null
  error_to_exit     = pluck settings, 'error_to_exit',  no
  command_source    = @new_value_source [ [ 'command', command, ] ]
  #.........................................................................................................
  switch command_type = CND.type_of command
    when 'text'
      cp = CP.spawn command, settings
    when 'list'
      unless command.length > 0
        throw new Error "µ40013 expected a list with at least one value, got #{rpr command}"
      cp = CP.spawn command[ 0 ], command[ 1 .. ], settings
    else throw new Error "µ40778 expected a text or a list for command, got #{command_type}"
  #.........................................................................................................
  stdout            = STPS.source cp.stdout
  stderr            = STPS.source cp.stderr
  #.........................................................................................................
  stdout_pipeline   = []
  stderr_pipeline   = []
  funnel            = []
  event_pipeline    = []
  event_buffer      = []
  #.........................................................................................................
  stdout_pipeline.push stdout
  stdout_pipeline.push @$split() unless stdout_is_binary
  # stdout_pipeline.push @async_map ( data, handler ) -> defer -> handler null, data
  stdout_pipeline.push @map ( line ) -> [ 'stdout', line, ]
  #.........................................................................................................
  stderr_pipeline.push stderr
  stderr_pipeline.push @$split()
  # stderr_pipeline.push @$show title: '**44321**'
  # stderr_pipeline.push @async_map ( data, handler ) -> defer -> handler null, data
  stderr_pipeline.push @map ( line ) -> [ 'stderr', line, ]
  #.........................................................................................................
  ### Event handling: collect all events from child process ###
  cp.on 'disconnect',                   => event_buffer.push [ 'disconnect',  null,          ]
  ### TAINT exit and error events should use same method to do post-processing ###
  cp.on 'error',      ( error )         => event_buffer.push [ 'error',       error ? null,  ]
  cp.on 'exit',       ( code, signal )  =>
    # debug '77100-1'
    code      = ( 128 + ( @_spawn._signals_and_codes[ signal ] ? 0 ) ) if signal? and not code?
    # debug '77100-2'
    comment   = comments[ code ] ? @_spawn._codes_and_comments[ code ] ? signal
    # debug '77100-3'
    comment  ?= if code is 0 then 'ok' else comments[ 'error' ] ? 'error'
    # debug '77100-4'
    event_buffer.push [ 'exit',   { code, signal, comment, },  ]
  #.......................................................................................................
  ### The 'close' event should always come last, so we use that to trigger asynchronous sending of
  all events collected in the signal buffer. See https://github.com/dominictarr/pull-cont ###
  event_pipeline.push pull_cont ( handler ) =>
    cp.on 'close', =>
      handler null, @new_value_source event_buffer
      return null
  #.........................................................................................................
  ### Since reading from a spawned process is inherently asynchronous, we cannot be sure all of the output
  from stdout and stderr has been sent down the pipeline before events from the child process arrive.
  Therefore, we have to buffer those events and send them on only when the confluence stream has indicated
  exhaustion: ###
  $ensure_event_order = =>
    cp_buffer     = []
    std_buffer    = []
    command_sent  = no
    return @$ 'null', ( event, send ) =>
      if event?
        [ category, ] = event
        ### Events from stdout and stderr are buffered until the command event has been sent; after that,
        they are sent immediately: ###
        if category in [ 'stdout', 'stderr', ]
          # debug '10921>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>', command_sent, std_buffer
          # send [ 'stderr', '!!!!!!!!!!!!!!!', ]
          if command_sent
            return if on_data? then on_data event else send event
          return std_buffer.push event
        ### The command event is sent right away; any buffered stdout, stderr events are flushed: ###
        if category is 'command'
          command_sent = yes
          send event
          while std_buffer.length > 0
            if on_data? then on_data std_buffer.shift() else send std_buffer.shift()
          return
        ### Keep everything else (i.e. events from child process) for later: ###
        cp_buffer.push event
      else
        ### Send all buffered CP events: ###
        send cp_buffer.shift() while cp_buffer.length > 0
        # if on_data? then on_data std_buffer.shift() else send std_buffer.shift()
      return null
  #.........................................................................................................
  confluence = pull_many [
    ( pull command_source     )
    ( pull stdout_pipeline... )
    ( pull stderr_pipeline... )
    ( pull event_pipeline...  )
    ]
  #.........................................................................................................
  funnel.push confluence
  funnel.push $ensure_event_order()
  # funnel.push @$show title: '**21129**'
  #.........................................................................................................
  if error_to_exit
    funnel.push do =>
      error = []
      return @$ ( event, send ) =>
        if event?
          [ key, value, ] = event
          switch key
            when 'command', 'stdout'  then send event
            when 'stderr'             then error.push value.trimRight()
            when 'exit'
              value.error = error.join '\n'
              value.error = null if value.error.length is 0
              send event
            else throw new Error "µ41543 internal error 110918"
  #.........................................................................................................
  source = pull funnel...
  return [ cp, source, ]

#-----------------------------------------------------------------------------------------------------------
@_spawn._signals_and_codes = {
  SIGHUP: 1, SIGINT: 2, SIGQUIT: 3, SIGILL: 4, SIGTRAP: 5, SIGABRT: 6, SIGIOT: 6, SIGBUS: 7, SIGFPE: 8,
  SIGKILL: 9, SIGUSR1: 10, SIGSEGV: 11, SIGUSR2: 12, SIGPIPE: 13, SIGALRM: 14, SIGTERM: 15, SIGSTKFLT: 16,
  SIGCHLD: 17, SIGCONT: 18, SIGSTOP: 19, SIGTSTP: 20, SIGTTIN: 21, SIGTTOU: 22, SIGURG: 23, SIGXCPU: 24,
  SIGXFSZ: 25, SIGVTALRM: 26, SIGPROF: 27, SIGWINCH: 28, SIGIO: 29, SIGPOLL: 29, SIGPWR: 30, SIGSYS: 31, }

#-----------------------------------------------------------------------------------------------------------
@_spawn._codes_and_comments =
  # 1:      'an error has occurred'
  126:    'permission denied'
  127:    'command not found'

