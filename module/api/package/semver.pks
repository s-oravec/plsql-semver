create or replace package semver as

    /**
    
    Semantic versioning package for PL/SQL
    
    */

    /** # Version */

    -- Note: this is the semver.org version of the spec that it implements
    -- Not necessarily the package version of this code.
    SEMVER_SPEC_VERSION constant varchar2(10) := '2.0.0';

    /**
    
    Maximal integer version version component
    
    */
    MAX_SAFE_INTEGER constant integer := 9007199254740991;

    /** Maximal version string length  */
    MAX_LENGTH constant pls_integer := 256;

    /** Comparison result subtype */
    subtype compare_result_type is pls_integer range - 1 .. 1;
    /** comparision result, when first value is less than the second */
    COMPARE_RESULT_LT constant compare_result_type := -1;
    /** comparision result, when both values are equal */
    COMPARE_RESULT_EQ constant compare_result_type := 0;
    /** comparision result, when first value is greater than the second */
    COMPARE_RESULT_GT constant compare_result_type := 1;

    /**
    
    Parse version into `semver_version` object.
    
    %param version SemVer Version string
    %return `semver_version` object, `null` if `version`is not a valid **SemVer** version
    
    */
    function parse(version in varchar2) return semver_version;

    /**
    
    Return the major version number.
    
    */
    function major(version in varchar2) return pls_integer;

    /**
    
    Return the minor version number.
    
    */
    function minor(version in varchar2) return pls_integer;

    /**
    
    Return the patch version number.
    
    */
    function patch(version in varchar2) return pls_integer;

    /**
    
    Return table of prerelease tags.
    
    */
    function prerelease(version in varchar2) return semver_tags;

    /**
    
    Return the table of build tags.
    
    */
    function build(version in varchar2) return semver_tags;

    /**
    
    Return the parsed version, or null if it's not valid.
    
    %param version SemVer string
    %return parsed and cleaned SemVer Version string
    
    */
    function valid(version in varchar2) return varchar2;

    /** release type subtype */
    subtype release_type is varchar2(30);
    /** major release */
    RELEASE_MAJOR constant release_type := 'major';
    /** minor release */
    RELEASE_MINOR constant release_type := 'minor';
    /** patch release */
    RELEASE_PATCH constant release_type := 'patch';
    /** premajor release */
    RELEASE_PREMAJOR constant release_type := 'premajor';
    /** preminor release */
    RELEASE_PREMINOR constant release_type := 'preminor';
    /** prepatch release */
    RELEASE_PREPATCH constant release_type := 'prepatch';
    /** prerelease release */
    RELEASE_PRERELEASE constant release_type := 'prerelease';

    /**
    
    Returns difference between two versions by the release type (major, premajor, minor, preminor, patch, prepatch, or prerelease), or null if the versions are the same.
    
    %param version1 SemVer Version string
    %param version2 SemVer Version string
    %return versoin component in which versions differ otherwise null
    
    */
    function diff
    (
        version1 in varchar2,
        version2 in varchar2
    ) return release_type;

    /**
    
    Compare versions and return comparison result
    
    %param version1 SemVer version
    %param version2 SemVer version
    %return comparison result -1 - less than, 0 - equal, 1 - greater than
    
    */
    function compare
    (
        version1 in varchar2,
        version2 in varchar2
    ) return compare_result_type;

    /**
    
    Reverse compare versions and return comparison result
    
    %param version1 SemVer version
    %param version2 SemVer version
    %return comparison result -1 - less than, 0 - equal, 1 - greater than
    
    */
    function rcompare
    (
        version1 in varchar2,
        version2 in varchar2
    ) return compare_result_type;

    /** Table of SemVer version objects type */
    type semver_version_table_type is table of semver_version;
    /** Table of SemVer version string type */
    type semver_string_table_type is table of varchar2(256);

    /**
    
    Sort table of SemVer Version objects
    
    %param semver_version_table table of SemVer Version objects
    %return sorted table
    
    */
    procedure sort(semver_version_table in out nocopy semver_version_table_type);

    /**
    
    Sort table of SemVer Version strings
    
    %param semver_version_table table of SemVer Version strings
    %return sorted table
    
    */
    procedure sort(semver_string_table in out nocopy semver_string_table_type);

    /**
    
    Reverse sort table of SemVer Version objects
    
    %param semver_version_table table of SemVer Version objects
    %return reverse sorted table
    
    */
    procedure rsort(semver_version_table in out nocopy semver_version_table_type);

    /**
    
    Reverse sort table of SemVer Version strings
    
    %param semver_version_table table of SemVer Version strings
    %return reverse sorted table
    
    */
    procedure rsort(semver_string_table in out nocopy semver_string_table_type);

    /**
    
    version1 > version2
    
    */
    function gt
    (
        version1 in varchar2,
        version2 in varchar2
    ) return boolean;

    /**
    
    version1 < version2
    
    */
    function lt
    (
        version1 in varchar2,
        version2 in varchar2
    ) return boolean;

    /**
    
    version1 = version2
    
    */
    function eq
    (
        version1 in varchar2,
        version2 in varchar2
    ) return boolean;

    /**
    
    version1 != version2
    
    */
    function neq
    (
        version1 in varchar2,
        version2 in varchar2
    ) return boolean;

    /**
    
    version1 >= version2
    
    */
    function gte
    (
        version1 in varchar2,
        version2 in varchar2
    ) return boolean;

    /**
    
    version1 >= version2
    
    */
    function lte
    (
        version1 in varchar2,
        version2 in varchar2
    ) return boolean;

    /**
    
    Pass in an operator, and it'll call the corresponding function above. Throws if an invalid operator is provided.
    
    %param version1 SemVer Version string
    %param operator operator - =, !=, >, <, >=, >=
    %param version2 SemVer Version string
    
    */
    function cmp
    (
        version1 in varchar2,
        operator in varchar2,
        version2 in varchar2
    ) return boolean;

    /**
    
    Remove excesive characters and return SemVer Version string
    
    %param version SemVer Version string
    
    */
    function clean(version in varchar2) return varchar2;

    /**
      
      Return the version incremented by the version component or null if it's not valid
    
    
      * `premajor` in one call will bump the version up to the next major
      version and down to a prerelease of that major version.
      `preminor`, and `prepatch` work the same way.
    * If called from a non-prerelease version, the `prerelease` will work the
      same as `prepatch`. It increments the patch version, then makes a
      prerelease. If the input version is already a prerelease it simply
      increments it.
      
      */
    function inc
    (
        version    in varchar2,
        release    in release_type,
        identifier in varchar2 default null
    ) return varchar2;

    /** # Ranges */

    /**
    
    Parse value into `semver_range` object.
    
    %param range range string
    %return `semver_range` object, `null` if `range` is not a valid SemVer Range string
    
    */
    function parse_range(range in varchar2) return semver_range;

    /**
    
    Return the valid range or null if it's not valid
    
    %param range SemVer Range string
    %return valid range
    
    */
    function valid_range(range in varchar2) return varchar2;

    /**
    
    Return true if the version satisfies the range.
    
    %param version SemVer Version string
    %param range SemVer Range string
    %return true if version satisfies range otherwise false
    
    */
    function satisfies
    (
        version in varchar2,
        range   in varchar2
    ) return boolean;

    /**
    
    Return true if any of the ranges comparators intersect
    
    %param range1 SemVer Range string
    %param range2 SemVer Range string
    %return true if ranges intersect otherwise false
    
    */
    function intersects
    (
        range1 in varchar2,
        range2 in varchar2
    ) return boolean;

    /**
    
    Return the highest version in the list that satisfies the range, or null if none of them do.
    
    %param versions table of versions
    %param range SemVer Range string
    %return highest version satisfying the range or null if none of them do
    
    */
    function max_satisfying
    (
        versions in semver_string_table_type,
        range    in varchar2
    ) return varchar2;

    /**
    
    Return the lowest version in the list that satisfies the range, or null if none of them do.
    
    %param versions table of versions
    %param range SemVer Range string
    %return lowest version satisfying the range or null if none of them do
    
    */
    function min_satisfying
    (
        versions in semver_string_table_type,
        range    in varchar2
    ) return varchar2;

    /**
    
    Return true if version is greater than all the versions possible in the range.
    
    %param versions table of versions
    %param range SemVer Range string
    %return true if version is greater than all the versions in the range otherwise false
    
    */
    function gtr
    (
        version in varchar2,
        range   in varchar2
    ) return boolean;

    /**
    
    Return true if version is less than all the versions possible in the range.
    
    %param versions table of versions
    %param range SemVer Range string
    %return true if version is lower than all the versions in the range otherwise false
    
    */
    function ltr
    (
        version in varchar2,
        range   in varchar2
    ) return boolean;

    /** # Exceptions */

    /** Exception SQL Error Message subtype */
    subtype exception_sqlerrm_type is varchar2(255);

    /** Invalid version SQL Error code */
    INVALID_VERSION_SQLCODE constant pls_integer := -20001;
    /** Invalid version SQL Error message */
    INVALID_VERSION_SQLERRM constant exception_sqlerrm_type := 'Invalid Version "$1"';
    /** Invalid version SQL Error exception */
    invalid_version_error exception;
    pragma exception_init(invalid_version_error, -20001);

    /** Version too long SQL Error code */
    VERSION_TOO_LONG_SQLCODE constant pls_integer := -20002;
    /** Version too long SQL Error message */
    VERSION_TOO_LONG_SQLERRM constant exception_sqlerrm_type := 'Version is longer than $1 characters';
    /** Version too long SQL Error exception */
    version_too_long_error exception;
    pragma exception_init(version_too_long_error, -20002);

end;
/
