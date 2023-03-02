

'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PSPG/EXPERIMENTS/DEMO'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
# FS                        = require 'fs'
PATH                      = require 'path'
PS                        = require 'pipestreams'
{ $
  $async
  select }                = PS.export()
types                     = require '../types'
{ isa
  validate
  declare
  size_of
  type_of }               = types
#...........................................................................................................
require                   '../exception-handler'
join_paths                = ( P... ) -> PATH.resolve PATH.join P...
abspath                   = ( P... ) -> join_paths __dirname, P...
{ to_width, width_of, }   = require 'to-width'
PSPG                      = require '../..'
path_1                    = abspath '../../src/experiments/test-data-1.tsv'
jr                        = JSON.stringify


#-----------------------------------------------------------------------------------------------------------
@demo_tabular_output = ->
  return new Promise ( resolve ) =>
    source    = PS.read_from_file path_1
    pipeline  = []
    pipeline.push source
    pipeline.push PS.$split_tsv()
    pipeline.push PS.$name_fields 'fncr', 'glyph', 'formula'
    pipeline.push @$add_random_words 10
    pipeline.push @$add_ncrs()
    pipeline.push @$add_numbers()
    pipeline.push @$add_nulls()
    pipeline.push @$reorder_fields()
    pipeline.push PSPG.$tee_as_table -> resolve()
    pipeline.push PS.$drain()
    PS.pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@demo_many_rows = ->
  return new Promise ( resolve ) =>
    source    = PS.new_value_source @get_random_words 800
    pipeline  = []
    pipeline.push source
    pipeline.push $ ( word, send ) -> send "#{word} ".repeat CND.random_integer 1, 20
    pipeline.push $ ( text, send ) -> send { text, }
    pipeline.push PSPG.$tee_as_table -> resolve()
    pipeline.push PS.$drain()
    PS.pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@demo_tabular_output_with_different_shapes = ->
  ### This is to demonstrate that when objects with different shapes—i.e. different sets of properties—are
  tabulated, the columns displayed represent the union of all keys of all objects. ###
  return new Promise ( resolve ) =>
    source    = PS.read_from_file path_1
    pipeline  = []
    pipeline.push source
    pipeline.push PS.$split_tsv()
    pipeline.push PS.$name_fields 'fncr', 'glyph', 'formula'
    pipeline.push @$add_random_words 10
    pipeline.push @$add_ncrs()
    pipeline.push @$add_numbers()
    pipeline.push @$reorder_fields()
    pipeline.push @$drop_keys()
    pipeline.push PSPG.$tee_as_table -> resolve()
    pipeline.push PS.$drain()
    PS.pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@demo_paged_output = ->
  return new Promise ( resolve ) =>
    source    = PS.read_from_file path_1
    pipeline  = []
    pipeline.push source
    pipeline.push PS.$split_tsv()
    pipeline.push PS.$name_fields 'fncr', 'glyph', 'formula'
    pipeline.push @$add_random_words 10
    pipeline.push @$add_ncrs()
    pipeline.push @$add_numbers()
    pipeline.push @$reorder_fields()
    pipeline.push @$as_line()
    pipeline.push PSPG.$page_output -> resolve()
    pipeline.push PS.$drain()
    PS.pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@demo_csv_output = ->
  return new Promise ( resolve ) =>
    source    = PS.read_from_file path_1
    pipeline  = []
    pipeline.push source
    pipeline.push PS.$split_tsv()
    pipeline.push PS.$name_fields 'fncr', 'glyph', 'formula'
    pipeline.push @$add_random_words 10
    pipeline.push @$add_ncrs()
    pipeline.push @$add_numbers()
    pipeline.push @$reorder_fields()
    pipeline.push @$add_csv_header()
    pipeline.push @$as_csv_line()
    # pipeline.push PS.$watch ( d ) -> urge '^77766^', jr d
    pipeline.push PSPG.$page_output { csv: true, }, -> resolve()
    pipeline.push PS.$drain()
    PS.pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@demo_key_value = ->
  return new Promise ( resolve ) =>
    source    = PS.read_from_file path_1
    pipeline  = []
    pipeline.push source
    pipeline.push PS.$split_tsv()
    pipeline.push PS.$name_fields 'fncr', 'glyph', 'formula'
    pipeline.push $ ( d, send ) -> send { key: d.glyph, value: d.formula, }
    pipeline.push @$add_csv_header()
    pipeline.push @$as_csv_line()
    # pipeline.push PS.$watch ( d ) -> urge '^77766^', jr d
    pipeline.push PSPG.$page_output { csv: true, }, -> resolve()
    pipeline.push PS.$drain()
    PS.pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@$reorder_fields = -> $ ( row, send ) =>
  { nr
    fncr
    nr2
    glyph
    glyph_ncr
    nr3
    formula
    formula_ncr
    bs }        = row
  send { nr, fncr, nr2, glyph, glyph_ncr, nr3, formula, formula_ncr, bs, }

#-----------------------------------------------------------------------------------------------------------
@$add_ncrs = ->
  return $ ( row, send ) =>
    row.glyph_ncr   = to_width ( @text_as_ncrs row.glyph    ), 20
    row.formula_ncr = to_width ( @text_as_ncrs row.formula  ), 20
    send row

#-----------------------------------------------------------------------------------------------------------
@$add_numbers = ->
  nr = 0
  return $ ( row, send ) =>
    nr             += +1
    row.nr          = nr
    row.nr2         = nr ** 2
    row.nr3         = nr ** 3
    send row

#-----------------------------------------------------------------------------------------------------------
@$add_nulls = ->
  return $ ( row, send ) =>
    switch row.nr
      when 3 then delete row.glyph
      when 4 then row.bs = null
    send row

#-----------------------------------------------------------------------------------------------------------
@$drop_keys = ->
  return $ ( row, send ) =>
    keys  = ( key for key of row )
    idx   = row.nr %% keys.length
    key   = keys[ idx ]
    send { "#{key}": row[ key ], }
    # send row

#-----------------------------------------------------------------------------------------------------------
@text_as_ncrs = ( text ) ->
  R = []
  for chr in Array.from text
    cid_hex = ( chr.codePointAt 0 ).toString 16
    R.push "&#x#{cid_hex};"
  return R.join ''

#-----------------------------------------------------------------------------------------------------------
@$add_random_words = ( n = 1 ) ->
  validate.count n
  CP    = require 'child_process'
  count = Math.min 1e5, n * 1000
  words = ( ( CP.execSync "shuf -n #{count} /usr/share/dict/words" ).toString 'utf-8' ).split '\n'
  words = ( word.replace /'s$/g, '' for word in words )
  words = ( word for word in words when word isnt '' )
  return $ ( fields, send ) =>
    fields.bs = ( words[ CND.random_integer 0, count ] for _ in [ 0 .. n ] ).join ' '
    send fields

#-----------------------------------------------------------------------------------------------------------
@get_random_words = ( n = 10 ) ->
  validate.count n
  CP    = require 'child_process'
  words = ( ( CP.execSync "shuf -n #{n} /usr/share/dict/words" ).toString 'utf-8' ).split '\n'
  words = ( word.replace /'s$/g, '' for word in words )
  words = ( word for word in words when word isnt '' )
  return words

#-----------------------------------------------------------------------------------------------------------
@$as_line = -> $ ( d, send ) =>
  d  = jr d unless isa.text d
  d += '\n' unless isa.line d
  send d

#-----------------------------------------------------------------------------------------------------------
as_csv = ( x ) ->
  x = x.toString() unless isa.text x
  return '"' + ( x.replace /"/g, '""' ) + '"'

#-----------------------------------------------------------------------------------------------------------
@$add_csv_header = ->
  is_first = true
  return $ ( d, send ) =>
    if is_first
      is_first = false
      send ( ( ( as_csv k ) for k, _ of d ).join ',' ) + '\n'
    else
      send d
    return null

#-----------------------------------------------------------------------------------------------------------
@$as_csv_line = -> $ ( d, send ) =>
  return send d if isa.text d
  send ( ( ( as_csv v ) for _, v of d ).join ',' ) + '\n'


############################################################################################################
unless module.parent?
  do =>
    # await @demo_many_rows()
    await @demo_tabular_output()
    # await @demo_tabular_output_with_different_shapes()
    # await @demo_paged_output()
    await @demo_csv_output()
    await @demo_key_value()


