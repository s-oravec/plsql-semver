create or replace package semver_range_impl as

    /**
    
    SemVer Range implementation package
    
    */

    /**
    
    SemVer Range Set string is not valid
    
    */
    ge_invalid_semver_range exception;

    /**
    
    Parses passed string into semver_range object
    
    %param a_value string value
    %return parset semver_range object
    %throw ge_invalid_semver_range when passed value is not valid SemVer Range Set string
    
    */
    function parse(a_value in varchar2) return semver_range;

    /**
    
    Returns if passed a_version satisfies a_range
    
    %param a_version SemVer version object
    %param a_range SemVer Range Set object
    %return true if satisfies else false
    
    */
    function satisfies
    (
        a_version in semver_version,
        a_range   in semver_range
    ) return boolean;

    /**
    
    Returns if passed a_version satisfies a_range
    
    %param a_version SemVer version object
    %param a_range SemVer Range object
    %return true if satisfies else false
    
    */
    function satisfies
    (
        a_version        in semver_version,
        a_comparator_set in semver_comparator_set
    ) return boolean;

    /**
    
    Version satisfies at least one Range definition in Rage Set
    
    %param a_range SemVer Range Set object
    %param a_version SemVer Version object
    %return result of comparison
    
    */
    function test
    (
        a_range   in semver_range,
        a_version in semver_version
    ) return boolean;

    /**
    
    Version satisfies all Comparators in Range 
    
    %param a_range SemVer Range object
    %param a_version SemVer Version object
    %return result of comparison
    
    */
    function test
    (
        a_comparator_set in semver_comparator_set,
        a_version        in semver_version
    ) return boolean;

    /**
    */
    function intersects
    (
        a_this  in semver_comparator_set,
        a_other in semver_comparator_set
    ) return boolean;

    /**    
    */
    function intersects
    (
        a_this  in semver_range,
        a_other in semver_range
    ) return boolean;

    subtype aggregate_function_type is varchar2(3);
    FN_MAX constant aggregate_function_type := 'max';
    FN_MIN constant aggregate_function_type := 'min';
    /** 
    
    min/max version satisfying range
    
    */
    function satisfying
    (
        a_versions           in semver_versions,
        a_range              in semver_range,
        a_aggregate_function in aggregate_function_type
    ) return semver_version;

    /**
    
    version is outside of range - lower or higher
    
    */
    function outside
    (
        a_version in semver_version,
        a_range   in semver_range,
        a_hilo    in semver_lexer.token_type
    ) return boolean;

end;
/
