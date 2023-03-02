


############################################################################################################
rpr                       = ( require 'util' ).inspect
#...........................................................................................................
# probes                    = require './probes'
@_width_of_string         = require 'string-width'
@_Wcstring                = require 'wcstring'
self                      = @
ƒ                         = ( method ) -> method.bind self

#-----------------------------------------------------------------------------------------------------------
@to_width = ƒ ( text, width, settings ) ->
  ### Fit text into `width` columns, taking into account ANSI color codes (that take up bytes but not width)
  and double-width glyphs such as CJK characters. ###
  throw new Error "width must at least be 2, got #{width}" unless width >= 2
  padder        = settings?[ 'padder'   ] ? ' '
  ellipsis      = settings?[ 'ellipsis' ] ? '…'
  align         = settings?[ 'align'    ] ? 'left'
  R             = text
  old_width     = @width_of R
  return R if old_width is width
  #.........................................................................................................
  if old_width > ( width_1 = width - 1)
    ### `WCString` occasionally is off by one, so here we fix that: ###
    R = ( new @_Wcstring text ).truncate width_1, ''
    R += ellipsis + if ( ( @width_of R ) < width_1 ) then ellipsis else ''
  #.........................................................................................................
  else
    ### TAINT assuming uncolored, single-width glyph for padding ###
    p = width - old_width
    switch align
      when 'left'   then R =                                      R + ( padder.repeat           p     )
      when 'right'  then R = ( padder.repeat            p     ) + R
      when 'center' then R = ( padder.repeat Math.floor p / 2 ) + R + ( padder.repeat Math.ceil p / 2 )
      else throw new Error "expected one of 'left, 'right'. 'center', got #{rpr align}"
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@width_of = ƒ ( text ) => @_width_of_string text





