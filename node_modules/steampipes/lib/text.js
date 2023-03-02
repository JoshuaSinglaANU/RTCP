(function() {
  'use strict';
  var CND, badge, debug, echo, help, info, isa, jr, rpr, type_of, urge, validate, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'STEAMPIPES/TEXT';

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  info = CND.get_logger('info', badge);

  urge = CND.get_logger('urge', badge);

  help = CND.get_logger('help', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  ({jr} = CND);

  //...........................................................................................................
  ({isa, validate, type_of} = require('./types'));

  // $pull_split               = require 'pull-split'
  // $pull_utf8_decoder        = require 'pull-utf8-decoder'

  //-----------------------------------------------------------------------------------------------------------
  this.new_text_source = function(text) {
    return $values([text]);
  };

  // #-----------------------------------------------------------------------------------------------------------
  // @new_text_sink = -> throw new Error "µ66539 not implemented"

  // #-----------------------------------------------------------------------------------------------------------
  // @$split = ( settings ) ->
  //   throw new Error "µ66662 MEH" if settings?
  //   R         = []
  //   matcher   = null
  //   mapper    = null
  //   reverse   = no
  //   skip_last = yes
  //   R.push $pull_utf8_decoder()
  //   R.push $pull_split matcher, mapper, reverse, skip_last
  //   R.push @$ ( line, send ) -> send line.replace /\r+$/g, ''
  //   return @pull R...

  //-----------------------------------------------------------------------------------------------------------
  this.$join = function(joiner = null) {
    var collector, is_first, length, type;
    collector = [];
    length = 0;
    type = null;
    is_first = true;
    return this.$({
      last: null
    }, function(data, send) {
      var this_type;
      if (data != null) {
        if (is_first) {
          is_first = false;
          type = type_of(data);
          switch (type) {
            case 'text':
              if (joiner == null) {
                joiner = '';
              }
              break;
            case 'buffer':
              if (joiner != null) {
                throw new Error(`µ66785 joiner not supported for buffers, got ${rpr(joiner)}`);
              }
              break;
            default:
              throw new Error(`µ66908 expected a text or a buffer, got a ${type}`);
          }
        } else {
          if ((this_type = type_of(data)) !== type) {
            throw new Error(`µ67031 expected a ${type}, got a ${this_type}`);
          }
        }
        length += data.length;
        collector.push(data);
      } else {
        if ((collector.length === 0) || (length === 0)) {
          return send('');
        }
        if (type === 'text') {
          return send(collector.join(''));
        }
        return send(Buffer.concat(collector, length));
      }
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$as_line = function() {
    return this.$map((line) => {
      var type;
      if ((type = type_of(line)) !== 'text') {
        `µ67154 expected a text, got a ${type}`;
      }
      return line + '\n';
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$trim = function() {
    return this.$map((line) => {
      var type;
      if ((type = type_of(line)) !== 'text') {
        `µ67277 expected a text, got a ${type}`;
      }
      return line.trim();
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$skip_empty = function() {
    return this.$filter((line) => {
      var type;
      if ((type = type_of(line)) !== 'text') {
        `µ67400 expected a text, got a ${type}`;
      }
      return line.length > 0;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$skip_blank = function() {
    return this.$filter((line) => {
      var type;
      if ((type = type_of(line)) !== 'text') {
        `µ67523 expected a text, got a ${type}`;
      }
      return (line.match(/^\s*$/)) == null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$as_text = function(settings) {
    var ref, serialize;
    serialize = (ref = settings != null ? settings['serialize'] : void 0) != null ? ref : JSON.stringify;
    return this.$map((data) => {
      return serialize(data);
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$desaturate = function() {
    /* remove ANSI escape sequences */
    var pattern;
    pattern = /\x1b\[[0-9;]*[JKmsu]/g;
    return this.$map((line) => {
      return line.replace(pattern, '');
    });
  };

}).call(this);

//# sourceMappingURL=text.js.map