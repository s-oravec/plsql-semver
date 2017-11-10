create or replace package semver_common as

    MAX_LENGTH constant pls_integer := 256;

    subtype typ_regexp_expression is varchar2(4000);
    subtype typ_regexp_modifier is varchar2(30);
    type typ_regexp is record(
        expression typ_regexp_expression,
        modifier   typ_regexp_modifier);
    subtype typ_regexp_name is varchar2(30);
    type typ_regexp_tab is table of typ_regexp index by varchar2(30);

    function regexpRecord
    (
        a_expression in typ_regexp_expression,
        a_modifier   in typ_regexp_modifier default null
    ) return typ_regexp;

    -- Numeric
    IS_NUMERIC constant typ_regexp_name := 'IS_NUMERIC';

    -- Delimiters
    DELIMITERS constant typ_regexp_name := 'DELIMITERS';

    --
    -- The following Regular Expressions can be used for tokenizing,
    -- validating, and parsing SemVer version strings.
    --
    -- ## Numeric Identifier
    -- A single `0`, or a non-zero digit followed by zero or more digits.
    --
    NUMERICIDENTIFIER constant typ_regexp_name := 'NUMERICIDENTIFIER';

    --
    -- ## Non-numeric Identifier
    -- Zero or more digits, followed by a letter or hyphen, and then zero or
    -- more letters, digits, or hyphens.
    --
    NONNUMERICIDENTIFIER constant typ_regexp_name := 'NONNUMERICIDENTIFIER';
    --
    -- ## Main Version
    -- Three dot-separated numeric identifiers.
    --
    MAINVERSION constant typ_regexp_name := 'MAINVERSION';
    --
    -- ## Pre-release Version Identifier
    -- A numeric identifier, or a non-numeric identifier.
    --
    PRERELEASEIDENTIFIER constant typ_regexp_name := 'PRERELEASEIDENTIFIER';
    --
    --
    -- ## Pre-release Version
    -- Hyphen, followed by one or more dot-separated pre-release version
    -- identifiers.
    --
    PRERELEASE constant typ_regexp_name := 'PRERELEASE';
    --
    -- ## Build Metadata Identifier
    -- Any combination of digits, letters, or hyphens.
    --
    BUILDIDENTIFIER constant typ_regexp_name := 'BUILDIDENTIFIER';
    --
    -- ## Build Metadata
    -- Plus sign, followed by one or more period-separated build metadata
    -- identifiers.
    --
    BUILD constant typ_regexp_name := 'BUILD';
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
    FULLVERSION constant typ_regexp_name := 'FULLVERSION';

    --
    GTLT constant typ_regexp_name := 'GTLT';
    --
    -- Something like "2.*" or "1.2.x".
    -- Note that "x.x" is a valid xRange identifer, meaning "any version"
    -- Only the first item is strictly required.
    --
    XRANGEIDENTIFIER constant typ_regexp_name := 'XRANGEIDENTIFIER';
    XRANGEPLAIN constant typ_regexp_name := 'XRANGEPLAIN';
    XRANGE constant typ_regexp_name := 'XRANGE';
    --
    -- Tilde ranges.
    -- Meaning is "reasonably at or greater than"
    --
    LONETILDE constant typ_regexp_name := 'LONETILDE';
    TILDETRIM constant typ_regexp_name := 'TILDETRIM';
    TILDE constant typ_regexp_name := 'TILDE';
    --
    -- Caret ranges.
    -- Meaning is "at least and backwards compatible with"
    --
    LONECARET constant typ_regexp_name := 'LONECARET';
    CARETTRIM constant typ_regexp_name := 'CARETTRIM';
    CARET constant typ_regexp_name := 'CARET';
    --
    -- A simple gt/lt/eq thing, or just "" to indicate "any version"
    COMPARATOR constant typ_regexp_name := 'COMPARATOR';
    --
    -- TODO:
    -- An expression to strip any whitespace between the gtlt and the thing
    -- it modifies, so that `> 1.2.3` ==> `>1.2.3`
    --
    -- Something like `1.2.3 - 1.2.4`
    -- Note that these all use the loose form, because they'll be
    -- checked against either the strict or loose comparator form
    -- later.
    HYPHENRANGE constant typ_regexp_name := 'HYPHENRANGE';
    --
    -- Star ranges basically just allow anything at all.
    STAR constant typ_regexp_name := 'STAR';
    --
    function src(a_regexp_name in typ_regexp_name) return typ_regexp;

end;
/
