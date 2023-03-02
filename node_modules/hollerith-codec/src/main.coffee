


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'HOLLERITH-CODEC/MAIN'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
#...........................................................................................................
@types                    = require './types'
{ isa
  validate
  cast
  declare
  size_of
  type_of }               = @types
VOID                      = Symbol 'VOID'


#-----------------------------------------------------------------------------------------------------------
@[ 'typemarkers' ]  = {}
#...........................................................................................................
tm_lo               = @[ 'typemarkers'  ][ 'lo'         ] = 0x00
tm_null             = @[ 'typemarkers'  ][ 'null'       ] = 'B'.codePointAt 0 # 0x42
tm_false            = @[ 'typemarkers'  ][ 'false'      ] = 'C'.codePointAt 0 # 0x43
tm_true             = @[ 'typemarkers'  ][ 'true'       ] = 'D'.codePointAt 0 # 0x44
tm_list             = @[ 'typemarkers'  ][ 'list'       ] = 'E'.codePointAt 0 # 0x45
tm_date             = @[ 'typemarkers'  ][ 'date'       ] = 'G'.codePointAt 0 # 0x47
tm_ninfinity        = @[ 'typemarkers'  ][ 'ninfinity'  ] = 'J'.codePointAt 0 # 0x4a
tm_nnumber          = @[ 'typemarkers'  ][ 'nnumber'    ] = 'K'.codePointAt 0 # 0x4b
tm_void             = @[ 'typemarkers'  ][ 'void'       ] = 'L'.codePointAt 0 # 0x4c
tm_pnumber          = @[ 'typemarkers'  ][ 'pnumber'    ] = 'M'.codePointAt 0 # 0x4d
tm_pinfinity        = @[ 'typemarkers'  ][ 'pinfinity'  ] = 'N'.codePointAt 0 # 0x4e
tm_text             = @[ 'typemarkers'  ][ 'text'       ] = 'T'.codePointAt 0 # 0x54
tm_private          = @[ 'typemarkers'  ][ 'private'    ] = 'Z'.codePointAt 0 # 0x5a
tm_hi               = @[ 'typemarkers'  ][ 'hi'         ] = 0xff

#-----------------------------------------------------------------------------------------------------------
@[ 'bytecounts' ]     = {}
bytecount_singular    = @[ 'bytecounts'   ][ 'singular'   ] = 1
bytecount_typemarker  = @[ 'bytecounts'   ][ 'typemarker' ] = 1
bytecount_float       = @[ 'bytecounts'   ][ 'float'      ] = 9
bytecount_date        = @[ 'bytecounts'   ][ 'date'       ] = bytecount_float + 1

#-----------------------------------------------------------------------------------------------------------
@[ 'sentinels' ]  = {}
#...........................................................................................................
### http://www.merlyn.demon.co.uk/js-datex.htm ###
@[ 'sentinels' ][ 'firstdate' ] = new Date -8640000000000000
@[ 'sentinels' ][ 'lastdate'  ] = new Date +8640000000000000

#-----------------------------------------------------------------------------------------------------------
@[ 'keys' ]  = {}
#...........................................................................................................
@[ 'keys' ][ 'lo' ] = Buffer.alloc 1, @[ 'typemarkers' ][ 'lo' ]
@[ 'keys' ][ 'hi' ] = Buffer.alloc 1, @[ 'typemarkers' ][ 'hi' ]

#-----------------------------------------------------------------------------------------------------------
@[ 'symbols' ]  = {}
symbol_fallback = @[ 'fallback' ] = Symbol 'fallback'


#===========================================================================================================
# RESULT BUFFER (RBUFFER)
#-----------------------------------------------------------------------------------------------------------
rbuffer_min_size        = 1024
rbuffer_max_size        = 65536
rbuffer                 = Buffer.alloc rbuffer_min_size

#-----------------------------------------------------------------------------------------------------------
grow_rbuffer = ->
  factor      = 2
  new_size    = Math.floor rbuffer.length * factor + 0.5
  # warn "µ44542 growing rbuffer to #{new_size} bytes"
  new_result_buffer = Buffer.alloc new_size
  rbuffer.copy new_result_buffer
  rbuffer           = new_result_buffer
  return null

#-----------------------------------------------------------------------------------------------------------
release_extraneous_rbuffer_bytes = ->
  if rbuffer.length > rbuffer_max_size
    # warn "µ44543 shrinking rbuffer to #{rbuffer_max_size} bytes"
    rbuffer = Buffer.alloc rbuffer_max_size
  return null


#===========================================================================================================
# VARIANTS
#-----------------------------------------------------------------------------------------------------------
@write_singular = ( idx, value ) ->
  grow_rbuffer() until rbuffer.length >= idx + bytecount_singular
  if      value is null   then typemarker = tm_null
  else if value is false  then typemarker = tm_false
  else if value is true   then typemarker = tm_true
  else if value is VOID   then typemarker = tm_void
  else throw new Error "µ56733 unable to encode value of type #{type_of value}"
  rbuffer[ idx ] = typemarker
  return idx + bytecount_singular

#-----------------------------------------------------------------------------------------------------------
@read_singular = ( buffer, idx ) ->
  switch typemarker = buffer[ idx ]
    when tm_null  then value = null
    when tm_false then value = false
    when tm_true  then value = true
    ### TAINT not strictly needed as we eliminate VOID prior to decoding ###
    when tm_void  then value = VOID
    else throw new Error "µ57564 unable to decode 0x#{typemarker.toString 16} at index #{idx} (#{rpr buffer})"
  return [ idx + bytecount_singular, value, ]


#===========================================================================================================
# PRIVATES
#-----------------------------------------------------------------------------------------------------------
@write_private = ( idx, value, encoder ) ->
  grow_rbuffer() until rbuffer.length >= idx + 3 * bytecount_typemarker
  #.........................................................................................................
  rbuffer[ idx ]  = tm_private
  idx            += bytecount_typemarker
  #.........................................................................................................
  rbuffer[ idx ]  = tm_list
  idx            += bytecount_typemarker
  #.........................................................................................................
  type            = value[ 'type'  ] ? 'private'
  proper_value    = value[ 'value' ]
  #.........................................................................................................
  if encoder?
    encoded_value   = encoder type, proper_value, symbol_fallback
    proper_value    = encoded_value unless encoded_value is symbol_fallback
  #.........................................................................................................
  else if type.startsWith '-'
    ### Built-in private types ###
    switch type
      when '-set'
        null # already dealt with in `write`
      else
        throw new Error "µ58395 unknown built-in private type #{rpr type}"
  #.........................................................................................................
  wrapped_value   = [ type, proper_value, ]
  idx             = @_encode wrapped_value, idx
  #.........................................................................................................
  rbuffer[ idx ]  = tm_lo
  idx            += bytecount_typemarker
  #.........................................................................................................
  return idx

#-----------------------------------------------------------------------------------------------------------
@read_private = ( buffer, idx, decoder ) ->
  idx                        += bytecount_typemarker
  [ idx, [ type,  value, ] ]  = @read_list buffer, idx
  #.........................................................................................................
  if decoder?
    R = decoder type, value, symbol_fallback
    throw new Error "µ59226 encountered illegal value `undefined` when reading private type" if R is undefined
    R = { type, value, } if R is symbol_fallback
  #.........................................................................................................
  else if type.startsWith '-'
    ### Built-in private types ###
    switch type
      when '-set'
        ### TAINT wasting bytes because wrapped twice ###
        R = new Set value[ 0 ]
      else
        throw new Error "µ60057 unknown built-in private type #{rpr type}"
  #.........................................................................................................
  else
    R = { type, value, }
  return [ idx, R, ]


#===========================================================================================================
# NUMBERS
#-----------------------------------------------------------------------------------------------------------
@write_number = ( idx, number ) ->
  grow_rbuffer() until rbuffer.length >= idx + bytecount_float
  if number < 0
    type    = tm_nnumber
    number  = -number
  else
    type    = tm_pnumber
  rbuffer[ idx ] = type
  rbuffer.writeDoubleBE number, idx + 1
  @_invert_buffer rbuffer, idx if type is tm_nnumber
  return idx + bytecount_float

#-----------------------------------------------------------------------------------------------------------
@write_infinity = ( idx, number ) ->
  grow_rbuffer() until rbuffer.length >= idx + bytecount_singular
  rbuffer[ idx ] = if number is -Infinity then tm_ninfinity else tm_pinfinity
  return idx + bytecount_singular

#-----------------------------------------------------------------------------------------------------------
@read_nnumber = ( buffer, idx ) ->
  throw new Error "µ60888 not a negative number at index #{idx}" unless buffer[ idx ] is tm_nnumber
  copy = @_invert_buffer ( Buffer.from buffer.slice idx, idx + bytecount_float ), 0
  return [ idx + bytecount_float, -( copy.readDoubleBE 1 ), ]

#-----------------------------------------------------------------------------------------------------------
@read_pnumber = ( buffer, idx ) ->
  throw new Error "µ61719 not a positive number at index #{idx}" unless buffer[ idx ] is tm_pnumber
  return [ idx + bytecount_float, buffer.readDoubleBE idx + 1, ]

#-----------------------------------------------------------------------------------------------------------
@_invert_buffer = ( buffer, idx ) ->
  buffer[ i ] = ~buffer[ i ] for i in [ idx + 1 .. idx + 8 ]
  return buffer


#===========================================================================================================
# DATES
#-----------------------------------------------------------------------------------------------------------
@write_date = ( idx, date ) ->
  grow_rbuffer() until rbuffer.length >= idx + bytecount_date
  number          = +date
  rbuffer[ idx ]  = tm_date
  return @write_number idx + 1, number

#-----------------------------------------------------------------------------------------------------------
@read_date = ( buffer, idx ) ->
  throw new Error "µ62550 not a date at index #{idx}" unless buffer[ idx ] is tm_date
  switch type = buffer[ idx + 1 ]
    when tm_nnumber    then [ idx, value, ] = @read_nnumber    buffer, idx + 1
    when tm_pnumber    then [ idx, value, ] = @read_pnumber    buffer, idx + 1
    else throw new Error "µ63381 unknown date type marker 0x#{type.toString 16} at index #{idx}"
  return [ idx, ( new Date value ), ]


#===========================================================================================================
# TEXTS
#-----------------------------------------------------------------------------------------------------------
@write_text = ( idx, text ) ->
  text                                = text.replace /\x01/g, '\x01\x02'
  text                                = text.replace /\x00/g, '\x01\x01'
  bytecount_text                      = ( Buffer.byteLength text, 'utf-8' ) + 2
  grow_rbuffer() until rbuffer.length >= idx + bytecount_text
  rbuffer[ idx ]                      = tm_text
  rbuffer.write text, idx + 1
  rbuffer[ idx + bytecount_text - 1 ] = tm_lo
  return idx + bytecount_text

#-----------------------------------------------------------------------------------------------------------
@read_text = ( buffer, idx ) ->
  # urge '©J2d6R', buffer[ idx ], buffer[ idx ] is tm_text
  throw new Error "µ64212 not a text at index #{idx}" unless buffer[ idx ] is tm_text
  stop_idx = idx
  loop
    stop_idx += +1
    break if ( byte = buffer[ stop_idx ] ) is tm_lo
    throw new Error "µ65043 runaway string at index #{idx}" unless byte?
  R = buffer.toString 'utf-8', idx + 1, stop_idx
  R = R.replace /\x01\x01/g, '\x00'
  R = R.replace /\x01\x02/g, '\x01'
  return [ stop_idx + 1, R, ]


#===========================================================================================================
# LISTS
#-----------------------------------------------------------------------------------------------------------
@read_list = ( buffer, idx ) ->
  throw new Error "µ65874 not a list at index #{idx}" unless buffer[ idx ] is tm_list
  R     = []
  idx  += +1
  loop
    break if ( byte = buffer[ idx ] ) is tm_lo
    [ idx, value, ] = @_decode buffer, idx, true
    R.push value[ 0 ]
    throw new Error "µ66705 runaway list at index #{idx}" unless byte?
  return [ idx + 1, R, ]


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@write = ( idx, value, encoder ) ->
  return @write_singular idx, value if value is VOID
  switch type = type_of value
    when 'text'       then return @write_text     idx, value
    when 'float'     then return @write_number   idx, value
    when 'infinity'   then return @write_infinity idx, value
    when 'date'       then return @write_date     idx, value
    #.......................................................................................................
    when 'set'
      ### TAINT wasting bytes because wrapped too deep ###
      return @write_private  idx, { type: '-set', value: [ ( Array.from value ), ], }
  #.........................................................................................................
  return @write_private  idx, value, encoder if isa.object value
  return @write_singular idx, value


#===========================================================================================================
# PUBLIC API
#-----------------------------------------------------------------------------------------------------------
@encode = ( key, encoder ) ->
  key = key[ .. ]
  key.push VOID
  rbuffer.fill 0x00
  throw new Error "µ67536 expected a list, got a #{type}" unless ( type = type_of key ) is 'list'
  idx = @_encode key, 0, encoder
  R   = Buffer.alloc idx
  rbuffer.copy R, 0, 0, idx
  release_extraneous_rbuffer_bytes()
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@encode_plus_hi = ( key, encoder ) ->
  ### TAINT code duplication ###
  rbuffer.fill 0x00
  throw new Error "µ68367 expected a list, got a #{type}" unless ( type = type_of key ) is 'list'
  idx             = @_encode key, 0, encoder
  grow_rbuffer() until rbuffer.length >= idx + 1
  rbuffer[ idx ]  = tm_hi
  idx            += +1
  R               = Buffer.alloc idx
  rbuffer.copy R, 0, 0, idx
  release_extraneous_rbuffer_bytes()
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@_encode = ( key, idx, encoder ) ->
  last_element_idx = key.length - 1
  for element, element_idx in key
    try
      if isa.list element
        rbuffer[ idx ]  = tm_list
        idx            += +1
        for sub_element in element
          idx = @_encode [ sub_element, ], idx, encoder
        rbuffer[ idx ]  = tm_lo
        idx            += +1
      else
        idx = @write idx, element, encoder
    catch error
      key_rpr = []
      for element in key
        if isa.buffer element
          throw new Error "µ45533 unable to encode buffers"
          # key_rpr.push "#{@rpr_of_buffer element, key[ 2 ]}"
        else
          key_rpr.push rpr element
      warn "µ44544 detected problem with key [ #{rpr key_rpr.join ', '} ]"
      throw error
  #.........................................................................................................
  return idx

#-----------------------------------------------------------------------------------------------------------
@decode = ( buffer, decoder ) ->
  ### eliminate VOID prior to decoding ###
  buffer = buffer.slice 0, buffer.length - 1
  return ( @_decode buffer, 0, false, decoder )[ 1 ]

#-----------------------------------------------------------------------------------------------------------
@_decode = ( buffer, idx, single, decoder ) ->
  R         = []
  last_idx  = buffer.length - 1
  loop
    break if idx > last_idx
    switch type = buffer[ idx ]
      when tm_list       then [ idx, value, ] = @read_list       buffer, idx
      when tm_text       then [ idx, value, ] = @read_text       buffer, idx
      when tm_nnumber    then [ idx, value, ] = @read_nnumber    buffer, idx
      when tm_ninfinity  then [ idx, value, ] = [ idx + 1, -Infinity, ]
      when tm_pnumber    then [ idx, value, ] = @read_pnumber    buffer, idx
      when tm_pinfinity  then [ idx, value, ] = [ idx + 1, +Infinity, ]
      when tm_date       then [ idx, value, ] = @read_date       buffer, idx
      when tm_private    then [ idx, value, ] = @read_private    buffer, idx, decoder
      else                    [ idx, value, ] = @read_singular   buffer, idx
    R.push value
    break if single
  #.........................................................................................................
  return [ idx, R ]


# debug ( require './dump' ).@rpr_of_buffer null, buffer = @encode [ 'aaa', [], ]
# debug '©tP5xQ', @decode buffer

#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@encodings =

  #.........................................................................................................
  dbcs2: """
    ⓪①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳㉑㉒㉓㉔㉕㉖㉗㉘㉙㉚㉛
    ㉜！＂＃＄％＆＇（）＊＋，－．／０１２３４５６７８９：；＜＝＞？
    ＠ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ［＼］＾＿
    ｀ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ｛｜｝～㉠
    ㉝㉞㉟㊱㊲㊳㊴㊵㊶㊷㊸㊹㊺㊻㊼㊽㊾㊿㋐㋑㋒㋓㋔㋕㋖㋗㋘㋙㋚㋛㋜㋝
    ㋞㋟㋠㋡㋢㋣㋤㋥㋦㋧㋨㋩㋪㋫㋬㋭㋮㋯㋰㋱㋲㋳㋴㋵㋶㋷㋸㋹㋺㋻㋼㋽
    ㋾㊊㊋㊌㊍㊎㊏㊐㊑㊒㊓㊔㊕㊖㊗㊘㊙㊚㊛㊜㊝㊞㊟㊠㊡㊢㊣㊤㊥㊦㊧㊨
    ㊩㊪㊫㊬㊭㊮㊯㊰㊀㊁㊂㊃㊄㊅㊆㊇㊈㊉㉈㉉㉊㉋㉌㉍㉎㉏⓵⓶⓷⓸⓹〓
    """
  #.........................................................................................................
  aleph: """
    БДИЛЦЧШЭЮƆƋƏƐƔƥƧƸψŐőŒœŊŁłЯɔɘɐɕəɞ
    ␣!"#$%&'()*+,-./0123456789:;<=>?
    @ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_
    `abcdefghijklmnopqrstuvwxyz{|}~ω
    ΓΔΘΛΞΠΣΦΨΩαβγδεζηθικλμνξπρςστυφχ
    Ж¡¢£¤¥¦§¨©ª«¬Я®¯°±²³´µ¶·¸¹º»¼½¾¿
    ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞß
    àáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ
    """
  #.........................................................................................................
  rdctn: """
    ∇≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡
    ␣!"#$%&'()*+,-./0123456789:;<=>?
    @ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_
    `abcdefghijklmnopqrstuvwxyz{|}~≡
    ∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃
    ∃∃¢£¤¥¦§¨©ª«¬Я®¯°±²³´µ¶·¸¹º»¼½¾¿
    ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞß
    àáâãäåæçèéêëìíîïðñò≢≢≢≢≢≢≢≢≢≢≢≢Δ
    """


#-----------------------------------------------------------------------------------------------------------
@rpr_of_buffer = ( buffer, encoding = 'rdctn' ) ->
  return ( rpr buffer ) + ' ' +  @_encode_buffer buffer, encoding

#-----------------------------------------------------------------------------------------------------------
@_encode_buffer = ( buffer, encoding = 'rdctn' ) ->
  ### TAINT use switch, emit error if `encoding` not list or known key ###
  encoding = @encodings[ encoding ] unless isa.list encoding
  return ( encoding[ buffer[ idx ] ] for idx in [ 0 ... buffer.length ] ).join ''

#-----------------------------------------------------------------------------------------------------------
@_compile_encodings = ->
  #.........................................................................................................
  chrs_of = ( text ) ->
    text = text.split /([\ud800-\udbff].|.)/
    return ( chr for chr in text when chr isnt '' )
  #.........................................................................................................
  for name, encoding of @encodings
    encoding = chrs_of encoding.replace /\n+/g, ''
    unless ( length = encoding.length ) is 256
      throw new Error "µ69198 expected 256 characters, found #{length} in encoding #{rpr name}"
    @encodings[ name ] = encoding
  return null
@_compile_encodings()

#-----------------------------------------------------------------------------------------------------------
@as_sortline = ( key, settings ) ->
  joiner      = settings?[ 'joiner'     ] ? ' '
  base        = settings?[ 'base'       ] ? 0x2800
  stringify   = settings?[ 'stringify'  ] ? JSON.stringify
  bare        = settings?[ 'bare'       ] ? no
  buffer      = @encode key
  buffer_txt  = ( String.fromCodePoint base + buffer[ idx ] for idx in [ 0 ... buffer.length - 1 ] ).join ''
  return buffer_txt if bare
  return buffer_txt + joiner + stringify key





