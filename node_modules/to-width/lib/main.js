(function() {
  //###########################################################################################################
  var rpr, self, ƒ;

  rpr = (require('util')).inspect;

  //...........................................................................................................
  // probes                    = require './probes'
  this._width_of_string = require('string-width');

  this._Wcstring = require('wcstring');

  self = this;

  ƒ = function(method) {
    return method.bind(self);
  };

  //-----------------------------------------------------------------------------------------------------------
  this.to_width = ƒ(function(text, width, settings) {
    /* `WCString` occasionally is off by one, so here we fix that: */
    var R, align, ellipsis, old_width, p, padder, ref, ref1, ref2, width_1;
    if (!(width >= 2)) {
      /* Fit text into `width` columns, taking into account ANSI color codes (that take up bytes but not width)
       and double-width glyphs such as CJK characters. */
      throw new Error(`width must at least be 2, got ${width}`);
    }
    padder = (ref = settings != null ? settings['padder'] : void 0) != null ? ref : ' ';
    ellipsis = (ref1 = settings != null ? settings['ellipsis'] : void 0) != null ? ref1 : '…';
    align = (ref2 = settings != null ? settings['align'] : void 0) != null ? ref2 : 'left';
    R = text;
    old_width = this.width_of(R);
    if (old_width === width) {
      return R;
    }
    //.........................................................................................................
    if (old_width > (width_1 = width - 1)) {
      R = (new this._Wcstring(text)).truncate(width_1, '');
      R += ellipsis + (((this.width_of(R)) < width_1) ? ellipsis : '');
    } else {
      /* TAINT assuming uncolored, single-width glyph for padding */
      //.........................................................................................................
      p = width - old_width;
      switch (align) {
        case 'left':
          R = R + (padder.repeat(p));
          break;
        case 'right':
          R = (padder.repeat(p)) + R;
          break;
        case 'center':
          R = (padder.repeat(Math.floor(p / 2))) + R + (padder.repeat(Math.ceil(p / 2)));
          break;
        default:
          throw new Error(`expected one of 'left, 'right'. 'center', got ${rpr(align)}`);
      }
    }
    //.........................................................................................................
    return R;
  });

  //-----------------------------------------------------------------------------------------------------------
  this.width_of = ƒ((text) => {
    return this._width_of_string(text);
  });

}).call(this);

//# sourceMappingURL=main.js.map