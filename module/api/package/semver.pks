create or replace package semver as

    -- Note: this is the semver.org version of the spec that it implements
    -- Not necessarily the package version of this code.
    SEMVER_SPEC_VERSION constant varchar2(10) := '2.0.0';

    MAX_SAFE_INTEGER constant integer := 9007199254740991;
    MAX_LENGTH       constant pls_integer := 256;

    subtype compare_result_type is pls_integer range - 1 .. 1;
    COMPARE_RESULT_LT constant compare_result_type := -1;
    COMPARE_RESULT_EQ constant compare_result_type := 0;
    COMPARE_RESULT_GT constant compare_result_type := 1;

    type semver_version_table_type is table of semver_version;
    type semver_string_table_type is table of varchar2(256);

    -- parse
    function parse(value in varchar2) return semver_version;

    COMPARATOR_ANY constant semver_comparator := new semver_comparator(null, null);

    subtype exception_sqlerrm_type is varchar2(255);

    INVALID_VERSION_SQLCODE constant pls_integer := -20001;
    INVALID_VERSION_SQLERRM constant exception_sqlerrm_type := 'Invalid Version "$1"';
    invalid_version_error exception;
    pragma exception_init(invalid_version_error, -20001);

    VERSION_TOO_LONG_SQLCODE constant pls_integer := -20002;
    VERSION_TOO_LONG_SQLERRM constant exception_sqlerrm_type := 'Version is longer than $1 characters';
    version_too_long_error exception;
    pragma exception_init(version_too_long_error, -20002);

    -- diff
    function diff
    (
        version1 in varchar2,
        version2 in varchar2
    ) return varchar2;

    function major(value in varchar2) return pls_integer;

    function minor(value in varchar2) return pls_integer;

    function patch(value in varchar2) return pls_integer;

    function prerelease(value in varchar2) return semver_tags;

    function build(value in varchar2) return semver_tags;

    function compare
    (
        version1 in varchar2,
        version2 in varchar2
    ) return compare_result_type;

    function compareIdentifiers
    (
        identifier1 in varchar2,
        identifier2 in varchar2
    ) return compare_result_type;

    function rcompareIdentifiers
    (
        identifier1 in varchar2,
        identifier2 in varchar2
    ) return compare_result_type;

    procedure sort(semver_version_table in out nocopy semver_version_table_type);
    procedure sort(semver_string_table in out nocopy semver_string_table_type);

    procedure rsort(semver_version_table in out nocopy semver_version_table_type);
    procedure rsort(semver_string_table in out nocopy semver_string_table_type);

    function gt
    (
        version1 in varchar2,
        version2 in varchar2
    ) return boolean;

    function lt
    (
        version1 in varchar2,
        version2 in varchar2
    ) return boolean;

    function eq
    (
        version1 in varchar2,
        version2 in varchar2
    ) return boolean;

    function neq
    (
        version1 in varchar2,
        version2 in varchar2
    ) return boolean;

    function gte
    (
        version1 in varchar2,
        version2 in varchar2
    ) return boolean;

    function lte
    (
        version1 in varchar2,
        version2 in varchar2
    ) return boolean;

    function cmp
    (
        version1 in varchar2,
        oper     in varchar2,
        version2 in varchar2
    ) return boolean;

    function valid(value in varchar2) return varchar2;

    function clean(value in varchar2) return varchar2;

    function inc
    (
        value      in varchar2,
        release    in varchar2,
        identifier in varchar2 default null
    ) return varchar2;

    ----------------------------------------------------------------------------  
    -- range methods
    ----------------------------------------------------------------------------  

    function parse_range(value in varchar2) return semver_range_set;

    function valid_range(value in varchar2) return varchar2;

    function satisfies
    (
        version   in varchar2,
        range_set in varchar2
    ) return boolean;

    function intersects
    (
        range1 in varchar2,
        range2 in varchar2
    ) return boolean;

    function max_satisfying
    (
        versions  in semver_string_table_type,
        range_set in varchar2
    ) return varchar2;

    function min_satisfying
    (
        versions  in semver_string_table_type,
        range_set in varchar2
    ) return varchar2;

    function gtr
    (
        version   in varchar2,
        range_set in varchar2
    ) return boolean;

    function ltr
    (
        version   in varchar2,
        range_set in varchar2
    ) return boolean;

end;
/
