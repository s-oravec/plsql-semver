create or replace package body semver_range_impl as

    d debug := new debug('semver:range');

    --exports.Range = Range;
    --function Range(range, loose) {
    --  if ((range instanceof Range) && range.loose === loose)
    --    return range;
    --
    --  if (!(this instanceof Range))
    --    return new Range(range, loose);
    --
    --  this.loose = loose;
    --
    --  // First, split based on boolean or ||
    --  this.raw = range;
    --  this.set = range.split(/\s*\|\|\s*/).map(function(range) {
    --    return this.parseRange(range.trim());
    --  }, this).filter(function(c) {
    --    // throw out any that are not relevant for whatever reason
    --    return c.length;
    --  });
    --
    --  if (!this.set.length) {
    --    throw new TypeError('Invalid SemVer Range: ' + range);
    --  }
    --
    --  this.format();
    --}
    --
    --Range.prototype.format = function() {
    --  this.range = this.set.map(function(comps) {
    --    return comps.join(' ').trim();
    --  }).join('||').trim();
    --  return this.range;
    --};
    --
    --Range.prototype.toString = function() {
    --  return this.range;
    --};
    --

    /*
    range-set  ::= range ( logical-or range ) *
    logical-or ::= ( ' ' ) * '||' ( ' ' ) *
    range      ::= hyphen | simple ( ' ' simple ) * | ''
    hyphen     ::= partial ' - ' partial
    simple     ::= primitive | partial | tilde | caret
    primitive  ::= ( '<' | '>' | '>=' | '<=' | '=' | ) partial
    partial    ::= xr ( '.' xr ( '.' xr qualifier ? )? )?
    xr         ::= 'x' | 'X' | '*' | nr
    nr         ::= '0' | ['1'-'9'] ( ['0'-'9'] ) *
    tilde      ::= '~' partial
    caret      ::= '^' partial
    qualifier  ::= ( '-' pre )? ( '+' build )?
    pre        ::= parts
    build      ::= parts
    parts      ::= part ( '.' part ) *
    part       ::= nr | [-0-9A-Za-z]+
    

    */
    
    function parse(a_value in varchar2) return semver_range is
      l_rangeSet semver_ast_rangeset;
    begin
      semver_range_parser.initialize(a_value);
      l_rangeSet := semver_range_parser.parse;

    --  // `> 1.2.3 < 1.2.5` => `>1.2.3 <1.2.5`
    --  range = range.replace(re[COMPARATORTRIM], comparatorTrimReplace);
    --  debug('comparator trim', range, re[COMPARATORTRIM]);
    --
    --  // `~ 1.2.3` => `~1.2.3`
    --  range = range.replace(re[TILDETRIM], tildeTrimReplace);
    --
    --  // `^ 1.2.3` => `^1.2.3`
    --  range = range.replace(re[CARETTRIM], caretTrimReplace);
    --
    --  // normalize spaces
    --  range = range.split(/\s+/).join(' ');
    --
    --  // At this point, the range is completely trimmed and
    --  // ready to be split into comparators.
    --
    --  var compRe = loose ? re[COMPARATORLOOSE] : re[COMPARATOR];
    --  var set = range.split(' ').map(function(comp) {
    --    return parseComparator(comp, loose);
    --  }).join(' ').split(/\s+/);
    --  if (this.loose) {
    --    // in loose mode, throw out any that are not valid comparators
    --    set = set.filter(function(comp) {
    --      return !!comp.match(compRe);
    --    });
    --  }
    --  set = set.map(function(comp) {
    --    return new Comparator(comp, loose);
    --  });
    --
    --  return set;
      
    end;

end;
/
