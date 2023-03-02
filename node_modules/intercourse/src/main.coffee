

'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'INTERCOURSE/MAIN'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
PATH                      = require 'path'
SP                        = require 'steampipes'
{ $
  $async }                  = SP.export()
DATOM                     = require 'datom'
{ new_datom
  select
  lets      }             = DATOM.export()
{ assign
  jr }                    = CND
copy                      = ( x ) -> assign {}, x
#...........................................................................................................
types                     = require './types'
{ isa
  validate
  declare
  size_of
  type_of }               = types

#-----------------------------------------------------------------------------------------------------------
collapse_text = ( list_of_texts ) ->
  R = list_of_texts
  R = R.join '\n'
  R = R.replace /^\s*/, ''
  R = R.replace /\s*$/, ''
  R = R + '\n' unless R.length is 0
  return R

#-----------------------------------------------------------------------------------------------------------
has_full_signatures = ( entry ) ->
  for k of entry
    return true if k.startsWith '('
  return false

#-----------------------------------------------------------------------------------------------------------
@$as_line_datoms = ( S ) ->
  line_nr = 0
  return $ ( line, send ) ->
    line_nr += +1
    if ( line.match /^\s*$/ )?  then  d = new_datom '^line', { value: line, $: { line_nr, }, ref: 'ald/1', is_blank: true, }
    else                              d = new_datom '^line', { value: line, $: { line_nr, }, ref: 'ald/2', }
    send d
    return null

#-----------------------------------------------------------------------------------------------------------
@$skip_comments = ( S ) -> SP.$filter ( d ) -> not ( d.value.match S.comments )?

#-----------------------------------------------------------------------------------------------------------
@$add_headers = ( S ) ->
  header_sig_re   = /// ^ (?<ictype> \S+ ) \s+ (?<icname> \S+? )(?<signature> \( .*? \) ) \s* : \s* (?<trailer> .*? ) \s* $ ///
  header_plain_re = /// ^ (?<ictype> \S+ ) \s+ (?<icname> \S+  )                          \s* : \s* (?<trailer> .*? ) \s* $ ///
  ignore_re       = /// ^ ignore \s* : \s*  $ ///
  return $ ( d, send ) =>
    return send d if d.is_blank
    return send d if ( d.value.match /^\s/ )?
    return ( send new_datom '^ignore',     { value: ( copy m.groups ), $: d, ref: 'ah/1', } ) if ( m = d.value.match ignore_re       )?
    return ( send new_datom '^definition', { value: ( copy m.groups ), $: d, ref: 'ah/2', } ) if ( m = d.value.match header_sig_re   )?
    return ( send new_datom '^definition', { value: ( copy m.groups ), $: d, ref: 'ah/3', } ) if ( m = d.value.match header_plain_re )?
    #.......................................................................................................
    throw new Error "µ83473 illegal line #{rpr d}"
    return null

#-----------------------------------------------------------------------------------------------------------
@$add_regions = ( S ) ->
  within_region = false
  prv_name      = null
  last          = Symbol 'last'
  #.........................................................................................................
  return $ { last, }, ( d, send ) =>
    #.......................................................................................................
    if d is last
      if prv_name?
        send new_datom ( '>' + prv_name ), { ref: 'ar/1', }
        prv_name = null
      return
    #.......................................................................................................
    if select d, '^line'
      return send d if within_region
      return if d.is_blank
      throw new Error "µ85818 found line outside of any region: #{rpr d}"
    #.......................................................................................................
    if prv_name?
      send new_datom ( '>' + prv_name ), { ref: 'ar/2', }
      within_region = false
      prv_name      = null
    #.......................................................................................................
    unless within_region
      ### TAINT use PipeDreams API for this ###
      prv_name      = d.$key[ 1 .. ]
      d             = lets d, ( d ) -> d.$key = ( '<' + prv_name ); d.ref = 'ar/3'
      within_region = true
      send d
    #.......................................................................................................
    return null

#-----------------------------------------------------------------------------------------------------------
@$skip_ignored = ( S ) ->
  within_ignore = false
  return $ ( d, send ) =>
    if      select d, '<ignore'   then within_ignore = true
    else if select d, '>ignore'   then within_ignore = false
    else unless within_ignore     then send d
    #.......................................................................................................
    return null

#-----------------------------------------------------------------------------------------------------------
@$reorder_trailers = ( S ) ->
  within_definition = false
  is_oneliner       = false
  return $ ( d, send ) =>
    #.......................................................................................................
    if select d, '<definition'
      within_definition = true
      trailer           = d.value.trailer
      d                 = lets d, ( d ) -> delete d.value.trailer
      if trailer? and ( trailer.length > 0 )
        is_oneliner = true
        send d
        send new_datom '^line', { value: ( '  ' + trailer.trim() ), $: d, ref: 'rt/1', }
      else
        send d
    #.......................................................................................................
    else if select d, '>definition'
      is_oneliner       = false
      within_definition = false
      send d
    #.......................................................................................................
    else if within_definition and is_oneliner and ( not select d, '>definition' ) and not d.is_blank
      throw new Error "µ87872 illegal follow-up after one-liner: #{rpr d}"
    #.......................................................................................................
    else
      send d
    #.......................................................................................................
    return null

#-----------------------------------------------------------------------------------------------------------
@get_signature_and_kenning = ( signature = null ) ->
  return [ null, 'null', ] unless signature?
  signature = Object.keys signature unless isa.list signature
  signature = signature[ .. ].sort()
  kenning   = '(' + ( signature.join ',' ) + ')'
  return [ signature, kenning, ]

#-----------------------------------------------------------------------------------------------------------
@$compile_definitions = ( S ) ->
  this_definition   = null
  this_indentation  = null
  #.........................................................................................................
  return $ ( d, send ) =>
    #.......................................................................................................
    if select d, '<definition'
      name                = d.value.icname
      type                = d.value.ictype
      location            = d.$
      signature           = null
      this_definition     = { name, type, text: [], location, kenning: 'null', }
      if d.value.signature?
        signature = []
        for argument in ( d.value.signature.replace /[()]/g, '' ).split ','
          signature.push argument if ( argument = argument.trim() )? and argument.length > 0
        [ signature
          kenning ]               = @get_signature_and_kenning signature
        this_definition.signature = signature
        this_definition.kenning   = kenning
    #.......................................................................................................
    else if select d, '>definition'
      this_definition.text  = collapse_text this_definition.text
      send new_datom '^definition', { value: this_definition, $: this_definition.location, ref: 'cd/1', }
      this_definition       = null
      this_indentation      = null
    #.......................................................................................................
    else if select d, '^line'
      return this_definition.text.push '' if d.is_blank
      text = d.value
      #.....................................................................................................
      unless this_indentation?
        unless ( match = text.match /^\s+/ )?
          throw new Error "µ88163 unexpected indentation: #{rpr d}"
        this_indentation = match[ 0 ]
      #.....................................................................................................
      else
        unless text.startsWith this_indentation
          throw new Error "µ90508 unexpected indentation: #{rpr d}"
      #.....................................................................................................
      text = text[ this_indentation.length .. ]
      this_definition.text.push text
    #.......................................................................................................
    else
      throw new Error "µ92853 unexpected datom: #{rpr d}"
    #.......................................................................................................
    return null

#-----------------------------------------------------------------------------------------------------------
@$collect = ( S, collector ) ->
  return $ ( d, send ) =>
    unless select d, '^definition'
      throw new Error "µ23982 expected a '^definition', got #{rpr d}"
    #.......................................................................................................
    lnr                 = d.$.line_nr
    definition          = d.value
    { type
      parts
      location
      kenning
      signature }       = definition
    entry               = ( collector[ definition.name ] ?= { type, } )
    #.......................................................................................................
    unless d.value.type is entry.type
      throw new Error """µ94432
        #{rpr definition.name} is of type #{rpr entry.type}, unable to change to #{rpr definition.type}
        (line ##{lnr})"""
    #.......................................................................................................
    if entry[ kenning ]?
      throw new Error """µ23983
        name #{definition.name} with kenning #{rpr kenning} already defined:
        #{rpr definition}
        (line ##{lnr})"""
    #.......................................................................................................
    ### TAINT must re-implement ###
    if ( kenning is 'null' ) and ( has_full_signatures entry )
      debug 'µ23983', entry
      throw new Error """µ23983
        can't overload explicit-signature definition with a null-signature definition:
        #{rpr definition}
        (line ##{lnr})"""
    #.......................................................................................................
    entry[ kenning ]            = { parts, location, kenning, type, }
    entry[ kenning ].signature  = signature if signature?
    #.......................................................................................................
    return null

#-----------------------------------------------------------------------------------------------------------
@$validate_definition = ( S, collector ) ->
  return $ ( d, send ) =>
    validate.datom d
    validate.true d.$key is '^definition'
    validate.ic_signature_entry d.value
    send d

#-----------------------------------------------------------------------------------------------------------
partition = ( S, text ) ->
  R     = []
  part  = null
  #.........................................................................................................
  flush = ->
    return null if ( not part? ) or ( part.length is 0 )
    R.push ( part.join '\n' ).replace /\s+$/, ''
    part = null
    return null
  #.........................................................................................................
  for line in text.split /\n/
    continue if ( line.match S.comments )?
    if ( line.match /^\S/ )?
      flush()
    part ?= []
    part.push line
  flush()
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@$partition = ( S, collector ) ->
  return $ ( d, send ) =>
    # if S.partition is 'indent'
    send lets d, ( d ) ->
      definition        = d.value
      text              = definition.text
      if S.partition is 'indent'
        definition.parts  = partition S, text
      else
        definition.parts  = [ text, ]
      delete definition.text
    return null

#-----------------------------------------------------------------------------------------------------------
@definitions_from_path = ( path, settings ) -> new Promise ( resolve, reject ) =>
  @_read_definitions ( SP.read_from_file path ), settings, ( error, R ) =>
    return reject error if error?
    resolve R

#-----------------------------------------------------------------------------------------------------------
@definitions_from_path_sync = ( path, settings ) ->
  return @definitions_from_text ( ( require 'fs' ).readFileSync path ), settings

#-----------------------------------------------------------------------------------------------------------
@definitions_from_text = ( text, settings ) ->
  buffer = Buffer.from text, { encoding: 'utf-8', }
  return @_read_definitions ( SP.new_value_source [ buffer, ] ), settings

#-----------------------------------------------------------------------------------------------------------
@_read_definitions = ( source, settings, handler = null ) ->
  ### TAINT find a way to ensure pipeline after source is indeed synchronous ###
  R         = {}
  S         = assign { partition: 'indent', comments: /^--/, }
  pipeline  = []
  validate.ic_settings S
  pipeline.push source
  pipeline.push SP.$split()
  pipeline.push @$as_line_datoms        S
  pipeline.push @$skip_comments         S
  pipeline.push @$add_headers           S
  pipeline.push @$add_regions           S
  pipeline.push @$skip_ignored          S
  pipeline.push @$reorder_trailers      S
  # pipeline.push SP.$show()
  pipeline.push @$compile_definitions   S
  pipeline.push @$partition             S
  pipeline.push @$validate_definition   S
  pipeline.push @$collect               S, R
  pipeline.push SP.$drain -> if handler? then handler null, R
  SP.pull pipeline...
  return if handler? then null else R





