

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'STEAMPIPES/EXPERIMENTS/ITO'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
{ jr }                    = CND
#...........................................................................................................
{ isa
  validate
  type_of }               = require './types'


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
### Signals are special values that, when sent down the pipeline, may alter behavior: ###
@signals = Object.freeze
  last:             Symbol 'last'             # Used to signal last data item
  # end:              Symbol 'end'              # Request stream to terminate

#-----------------------------------------------------------------------------------------------------------
### Marks are special values that identify types, behavior of pipeline elements etc: ###
@marks = Object.freeze
  steampipes:       Symbol 'steampipes'       # Marks steampipes objects
  # validated:        Symbol 'validated'        # Marks a validated sink
  # isa_duct:         Symbol 'isa_duct'         # Marks a duct as such
  # isa_pusher:       Symbol 'isa_pusher'       # Marks a push source as such
  # send_last:        Symbol 'send_last'        # Marks transforms expecting a certain value before EOS
  # async:            Symbol 'async'            # Marks transforms as asynchronous (experimental)
@seal = Symbol 'steampipes'

#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@remit  = @$ = ( modifiers..., transform ) ->
  validate.function transform
  throw new Error "µ20123 transform arity #{arity} not implemented" unless ( arity = transform.length ) is 2
  return @modify modifiers..., transform if modifiers.length > 0
  o     = []
  send  = sink.push
  t     = ( d, send ) -> transform d, send
  return { [@seal], t, o, send, }

# #-----------------------------------------------------------------------------------------------------------
# @$async = ( method ) ->
#   ### TAINT incomplete implementation: surround, leapfrog arguments missing ###
#   throw new Error "µ77644 surround arguments not yet implemented" unless arguments.length is 1
#   throw new Error "µ77644 method arity #{arity} not implemented" unless ( arity = method.length ) is 3
#   resolve = null
#   done    = ->
#     throw new Error "µ82081 arguments not allowed" unless arguments.length is 0
#     resolve()
#   R = ( d, send ) => return new Promise ( resolve_ ) =>
#     resolve = resolve_
#     await method d, send, done
#   R[ @marks.async ] = @marks.async
#   return R

# #-----------------------------------------------------------------------------------------------------------
# @_classify_sink = ( transform ) ->
#   @_$drain transform unless transform[ @marks.validated ]?
#   R = { type: 'sink', }

# #-----------------------------------------------------------------------------------------------------------
# @_classify_transform = ( transform ) ->
#   R = do =>
#     return { type: transform.type,              } if transform[ @marks.isa_duct   ]?
#     return { type: 'source', isa_pusher: true,  } if transform[ @marks.isa_pusher ]?
#     return { type: 'source',                    } if transform[ Symbol.iterator   ]?
#     return @_classify_sink transform              if ( isa.object transform ) and transform.sink?
#     switch type = type_of transform
#       when 'function'           then return { type: 'through', }
#       when 'generatorfunction'  then return { type: 'source', must_call: true, }
#     throw new Error "µ44521 expected an iterable, a function, a generator function or a sink, got a #{type}"
#   R.mode = if transform[ @marks.async ]? then 'async' else 'sync'
#   return R

# #-----------------------------------------------------------------------------------------------------------
# @_flatten_transforms = ( transforms, R = null ) ->
#   R ?= []
#   for transform in transforms
#     if transform[ @marks.isa_duct ]?
#       ### TAINT necessary to do this recursively? ###
#       R.push t for t in transform.transforms
#     else
#       R.push transform
#   return R

# #-----------------------------------------------------------------------------------------------------------
# @_new_duct = ( transforms ) ->
#   transforms  = @_flatten_transforms transforms
#   blurbs      = ( @_classify_transform transform for transform in transforms )
#   R           = { [@marks.steampipes], [@marks.isa_duct], transforms, blurbs, }
#   R.mode      = if ( blurbs.some ( blurb ) -> blurb.mode is 'async' ) then 'async' else 'sync'
#   if transforms.length is 0
#     R.is_empty = true
#     return R
#   #.........................................................................................................
#   R.first = blurbs[ 0 ]
#   if transforms.length is 1
#     R.is_single   = true
#     R.last        = R.first
#     R.type        = R.first.type
#   else
#     R.last        = blurbs[ transforms.length - 1 ]
#     switch key = "#{R.first.type}/#{R.last.type}"
#       when 'source/through'   then R.type = 'source'
#       when 'through/sink'     then R.type = 'sink'
#       when 'through/through'  then R.type = 'through'
#       when 'source/sink'      then R.type = 'circuit'
#       else throw new Error "µ44521 illegal duct configuration #{rpr key}"
#     for idx in [ 1 ... blurbs.length - 1 ] by +1
#       unless ( b = blurbs[ idx ] ).type is 'through'
#         throw new Error "µ44522 illegal duct configuration at transform index #{idx}: #{rpr b}"
#   return R

# #-----------------------------------------------------------------------------------------------------------
# @_pull = ( transforms... ) ->
#   duct                  = @_new_duct transforms
#   { transforms, }       = duct
#   original_source       = null
#   throw new Error "µ77764 source as last transform not yet supported" if duct.last.type  is 'source'
#   throw new Error "µ77765 sink as first transform not yet supported"  if duct.first.type is 'sink'
#   #.........................................................................................................
#   if duct.first.type is 'source'
#     transforms[ 0 ] = transforms[ 0 ]() if duct.first.must_call
#     source          = transforms[ 0 ]
#   #.........................................................................................................
#   return duct unless duct.type is 'circuit'
#   #.........................................................................................................
#   drain                 = transforms[ transforms.length - 1 ]
#   duct.buckets          = buckets = ( transforms[ idx ].sink for idx in [ 1 ... transforms.length - 1 ] )
#   debug 'µ12009', transforms
#   duct.buckets.push drain.sink if drain.use_sink
#   duct.has_ended        = false
#   local_sink            = null
#   local_source          = null
#   has_local_sink        = null
#   last                  = @signals.last
#   last_transform_idx    = buckets.length - if drain.use_sink then 2 else 1
#   tf_idxs               = [ 0 .. last_transform_idx ]
#   #.........................................................................................................
#   send = ( d ) =>
#     return duct.has_ended = true if d is @signals.end
#     local_sink.push d if has_local_sink
#     return null
#   send.end = => duct.has_ended = true
#   #.........................................................................................................
#   exhaust_pipeline = =>
#     loop
#       data_count    = 0
#       # for transform, idx in transforms
#       for idx in tf_idxs
#         continue if ( local_source = buckets[ idx ] ).length is 0
#         transform       = transforms[  idx + 1 ]
#         local_sink      = buckets[ idx + 1 ]
#         has_local_sink  = local_sink?
#         d               = local_source.shift()
#         data_count     += local_source.length
#         if d is last
#           transform d, send if transform[ @marks.send_last ]?
#           send last unless idx is last_transform_idx
#         else
#           transform d, send
#       break if data_count is 0
#     return null
#   #.........................................................................................................
#   exhaust_async_pipeline = =>
#     loop
#       data_count    = 0
#       # for transform, idx in transforms
#       for idx in tf_idxs
#         continue if ( local_source = buckets[ idx ] ).length is 0
#         transform       = transforms[  idx + 1 ]
#         local_sink      = buckets[ idx + 1 ]
#         has_local_sink  = local_sink?
#         d               = local_source.shift()
#         data_count     += local_source.length
#         if transform[ @marks.async ]?
#           if d is last
#             await transform d, send if transform[ @marks.send_last ]?
#             send last unless idx is last_transform_idx
#           else
#             await transform d, send
#         else
#           if d is last
#             transform d, send if transform[ @marks.send_last ]?
#             send last unless idx is last_transform_idx
#           else
#             transform d, send
#       break if data_count is 0
#     return null
#   #.........................................................................................................
#   duct.send                   = send
#   duct.exhaust_pipeline       = exhaust_pipeline
#   duct.exhaust_async_pipeline = exhaust_async_pipeline
#   #.........................................................................................................
#   return duct

# #-----------------------------------------------------------------------------------------------------------
# @pull = ( transforms... ) ->
#   duct = @_pull transforms...
#   return duct unless duct.type is 'circuit'
#   return @_pull_async duct if duct.mode is 'async'
#   return @_push duct if duct.transforms[ 0 ][ @marks.isa_pusher ]?
#   first_bucket = duct.buckets[ 0 ]
#   #.........................................................................................................
#   for d from duct.transforms[ 0 ]
#     break if duct.has_ended
#     # continue if d is @signals.discard
#     first_bucket.push d
#     duct.exhaust_pipeline()
#   #.........................................................................................................
#   first_bucket.push @signals.last
#   duct.exhaust_pipeline()
#   drain = duct.transforms[ duct.transforms.length - 1 ]
#   if ( on_end = drain.on_end )?
#     if drain.call_with_datoms then drain.on_end drain.sink else drain.on_end()
#   return duct

# #-----------------------------------------------------------------------------------------------------------
# @_pull_async = ( duct ) ->
#   return duct unless duct.type is 'circuit'
#   return @_push duct if duct.transforms[ 0 ][ @marks.isa_pusher ]?
#   first_bucket = duct.buckets[ 0 ]
#   #.........................................................................................................
#   for d from duct.transforms[ 0 ]
#     break if duct.has_ended
#     # continue if d is @signals.discard
#     first_bucket.push d
#     await duct.exhaust_async_pipeline()
#   #.........................................................................................................
#   first_bucket.push @signals.last
#   await duct.exhaust_async_pipeline()
#   drain = duct.transforms[ duct.transforms.length - 1 ]
#   if ( on_end = drain.on_end )?
#     if drain.call_with_datoms then drain.on_end drain.sink else drain.on_end()
#   return duct

# #-----------------------------------------------------------------------------------------------------------
# @_push = ( duct ) ->
#   ### Make `duct` available from the POV of the push source: ###
#   source        = duct.transforms[ 0 ]
#   source.duct   = duct
#   ### copy buffered data (from before when `pull()` was called) to `source`: ###
#   first_bucket  = duct.buckets[ 0 ]
#   first_bucket.splice first_bucket.length, 0, source.buffer...
#   ### Process any data as may have accumulated at this point: ###
#   if duct.mode is 'async' then  await duct.exhaust_async_pipeline()
#   else                          duct.exhaust_pipeline()
#   return null


