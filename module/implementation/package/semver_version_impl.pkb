create or replace package body semver_version_impl as

    d debug := new debug('semver');

    src semver_common.typ_regexp_tab;

    -- Numeric
    IS_NUMERIC constant semver_common.typ_regexp_name := 'IS_NUMERIC';

    -- Delimiters
    DELIMITERS constant semver_common.typ_regexp_name := 'DELIMITERS';

    --
    -- The following Regular Expressions can be used for tokenizing,
    -- validating, and parsing SemVer version strings.
    --
    -- ## Numeric Identifier
    -- A single `0`, or a non-zero digit followed by zero or more digits.
    --
    NUMERICIDENTIFIER constant semver_common.typ_regexp_name := 'NUMERICIDENTIFIER';

    --
    -- ## Non-numeric Identifier
    -- Zero or more digits, followed by a letter or hyphen, and then zero or
    -- more letters, digits, or hyphens.
    --
    NONNUMERICIDENTIFIER constant semver_common.typ_regexp_name := 'NONNUMERICIDENTIFIER';
    --
    -- ## Main Version
    -- Three dot-separated numeric identifiers.
    --
    MAINVERSION constant semver_common.typ_regexp_name := 'MAINVERSION';
    --
    -- ## Pre-release Version Identifier
    -- A numeric identifier, or a non-numeric identifier.
    --
    PRERELEASEIDENTIFIER constant semver_common.typ_regexp_name := 'PRERELEASEIDENTIFIER';
    --
    --
    -- ## Pre-release Version
    -- Hyphen, followed by one or more dot-separated pre-release version
    -- identifiers.
    --
    PRERELEASE constant semver_common.typ_regexp_name := 'PRERELEASE';
    --
    -- ## Build Metadata Identifier
    -- Any combination of digits, letters, or hyphens.
    --
    BUILDIDENTIFIER constant semver_common.typ_regexp_name := 'BUILDIDENTIFIER';
    --
    -- ## Build Metadata
    -- Plus sign, followed by one or more period-separated build metadata
    -- identifiers.
    --
    BUILD constant semver_common.typ_regexp_name := 'BUILD';
    --
    -- ## Full Version String
    -- A main version, followed optionally by a pre-release version and
    -- build metadata.
    --
    -- Note that the only major, minor, patch, and pre-release sections of
    -- the version string are capturing groups.  The build metadata is not a
    -- capturing group, because it should not ever be used in version
    -- comparison.
    --
    FULLVERSION constant semver_common.typ_regexp_name := 'FULLVERSION';

    --
    --src[GTLT] = '((?:<|>)?=?)';
    --
    -- Something like "2.*" or "1.2.x".
    -- Note that "x.x" is a valid xRange identifer, meaning "any version"
    -- Only the first item is strictly required.
    --src[XRANGEIDENTIFIERLOOSE] = src[NUMERICIDENTIFIERLOOSE] + '|x|X|\\*';
    --src[XRANGEIDENTIFIER] = src[NUMERICIDENTIFIER] + '|x|X|\\*';
    --
    --src[XRANGEPLAIN] = '[v=\\s]*(' + src[XRANGEIDENTIFIER] + ')' +
    --                   '(?:\\.(' + src[XRANGEIDENTIFIER] + ')' +
    --                   '(?:\\.(' + src[XRANGEIDENTIFIER] + ')' +
    --                   '(?:' + src[PRERELEASE] + ')?' +
    --                   src[BUILD] + '?' +
    --                   ')?)?';
    --
    --src[XRANGEPLAINLOOSE] = '[v=\\s]*(' + src[XRANGEIDENTIFIERLOOSE] + ')' +
    --                        '(?:\\.(' + src[XRANGEIDENTIFIERLOOSE] + ')' +
    --                        '(?:\\.(' + src[XRANGEIDENTIFIERLOOSE] + ')' +
    --                        '(?:' + src[PRERELEASELOOSE] + ')?' +
    --                        src[BUILD] + '?' +
    --                        ')?)?';
    --
    --src[XRANGE] = '^' + src[GTLT] + '\\s*' + src[XRANGEPLAIN] + '$';
    --src[XRANGELOOSE] = '^' + src[GTLT] + '\\s*' + src[XRANGEPLAINLOOSE] + '$';
    --
    -- Tilde ranges.
    -- Meaning is "reasonably at or greater than"
    --src[LONETILDE] = '(?:~>?)';
    --
    --src[TILDETRIM] = '(\\s*)' + src[LONETILDE] + '\\s+';
    --re[TILDETRIM] = new RegExp(src[TILDETRIM], 'g');
    --var tildeTrimReplace = '$1~';
    --
    --src[TILDE] = '^' + src[LONETILDE] + src[XRANGEPLAIN] + '$';
    --src[TILDELOOSE] = '^' + src[LONETILDE] + src[XRANGEPLAINLOOSE] + '$';
    --
    -- Caret ranges.
    -- Meaning is "at least and backwards compatible with"
    --src[LONECARET] = '(?:\\^)';
    --
    --src[CARETTRIM] = '(\\s*)' + src[LONECARET] + '\\s+';
    --re[CARETTRIM] = new RegExp(src[CARETTRIM], 'g');
    --var caretTrimReplace = '$1^';
    --
    --src[CARET] = '^' + src[LONECARET] + src[XRANGEPLAIN] + '$';
    --src[CARETLOOSE] = '^' + src[LONECARET] + src[XRANGEPLAINLOOSE] + '$';
    --
    -- A simple gt/lt/eq thing, or just "" to indicate "any version"
    --src[COMPARATORLOOSE] = '^' + src[GTLT] + '\\s*(' + LOOSEPLAIN + ')$|^$';
    --src[COMPARATOR] = '^' + src[GTLT] + '\\s*(' + FULLPLAIN + ')$|^$';
    --
    --
    -- An expression to strip any whitespace between the gtlt and the thing
    -- it modifies, so that `> 1.2.3` ==> `>1.2.3`
    --src[COMPARATORTRIM] = '(\\s*)' + src[GTLT] +
    --                      '\\s*(' + LOOSEPLAIN + '|' + src[XRANGEPLAIN] + ')';
    --
    -- this one has to use the /g flag
    --re[COMPARATORTRIM] = new RegExp(src[COMPARATORTRIM], 'g');
    --var comparatorTrimReplace = '$1$2$3';
    --
    --
    -- Something like `1.2.3 - 1.2.4`
    -- Note that these all use the loose form, because they'll be
    -- checked against either the strict or loose comparator form
    -- later.
    --src[HYPHENRANGE] = '^\\s*(' + src[XRANGEPLAIN] + ')' +
    --                   '\\s+-\\s+' +
    --                   '(' + src[XRANGEPLAIN] + ')' +
    --                   '\\s*$';
    --
    --src[HYPHENRANGELOOSE] = '^\\s*(' + src[XRANGEPLAINLOOSE] + ')' +
    --                        '\\s+-\\s+' +
    --                        '(' + src[XRANGEPLAINLOOSE] + ')' +
    --                        '\\s*$';
    --
    -- Star ranges basically just allow anything at all.
    --src[STAR] = '(<|>)?=?\\s*\\*';

    ----------------------------------------------------------------------------  
    function compareIdentifiers
    (
        a_this  in varchar2,
        a_other in varchar2
    ) return semver.compare_result_type is
        l_this_is_number  boolean := regexp_like(a_this, src(IS_NUMERIC).expression);
        l_other_is_number boolean := regexp_like(a_other, src(IS_NUMERIC).expression);
        l_this            integer;
        l_other           integer;
    begin
        --
        if l_this_is_number and l_other_is_number then
            l_this  := to_number(a_this);
            l_other := to_number(a_other);
        end if;
        -- NoFormat Start
        return 
            semver_util.ternary_pls_integer(l_this_is_number and not l_other_is_number, -1, 
                semver_util.ternary_pls_integer(l_other_is_number and not l_this_is_number,  1, 
                    semver_util.ternary_pls_integer(l_this < l_other, -1,
                        semver_util.ternary_pls_integer(l_this > l_other,  1, 0)
                    )
                )
            )
        ;
        -- NoFormat End
    end;

    ----------------------------------------------------------------------------  
    function rcompareIdentifiers
    (
        a_this  in varchar2,
        a_other in varchar2
    ) return semver.compare_result_type is
    begin
        return compareIdentifiers(a_other, a_this);
    end;

    ----------------------------------------------------------------------------  
    function compareMain
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return semver.compare_result_type is
        l_cmp_major_result semver.compare_result_type;
        l_cmp_minor_result semver.compare_result_type;
    begin
        l_cmp_major_result := compareIdentifiers(a_this.major, a_other.major);
        if l_cmp_major_result = semver.COMPARE_RESULT_EQ then
            l_cmp_minor_result := compareIdentifiers(a_this.minor, a_other.minor);
            if l_cmp_minor_result = semver.COMPARE_RESULT_EQ then
                return compareIdentifiers(a_this.patch, a_other.patch);
            else
                return l_cmp_minor_result;
            end if;
        else
            return l_cmp_major_result;
        end if;
    end;

    ----------------------------------------------------------------------------  
    function comparePrerelease
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return semver.compare_result_type is
        l_this_has_prerelease  boolean := a_this.prerelease is not null and a_this.prerelease.count > 0;
        l_other_has_prerelease boolean := a_other.prerelease is not null and a_other.prerelease.count > 0;
        l_idx                  pls_integer := 1;
    begin
        --  // NOT having a prerelease is > having one
        if l_this_has_prerelease and not l_other_has_prerelease then
            return semver.COMPARE_RESULT_LT;
        elsif not l_this_has_prerelease and l_other_has_prerelease then
            return semver.COMPARE_RESULT_GT;
        elsif not l_this_has_prerelease and not l_other_has_prerelease then
            return semver.COMPARE_RESULT_EQ;
        end if;
        --
        loop
            if a_this.prerelease(l_idx) is null and a_other.prerelease(l_idx) is null then
                return semver.COMPARE_RESULT_EQ;
            elsif a_other.prerelease(l_idx) is null then
                return semver.COMPARE_RESULT_GT;
            elsif a_this.prerelease(l_idx) is null then
                return semver.COMPARE_RESULT_LT;
            elsif a_this.prerelease(l_idx) = a_other.prerelease(l_idx) then
                null;
            else
                return compareIdentifiers(a_this.prerelease(l_idx), a_other.prerelease(l_idx));
            end if;
            l_idx := l_idx + 1;
        end loop;
    end;

    ----------------------------------------------------------------------------  
    function compare
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return semver.compare_result_type is
        l_compareMainResult semver.compare_result_type;
    begin
        l_compareMainResult := compareMain(a_this, a_other);
        if l_compareMainResult = semver.COMPARE_RESULT_EQ then
            return comparePrerelease(a_this, a_other);
        else
            return l_compareMainResult;
        end if;
    end;

    ----------------------------------------------------------------------------  
    function rcompare
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return semver.compare_result_type is
    begin
        return compare(a_other, a_this);
    end;

    -- preminor will bump the version up to the next minor release, and immediately
    -- down to pre-release. premajor and prepatch work the same way.
    ----------------------------------------------------------------------------
    procedure inc
    (
        a_this       in out nocopy semver_version,
        a_release    in varchar2,
        a_identifier in varchar2
    ) is
    begin
        case a_release
            when 'premajor' then
                a_this.build      := new semver_tags();
                a_this.prerelease := new semver_tags();
                a_this.patch      := 0;
                a_this.minor      := 0;
                a_this.major      := a_this.major + 1;
                inc(a_this, 'pre', a_identifier);
            when 'preminor' then
                a_this.build      := new semver_tags();
                a_this.prerelease := new semver_tags();
                a_this.patch      := 0;
                a_this.minor      := a_this.minor + 1;
                inc(a_this, 'pre', a_identifier);
            when 'prepatch' then
                -- If this is already a prerelease, it will bump to the next version
                -- drop any prereleases that might already exist, since they are not
                -- relevant at this point.
                a_this.build      := new semver_tags();
                a_this.prerelease := new semver_tags();
                inc(a_this, 'patch', a_identifier);
                inc(a_this, 'pre', a_identifier);
            when 'prerelease' then
                -- If the input is a non-prerelease version, this acts the same as
                -- prepatch.
                if a_this.prerelease is null or a_this.prerelease.count = 0 then
                    inc(a_this, 'patch', a_identifier);
                end if;
                inc(a_this, 'pre', a_identifier);
            when 'major' then
                -- If this is a pre-major version, bump up to the same major version.
                -- Otherwise increment major.
                -- 1.0.0-5 bumps to 1.0.0
                -- 1.1.0 bumps to 2.0.0
                if a_this.minor != 0 or a_this.patch != 0 or a_this.prerelease is null or a_this.prerelease.count = 0 then
                    a_this.major := a_this.major + 1;
                end if;
                a_this.minor      := 0;
                a_this.patch      := 0;
                a_this.build      := new semver_tags();
                a_this.prerelease := new semver_tags();
            when 'minor' then
                -- If this is a pre-minor version, bump up to the same minor version.
                -- Otherwise increment minor.
                -- 1.2.0-5 bumps to 1.2.0
                -- 1.2.1 bumps to 1.3.0
                if a_this.patch != 0 or a_this.prerelease is null or a_this.prerelease.count = 0 then
                    a_this.minor := a_this.minor + 1;
                end if;
                a_this.patch      := 0;
                a_this.build      := new semver_tags();
                a_this.prerelease := new semver_tags();
            when 'patch' then
                -- If this is not a pre-release version, it will increment the patch.
                -- If it is a pre-release it will bump up to the same patch version.
                -- 1.2.0-5 patches to 1.2.0
                -- 1.2.0 patches to 1.2.1
                if a_this.prerelease is null or a_this.prerelease.count = 0 then
                    a_this.patch := a_this.patch + 1;
                end if;
                a_this.build      := new semver_tags();
                a_this.prerelease := new semver_tags();
            when 'pre' then
                -- This probably shouldn't be used publicly.
                -- 1.0.0 "pre" would become 1.0.0-0 which is the wrong direction.            
                if a_this.prerelease is null or a_this.prerelease.count = 0 then
                    a_this.prerelease := new semver_tags('0');
                else
                    declare
                        l_idx pls_integer := a_this.prerelease.count;
                    begin
                        while l_idx > 0 loop
                            if regexp_like(a_this.prerelease(l_idx), src(IS_NUMERIC).expression) then
                                a_this.prerelease(l_idx) := a_this.prerelease(l_idx) + 1;
                                l_idx := -1;
                            end if;
                            l_idx := l_idx - 1;
                        end loop;
                        if l_idx = 0 then
                            -- didn't increment anything
                            a_this.prerelease.extend();
                            a_this.prerelease(a_this.prerelease.count) := '0';
                        end if;
                    end;
                end if;
                if a_identifier is not null then
                    -- 1.2.0-beta.1 bumps to 1.2.0-beta.2,
                    -- 1.2.0-beta.fooblz or 1.2.0-beta bumps to 1.2.0-beta.0
                    if a_this.prerelease(1) = a_identifier then
                        if not regexp_like(a_this.prerelease(2), src(IS_NUMERIC).expression) then
                            a_this.prerelease := new semver_tags(a_identifier, '0');
                        end if;
                    else
                        a_this.prerelease := new semver_tags(a_identifier, '0');
                    end if;
                end if;
            else
                raise_application_error(-20000, 'Invalid increment argument "' || a_release || '"');
        end case;
    end;

    ----------------------------------------------------------------------------
    function gt
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return boolean is
    begin
        return compare(a_this, a_other) = semver.COMPARE_RESULT_GT;
    end;

    ----------------------------------------------------------------------------
    function lt
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return boolean is
    begin
        return compare(a_this, a_other) = semver.COMPARE_RESULT_LT;
    end;

    ----------------------------------------------------------------------------
    function eq
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return boolean is
    begin
        return compare(a_this, a_other) = semver.COMPARE_RESULT_EQ;
    end;

    ----------------------------------------------------------------------------
    function neq
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return boolean is
    begin
        return compare(a_this, a_other) != semver.COMPARE_RESULT_EQ;
    end;

    ----------------------------------------------------------------------------
    function gte
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return boolean is
    begin
        return compare(a_this, a_other) in(semver.COMPARE_RESULT_GT, semver.COMPARE_RESULT_EQ);
    end;

    ----------------------------------------------------------------------------
    function lte
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return boolean is
    begin
        return compare(a_this, a_other) in(semver.COMPARE_RESULT_LT, semver.COMPARE_RESULT_EQ);
    end;

    ---------------------------------------------------------------------------- 
    function cmp
    (
        a_this  in semver_version,
        a_op    in varchar2,
        a_other in semver_version
    ) return boolean is
    begin
        case a_op
            when '===' then
                -- if (typeof a === 'object') a = a.version;
                -- if (typeof b === 'object') b = b.version;
                return a_this.format = a_other.format;
            when '!==' then
                -- if (typeof a === 'object') a = a.version;
                -- if (typeof b === 'object') b = b.version;
                return a_this.format != a_other.format;
            when '' then
                return eq(a_this, a_other);
            when '=' then
                return eq(a_this, a_other);
            when '==' then
                return eq(a_this, a_other);
            when '!=' then
                return neq(a_this, a_other);
            when '>' then
                return gt(a_this, a_other);
            when '>=' then
                return gte(a_this, a_other);
            when '<' then
                return lt(a_this, a_other);
            when '<=' then
                return lte(a_this, a_other);
            else
                raise_application_error(-20000, 'Invalid operator: "' || a_op || '"');
        end case;
    end;
    --
    --exports.Comparator = Comparator;
    --function Comparator(comp, loose) {
    --  if (comp instanceof Comparator) {
    --    if (comp.loose === loose)
    --      return comp;
    --    else
    --      comp = comp.value;
    --  }
    --
    --  if (!(this instanceof Comparator))
    --    return new Comparator(comp, loose);
    --
    --  debug('comparator', comp, loose);
    --  this.loose = loose;
    --  this.parse(comp);
    --
    --  if (this.semver === ANY)
    --    this.value = '';
    --  else
    --    this.value = this.operator + this.semver.version;
    --
    --  debug('comp', this);
    --}
    --
    --var ANY = {};
    --Comparator.prototype.parse = function(comp) {
    --  var r = this.loose ? re[COMPARATORLOOSE] : re[COMPARATOR];
    --  var m = comp.match(r);
    --
    --  if (!m)
    --    throw new TypeError('Invalid comparator: ' + comp);
    --
    --  this.operator = m[1];
    --  if (this.operator === '=')
    --    this.operator = '';
    --
    --  // if it literally is just '>' or '' then allow anything.
    --  if (!m[2])
    --    this.semver = ANY;
    --  else
    --    this.semver = new SemVer(m[2], this.loose);
    --};
    --
    --Comparator.prototype.toString = function() {
    --  return this.value;
    --};
    --
    --Comparator.prototype.test = function(FULLVERSION) {
    --  debug('Comparator.test', version, this.loose);
    --
    --  if (this.semver === ANY)
    --    return true;
    --
    --  if (typeof version === 'string')
    --    version = new SemVer(version, this.loose);
    --
    --  return cmp(version, this.operator, this.semver, this.loose);
    --};
    --
    --
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
    --Range.prototype.parseRange = function(range) {
    --  var loose = this.loose;
    --  range = range.trim();
    --  debug('range', range, loose);
    --  // `1.2.3 - 1.2.4` => `>=1.2.3 <=1.2.4`
    --  var hr = loose ? re[HYPHENRANGELOOSE] : re[HYPHENRANGE];
    --  range = range.replace(hr, hyphenReplace);
    --  debug('hyphen replace', range);
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
    --};
    --
    -- Mostly just for testing and legacy API reasons
    --exports.toComparators = toComparators;
    --function toComparators(range, loose) {
    --  return new Range(range, loose).set.map(function(comp) {
    --    return comp.map(function(c) {
    --      return c.value;
    --    }).join(' ').trim().split(' ');
    --  });
    --}
    --
    -- comprised of xranges, tildes, stars, and gtlt's at this point.
    -- already replaced the hyphen ranges
    -- turn into a set of JUST comparators.
    --function parseComparator(comp, loose) {
    --  debug('comp', comp);
    --  comp = replaceCarets(comp, loose);
    --  debug('caret', comp);
    --  comp = replaceTildes(comp, loose);
    --  debug('tildes', comp);
    --  comp = replaceXRanges(comp, loose);
    --  debug('xrange', comp);
    --  comp = replaceStars(comp, loose);
    --  debug('stars', comp);
    --  return comp;
    --}
    --
    --function isX(id) {
    --  return !id || id.toLowerCase() === 'x' || id === '*';
    --}
    --
    -- ~, ~> --> * (any, kinda silly)
    -- ~2, ~2.x, ~2.x.x, ~>2, ~>2.x ~>2.x.x --> >=2.0.0 <3.0.0
    -- ~2.0, ~2.0.x, ~>2.0, ~>2.0.x --> >=2.0.0 <2.1.0
    -- ~1.2, ~1.2.x, ~>1.2, ~>1.2.x --> >=1.2.0 <1.3.0
    -- ~1.2.3, ~>1.2.3 --> >=1.2.3 <1.3.0
    -- ~1.2.0, ~>1.2.0 --> >=1.2.0 <1.3.0
    --function replaceTildes(comp, loose) {
    --  return comp.trim().split(/\s+/).map(function(comp) {
    --    return replaceTilde(comp, loose);
    --  }).join(' ');
    --}
    --
    --function replaceTilde(comp, loose) {
    --  var r = loose ? re[TILDELOOSE] : re[TILDE];
    --  return comp.replace(r, function(_, M, m, p, pr) {
    --    debug('tilde', comp, _, M, m, p, pr);
    --    var ret;
    --
    --    if (isX(M))
    --      ret = '';
    --    else if (isX(m))
    --      ret = '>=' + M + '.0.0 <' + (+M + 1) + '.0.0';
    --    else if (isX(p))
    --      // ~1.2 == >=1.2.0 <1.3.0
    --      ret = '>=' + M + '.' + m + '.0 <' + M + '.' + (+m + 1) + '.0';
    --    else if (pr) {
    --      debug('replaceTilde pr', pr);
    --      if (pr.charAt(0) !== '-')
    --        pr = '-' + pr;
    --      ret = '>=' + M + '.' + m + '.' + p + pr +
    --            ' <' + M + '.' + (+m + 1) + '.0';
    --    } else
    --      // ~1.2.3 == >=1.2.3 <1.3.0
    --      ret = '>=' + M + '.' + m + '.' + p +
    --            ' <' + M + '.' + (+m + 1) + '.0';
    --
    --    debug('tilde return', ret);
    --    return ret;
    --  });
    --}
    --
    -- ^ --> * (any, kinda silly)
    -- ^2, ^2.x, ^2.x.x --> >=2.0.0 <3.0.0
    -- ^2.0, ^2.0.x --> >=2.0.0 <3.0.0
    -- ^1.2, ^1.2.x --> >=1.2.0 <2.0.0
    -- ^1.2.3 --> >=1.2.3 <2.0.0
    -- ^1.2.0 --> >=1.2.0 <2.0.0
    --function replaceCarets(comp, loose) {
    --  return comp.trim().split(/\s+/).map(function(comp) {
    --    return replaceCaret(comp, loose);
    --  }).join(' ');
    --}
    --
    --function replaceCaret(comp, loose) {
    --  debug('caret', comp, loose);
    --  var r = loose ? re[CARETLOOSE] : re[CARET];
    --  return comp.replace(r, function(_, M, m, p, pr) {
    --    debug('caret', comp, _, M, m, p, pr);
    --    var ret;
    --
    --    if (isX(M))
    --      ret = '';
    --    else if (isX(m))
    --      ret = '>=' + M + '.0.0 <' + (+M + 1) + '.0.0';
    --    else if (isX(p)) {
    --      if (M === '0')
    --        ret = '>=' + M + '.' + m + '.0 <' + M + '.' + (+m + 1) + '.0';
    --      else
    --        ret = '>=' + M + '.' + m + '.0 <' + (+M + 1) + '.0.0';
    --    } else if (pr) {
    --      debug('replaceCaret pr', pr);
    --      if (pr.charAt(0) !== '-')
    --        pr = '-' + pr;
    --      if (M === '0') {
    --        if (m === '0')
    --          ret = '>=' + M + '.' + m + '.' + p + pr +
    --                ' <' + M + '.' + m + '.' + (+p + 1);
    --        else
    --          ret = '>=' + M + '.' + m + '.' + p + pr +
    --                ' <' + M + '.' + (+m + 1) + '.0';
    --      } else
    --        ret = '>=' + M + '.' + m + '.' + p + pr +
    --              ' <' + (+M + 1) + '.0.0';
    --    } else {
    --      debug('no pr');
    --      if (M === '0') {
    --        if (m === '0')
    --          ret = '>=' + M + '.' + m + '.' + p +
    --                ' <' + M + '.' + m + '.' + (+p + 1);
    --        else
    --          ret = '>=' + M + '.' + m + '.' + p +
    --                ' <' + M + '.' + (+m + 1) + '.0';
    --      } else
    --        ret = '>=' + M + '.' + m + '.' + p +
    --              ' <' + (+M + 1) + '.0.0';
    --    }
    --
    --    debug('caret return', ret);
    --    return ret;
    --  });
    --}
    --
    --function replaceXRanges(comp, loose) {
    --  debug('replaceXRanges', comp, loose);
    --  return comp.split(/\s+/).map(function(comp) {
    --    return replaceXRange(comp, loose);
    --  }).join(' ');
    --}
    --
    --function replaceXRange(comp, loose) {
    --  comp = comp.trim();
    --  var r = loose ? re[XRANGELOOSE] : re[XRANGE];
    --  return comp.replace(r, function(ret, gtlt, M, m, p, pr) {
    --    debug('xRange', comp, ret, gtlt, M, m, p, pr);
    --    var xM = isX(M);
    --    var xm = xM || isX(m);
    --    var xp = xm || isX(p);
    --    var anyX = xp;
    --
    --    if (gtlt === '=' && anyX)
    --      gtlt = '';
    --
    --    if (xM) {
    --      if (gtlt === '>' || gtlt === '<') {
    --        // nothing is allowed
    --        ret = '<0.0.0';
    --      } else {
    --        // nothing is forbidden
    --        ret = '*';
    --      }
    --    } else if (gtlt && anyX) {
    --      // replace X with 0
    --      if (xm)
    --        m = 0;
    --      if (xp)
    --        p = 0;
    --
    --      if (gtlt === '>') {
    --        // >1 => >=2.0.0
    --        // >1.2 => >=1.3.0
    --        // >1.2.3 => >= 1.2.4
    --        gtlt = '>=';
    --        if (xm) {
    --          M = +M + 1;
    --          m = 0;
    --          p = 0;
    --        } else if (xp) {
    --          m = +m + 1;
    --          p = 0;
    --        }
    --      } else if (gtlt === '<=') {
    --        // <=0.7.x is actually <0.8.0, since any 0.7.x should
    --        // pass.  Similarly, <=7.x is actually <8.0.0, etc.
    --        gtlt = '<';
    --        if (xm)
    --          M = +M + 1;
    --        else
    --          m = +m + 1;
    --      }
    --
    --      ret = gtlt + M + '.' + m + '.' + p;
    --    } else if (xm) {
    --      ret = '>=' + M + '.0.0 <' + (+M + 1) + '.0.0';
    --    } else if (xp) {
    --      ret = '>=' + M + '.' + m + '.0 <' + M + '.' + (+m + 1) + '.0';
    --    }
    --
    --    debug('xRange return', ret);
    --
    --    return ret;
    --  });
    --}
    --
    -- Because * is AND-ed with everything else in the comparator,
    -- and '' means "any version", just remove the *s entirely.
    --function replaceStars(comp, loose) {
    --  debug('replaceStars', comp, loose);
    --  // Looseness is ignored here.  star is always as loose as it gets!
    --  return comp.trim().replace(re[STAR], '');
    --}
    --
    -- This function is passed to string.replace(re[HYPHENRANGE])
    -- M, m, patch, prerelease, build
    -- 1.2 - 3.4.5 => >=1.2.0 <=3.4.5
    -- 1.2.3 - 3.4 => >=1.2.0 <3.5.0 Any 3.4.x will do
    -- 1.2 - 3.4 => >=1.2.0 <3.5.0
    --function hyphenReplace($0,
    --                       from, fM, fm, fp, fpr, fb,
    --                       to, tM, tm, tp, tpr, tb) {
    --
    --  if (isX(fM))
    --    from = '';
    --  else if (isX(fm))
    --    from = '>=' + fM + '.0.0';
    --  else if (isX(fp))
    --    from = '>=' + fM + '.' + fm + '.0';
    --  else
    --    from = '>=' + from;
    --
    --  if (isX(tM))
    --    to = '';
    --  else if (isX(tm))
    --    to = '<' + (+tM + 1) + '.0.0';
    --  else if (isX(tp))
    --    to = '<' + tM + '.' + (+tm + 1) + '.0';
    --  else if (tpr)
    --    to = '<=' + tM + '.' + tm + '.' + tp + '-' + tpr;
    --  else
    --    to = '<=' + to;
    --
    --  return (from + ' ' + to).trim();
    --}
    --
    --
    -- if ANY of the sets match ALL of its comparators, then pass
    --Range.prototype.test = function(FULLVERSION) {
    --  if (!version)
    --    return false;
    --
    --  if (typeof version === 'string')
    --    version = new SemVer(version, this.loose);
    --
    --  for (var i = 0; i < this.set.length; i++) {
    --    if (testSet(this.set[i], version))
    --      return true;
    --  }
    --  return false;
    --};
    --
    --function testSet(set, version) {
    --  for (var i = 0; i < set.length; i++) {
    --    if (!set[i].test(FULLVERSION))
    --      return false;
    --  }
    --
    --  if (version.prerelease.length) {
    --    // Find the set of versions that are allowed to have prereleases
    --    // For example, ^1.2.3-pr.1 desugars to >=1.2.3-pr.1 <2.0.0
    --    // That should allow `1.2.3-pr.2` to pass.
    --    // However, `1.2.4-alpha.notready` should NOT be allowed,
    --    // even though it's within the range set by the comparators.
    --    for (var i = 0; i < set.length; i++) {
    --      debug(set[i].semver);
    --      if (set[i].semver === ANY)
    --        continue;
    --
    --      if (set[i].semver.prerelease.length > 0) {
    --        var allowed = set[i].semver;
    --        if (allowed.major === version.major &&
    --            allowed.minor === version.minor &&
    --            allowed.patch === version.patch)
    --          return true;
    --      }
    --    }
    --
    --    // Version has a -pre, but it's not one of the ones we like.
    --    return false;
    --  }
    --
    --  return true;
    --}
    --
    --exports.satisfies = satisfies;
    --function satisfies(version, range, loose) {
    --  try {
    --    range = new Range(range, loose);
    --  } catch (er) {
    --    return false;
    --  }
    --  return range.test(FULLVERSION);
    --}
    --
    --exports.maxSatisfying = maxSatisfying;
    --function maxSatisfying(versions, range, loose) {
    --  return versions.filter(function(FULLVERSION) {
    --    return satisfies(version, range, loose);
    --  }).sort(function(a, b) {
    --    return rcompare(a, b, loose);
    --  })[0] || null;
    --}
    --
    --exports.minSatisfying = minSatisfying;
    --function minSatisfying(versions, range, loose) {
    --  return versions.filter(function(FULLVERSION) {
    --    return satisfies(version, range, loose);
    --  }).sort(function(a, b) {
    --    return compare(a, b, loose);
    --  })[0] || null;
    --}
    --
    --exports.validRange = validRange;
    --function validRange(range, loose) {
    --  try {
    --    // Return '*' instead of '' so that truthiness works.
    --    // This will throw if it's invalid anyway
    --    return new Range(range, loose).range || '*';
    --  } catch (er) {
    --    return null;
    --  }
    --}
    --
    -- Determine if version is less than all the versions possible in the range
    --exports.ltr = ltr;
    --function ltr(version, range, loose) {
    --  return outside(version, range, '<', loose);
    --}
    --
    -- Determine if version is greater than all the versions possible in the range.
    --exports.gtr = gtr;
    --function gtr(version, range, loose) {
    --  return outside(version, range, '>', loose);
    --}
    --
    --exports.outside = outside;
    --function outside(version, range, hilo, loose) {
    --  version = new SemVer(version, loose);
    --  range = new Range(range, loose);
    --
    --  var gtfn, ltefn, ltfn, comp, ecomp;
    --  switch (hilo) {
    --    case '>':
    --      gtfn = gt;
    --      ltefn = lte;
    --      ltfn = lt;
    --      comp = '>';
    --      ecomp = '>=';
    --      break;
    --    case '<':
    --      gtfn = lt;
    --      ltefn = gte;
    --      ltfn = gt;
    --      comp = '<';
    --      ecomp = '<=';
    --      break;
    --    default:
    --      throw new TypeError('Must provide a hilo val of "<" or ">"');
    --  }
    --
    --  // If it satisifes the range it is not outside
    --  if (satisfies(version, range, loose)) {
    --    return false;
    --  }
    --
    --  // From now on, variable terms are as if we're in "gtr" mode.
    --  // but note that everything is flipped for the "ltr" function.
    --
    --  for (var i = 0; i < range.set.length; ++i) {
    --    var comparators = range.set[i];
    --
    --    var high = null;
    --    var low = null;
    --
    --    comparators.forEach(function(comparator) {
    --      if (comparator.semver === ANY) {
    --        comparator = new Comparator('>=0.0.0')
    --      }
    --      high = high || comparator;
    --      low = low || comparator;
    --      if (gtfn(comparator.semver, high.semver, loose)) {
    --        high = comparator;
    --      } else if (ltfn(comparator.semver, low.semver, loose)) {
    --        low = comparator;
    --      }
    --    });
    --
    --    // If the edge version comparator has a operator then our version
    --    // isn't outside it
    --    if (high.operator === comp || high.operator === ecomp) {
    --      return false;
    --    }
    --
    --    // If the lowest version comparator has an operator and our version
    --    // is less than it then it isn't higher than the range
    --    if ((!low.operator || low.operator === comp) &&
    --        ltefn(version, low.semver)) {
    --      return false;
    --    } else if (low.operator === ecomp && ltfn(version, low.semver)) {
    --      return false;
    --    }
    --  }
    --  return true;
    --}
    --

    ----------------------------------------------------------------------------
    function parse(a_value in varchar2) return semver_version is
        l_result      semver_version;
        l_semverParts semver_tags;
    
        function parse_suffix
        (
            a_value             in varchar2,
            a_identifier_regexp in varchar2
        ) return semver_tags is
            l_result semver_tags;
            e_divide_by_zero exception;
            pragma exception_init(e_divide_by_zero, -1476);
        begin
            -- NoFormat Start
            with identifier as
             (select semver_util.value_at_position(a_value, '.', level) as value from dual connect by level <= regexp_count(a_value, '\.') + 1)
            select value bulk collect into l_result
              from identifier
             where -- raise exception when value is not numeric or nonnumeric identifier
                   1 / case when regexp_like(value, '^' || src(a_identifier_regexp).expression || '$') then 1 else 0 end = 1;
            -- noformat end
            return l_result;
        exception
            when e_divide_by_zero then
                raise_application_error(-20000, 'Invalid ' || a_identifier_regexp || ' specified: "' || a_Value || '"');
        end;
    
    begin
        d.log('parsing value "' || a_value || '"');
        -- validate
        if length(a_value) > semver_common.MAX_LENGTH then
            raise_application_error(-20000, 'Value too long.');
        end if;
        --
        if regexp_like(a_value, src(FULLVERSION).expression, src(FULLVERSION).modifier) then
            d.log('value satisfies FULLVERSION regexp');
            select value
              bulk collect
              into l_semverParts
              from (select regexp_substr(a_value, src(FULLVERSION).expression, 1, 1, src(FULLVERSION).modifier, N) as value
                      from dual, (select level as N from dual connect by level <= 5))
             where regexp_like(value, '[0-9]+') -- major, minor, patch
                or value like '-%' -- prerelease
                or value like '+%' -- build
            ;
            --
            l_result := new semver_version(major => to_number(l_semverParts(1)),
                                           minor => to_number(l_semverParts(2)),
                                           patch => to_number(l_semverParts(3)));
            --
            if l_semverParts.count > 3 then
                if l_semverParts(4) like '-%' then
                    d.log('parsing prerelease "' || l_semverParts(4) || '"');
                    l_result.prerelease := parse_suffix(substr(l_semverParts(4), 2), PRERELEASEIDENTIFIER);
                else
                    d.log('parsing build "' || l_semverParts(4) || '"');
                    l_result.build := parse_suffix(substr(l_semverParts(4), 2), BUILDIDENTIFIER);
                end if;
            end if;
            --
            if l_semverParts.count > 4 then
                d.log('parsing build "' || l_semverParts(5) || '"');
                l_result.build := parse_suffix(substr(l_semverParts(5), 2), BUILDIDENTIFIER);
            end if;
            --
            d.log('successfully parsed');
            return l_result;
            --
        else
            raise_application_error(-20000, 'Invalid SemVer string "' || a_value || '"');
        end if;
        --
    exception
        when others then
            raise_application_error(-20000, 'Invalid SemVer string "' || a_value || '"' || chr(10) || sqlerrm);
    end;

    ----------------------------------------------------------------------------  
    function to_string(a_semver in semver_version) return varchar2 is
    begin
        -- NoFormat Start
        return
            a_semver.major || '.' ||
            a_semver.minor || '.' ||
            a_semver.patch ||
            semver_util.ternary_varchar2(
                a_semver.prerelease is not null and a_semver.prerelease.count > 0,
                '-' || semver_util.join_semver_tags(a_semver.prerelease, '.')
            ) ||
            semver_util.ternary_varchar2(
                a_semver.build is not null and a_semver.build.count > 0,
                '+' || semver_util.join_semver_tags(a_semver.build, '.')
            )
        ;
        -- NoFormat End
    end;

    ----------------------------------------------------------------------------
    function valid(a_value in varchar2) return varchar2 is
        l_semver semver_version;
    begin
        d.log('validating value> ' || a_value);
        <<try_parse_version>>
        begin
            l_semver := parse(a_value);
            d.log('value is valid semver string');
            return to_string(l_semver);
        exception
            when others then
                d.log('value is not valid semver string > return null');
                return null;
        end try_parse_version;
    end;

    ----------------------------------------------------------------------------
    function clean(a_value in varchar2) return varchar2 is
    begin
        return valid(regexp_replace(a_value, '^[=v]+', ''));
    end;

begin
    src(IS_NUMERIC) := semver_common.regexpRecord('^[0-9]+$');
    src(DELIMITERS) := semver_common.regexpRecord('(\.)|(\+)|-');
    src(NUMERICIDENTIFIER) := semver_common.regexpRecord('0|[1-9]\d*');
    src(NONNUMERICIDENTIFIER) := semver_common.regexpRecord('\d*[a-zA-Z-][a-zA-Z0-9-]*');
    src(BUILDIDENTIFIER) := semver_common.regexpRecord('[0-9a-zA-Z-]+');
    -- NoFormat Start
    src(MAINVERSION) := semver_common.regexpRecord('(' || src(NUMERICIDENTIFIER).expression || ')\.' ||
                                     '(' || src(NUMERICIDENTIFIER).expression || ')\.' ||
                                     '(' || src(NUMERICIDENTIFIER).expression || ')');
    src(PRERELEASEIDENTIFIER) := semver_common.regexpRecord('(' || src(NUMERICIDENTIFIER).expression ||
                                              '|' || src(NONNUMERICIDENTIFIER).expression || ')');
    src(PRERELEASE) := semver_common.regexpRecord('(-(' || src(PRERELEASEIDENTIFIER).expression ||
                                    '(\.' || src(PRERELEASEIDENTIFIER).expression || ')*))');
    src(BUILD) := semver_common.regexpRecord('(\+(' || src(BUILDIDENTIFIER).expression ||
                               '(\.' || src(BUILDIDENTIFIER).expression || ')*))');
    --
    -- oracle's regexp implementation just sucks
    --src(FULLVERSION) := regexpRecord('^' || 'v?' || src(MAINVERSION).expression || src(PRERELEASE).expression || '?' || src(BUILD).expression || '?' || '$');
    -- simplified
    src(FULLVERSION) := semver_common.regexpRecord('^v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-[a-zA-Z0-9\.-]*)?(\+[a-zA-Z0-9\.-]*)?$');
    -- NoFormat End
end;
/
