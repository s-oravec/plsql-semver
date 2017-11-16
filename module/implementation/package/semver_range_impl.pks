create or replace package semver_range_impl as

    /**
    
    SemVer Range implementation package
    
    */

    /**
    
    SemVer Range Set string is not valid
    
    */
    ge_invalid_semver_range_set exception;

    /**
    
    Parses passed string into semver_range_set object
    
    %param a_value string value
    %return parset semver_range_set object
    %throw ge_invalid_semver_range_set when passed value is not valid SemVer Range Set string
    
    */
    function parse(a_value in varchar2) return semver_range_set;

    /**
    
    Returns if passed a_version satisfies a_range_set
    
    %param a_version SemVer version object
    %param a_range_set SemVer Range Set object
    %return true if satisfies else false
    
    */
    function satisfies
    (
        a_version   in semver_version,
        a_range_set in semver_range_set
    ) return boolean;

    /**
    
    Returns if passed a_version satisfies a_range
    
    %param a_version SemVer version object
    %param a_range_set SemVer Range object
    %return true if satisfies else false
    
    */
    function satisfies
    (
        a_version in semver_version,
        a_range   in semver_range
    ) return boolean;

    /**
    
    Version satisfies at least one Range definition in Rage Set
    
    %param a_range_set SemVer Range Set object
    %param a_version SemVer Version object
    %return result of comparison
    
    */
    function test
    (
        a_range_set in semver_range_set,
        a_version   in semver_version
    ) return boolean;

    /**
    
    Version satisfies all Comparators in Range 
    
    %param a_range SemVer Range object
    %param a_version SemVer Version object
    %return result of comparison
    
    */
    function test
    (
        a_range   in semver_range,
        a_version in semver_version
    ) return boolean;

    /**
    */
    function intersects
    (
        a_this  in semver_range,
        a_other in semver_range
    ) return boolean;

    /**    
    */
    function intersects
    (
        a_this  in semver_range_set,
        a_other in semver_range_set
    ) return boolean;

end;
/
