(function() {
  'use strict';
  var CND, badge, debug, types;

  //###########################################################################################################
  CND = require('cnd');

  badge = 'STEAMPIPES/SORT';

  debug = CND.get_logger('debug', badge);

  types = require('./types');

  // #-----------------------------------------------------------------------------------------------------------
  // @$sort = ( settings ) ->
  //   last      = Symbol 'last'
  //   settings  = { key: null, settings..., }
  //   collector = []
  //   return @$ { last, }, ( d, send ) =>
  //     if d is last
  //       if ( key = settings.key )?
  //         collector.sort ( a, b ) =>
  //           return -1 if a[ key ] < b[ key ]
  //           return +1 if a[ key ] > b[ key ]
  //           return  0
  //       else
  //         collector.sort()
  //       send d for d in collector
  //       collector.length = 0
  //       return null
  //     collector.push d
  //     return null

  //-----------------------------------------------------------------------------------------------------------
  this.$sort = function(settings) {
    /* https://github.com/mziccard/node-timsort */
    var $sort, TIMSORT, arity, direction, key, ref, ref1, ref2, ref3, sorter, strict, type_of, validate_type;
    TIMSORT = require('timsort');
    direction = 'ascending';
    sorter = null;
    key = null;
    strict = true;
    switch (arity = arguments.length) {
      case 0:
        null;
        break;
      case 1:
        direction = (ref = settings['direction']) != null ? ref : 'ascending';
        sorter = (ref1 = settings['sorter']) != null ? ref1 : null;
        key = (ref2 = settings['key']) != null ? ref2 : null;
        strict = (ref3 = settings['strict']) != null ? ref3 : true;
        break;
      default:
        throw new Error(`µ33893 expected 0 or 1 arguments, got ${arity}`);
    }
    //.........................................................................................................
    if (direction !== 'ascending' && direction !== 'descending') {
      throw new Error(`µ34658 expected 'ascending' or 'descending' for direction, got ${rpr(direction)}`);
    }
    //.........................................................................................................
    if (sorter == null) {
      //.......................................................................................................
      type_of = (x) => {
        /* NOTE for the purposes of magnitude comparison, `Infinity` can be treated as a number: */
        var R;
        R = types.type_of(x);
        if (R === 'infinity') {
          return 'float';
        } else {
          return R;
        }
      };
      //.......................................................................................................
      validate_type = (type_a, type_b, include_list = false) => {
        if (type_a !== type_b) {
          throw new Error(`µ35423 unable to compare a ${type_a} to a ${type_b}`);
        }
        if (include_list) {
          if (type_a !== 'float' && type_a !== 'date' && type_a !== 'text' && type_a !== 'list') {
            throw new Error(`µ36188 unable to compare values of type ${type_a}`);
          }
        } else {
          if (type_a !== 'float' && type_a !== 'date' && type_a !== 'text') {
            throw new Error(`µ36953 unable to compare values of type ${type_a}`);
          }
        }
        return null;
      };
      //.......................................................................................................
      if (key != null) {
        sorter = (a, b) => {
          a = a[key];
          b = b[key];
          if (strict) {
            validate_type(type_of(a), type_of(b), false);
          }
          if ((direction === 'ascending' ? a > b : a < b)) {
            return +1;
          }
          if ((direction === 'ascending' ? a < b : a > b)) {
            return -1;
          }
          return 0;
        };
      } else {
        //.......................................................................................................
        sorter = (a, b) => {
          var type_a, type_b;
          if (strict) {
            validate_type((type_a = type_of(a)), (type_b = type_of(b)), true);
          }
          if (type_a === 'list') {
            a = a[0];
            b = b[0];
            if (strict) {
              validate_type(type_of(a), type_of(b), false);
            }
          }
          if ((direction === 'ascending' ? a > b : a < b)) {
            return +1;
          }
          if ((direction === 'ascending' ? a < b : a > b)) {
            return -1;
          }
          return 0;
        };
      }
    }
    //.........................................................................................................
    $sort = () => {
      var collector;
      collector = [];
      return this.$({
        last: null
      }, (data, send) => {
        var i, len, x;
        if (data != null) {
          collector.push(data);
        } else {
          TIMSORT.sort(collector, sorter);
          for (i = 0, len = collector.length; i < len; i++) {
            x = collector[i];
            send(x);
          }
          collector.length = 0;
        }
        return null;
      });
    };
    //.........................................................................................................
    return $sort();
  };

}).call(this);

//# sourceMappingURL=sort.js.map